-- =============================================================================
-- Stored Procedure: sp_registrar_compra
-- =============================================================================
-- Propósito:
--   Registrar una orden de compra de ingredientes a un proveedor,
--   delegando la actualización del inventario al trigger cuando
--   la compra sea marcada como recibida.
--
-- Descripción:
--   Este procedure gestiona el proceso de compra de ingredientes:
--   1. Crea el encabezado de compra en estado 'pendiente'
--   2. Inserta cada ingrediente en compra_detalle con cantidad y precio
--   3. Calcula el total de la compra automáticamente
--   4. Si se marca como recibida, actualiza el estado
--   5. El trigger trg_actualizar_estado_compra se encarga de:
--      - Actualizar el inventario_local sumando cantidades
--      - Registrar movimientos de tipo 'entrada'
--      - Establecer fecha_recepcion
--
--   Esto permite separar el momento de ordenar del momento de recibir,
--   útil cuando hay tiempo de entrega entre ambos eventos.
--
-- Regla de negocio:
--   "El inventario solo se actualiza cuando la mercadería es recibida
--   físicamente, no al momento de generar la orden de compra."
--
-- Parámetros de entrada:
--   @p_local_id      - Local que recibe los ingredientes
--   @p_proveedor_id  - Proveedor que suministra
--   @p_empleado_id   - Empleado que gestiona la compra
--   @p_ingredientes  - JSON array: [{"ingrediente_id": 1, "cantidad": 50, "precio_unitario": 500}]
--   @p_recibida      - TRUE si se recibe inmediatamente, FALSE si es solo orden
--
-- Parámetros de salida:
--   @p_compra_id - ID de la compra generada
--   @p_total     - Monto total de la compra
--
-- Uso:
--   -- Registrar orden pendiente (inventario no se actualiza aún)
--   SELECT * FROM sp_registrar_compra(
--     p_local_id := 1,
--     p_proveedor_id := 3,
--     p_empleado_id := 8,
--     p_ingredientes := '[
--       {"ingrediente_id": 15, "cantidad": 100, "precio_unitario": 1200},
--       {"ingrediente_id": 22, "cantidad": 50, "precio_unitario": 850}
--     ]'::jsonb,
--     p_recibida := FALSE
--   );
--
--   -- Registrar compra recibida inmediatamente (inventario se actualiza)
--   SELECT * FROM sp_registrar_compra(
--     p_local_id := 1,
--     p_proveedor_id := 3,
--     p_empleado_id := 8,
--     p_ingredientes := '[...]'::jsonb,
--     p_recibida := TRUE
--   );
--
-- Dependencias:
--   - Tabla: compra, compra_detalle
--   - Tabla: proveedor, ingrediente (validación de existencia)
--   - Trigger: trg_actualizar_estado_compra (actualiza inventario cuando estado='recibida')
--
-- Validaciones implementadas:
--   - Verifica que el array de ingredientes no esté vacío
--   - Valida cantidades y precios positivos
--   - Calcula total automáticamente desde el detalle
--
-- Nota técnica:
--   Para marcar una compra pendiente como recibida posteriormente:
--     UPDATE compra SET estado = 'recibida' WHERE id = 123;
--   El trigger se encargará automáticamente del inventario.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE FUNCTION sp_registrar_compra(
  p_local_id      INT,
  p_proveedor_id  INT,
  p_empleado_id   INT,
  p_ingredientes  JSONB,
  p_recibida      BOOLEAN,
  OUT p_compra_id INT,
  OUT p_total     NUMERIC(12, 2)
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_ingrediente       JSONB;
  v_ingrediente_id    INT;
  v_cantidad          NUMERIC(12, 3);
  v_precio_unitario   NUMERIC(10, 2);
  v_subtotal          NUMERIC(12, 2);
BEGIN
  -- Validar que el array de ingredientes no esté vacío
  IF jsonb_array_length(p_ingredientes) = 0 THEN
    RAISE EXCEPTION 'La compra debe incluir al menos un ingrediente';
  END IF;

  -- Crear encabezado de compra en estado 'pendiente'
  -- El trigger manejará la actualización de inventario cuando cambie a 'recibida'
  INSERT INTO compra (
    local_id,
    proveedor_id,
    empleado_id,
    fecha_compra,
    fecha_recepcion,
    estado,
    total
  )
  VALUES (
    p_local_id,
    p_proveedor_id,
    p_empleado_id,
    NOW(),
    NULL,
    'pendiente',
    0
  )
  RETURNING id INTO p_compra_id;

  p_total := 0;

  -- Procesar cada ingrediente de la compra
  FOR v_ingrediente IN SELECT * FROM jsonb_array_elements(p_ingredientes)
  LOOP
    v_ingrediente_id := (v_ingrediente->>'ingrediente_id')::INT;
    v_cantidad := (v_ingrediente->>'cantidad')::NUMERIC(12, 3);
    v_precio_unitario := (v_ingrediente->>'precio_unitario')::NUMERIC(10, 2);

    -- Validar cantidad positiva
    IF v_cantidad <= 0 THEN
      RAISE EXCEPTION 'La cantidad del ingrediente_id % debe ser mayor a cero', 
        v_ingrediente_id;
    END IF;

    -- Validar precio no negativo (puede ser cero para donaciones)
    IF v_precio_unitario < 0 THEN
      RAISE EXCEPTION 'El precio del ingrediente_id % no puede ser negativo', 
        v_ingrediente_id;
    END IF;

    -- Calcular subtotal de la línea
    v_subtotal := v_cantidad * v_precio_unitario;

    -- Insertar detalle de compra
    INSERT INTO compra_detalle (
      compra_id,
      ingrediente_id,
      cantidad,
      precio_unitario
    )
    VALUES (
      p_compra_id,
      v_ingrediente_id,
      v_cantidad,
      v_precio_unitario
    );

    -- Acumular total
    p_total := p_total + v_subtotal;
  END LOOP;

  -- Actualizar el total en el encabezado de compra
  UPDATE compra
  SET total = p_total
  WHERE id = p_compra_id;

  -- Si la compra está marcada como recibida, actualizar el estado
  -- IMPORTANTE: El trigger trg_actualizar_estado_compra se disparará
  -- automáticamente y actualizará el inventario_local con las cantidades
  IF p_recibida THEN
    UPDATE compra
    SET
      estado = 'recibida',
      fecha_recepcion = NOW()
    WHERE id = p_compra_id;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error al registrar compra: %', SQLERRM;
END;
$$;

-- =============================================================================
-- Fin del stored procedure: sp_registrar_compra
-- =============================================================================
