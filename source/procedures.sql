-- =============================================================================
-- 1. sp_registrar_venta
-- Área: Ventas / Facturación
-- Descripción: Registra una venta completa de forma atómica
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_registrar_venta(
  p_local_id         INT,
  p_empleado_id      INT,
  p_cliente_id       INT,
  p_tipo_servicio    tipo_servicio,
  p_platos           JSONB,  -- [{"plato_id": 1, "cantidad": 2, "precio_unitario": 5000}]
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
  v_subtotal         NUMERIC(12, 2) := 0;
  v_total            NUMERIC(12, 2) := 0;
  v_impuesto         NUMERIC(10, 2) := 0;
  v_puntos_ganados   INT := 0;
BEGIN
  -- Crear encabezado de venta
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

  -- Procesar cada plato
  FOR v_plato IN SELECT * FROM jsonb_array_elements(p_platos)
  LOOP
    v_plato_id := (v_plato->>'plato_id')::INT;
    v_cantidad := (v_plato->>'cantidad')::SMALLINT;
    v_precio_unitario := (v_plato->>'precio_unitario')::NUMERIC(10, 2);

    -- Obtener receta vigente del plato
    SELECT id INTO v_receta_id
    FROM receta
    WHERE plato_id = v_plato_id
      AND vigente = TRUE
    LIMIT 1;

    IF v_receta_id IS NULL THEN
      RAISE EXCEPTION 'No existe receta vigente para el plato_id %', v_plato_id;
    END IF;

    -- Insertar línea de detalle
    -- El trigger trg_descontar_inventario_por_venta se encarga automáticamente
    -- de descontar los ingredientes del inventario según la receta
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

  -- Los triggers trg_descontar_inventario_por_venta y trg_actualizar_total_venta
  -- ya se ejecutaron automáticamente al insertar en venta_detalle
  -- Leer los valores calculados por el trigger
  SELECT subtotal, impuesto, total INTO v_subtotal, v_impuesto, v_total
  FROM venta
  WHERE id = p_venta_id;

  -- Calcular puntos de fidelización (1 punto por cada 1000 colones)
  IF p_cliente_id IS NOT NULL THEN
    v_puntos_ganados := FLOOR(v_total / 1000);
  END IF;

  -- Actualizar puntos y estado de la venta
  UPDATE venta
  SET
    puntos_ganados = v_puntos_ganados,
    estado = 'pagada'
  WHERE id = p_venta_id;

  -- Registrar pago
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

  -- Calcular cambio
  p_cambio := p_monto_pago - v_total;

  IF p_cambio < 0 THEN
    RAISE EXCEPTION 'Monto de pago insuficiente. Total: %, Pagado: %', v_total, p_monto_pago;
  END IF;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE EXCEPTION 'Error al registrar venta: %', SQLERRM;
END;
$$;

-- =============================================================================
-- 2. sp_registrar_compra
-- Área: Inventario / Compras
-- Descripción: Registra una orden de compra a un proveedor
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_registrar_compra(
  p_local_id      INT,
  p_proveedor_id  INT,
  p_empleado_id   INT,
  p_ingredientes  JSONB,  -- [{"ingrediente_id": 1, "cantidad": 50, "precio_unitario": 500}]
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
  -- Crear encabezado de compra siempre en estado 'pendiente'
  -- El trigger trg_actualizar_estado_compra manejará la actualización de inventario
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

  -- Procesar cada ingrediente
  FOR v_ingrediente IN SELECT * FROM jsonb_array_elements(p_ingredientes)
  LOOP
    v_ingrediente_id := (v_ingrediente->>'ingrediente_id')::INT;
    v_cantidad := (v_ingrediente->>'cantidad')::NUMERIC(12, 3);
    v_precio_unitario := (v_ingrediente->>'precio_unitario')::NUMERIC(10, 2);
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

  -- Actualizar total en el encabezado de compra
  UPDATE compra
  SET total = p_total
  WHERE id = p_compra_id;

  -- Si la compra está marcada como recibida, actualizar el estado
  -- El trigger trg_actualizar_estado_compra se encargará de actualizar el inventario
  IF p_recibida THEN
    UPDATE compra
    SET
      estado = 'recibida',
      fecha_recepcion = NOW()
    WHERE id = p_compra_id;
  END IF;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE EXCEPTION 'Error al registrar compra: %', SQLERRM;
END;
$$;

-- =============================================================================
-- 3. sp_gestionar_reserva
-- Área: Reservas / Clientes
-- Descripción: Crea o actualiza una reserva para un cliente
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_gestionar_reserva(
  p_local_id              INT,
  p_identificacion_cliente VARCHAR(20),
  p_nombre_cliente        VARCHAR(100),
  p_fecha_reserva         TIMESTAMPTZ,
  p_num_personas          SMALLINT,
  p_descripcion           TEXT,
  p_empleado_id           INT,
  p_reserva_id            INT DEFAULT NULL,
  OUT p_reserva_id_out    INT,
  OUT p_es_cliente_nuevo  BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_cliente_id      INT;
  v_reservas_count  INT;
BEGIN
  p_es_cliente_nuevo := FALSE;

  -- Buscar o crear cliente
  SELECT id INTO v_cliente_id
  FROM cliente
  WHERE identificacion = p_identificacion_cliente;

  IF v_cliente_id IS NULL THEN
    -- Crear nuevo cliente
    INSERT INTO cliente (
      identificacion,
      tipo_id,
      nombre,
      fecha_registro,
      activo
    )
    VALUES (
      p_identificacion_cliente,
      'cedula_fisica',
      p_nombre_cliente,
      NOW(),
      TRUE
    )
    RETURNING id INTO v_cliente_id;

    p_es_cliente_nuevo := TRUE;

    -- Crear registro de fidelización
    INSERT INTO fidelizacion (
      cliente_id,
      puntos_totales,
      fecha_registro
    )
    VALUES (
      v_cliente_id,
      0,
      CURRENT_DATE
    );
  END IF;

  -- Verificar conflicto de capacidad (validación simplificada por fecha)
  SELECT COUNT(*) INTO v_reservas_count
  FROM reserva
  WHERE local_id = p_local_id
    AND DATE(fecha_reserva) = DATE(p_fecha_reserva)
    AND estado IN ('pendiente', 'confirmada')
    AND (p_reserva_id IS NULL OR id <> p_reserva_id);

  IF v_reservas_count >= 5 THEN
    RAISE EXCEPTION 'El local ya tiene capacidad saturada para la fecha %. Reservas confirmadas: %',
      DATE(p_fecha_reserva), v_reservas_count;
  END IF;

  -- Crear o actualizar reserva
  IF p_reserva_id IS NULL THEN
    -- Crear nueva reserva
    INSERT INTO reserva (
      local_id,
      cliente_id,
      empleado_id,
      fecha_reserva,
      num_personas,
      estado,
      descripcion,
      fecha_registro
    )
    VALUES (
      p_local_id,
      v_cliente_id,
      p_empleado_id,
      p_fecha_reserva,
      p_num_personas,
      'pendiente',
      p_descripcion,
      NOW()
    )
    RETURNING id INTO p_reserva_id_out;
  ELSE
    -- Actualizar reserva existente
    UPDATE reserva
    SET
      fecha_reserva = p_fecha_reserva,
      num_personas = p_num_personas,
      descripcion = p_descripcion
    WHERE id = p_reserva_id;

    p_reserva_id_out := p_reserva_id;
  END IF;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE EXCEPTION 'Error al gestionar reserva: %', SQLERRM;
END;
$$;

-- =============================================================================
-- 4. sp_traslado_ingredientes
-- Área: Inventario / Compras
-- Descripción: Gestiona el traslado de ingredientes entre dos locales
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_traslado_ingredientes(
  p_local_origen_id  INT,
  p_local_destino_id INT,
  p_empleado_id      INT,
  p_ingredientes     JSONB,  -- [{"ingrediente_id": 1, "cantidad": 10}]
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

  -- Validar que los locales sean diferentes
  IF p_local_origen_id = p_local_destino_id THEN
    RAISE EXCEPTION 'El local de origen y destino no pueden ser el mismo';
  END IF;

  -- Crear encabezado de traslado
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

  -- Procesar cada ingrediente
  FOR v_ingrediente IN SELECT * FROM jsonb_array_elements(p_ingredientes)
  LOOP
    v_ingrediente_id := (v_ingrediente->>'ingrediente_id')::INT;
    v_cantidad := (v_ingrediente->>'cantidad')::NUMERIC(12, 3);

    -- Obtener inventario de origen con bloqueo
    SELECT id, cantidad_actual INTO v_inv_origen_id, v_stock_origen
    FROM inventario_local
    WHERE local_id = p_local_origen_id
      AND ingrediente_id = v_ingrediente_id
    FOR UPDATE;

    IF v_inv_origen_id IS NULL THEN
      RAISE EXCEPTION 'El ingrediente_id % no existe en el inventario del local origen (local_id %)',
        v_ingrediente_id, p_local_origen_id;
    END IF;

    -- Validar stock suficiente
    IF v_stock_origen < v_cantidad THEN
      RAISE EXCEPTION 'Stock insuficiente del ingrediente_id % en local origen. Disponible: %, Solicitado: %',
        v_ingrediente_id, v_stock_origen, v_cantidad;
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

    -- Registrar movimiento de salida
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
      'Traslado #' || p_traslado_id || ' hacia local ' || p_local_destino_id,
      p_empleado_id
    );

    -- Buscar o crear inventario en local destino
    SELECT id INTO v_inv_destino_id
    FROM inventario_local
    WHERE local_id = p_local_destino_id
      AND ingrediente_id = v_ingrediente_id;

    IF v_inv_destino_id IS NULL THEN
      INSERT INTO inventario_local (
        local_id,
        ingrediente_id,
        cantidad_actual,
        cantidad_minima
      )
      VALUES (
        p_local_destino_id,
        v_ingrediente_id,
        v_cantidad,
        0
      )
      RETURNING id INTO v_inv_destino_id;
    ELSE
      UPDATE inventario_local
      SET
        cantidad_actual = cantidad_actual + v_cantidad,
        ultima_actualizacion = NOW()
      WHERE id = v_inv_destino_id;
    END IF;

    -- Registrar movimiento de entrada
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
      'Traslado #' || p_traslado_id || ' desde local ' || p_local_origen_id,
      p_empleado_id
    );
  END LOOP;

  -- Actualizar estado del traslado
  UPDATE traslado_interno
  SET
    estado = 'recibido',
    fecha_recepcion = NOW()
  WHERE id = p_traslado_id;

  p_exitoso := TRUE;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    p_exitoso := FALSE;
    RAISE EXCEPTION 'Error al procesar traslado: %', SQLERRM;
END;
$$;

-- =============================================================================
-- 5. sp_reporte_ventas_periodo
-- Área: Empleados / Reportes
-- Descripción: Genera un reporte consolidado de ventas para un rango de fechas
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_reporte_ventas_periodo(
  p_fecha_inicio DATE,
  p_fecha_fin    DATE,
  p_local_id     INT DEFAULT NULL
)
RETURNS TABLE (
  local_nombre           VARCHAR(100),
  total_ventas           NUMERIC(12, 2),
  cantidad_ordenes       BIGINT,
  ticket_promedio        NUMERIC(12, 2),
  metodo_pago_principal  VARCHAR(40),
  empleado_top           VARCHAR(200)
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  WITH ventas_periodo AS (
    SELECT
      v.id AS venta_id,
      v.local_id,
      v.empleado_id,
      v.total,
      l.nombre AS local_nombre
    FROM venta v
    INNER JOIN local l ON v.local_id = l.id
    WHERE DATE(v.fecha_hora) BETWEEN p_fecha_inicio AND p_fecha_fin
      AND v.estado = 'pagada'
      AND (p_local_id IS NULL OR v.local_id = p_local_id)
  ),
  pagos_metodo AS (
    SELECT
      vp.local_id,
      vp.metodo_pago_id,
      mp.nombre AS metodo_nombre,
      COUNT(*) AS uso_count
    FROM venta v
    INNER JOIN venta_pago vp ON v.id = vp.venta_id
    INNER JOIN metodo_pago mp ON vp.metodo_pago_id = mp.id
    WHERE DATE(v.fecha_hora) BETWEEN p_fecha_inicio AND p_fecha_fin
      AND v.estado = 'pagada'
      AND (p_local_id IS NULL OR v.local_id = p_local_id)
    GROUP BY vp.local_id, vp.metodo_pago_id, mp.nombre
  ),
  metodo_principal AS (
    SELECT DISTINCT ON (local_id)
      local_id,
      metodo_nombre
    FROM pagos_metodo
    ORDER BY local_id, uso_count DESC
  ),
  empleados_top AS (
    SELECT DISTINCT ON (local_id)
      local_id,
      empleado_id,
      COUNT(*) AS ventas_count
    FROM ventas_periodo
    GROUP BY local_id, empleado_id
    ORDER BY local_id, ventas_count DESC
  )
  SELECT
    vp.local_nombre,
    COALESCE(SUM(vp.total), 0) AS total_ventas,
    COUNT(vp.venta_id) AS cantidad_ordenes,
    COALESCE(AVG(vp.total), 0) AS ticket_promedio,
    COALESCE(mp.metodo_nombre, 'N/A') AS metodo_pago_principal,
    COALESCE(e.nombre || ' ' || e.apellido1, 'N/A') AS empleado_top
  FROM ventas_periodo vp
  LEFT JOIN metodo_principal mp ON vp.local_id = mp.local_id
  LEFT JOIN empleados_top et ON vp.local_id = et.local_id
  LEFT JOIN empleado e ON et.empleado_id = e.id
  GROUP BY vp.local_id, vp.local_nombre, mp.metodo_nombre, e.nombre, e.apellido1
  ORDER BY total_ventas DESC;
END;
$$;

-- =============================================================================
-- 6. sp_actualizar_puntos_fidelizacion
-- Área: Ventas / Clientes
-- Descripción: Acumula o descuenta puntos de fidelización a un cliente
-- =============================================================================
CREATE OR REPLACE FUNCTION sp_actualizar_puntos_fidelizacion(
  p_cliente_id    INT,
  p_venta_id      BIGINT DEFAULT NULL,
  p_puntos        INT,
  p_descripcion   TEXT,
  OUT p_puntos_nuevos INT,
  OUT p_exitoso   BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_fidelizacion_id  INT;
  v_puntos_actuales  INT;
BEGIN
  p_exitoso := FALSE;

  -- Obtener registro de fidelización del cliente
  SELECT id, puntos_totales INTO v_fidelizacion_id, v_puntos_actuales
  FROM fidelizacion
  WHERE cliente_id = p_cliente_id;

  IF v_fidelizacion_id IS NULL THEN
    RAISE EXCEPTION 'El cliente_id % no tiene registro de fidelización', p_cliente_id;
  END IF;

  -- Validar que no quede saldo negativo en caso de canje
  IF v_puntos_actuales + p_puntos < 0 THEN
    RAISE EXCEPTION 'Puntos insuficientes para el canje. Disponibles: %, Solicitados: %',
      v_puntos_actuales, ABS(p_puntos);
  END IF;

  -- Actualizar puntos totales
  UPDATE fidelizacion
  SET puntos_totales = puntos_totales + p_puntos
  WHERE id = v_fidelizacion_id
  RETURNING puntos_totales INTO p_puntos_nuevos;

  -- Registrar movimiento en historial
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

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    p_exitoso := FALSE;
    RAISE EXCEPTION 'Error al actualizar puntos de fidelización: %', SQLERRM;
END;
$$;
