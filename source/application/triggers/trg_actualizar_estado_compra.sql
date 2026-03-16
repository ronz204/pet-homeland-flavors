-- =============================================================================
-- Trigger: trg_actualizar_estado_compra
-- =============================================================================
-- Propósito:
--   Actualizar automáticamente el inventario local cuando una compra de
--   ingredientes es recibida físicamente en el local, manteniendo la
--   separación entre la orden de compra y la recepción efectiva.
--
-- Descripción:
--   Cuando el estado de una compra cambia a 'recibida':
--   1. Recorre todos los ingredientes de la compra (compra_detalle)
--   2. Suma las cantidades recibidas al inventario_local del local destino
--   3. Crea o actualiza el registro de inventario según corresponda
--   4. Registra cada movimiento en movimiento_inventario con tipo 'entrada'
--   5. Actualiza la fecha_recepcion si no estaba establecida
--
--   Este trigger complementa al sp_registrar_compra cuando la recepción
--   ocurre en un momento posterior al registro de la orden.
--
-- Regla de negocio:
--   "El inventario solo se actualiza cuando la mercadería es efectivamente
--   recibida en el local, no al momento de ordenar."
--
-- Evento: AFTER UPDATE sobre compra
-- Tipo: FOR EACH ROW
--
-- Dependencias:
--   - Tabla: compra (disparador)
--   - Tabla: compra_detalle (ingredientes de la compra)
--   - Tabla: ingrediente (información del insumo)
--   - Tabla: inventario_local (stock por local)
--   - Tabla: movimiento_inventario (trazabilidad)
--   - Stored Procedure: sp_registrar_compra (contexto de uso)
--
-- Condiciones de ejecución:
--   Solo se ejecuta cuando:
--   - El estado nuevo es 'recibida' AND
--   - El estado anterior era diferente a 'recibida'
--
--   Esto evita procesamiento duplicado si se actualiza una compra ya recibida.
--
-- Nota técnica:
--   Si el ingrediente no existe en inventario_local, lo crea automáticamente
--   con los valores iniciales apropiados. Si ya existe, solo suma la cantidad.
--
-- Fecha creación: 2026-03-16
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
      -- Buscar si ya existe registro en inventario_local
      SELECT id INTO v_inv_local_id
      FROM inventario_local
      WHERE local_id = NEW.local_id
        AND ingrediente_id = v_detalle_rec.ingrediente_id;

      IF v_inv_local_id IS NULL THEN
        -- Crear nuevo registro de inventario si no existe
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
          0,  -- Valor por defecto, se ajustará posteriormente
          NOW()
        )
        RETURNING id INTO v_inv_local_id;
      ELSE
        -- Actualizar inventario existente sumando la cantidad recibida
        UPDATE inventario_local
        SET
          cantidad_actual = cantidad_actual + v_detalle_rec.cantidad,
          ultima_actualizacion = NOW()
        WHERE id = v_inv_local_id;
      END IF;

      -- Registrar movimiento de inventario para trazabilidad
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

    -- Actualizar fecha de recepción si no estaba establecida
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
-- Fin del trigger: trg_actualizar_estado_compra
-- =============================================================================
