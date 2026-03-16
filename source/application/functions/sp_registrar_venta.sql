-- =============================================================================
-- Stored Procedure: sp_registrar_venta
-- =============================================================================
-- Propósito:
--   Registrar una venta completa de forma atómica, incluyendo encabezado,
--   detalle, pago y puntos de fidelización, delegando el control de
--   inventario y cálculo de totales a los triggers correspondientes.
--
-- Descripción:
--   Este procedure es el punto central del proceso de venta:
--   1. Crea el encabezado en la tabla venta (estado: 'abierta')
--   2. Inserta cada plato vendido en venta_detalle con su receta vigente
--   3. Los triggers automáticamente:
--      - Descuentan ingredientes del inventario (trg_descontar_inventario_por_venta)
--      - Calculan subtotal, IVA y total (trg_actualizar_total_venta)
--   4. Actualiza puntos ganados (1 punto por cada ₡1,000)
--   5. Cambia el estado a 'pagada'
--   6. Registra el método de pago
--   7. Acumula puntos de fidelización si aplica
--
--   Si cualquier paso falla (ej: sin stock), toda la transacción se revierte.
--
-- Regla de negocio:
--   "Cada venta debe ser atómica: o se completa totalmente (con inventario
--   descontado y pago registrado) o se cancela completamente."
--
-- Parámetros de entrada:
--   @p_local_id       - Local donde se realiza la venta
--   @p_empleado_id    - ID del empleado (cajero/mesero) que procesa
--   @p_cliente_id     - ID del cliente (NULL para ventas sin cliente)
--   @p_tipo_servicio  - 'salon', 'para_llevar' o 'evento'
--   @p_platos         - JSON array: [{"plato_id": 1, "cantidad": 2, "precio_unitario": 5000}]
--   @p_metodo_pago_id - Forma de pago (efectivo, tarjeta, SINPE, etc.)
--   @p_monto_pago     - Monto recibido del cliente
--
-- Parámetros de salida:
--   @p_venta_id - ID de la venta creada (útil para facturación)
--   @p_cambio   - Vuelto a devolver al cliente
--
-- Uso:
--   SELECT * FROM sp_registrar_venta(
--     p_local_id := 1,
--     p_empleado_id := 10,
--     p_cliente_id := 25,
--     p_tipo_servicio := 'salon',
--     p_platos := '[
--       {"plato_id": 5, "cantidad": 2, "precio_unitario": 8500},
--       {"plato_id": 12, "cantidad": 1, "precio_unitario": 6500}
--     ]'::jsonb,
--     p_metodo_pago_id := 1,
--     p_monto_pago := 25000
--   );
--
-- Dependencias:
--   - Tabla: venta, venta_detalle, venta_pago
--   - Tabla: receta (para obtener receta vigente de cada plato)
--   - Trigger: trg_descontar_inventario_por_venta (descuenta stock automáticamente)
--   - Trigger: trg_actualizar_total_venta (calcula totales automáticamente)
--   - Procedure: sp_actualizar_puntos_fidelizacion (acumula puntos)
--
-- Validaciones implementadas:
--   - Verifica que cada plato tenga una receta vigente
--   - Valida que el monto de pago sea suficiente para cubrir el total
--   - Los triggers validan que haya stock suficiente de ingredientes
--
-- Nota técnica:
--   El procedure NO calcula inventario ni totales directamente — los triggers
--   lo hacen automáticamente. Esto evita duplicación de lógica y garantiza
--   que cualquier modificación a venta_detalle (incluso manual) mantenga
--   inventario y totales consistentes.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE FUNCTION sp_registrar_venta(
  p_local_id         INT,
  p_empleado_id      INT,
  p_cliente_id       INT,
  p_tipo_servicio    tipo_servicio,
  p_platos           JSONB,
  p_metodo_pago_id   SMALLINT,
  p_monto_pago       NUMERIC(12, 2),
  OUT p_venta_id     BIGINT,
  OUT p_cambio       NUMERIC(12, 2)
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_plato            JSONB;
  v_plato_id         INT;
  v_cantidad         SMALLINT;
  v_precio_unitario  NUMERIC(10, 2);
  v_receta_id        INT;
  v_total            NUMERIC(12, 2);
  v_puntos_ganados   INT := 0;
BEGIN
  -- Validar que el array de platos no esté vacío
  IF jsonb_array_length(p_platos) = 0 THEN
    RAISE EXCEPTION 'La venta debe incluir al menos un plato';
  END IF;

  -- Validar que el monto de pago sea positivo
  IF p_monto_pago <= 0 THEN
    RAISE EXCEPTION 'El monto de pago debe ser mayor a cero';
  END IF;

  -- Crear encabezado de venta en estado 'abierta'
  -- Los totales se inicializan en 0 y el trigger los calculará
  INSERT INTO venta (
    local_id,
    empleado_id,
    cliente_id,
    tipo_servicio,
    fecha_hora,
    subtotal,
    impuesto,
    total,
    puntos_ganados,
    estado
  )
  VALUES (
    p_local_id,
    p_empleado_id,
    p_cliente_id,
    p_tipo_servicio,
    NOW(),
    0,
    0,
    0,
    0,
    'abierta'
  )
  RETURNING id INTO p_venta_id;

  -- Procesar cada plato del pedido
  FOR v_plato IN SELECT * FROM jsonb_array_elements(p_platos)
  LOOP
    v_plato_id := (v_plato->>'plato_id')::INT;
    v_cantidad := (v_plato->>'cantidad')::SMALLINT;
    v_precio_unitario := (v_plato->>'precio_unitario')::NUMERIC(10, 2);

    -- Validar cantidad positiva
    IF v_cantidad <= 0 THEN
      RAISE EXCEPTION 'La cantidad del plato_id % debe ser mayor a cero', v_plato_id;
    END IF;

    -- Validar precio positivo
    IF v_precio_unitario <= 0 THEN
      RAISE EXCEPTION 'El precio del plato_id % debe ser mayor a cero', v_plato_id;
    END IF;

    -- Obtener la receta vigente del plato
    SELECT id INTO v_receta_id
    FROM receta
    WHERE plato_id = v_plato_id
      AND vigente = TRUE
    LIMIT 1;

    -- Validar que existe receta vigente
    IF v_receta_id IS NULL THEN
      RAISE EXCEPTION 'No existe receta vigente para el plato_id %. Contacte al gerente.', 
        v_plato_id;
    END IF;

    -- Insertar línea de detalle
    -- IMPORTANTE: Al hacer este INSERT, se disparan automáticamente:
    --   1. trg_descontar_inventario_por_venta (descuenta ingredientes)
    --   2. trg_actualizar_total_venta (recalcula subtotal, IVA y total)
    INSERT INTO venta_detalle (
      venta_id,
      plato_id,
      receta_id,
      cantidad,
      precio_unitario,
      descuento_linea
    )
    VALUES (
      p_venta_id,
      v_plato_id,
      v_receta_id,
      v_cantidad,
      v_precio_unitario,
      0
    );
  END LOOP;

  -- Leer el total calculado automáticamente por el trigger
  SELECT total INTO v_total
  FROM venta
  WHERE id = p_venta_id;

  -- Validar que el pago cubra el total
  IF p_monto_pago < v_total THEN
    RAISE EXCEPTION 'Monto de pago insuficiente. Total: %, Pagado: %', 
      v_total, p_monto_pago;
  END IF;

  -- Calcular puntos de fidelización (1 punto por cada ₡1,000)
  IF p_cliente_id IS NOT NULL THEN
    v_puntos_ganados := FLOOR(v_total / 1000);
  END IF;

  -- Actualizar estado de venta a 'pagada' y registrar puntos
  UPDATE venta
  SET
    puntos_ganados = v_puntos_ganados,
    estado = 'pagada'
  WHERE id = p_venta_id;

  -- Registrar método de pago
  INSERT INTO venta_pago (
    venta_id,
    metodo_pago_id,
    monto,
    referencia
  )
  VALUES (
    p_venta_id,
    p_metodo_pago_id,
    p_monto_pago,
    NULL
  );

  -- Acumular puntos de fidelización si el cliente está registrado
  IF p_cliente_id IS NOT NULL AND v_puntos_ganados > 0 THEN
    PERFORM sp_actualizar_puntos_fidelizacion(
      p_cliente_id,
      p_venta_id,
      v_puntos_ganados,
      'Compra - Venta #' || p_venta_id
    );
  END IF;

  -- Calcular cambio a devolver
  p_cambio := p_monto_pago - v_total;

EXCEPTION
  WHEN OTHERS THEN
    -- PostgreSQL hace ROLLBACK automático en caso de error
    RAISE EXCEPTION 'Error al registrar venta: %', SQLERRM;
END;
$$;

-- =============================================================================
-- Fin del stored procedure: sp_registrar_venta
-- =============================================================================
