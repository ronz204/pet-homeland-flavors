-- =============================================================================
-- Stored Procedure: sp_gestionar_reserva
-- =============================================================================
-- Propósito:
--   Crear o actualizar reservas de clientes, registrando automáticamente
--   clientes nuevos y validando disponibilidad del local para la fecha
--   solicitada.
--
-- Descripción:
--   Este procedure gestiona el proceso completo de reservas:
--   1. Busca si el cliente ya existe por su identificación
--   2. Si no existe, lo crea automáticamente en la tabla cliente
--   3. Si es cliente nuevo, también crea su registro de fidelización
--   4. Valida que el local no esté saturado para la fecha solicitada
--   5. Crea una nueva reserva o actualiza una existente
--
--   Esto simplifica el proceso de reservas al no requerir que el cliente
--   esté previamente registrado, útil para llamadas telefónicas rápidas.
--
-- Regla de negocio:
--   "Un local puede tener máximo 5 reservas activas por día. Si se alcanza
--   el límite, se debe rechazar nuevas reservas para esa fecha."
--
-- Parámetros de entrada:
--   @p_local_id               - Local donde se realizará el evento
--   @p_identificacion_cliente - Cédula o identificación del cliente
--   @p_nombre_cliente         - Nombre completo (usado si cliente es nuevo)
--   @p_fecha_reserva          - Fecha y hora del evento reservado
--   @p_num_personas           - Cantidad de personas que asistirán
--   @p_descripcion            - Detalles del evento o preferencias
--   @p_empleado_id            - Empleado que registra la reserva
--   @p_reserva_id             - ID de reserva existente (NULL para crear nueva)
--
-- Parámetros de salida:
--   @p_reserva_id_out   - ID de la reserva creada o actualizada
--   @p_es_cliente_nuevo - TRUE si se creó un nuevo cliente en el proceso
--
-- Uso:
--   -- Crear nueva reserva (cliente existente o nuevo)
--   SELECT * FROM sp_gestionar_reserva(
--     p_local_id := 2,
--     p_identificacion_cliente := '1-0234-0567',
--     p_nombre_cliente := 'María González Pérez',
--     p_fecha_reserva := '2026-03-20 19:00:00',
--     p_num_personas := 8,
--     p_descripcion := 'Cumpleaños, mesa cerca de ventana',
--     p_empleado_id := 5,
--     p_reserva_id := NULL
--   );
--
--   -- Actualizar reserva existente
--   SELECT * FROM sp_gestionar_reserva(
--     p_local_id := 2,
--     p_identificacion_cliente := '1-0234-0567',
--     p_nombre_cliente := 'María González Pérez',
--     p_fecha_reserva := '2026-03-20 20:00:00',  -- Nueva hora
--     p_num_personas := 10,  -- Más personas
--     p_descripcion := 'Cumpleaños, mesa cerca de ventana',
--     p_empleado_id := 5,
--     p_reserva_id := 45  -- ID de reserva a actualizar
--   );
--
-- Dependencias:
--   - Tabla: reserva
--   - Tabla: cliente (se crea si no existe)
--   - Tabla: fidelizacion (se crea para clientes nuevos)
--   - Tabla: empleado (validación de quien registra)
--
-- Validaciones implementadas:
--   - Verifica capacidad del local para la fecha (máx 5 reservas/día)
--   - Valida que el número de personas sea positivo
--   - Crea automáticamente cliente y su fidelización si es necesario
--
-- Nota técnica:
--   La validación de capacidad es simplificada (5 reservas por día).
--   Una mejora futura podría considerar aforo real del local y reservas
--   por franja horaria.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE FUNCTION sp_gestionar_reserva(
  p_local_id               INT,
  p_identificacion_cliente VARCHAR(20),
  p_nombre_cliente         VARCHAR(100),
  p_fecha_reserva          TIMESTAMPTZ,
  p_num_personas           SMALLINT,
  p_descripcion            TEXT,
  p_empleado_id            INT,
  p_reserva_id             INT DEFAULT NULL,
  OUT p_reserva_id_out     INT,
  OUT p_es_cliente_nuevo   BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_cliente_id      INT;
  v_reservas_count  INT;
BEGIN
  p_es_cliente_nuevo := FALSE;

  -- Validar número de personas positivo
  IF p_num_personas <= 0 THEN
    RAISE EXCEPTION 'El número de personas debe ser mayor a cero';
  END IF;

  -- Validar que la fecha de reserva sea futura (excepto para actualizaciones)
  IF p_reserva_id IS NULL AND p_fecha_reserva <= NOW() THEN
    RAISE EXCEPTION 'La fecha de reserva debe ser en el futuro';
  END IF;

  -- Buscar si el cliente ya existe por su identificación
  SELECT id INTO v_cliente_id
  FROM cliente
  WHERE identificacion = p_identificacion_cliente;

  -- Si el cliente no existe, crearlo automáticamente
  IF v_cliente_id IS NULL THEN
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

    -- Crear registro de fidelización para el nuevo cliente
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

  -- Verificar disponibilidad del local para la fecha
  -- Validación simplificada: máximo 5 reservas activas por día
  SELECT COUNT(*) INTO v_reservas_count
  FROM reserva
  WHERE local_id = p_local_id
    AND DATE(fecha_reserva) = DATE(p_fecha_reserva)
    AND estado IN ('pendiente', 'confirmada')
    AND (p_reserva_id IS NULL OR id <> p_reserva_id);

  IF v_reservas_count >= 5 THEN
    RAISE EXCEPTION 'El local ya tiene capacidad saturada para %. Reservas activas: %',
      DATE(p_fecha_reserva), 
      v_reservas_count;
  END IF;

  -- Crear nueva reserva o actualizar existente
  IF p_reserva_id IS NULL THEN
    -- Crear nueva reserva en estado 'pendiente'
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
    -- Actualizar reserva existente (fecha, personas o descripción)
    UPDATE reserva
    SET
      fecha_reserva = p_fecha_reserva,
      num_personas = p_num_personas,
      descripcion = p_descripcion
    WHERE id = p_reserva_id
      AND estado IN ('pendiente', 'confirmada');  -- Solo actualizar si no está cancelada/completada

    -- Validar que la actualización afectó una fila
    IF NOT FOUND THEN
      RAISE EXCEPTION 'No se puede actualizar la reserva_id %. Verifique que exista y esté activa.', 
        p_reserva_id;
    END IF;

    p_reserva_id_out := p_reserva_id;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Error al gestionar reserva: %', SQLERRM;
END;
$$;

-- =============================================================================
-- Fin del stored procedure: sp_gestionar_reserva
-- =============================================================================
