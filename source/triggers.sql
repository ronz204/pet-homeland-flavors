-- =============================================================================
-- 1. trg_descontar_inventario_por_venta
-- Área: Control de inventario automático
-- Evento: AFTER INSERT sobre venta_detalle
-- =============================================================================

-- Función del trigger
CREATE OR REPLACE FUNCTION fn_descontar_inventario_por_venta()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_local_id         INT;
  v_ingrediente_rec  RECORD;
  v_inv_local_id     BIGINT;
  v_stock_actual     NUMERIC(12, 3);
  v_cantidad_consumo NUMERIC(12, 3);
BEGIN
  -- Obtener el local_id desde la venta
  SELECT local_id INTO v_local_id
  FROM venta
  WHERE id = NEW.venta_id;

  -- Procesar cada ingrediente de la receta vigente
  FOR v_ingrediente_rec IN
    SELECT
      ri.ingrediente_id,
      ri.cantidad AS cantidad_unitaria,
      i.nombre AS ingrediente_nombre
    FROM receta_ingrediente ri
    INNER JOIN ingrediente i ON ri.ingrediente_id = i.id
    WHERE ri.receta_id = NEW.receta_id
      AND ri.es_opcional = FALSE
  LOOP
    -- Calcular cantidad total a consumir
    v_cantidad_consumo := v_ingrediente_rec.cantidad_unitaria * NEW.cantidad;

    -- Obtener el registro de inventario local con bloqueo
    SELECT id, cantidad_actual INTO v_inv_local_id, v_stock_actual
    FROM inventario_local
    WHERE local_id = v_local_id
      AND ingrediente_id = v_ingrediente_rec.ingrediente_id
    FOR UPDATE;

    -- Validar que existe el ingrediente en inventario
    IF v_inv_local_id IS NULL THEN
      RAISE EXCEPTION 'El ingrediente "%" (ID %) no existe en el inventario del local_id %',
        v_ingrediente_rec.ingrediente_nombre,
        v_ingrediente_rec.ingrediente_id,
        v_local_id;
    END IF;

    -- Validar stock suficiente
    IF v_stock_actual < v_cantidad_consumo THEN
      RAISE EXCEPTION 'Stock insuficiente de "%" en local_id %. Disponible: %, Requerido: %',
        v_ingrediente_rec.ingrediente_nombre,
        v_local_id,
        v_stock_actual,
        v_cantidad_consumo;
    END IF;

    -- Descontar del inventario
    UPDATE inventario_local
    SET
      cantidad_actual = cantidad_actual - v_cantidad_consumo,
      ultima_actualizacion = NOW()
    WHERE id = v_inv_local_id;

    -- Registrar movimiento de inventario
    INSERT INTO movimiento_inventario (
      inventario_local_id,
      tipo_movimiento,
      cantidad,
      fecha,
      referencia_id,
      referencia_tipo,
      observacion
    )
    VALUES (
      v_inv_local_id,
      'salida',
      v_cantidad_consumo,
      NOW(),
      NEW.venta_id,
      'venta',
      'Venta #' || NEW.venta_id || ' - Detalle #' || NEW.id
    );
  END LOOP;

  RETURN NEW;
END;
$$;

-- Crear el trigger
CREATE TRIGGER trg_descontar_inventario_por_venta
  AFTER INSERT ON venta_detalle
  FOR EACH ROW
  EXECUTE FUNCTION fn_descontar_inventario_por_venta();

-- =============================================================================
-- 2. trg_actualizar_estado_compra
-- Área: Actualización de estados automática
-- Evento: AFTER UPDATE sobre compra
-- =============================================================================

-- Función del trigger
CREATE OR REPLACE FUNCTION fn_actualizar_estado_compra()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_detalle_rec  RECORD;
  v_inv_local_id BIGINT;
BEGIN
  -- Solo procesar cuando cambia a 'recibida' desde otro estado
  IF NEW.estado = 'recibida' AND OLD.estado <> 'recibida' THEN
    
    -- Procesar cada ingrediente de la compra
    FOR v_detalle_rec IN
      SELECT
        cd.ingrediente_id,
        cd.cantidad,
        i.nombre AS ingrediente_nombre
      FROM compra_detalle cd
      INNER JOIN ingrediente i ON cd.ingrediente_id = i.id
      WHERE cd.compra_id = NEW.id
    LOOP
      -- Buscar o crear registro en inventario_local
      SELECT id INTO v_inv_local_id
      FROM inventario_local
      WHERE local_id = NEW.local_id
        AND ingrediente_id = v_detalle_rec.ingrediente_id;

      IF v_inv_local_id IS NULL THEN
        -- Crear nuevo registro de inventario
        INSERT INTO inventario_local (
          local_id,
          ingrediente_id,
          cantidad_actual,
          cantidad_minima,
          ultima_actualizacion
        )
        VALUES (
          NEW.local_id,
          v_detalle_rec.ingrediente_id,
          v_detalle_rec.cantidad,
          0,
          NOW()
        )
        RETURNING id INTO v_inv_local_id;
      ELSE
        -- Actualizar inventario existente
        UPDATE inventario_local
        SET
          cantidad_actual = cantidad_actual + v_detalle_rec.cantidad,
          ultima_actualizacion = NOW()
        WHERE id = v_inv_local_id;
      END IF;

      -- Registrar movimiento de inventario
      INSERT INTO movimiento_inventario (
        inventario_local_id,
        tipo_movimiento,
        cantidad,
        fecha,
        referencia_id,
        referencia_tipo,
        observacion,
        empleado_id
      )
      VALUES (
        v_inv_local_id,
        'entrada',
        v_detalle_rec.cantidad,
        NOW(),
        NEW.id,
        'compra',
        'Compra #' || NEW.id || ' - ' || v_detalle_rec.ingrediente_nombre,
        NEW.empleado_id
      );
    END LOOP;

    -- Actualizar fecha de recepción si no está establecida
    IF NEW.fecha_recepcion IS NULL THEN
      UPDATE compra
      SET fecha_recepcion = NOW()
      WHERE id = NEW.id;
    END IF;

  END IF;

  RETURN NEW;
END;
$$;

-- Crear el trigger
CREATE TRIGGER trg_actualizar_estado_compra
  AFTER UPDATE ON compra
  FOR EACH ROW
  EXECUTE FUNCTION fn_actualizar_estado_compra();

-- =============================================================================
-- 3. trg_auditoria_precio_plato
-- Área: Historial de cambios / Auditoría
-- Evento: AFTER UPDATE sobre plato
-- =============================================================================

-- Función del trigger
CREATE OR REPLACE FUNCTION fn_auditoria_precio_plato()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Solo auditar si el precio realmente cambió
  IF NEW.precio_base <> OLD.precio_base THEN
    INSERT INTO auditoria_precio_plato (
      plato_id,
      precio_anterior,
      precio_nuevo,
      usuario_db,
      fecha_cambio
    )
    VALUES (
      NEW.id,
      OLD.precio_base,
      NEW.precio_base,
      current_user,
      NOW()
    );
  END IF;

  RETURN NEW;
END;
$$;

-- Crear el trigger
CREATE TRIGGER trg_auditoria_precio_plato
  AFTER UPDATE ON plato
  FOR EACH ROW
  EXECUTE FUNCTION fn_auditoria_precio_plato();

-- =============================================================================
-- 4. trg_actualizar_total_venta
-- Área: Actualización de estados automática
-- Evento: AFTER INSERT OR UPDATE OR DELETE sobre venta_detalle
-- =============================================================================

-- Función del trigger
CREATE OR REPLACE FUNCTION fn_actualizar_total_venta()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_venta_id        BIGINT;
  v_subtotal        NUMERIC(12, 2);
  v_descuento       NUMERIC(10, 2);
  v_impuesto        NUMERIC(10, 2);
  v_total           NUMERIC(12, 2);
  v_estado_venta    estado_venta;
BEGIN
  -- Determinar el ID de la venta afectada
  IF TG_OP = 'DELETE' THEN
    v_venta_id := OLD.venta_id;
  ELSE
    v_venta_id := NEW.venta_id;
  END IF;

  -- Verificar el estado de la venta
  SELECT estado INTO v_estado_venta
  FROM venta
  WHERE id = v_venta_id;

  -- Solo actualizar si la venta está en estado 'abierta'
  IF v_estado_venta = 'abierta' THEN
    
    -- Calcular subtotal desde las líneas de detalle
    SELECT COALESCE(SUM(subtotal_linea), 0)
    INTO v_subtotal
    FROM venta_detalle
    WHERE venta_id = v_venta_id;

    -- Obtener descuento actual (si existe)
    SELECT descuento INTO v_descuento
    FROM venta
    WHERE id = v_venta_id;

    v_descuento := COALESCE(v_descuento, 0);

    -- Calcular impuesto (13% IVA Costa Rica sobre subtotal - descuento)
    v_impuesto := ROUND((v_subtotal - v_descuento) * 0.13, 2);

    -- Calcular total
    v_total := v_subtotal - v_descuento + v_impuesto;

    -- Actualizar la venta
    UPDATE venta
    SET
      subtotal = v_subtotal,
      impuesto = v_impuesto,
      total = v_total
    WHERE id = v_venta_id;

  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;

-- Crear el trigger
CREATE TRIGGER trg_actualizar_total_venta
  AFTER INSERT OR UPDATE OR DELETE ON venta_detalle
  FOR EACH ROW
  EXECUTE FUNCTION fn_actualizar_total_venta();
