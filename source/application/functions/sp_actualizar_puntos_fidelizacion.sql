-- =============================================================================
-- Stored Procedure: sp_actualizar_puntos_fidelizacion
-- =============================================================================
-- Propósito:
--   Gestionar los puntos del programa de fidelización de clientes,
--   permitiendo acumular puntos por compras o descontar por canjes,
--   manteniendo un historial completo de movimientos.
--
-- Descripción:
--   Este procedure maneja todas las operaciones de puntos de fidelización:
--   - Acumular puntos cuando un cliente realiza una compra
--   - Descontar puntos cuando un cliente canjea beneficios
--   - Validar que el cliente tenga saldo suficiente para canjes
--   - Registrar cada movimiento en el historial para auditoría
--
--   Es invocado automáticamente por sp_registrar_venta cuando se completa
--   una venta, pero también puede usarse manualmente para ajustes o canjes
--   especiales.
--
-- Regla de negocio:
--   "Los clientes acumulan 1 punto por cada ₡1,000 gastados. Los puntos
--   pueden canjearse por descuentos, pero nunca generar saldo negativo."
--
-- Parámetros de entrada:
--   @p_cliente_id   - ID del cliente en el programa de fidelización
--   @p_venta_id     - ID de la venta asociada (NULL para ajustes manuales)
--   @p_puntos       - Cantidad a acumular (positivo) o descontar (negativo)
--   @p_descripcion  - Motivo del movimiento para auditoría
--
-- Parámetros de salida:
--   @p_puntos_nuevos - Saldo actualizado de puntos del cliente
--   @p_exitoso       - TRUE si la operación fue exitosa
--
-- Uso:
--   -- Acumular puntos por venta
--   SELECT * FROM sp_actualizar_puntos_fidelizacion(
--     p_cliente_id := 5,
--     p_venta_id := 123,
--     p_puntos := 15,
--     p_descripcion := 'Compra - Venta #123'
--   );
--
--   -- Canjear puntos por descuento
--   SELECT * FROM sp_actualizar_puntos_fidelizacion(
--     p_cliente_id := 5,
--     p_venta_id := NULL,
--     p_puntos := -50,
--     p_descripcion := 'Canje: Descuento 10%'
--   );
--
-- Dependencias:
--   - Tabla: fidelizacion (almacena puntos totales)
--   - Tabla: fidelizacion_movimiento (historial de transacciones)
--   - Tabla: cliente (validación de existencia)
--   - Invocado por: sp_registrar_venta
--
-- Validaciones implementadas:
--   - Verifica que el cliente tenga registro de fidelización
--   - Valida saldo suficiente para canjes (no permite negativos)
--   - Registra cada movimiento para trazabilidad
--
-- Nota de negocio:
--   Los puntos no tienen fecha de expiración en la versión actual.
--   Una mejora futura podría implementar vencimiento de puntos.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE FUNCTION sp_actualizar_puntos_fidelizacion(
  p_cliente_id    INT,
  p_puntos        INT,
  p_descripcion   TEXT,
  OUT p_puntos_nuevos INT,
  OUT p_exitoso   BOOLEAN,
  p_venta_id      BIGINT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_fidelizacion_id  INT;
  v_puntos_actuales  INT;
BEGIN
  p_exitoso := FALSE;

  -- Validar que los puntos no sean cero
  IF p_puntos = 0 THEN
    RAISE EXCEPTION 'La cantidad de puntos no puede ser cero';
  END IF;

  -- Obtener registro de fidelización del cliente
  SELECT id, puntos_totales 
  INTO v_fidelizacion_id, v_puntos_actuales
  FROM fidelizacion
  WHERE cliente_id = p_cliente_id;

  -- Validar que existe registro de fidelización
  IF v_fidelizacion_id IS NULL THEN
    RAISE EXCEPTION 'El cliente_id % no tiene registro de fidelización activo', 
      p_cliente_id;
  END IF;

  -- Validar saldo suficiente para canjes (puntos negativos)
  IF p_puntos < 0 AND v_puntos_actuales + p_puntos < 0 THEN
    RAISE EXCEPTION 'Puntos insuficientes para el canje. Disponibles: %, Solicitados: %',
      v_puntos_actuales, 
      ABS(p_puntos);
  END IF;

  -- Actualizar puntos totales en tabla fidelizacion
  UPDATE fidelizacion
  SET puntos_totales = puntos_totales + p_puntos
  WHERE id = v_fidelizacion_id
  RETURNING puntos_totales INTO p_puntos_nuevos;

  -- Registrar movimiento en historial para auditoría
  INSERT INTO fidelizacion_movimiento (
    fidelizacion_id,
    puntos,
    descripcion,
    fecha
  )
  VALUES (
    v_fidelizacion_id,
    p_puntos,
    p_descripcion,
    NOW()
  );

  p_exitoso := TRUE;

EXCEPTION
  WHEN OTHERS THEN
    p_exitoso := FALSE;
    RAISE EXCEPTION 'Error al actualizar puntos de fidelización: %', SQLERRM;
END;
$$;

-- =============================================================================
-- Fin del stored procedure: sp_actualizar_puntos_fidelizacion
-- =============================================================================
