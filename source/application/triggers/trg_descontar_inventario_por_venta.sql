-- =============================================================================
-- Trigger: trg_descontar_inventario_por_venta
-- =============================================================================
-- Propósito:
--   Descontar automáticamente el inventario de ingredientes cuando se
--   registra una venta, garantizando que el stock refleje el consumo real
--   de cada plato vendido según su receta vigente.
--
-- Descripción:
--   Cada vez que se inserta una línea en venta_detalle, este trigger:
--   1. Consulta la receta vigente del plato vendido
--   2. Calcula la cantidad de cada ingrediente necesario (cantidad plato × receta)
--   3. Descuenta el stock del inventario_local del local de la venta
--   4. Registra el movimiento en movimiento_inventario con tipo 'salida'
--
--   Si no hay stock suficiente, la operación se cancela con una excepción,
--   protegiendo la integridad del inventario.
--
-- Regla de negocio:
--   "Cada plato vendido consume ingredientes del inventario del local 
--   según su receta estandarizada."
--
-- Evento: AFTER INSERT sobre venta_detalle
-- Tipo: FOR EACH ROW
--
-- Dependencias:
--   - Tabla: venta_detalle (disparador)
--   - Tabla: venta (para obtener local_id)
--   - Tabla: receta_ingrediente (composición del plato)
--   - Tabla: ingrediente (información del insumo)
--   - Tabla: inventario_local (stock por local)
--   - Tabla: movimiento_inventario (trazabilidad)
--   - Stored Procedure: sp_registrar_venta (contexto de uso)
--
-- Validaciones implementadas:
--   - Verifica que el ingrediente exista en el inventario del local
--   - Verifica que haya stock suficiente antes de descontar
--   - Bloquea el registro de inventario con FOR UPDATE para concurrencia
--
-- Nota técnica:
--   Solo procesa ingredientes NO opcionales (es_opcional = FALSE).
--   Los ingredientes opcionales no afectan el inventario automáticamente.
--
-- Fecha creación: 2026-03-16
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
  -- Obtener el local donde se realizó la venta
  SELECT local_id INTO v_local_id
  FROM venta
  WHERE id = NEW.venta_id;

  -- Procesar cada ingrediente de la receta vigente del plato
  FOR v_ingrediente_rec IN
    SELECT
      ri.ingrediente_id,
      ri.cantidad AS cantidad_unitaria,
      i.nombre AS ingrediente_nombre
    FROM receta_ingrediente ri
    INNER JOIN ingrediente i ON ri.ingrediente_id = i.id
    WHERE ri.receta_id = NEW.receta_id
      AND ri.es_opcional = FALSE  -- Solo ingredientes obligatorios
  LOOP
    -- Calcular cantidad total a consumir
    v_cantidad_consumo := v_ingrediente_rec.cantidad_unitaria * NEW.cantidad;

    -- Obtener el registro de inventario local con bloqueo para concurrencia
    SELECT id, cantidad_actual INTO v_inv_local_id, v_stock_actual
    FROM inventario_local
    WHERE local_id = v_local_id
      AND ingrediente_id = v_ingrediente_rec.ingrediente_id
    FOR UPDATE;

    -- Validar que existe el ingrediente en el inventario del local
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

    -- Registrar movimiento de inventario para trazabilidad
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
-- Fin del trigger: trg_descontar_inventario_por_venta
-- =============================================================================
