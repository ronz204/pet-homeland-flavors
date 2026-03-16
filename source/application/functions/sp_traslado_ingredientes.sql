-- =============================================================================
-- Stored Procedure: sp_traslado_ingredientes
-- =============================================================================
-- Propósito:
--   Gestionar el traslado de ingredientes entre dos locales de forma
--   atómica, actualizando inventarios en ambos lados y manteniendo
--   trazabilidad completa del movimiento.
--
-- Descripción:
--   Este procedure es crítico para la distribución de inventario:
--   1. Valida que los locales sean diferentes
--   2. Crea el encabezado del traslado en estado 'solicitado'
--   3. Para cada ingrediente:
--      - Verifica stock suficiente en el local origen (con bloqueo FOR UPDATE)
--      - Descuenta del inventario origen
--      - Registra movimiento de tipo 'traslado_salida'
--      - Suma al inventario destino (crea registro si no existe)
--      - Registra movimiento de tipo 'traslado_entrada'
--   4. Cambia el estado del traslado a 'recibido'
--
--   Si falta stock en algún ingrediente, toda la operación se cancela
--   para evitar traslados parciales.
--
-- Regla de negocio:
--   "Los traslados entre locales deben ser completos y atómicos. Si un
--   ingrediente no tiene stock suficiente, todo el traslado se cancela."
--
-- Parámetros de entrada:
--   @p_local_origen_id  - Local que envía los ingredientes
--   @p_local_destino_id - Local que recibe los ingredientes
--   @p_empleado_id      - Empleado que solicita el traslado
--   @p_ingredientes     - JSON array: [{"ingrediente_id": 1, "cantidad": 10}]
--
-- Parámetros de salida:
--   @p_traslado_id - ID del traslado generado
--   @p_exitoso     - TRUE si el traslado fue exitoso
--
-- Uso:
--   SELECT * FROM sp_traslado_ingredientes(
--     p_local_origen_id := 1,
--     p_local_destino_id := 3,
--     p_empleado_id := 12,
--     p_ingredientes := '[
--       {"ingrediente_id": 8, "cantidad": 25},
--       {"ingrediente_id": 15, "cantidad": 10.5},
--       {"ingrediente_id": 22, "cantidad": 50}
--     ]'::jsonb
--   );
--
-- Dependencias:
--   - Tabla: traslado_interno, traslado_detalle
--   - Tabla: inventario_local (origen y destino)
--   - Tabla: movimiento_inventario (trazabilidad)
--
-- Validaciones implementadas:
--   - Verifica que origen y destino sean diferentes
--   - Valida stock suficiente en origen (con bloqueo de fila)
--   - Verifica que el ingrediente exista en inventario origen
--   - Crea inventario destino automáticamente si no existe
--   - Valida cantidades positivas
--
-- Nota técnica:
--   Usa SELECT ... FOR UPDATE para bloquear el registro de inventario
--   origen durante la transacción, evitando condiciones de carrera si
--   múltiples usuarios solicitan traslados simultáneamente.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE FUNCTION sp_traslado_ingredientes(
  p_local_origen_id  INT,
  p_local_destino_id INT,
  p_empleado_id      INT,
  p_ingredientes     JSONB,
  OUT p_traslado_id  INT,
  OUT p_exitoso      BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_ingrediente      JSONB;
  v_ingrediente_id   INT;
  v_cantidad         NUMERIC(12, 3);
  v_inv_origen_id    BIGINT;
  v_inv_destino_id   BIGINT;
  v_stock_origen     NUMERIC(12, 3);
BEGIN
  p_exitoso := FALSE;

  -- Validar que el array de ingredientes no esté vacío
  IF jsonb_array_length(p_ingredientes) = 0 THEN
    RAISE EXCEPTION 'El traslado debe incluir al menos un ingrediente';
  END IF;

  -- Validar que los locales sean diferentes
  IF p_local_origen_id = p_local_destino_id THEN
    RAISE EXCEPTION 'El local de origen y destino no pueden ser el mismo';
  END IF;

  -- Crear encabezado de traslado en estado 'solicitado'
  INSERT INTO traslado_interno (
    local_origen_id,
    local_destino_id,
    empleado_id,
    fecha_solicitud,
    estado
  )
  VALUES (
    p_local_origen_id,
    p_local_destino_id,
    p_empleado_id,
    NOW(),
    'solicitado'
  )
  RETURNING id INTO p_traslado_id;

  -- Procesar cada ingrediente del traslado
  FOR v_ingrediente IN SELECT * FROM jsonb_array_elements(p_ingredientes)
  LOOP
    v_ingrediente_id := (v_ingrediente->>'ingrediente_id')::INT;
    v_cantidad := (v_ingrediente->>'cantidad')::NUMERIC(12, 3);

    -- Validar cantidad positiva
    IF v_cantidad <= 0 THEN
      RAISE EXCEPTION 'La cantidad del ingrediente_id % debe ser mayor a cero', 
        v_ingrediente_id;
    END IF;

    -- Obtener inventario de origen con bloqueo para concurrencia
    -- FOR UPDATE evita que otro proceso modifique el stock simultáneamente
    SELECT id, cantidad_actual 
    INTO v_inv_origen_id, v_stock_origen
    FROM inventario_local
    WHERE local_id = p_local_origen_id
      AND ingrediente_id = v_ingrediente_id
    FOR UPDATE;

    -- Validar que el ingrediente existe en el inventario origen
    IF v_inv_origen_id IS NULL THEN
      RAISE EXCEPTION 'El ingrediente_id % no existe en el inventario del local origen (local_id %)',
        v_ingrediente_id, 
        p_local_origen_id;
    END IF;

    -- Validar stock suficiente en origen
    IF v_stock_origen < v_cantidad THEN
      RAISE EXCEPTION 'Stock insuficiente del ingrediente_id % en local origen. Disponible: %, Solicitado: %',
        v_ingrediente_id, 
        v_stock_origen, 
        v_cantidad;
    END IF;

    -- Insertar detalle del traslado
    INSERT INTO traslado_detalle (
      traslado_id,
      ingrediente_id,
      cantidad
    )
    VALUES (
      p_traslado_id,
      v_ingrediente_id,
      v_cantidad
    );

    -- Descontar del inventario origen
    UPDATE inventario_local
    SET
      cantidad_actual = cantidad_actual - v_cantidad,
      ultima_actualizacion = NOW()
    WHERE id = v_inv_origen_id;

    -- Registrar movimiento de salida en origen
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
      v_inv_origen_id,
      'traslado_salida',
      v_cantidad,
      NOW(),
      p_traslado_id,
      'traslado',
      'Traslado #' || p_traslado_id || ' hacia local_id ' || p_local_destino_id,
      p_empleado_id
    );

    -- Buscar o crear inventario en local destino
    SELECT id INTO v_inv_destino_id
    FROM inventario_local
    WHERE local_id = p_local_destino_id
      AND ingrediente_id = v_ingrediente_id;

    IF v_inv_destino_id IS NULL THEN
      -- Crear nuevo registro de inventario en destino
      INSERT INTO inventario_local (
        local_id,
        ingrediente_id,
        cantidad_actual,
        cantidad_minima,
        ultima_actualizacion
      )
      VALUES (
        p_local_destino_id,
        v_ingrediente_id,
        v_cantidad,
        0,  -- Se ajustará posteriormente según necesidades
        NOW()
      )
      RETURNING id INTO v_inv_destino_id;
    ELSE
      -- Actualizar inventario existente en destino
      UPDATE inventario_local
      SET
        cantidad_actual = cantidad_actual + v_cantidad,
        ultima_actualizacion = NOW()
      WHERE id = v_inv_destino_id;
    END IF;

    -- Registrar movimiento de entrada en destino
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
      v_inv_destino_id,
      'traslado_entrada',
      v_cantidad,
      NOW(),
      p_traslado_id,
      'traslado',
      'Traslado #' || p_traslado_id || ' desde local_id ' || p_local_origen_id,
      p_empleado_id
    );
  END LOOP;

  -- Actualizar estado del traslado a 'recibido' y registrar fecha
  UPDATE traslado_interno
  SET
    estado = 'recibido',
    fecha_recepcion = NOW()
  WHERE id = p_traslado_id;

  p_exitoso := TRUE;

EXCEPTION
  WHEN OTHERS THEN
    p_exitoso := FALSE;
    RAISE EXCEPTION 'Error al procesar traslado: %', SQLERRM;
END;
$$;

-- =============================================================================
-- Fin del stored procedure: sp_traslado_ingredientes
-- =============================================================================
