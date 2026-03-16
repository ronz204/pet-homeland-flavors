-- =============================================================================
-- Vista: vw_desempeno_empleados
-- =============================================================================
-- Propósito:
--   Análisis del desempeño de ventas por empleado para evaluación de
--   productividad, comisiones y reconocimiento del personal destacado.
--
-- Descripción:
--   Esta vista resume el desempeño de cada empleado activo durante el mes
--   en curso, mostrando la cantidad de ventas procesadas, el monto total
--   vendido y el promedio por transacción. La información se asocia con
--   la asignación actual del empleado (local y rol).
--
-- Métricas incluidas:
--   - ventas_procesadas: Cantidad de ventas completadas en el mes
--   - total_vendido: Suma de ingresos generados
--   - promedio_por_venta: Monto promedio de cada transacción (ticket promedio)
--
-- Período de cálculo:
--   - Mes actual (DATE_TRUNC('month', NOW()))
--   - Solo ventas con estado 'pagada'
--
-- Consideraciones:
--   - Se usa la asignación más reciente del empleado (DISTINCT ON)
--   - Empleados sin ventas en el mes aparecerán con métricas en 0
--   - Solo incluye empleados activos
--
-- Uso:
--   -- Top 5 vendedores del mes
--   SELECT * FROM vw_desempeno_empleados
--   ORDER BY total_vendido DESC
--   LIMIT 5;
--
--   -- Empleados de un local específico
--   SELECT * FROM vw_desempeno_empleados
--   WHERE local_nombre = 'San José Centro'
--   ORDER BY ventas_procesadas DESC;
--
--   -- Rendimiento por rol
--   SELECT rol,
--          COUNT(*) AS empleados,
--          SUM(total_vendido) AS ventas_totales,
--          AVG(promedio_por_venta) AS ticket_promedio_rol
--   FROM vw_desempeno_empleados
--   GROUP BY rol
--   ORDER BY ventas_totales DESC;
--
-- Dependencias:
--   - Tabla: empleado
--   - Tabla: empleado_local
--   - Tabla: local
--   - Tabla: rol
--   - Tabla: venta
--
-- Nota de RR.HH.:
--   Esta vista es útil para cálculo de comisiones, evaluaciones mensuales
--   y programas de incentivos. Los datos se reinician cada mes.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE VIEW vw_desempeno_empleados AS
WITH asignacion_actual AS (
  SELECT DISTINCT ON (el.empleado_id)
    el.empleado_id,
    l.id AS local_id,
    l.nombre AS local_nombre,
    r.nombre AS rol
  FROM 
    empleado_local el
  INNER JOIN 
    local l ON l.id = el.local_id
  INNER JOIN 
    rol r ON r.id = el.rol_id
  WHERE 
    el.activo = TRUE
  ORDER BY 
    el.empleado_id, 
    el.fecha_inicio DESC
)
SELECT 
  e.id AS empleado_id,
  e.cedula,
  e.nombre || ' ' || e.apellido1 AS empleado_nombre,
    
  -- Asignación actual
  a.local_id,
  a.local_nombre,
  a.rol,
    
  -- Métricas de desempeño del mes actual
  COUNT(v.id) AS ventas_procesadas,
  COALESCE(SUM(v.total), 0) AS total_vendido,
  ROUND(COALESCE(AVG(v.total), 0), 2) AS promedio_por_venta,
    
  -- Información de contacto (para reconocimientos)
  e.telefono,
  e.email,
    
  -- Métricas adicionales
  COALESCE(SUM(v.puntos_ganados), 0) AS puntos_generados_clientes,
  COUNT(DISTINCT DATE(v.fecha_hora)) AS dias_trabajados

FROM empleado e
INNER JOIN
  asignacion_actual a ON a.empleado_id = e.id
LEFT JOIN 
  venta v ON v.empleado_id = e.id 
  AND v.estado = 'pagada'
  AND DATE_TRUNC('month', v.fecha_hora) = DATE_TRUNC('month', NOW())
WHERE 
  e.activo = TRUE
GROUP BY 
  e.id,
  e.cedula,
  e.nombre,
  e.apellido1,
  e.telefono,
  e.email,
  a.local_id,
  a.local_nombre,
  a.rol
ORDER BY 
  total_vendido DESC,
  ventas_procesadas DESC;

-- =============================================================================
-- Índices sugeridos en tablas base para optimizar rendimiento
-- =============================================================================
-- Los siguientes índices mejorarían el rendimiento de esta vista:
-- 
-- CREATE INDEX IF NOT EXISTS idx_venta_empleado_fecha_estado 
--   ON venta(empleado_id, fecha_hora, estado);
--
-- CREATE INDEX IF NOT EXISTS idx_empleado_local_activo 
--   ON empleado_local(empleado_id, activo, fecha_inicio) 
--   WHERE activo = TRUE;
--
-- CREATE INDEX IF NOT EXISTS idx_venta_fecha_truncada 
--   ON venta(DATE_TRUNC('month', fecha_hora), estado);
-- =============================================================================
