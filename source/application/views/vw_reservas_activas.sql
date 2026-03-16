-- =============================================================================
-- Vista: vw_reservas_activas
-- =============================================================================
-- Propósito:
--   Proporcionar un listado operativo de reservas pendientes y confirmadas
--   para facilitar la planificación de servicios y gestión de capacidad.
--
-- Descripción:
--   Esta vista consolida todas las reservas con estado pendiente o confirmada
--   que están programadas para hoy en adelante, presentando la información
--   necesaria para su gestión: local, cliente, fecha/hora, número de personas
--   y empleado responsable del registro.
--
-- Métricas incluidas:
--   - fecha_reserva: Fecha y hora programada del evento
--   - num_personas: Capacidad requerida para la reserva
--   - estado: Estado actual (pendiente o confirmada)
--   - registrado_por: Empleado que ingresó la reserva
--
-- Criterios de inclusión:
--   - Estado IN ('pendiente', 'confirmada')
--   - Fecha de reserva >= NOW() (desde este momento en adelante)
--   - Ordenado por fecha ascendente (próximas primero)
--
-- Uso:
--   -- Reservas del día de hoy
--   SELECT * FROM vw_reservas_activas
--   WHERE DATE(fecha_reserva) = CURRENT_DATE;
--
--   -- Reservas de un local específico
--   SELECT * FROM vw_reservas_activas
--   WHERE local_nombre ILIKE '%centro%'
--   ORDER BY fecha_reserva;
--
--   -- Reservas grandes (eventos)
--   SELECT * FROM vw_reservas_activas
--   WHERE num_personas >= 10
--   ORDER BY num_personas DESC;
--
--   -- Reporte semanal
--   SELECT * FROM vw_reservas_activas
--   WHERE fecha_reserva BETWEEN NOW() AND NOW() + INTERVAL '7 days';
--
-- Dependencias:
--   - Tabla: reserva
--   - Tabla: local
--   - Tabla: cliente
--   - Tabla: empleado
--
-- Nota de operación:
--   Esta vista debe consultarse al inicio de cada turno para planificar
--   la disposición de mesas y el personal necesario.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE VIEW vw_reservas_activas AS
SELECT 
    -- Identificación de la reserva
    r.id AS reserva_id,
    
    -- Información del local
    l.id AS local_id,
    l.nombre AS local_nombre,
    l.telefono AS local_telefono,
    
    -- Información del cliente
    c.id AS cliente_id,
    c.nombre AS cliente_nombre,
    c.apellido1 AS cliente_apellido1,
    c.apellido2 AS cliente_apellido2,
    c.telefono AS cliente_telefono,
    c.email AS cliente_email,
    
    -- Detalles de la reserva
    r.fecha_reserva,
    r.num_personas,
    r.estado,
    r.descripcion,
    
    -- Información de registro
    COALESCE(e.nombre || ' ' || e.apellido1, 'Sistema') AS registrado_por,
    r.fecha_registro,
    
    -- Métricas calculadas
    EXTRACT(DAY FROM (r.fecha_reserva - NOW()))::INTEGER AS dias_faltantes,
    EXTRACT(HOUR FROM (r.fecha_reserva - NOW()))::INTEGER AS horas_faltantes

FROM 
    reserva r
    
INNER JOIN 
    local l ON l.id = r.local_id
    
INNER JOIN 
    cliente c ON c.id = r.cliente_id
    
LEFT JOIN 
    empleado e ON e.id = r.empleado_id

WHERE 
    -- Solo reservas pendientes o confirmadas
    r.estado IN ('pendiente', 'confirmada')
    
    -- Desde ahora en adelante
    AND r.fecha_reserva >= NOW()

ORDER BY 
    r.fecha_reserva ASC;

-- =============================================================================
-- Índices sugeridos en tablas base para optimizar rendimiento
-- =============================================================================
-- Los siguientes índices mejorarían el rendimiento de esta vista:
-- 
-- CREATE INDEX IF NOT EXISTS idx_reserva_estado_fecha 
--   ON reserva(estado, fecha_reserva);
--
-- CREATE INDEX IF NOT EXISTS idx_reserva_fecha_activas 
--   ON reserva(fecha_reserva, estado) 
--   WHERE estado IN ('pendiente', 'confirmada');
--
-- CREATE INDEX IF NOT EXISTS idx_reserva_local_fecha 
--   ON reserva(local_id, fecha_reserva);
-- =============================================================================
