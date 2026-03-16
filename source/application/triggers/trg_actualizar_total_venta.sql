-- =============================================================================
-- Trigger: trg_actualizar_total_venta
-- =============================================================================
-- Propósito:
--   Recalcular automáticamente los totales del encabezado de venta
--   (subtotal, impuesto, total) cada vez que se modifica el detalle,
--   garantizando consistencia entre el desglose y el monto final.
--
-- Descripción:
--   Este trigger se ejecuta en tres escenarios:
--   - INSERT: Cuando se agrega un nuevo ítem a la venta
--   - UPDATE: Cuando se modifica cantidad o precio de un ítem existente
--   - DELETE: Cuando se elimina un ítem de la venta
--
--   Para cada operación:
--   1. Suma todos los subtotales de venta_detalle
--   2. Aplica el descuento (si existe) en el encabezado
--   3. Calcula el IVA del 13% sobre (subtotal - descuento)
--   4. Calcula el total final
--   5. Actualiza la tabla venta con los valores recalculados
--
--   Solo procesa ventas en estado 'abierta' para evitar modificar
--   ventas ya pagadas o anuladas.
--
-- Regla de negocio:
--   "El total de una venta debe calcularse siempre desde sus líneas de
--   detalle para evitar inconsistencias entre el encabezado y el desglose."
--
-- Evento: AFTER INSERT OR UPDATE OR DELETE sobre venta_detalle
-- Tipo: FOR EACH ROW
--
-- Dependencias:
--   - Tabla: venta_detalle (disparador)
--   - Tabla: venta (donde se actualizan los totales)
--   - Tipo ENUM: estado_venta
--   - Stored Procedure: sp_registrar_venta (contexto de uso)
--
-- Cálculo de impuestos:
--   Base imponible = subtotal - descuento
--   IVA (13%) = base_imponible × 0.13
--   Total = subtotal - descuento + IVA
--
-- Ejemplo:
--   Subtotal:  ₡10,000
--   Descuento: ₡1,000
--   Base:      ₡9,000
--   IVA (13%): ₡1,170
--   Total:     ₡10,170
--
-- Nota técnica:
--   Este trigger y trg_descontar_inventario_por_venta se disparan en la
--   misma operación (INSERT en venta_detalle), pero son independientes.
--   PostgreSQL los ejecuta en el orden en que fueron creados.
--
-- Fecha creación: 2026-03-16
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
    
    -- Calcular subtotal sumando todas las líneas de detalle
    SELECT COALESCE(SUM(subtotal_linea), 0)
    INTO v_subtotal
    FROM venta_detalle
    WHERE venta_id = v_venta_id;

    -- Obtener descuento actual del encabezado (si existe)
    SELECT descuento INTO v_descuento
    FROM venta
    WHERE id = v_venta_id;

    v_descuento := COALESCE(v_descuento, 0);

    -- Calcular IVA del 13% (Costa Rica) sobre subtotal menos descuento
    v_impuesto := ROUND((v_subtotal - v_descuento) * 0.13, 2);

    -- Calcular total final
    v_total := v_subtotal - v_descuento + v_impuesto;

    -- Actualizar el encabezado de la venta
    UPDATE venta
    SET
      subtotal = v_subtotal,
      impuesto = v_impuesto,
      total = v_total
    WHERE id = v_venta_id;

  END IF;

  -- Retornar el registro apropiado según la operación
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

-- =============================================================================
-- Fin del trigger: trg_actualizar_total_venta
-- =============================================================================
