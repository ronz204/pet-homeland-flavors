-- =============================================================================
-- Stored Procedure: sp_reporte_ventas_periodo
-- =============================================================================
-- Propósito:
--   Generar un reporte consolidado de ventas por local para un rango
--   de fechas específico, proporcionando métricas clave de desempeño
--   comercial y operativo.
--
-- Descripción:
--   Este procedure de tipo reporte (RETURNS TABLE) genera estadísticas
--   de ventas con las siguientes métricas por local:
--   - Total de ventas en colones (suma de todas las ventas pagadas)
--   - Cantidad de órdenes procesadas
--   - Ticket promedio (gasto promedio por venta)
--   - Método de pago más utilizado
--   - Empleado con más ventas en el período
--
--   Puede filtrar por un local específico o generar el reporte para
--   todos los locales simultáneamente, útil para análisis comparativo.
--
-- Regla de negocio:
--   "Los reportes de ventas solo incluyen transacciones en estado 'pagada',
--   excluyendo ventas abiertas o anuladas para reflejar ingresos reales."
--
-- Parámetros de entrada:
--   @p_fecha_inicio - Fecha inicial del período (incluida)
--   @p_fecha_fin    - Fecha final del período (incluida)
--   @p_local_id     - ID del local específico (NULL para todos los locales)
--
-- Retorna:
--   Tabla con las siguientes columnas:
--   - local_nombre: Nombre del local
--   - total_ventas: Suma de ventas en colones
--   - cantidad_ordenes: Número de ventas procesadas
--   - ticket_promedio: Promedio de venta por transacción
--   - metodo_pago_principal: Método de pago más usado
--   - empleado_top: Empleado con más ventas
--
-- Uso:
--   -- Reporte de un local específico
--   SELECT * FROM sp_reporte_ventas_periodo(
--     '2026-03-01',
--     '2026-03-31',
--     1
--   );
--
--   -- Reporte de todos los locales (comparativo)
--   SELECT * FROM sp_reporte_ventas_periodo(
--     '2026-03-01',
--     '2026-03-31',
--     NULL
--   )
--   ORDER BY total_ventas DESC;
--
--   -- Reporte semanal del local 2
--   SELECT * FROM sp_reporte_ventas_periodo(
--     (CURRENT_DATE - INTERVAL '7 days')::DATE,
--     CURRENT_DATE,
--     2
--   );
--
-- Dependencias:
--   - Tabla: venta (transacciones pagadas)
--   - Tabla: local (nombre del local)
--   - Tabla: venta_pago (métodos de pago)
--   - Tabla: metodo_pago (nombre del método)
--   - Tabla: empleado (información del vendedor)
--
-- Criterios de filtrado:
--   - Solo ventas en estado 'pagada'
--   - Fecha evaluada usando DATE(fecha_hora) para inclusión completa de días
--   - Los locales sin ventas en el período NO aparecen en el resultado
--
-- Nota técnica:
--   Este procedure es de solo lectura (no modifica datos). Usa CTEs
--   (Common Table Expressions) para organizar las queries y facilitar
--   el mantenimiento. Puede tardar en períodos largos con muchas ventas.
--
-- Fecha creación: 2026-03-16
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
  -- Validar que la fecha de inicio sea anterior o igual a la fecha fin
  IF p_fecha_inicio > p_fecha_fin THEN
    RAISE EXCEPTION 'La fecha de inicio (%) no puede ser posterior a la fecha fin (%)',
      p_fecha_inicio,
      p_fecha_fin;
  END IF;

  RETURN QUERY
  -- CTE 1: Obtener todas las ventas del período
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
      AND v.estado = 'pagada'  -- Solo ventas completadas
      AND (p_local_id IS NULL OR v.local_id = p_local_id)
  ),
  
  -- CTE 2: Contar uso de cada método de pago por local
  pagos_metodo AS (
    SELECT
      v.local_id,
      vp.metodo_pago_id,
      mp.nombre AS metodo_nombre,
      COUNT(*) AS uso_count
    FROM venta v
    INNER JOIN venta_pago vp ON v.id = vp.venta_id
    INNER JOIN metodo_pago mp ON vp.metodo_pago_id = mp.id
    WHERE DATE(v.fecha_hora) BETWEEN p_fecha_inicio AND p_fecha_fin
      AND v.estado = 'pagada'
      AND (p_local_id IS NULL OR v.local_id = p_local_id)
    GROUP BY v.local_id, vp.metodo_pago_id, mp.nombre
  ),
  
  -- CTE 3: Obtener el método de pago más usado por local
  metodo_principal AS (
    SELECT DISTINCT ON (local_id)
      local_id,
      metodo_nombre
    FROM pagos_metodo
    ORDER BY local_id, uso_count DESC
  ),
  
  -- CTE 4: Contar ventas por empleado y local
  ventas_por_empleado AS (
    SELECT
      local_id,
      empleado_id,
      COUNT(*) AS ventas_count
    FROM ventas_periodo
    GROUP BY local_id, empleado_id
  ),
  
  -- CTE 5: Obtener el empleado con más ventas por local
  empleados_top AS (
    SELECT DISTINCT ON (local_id)
      local_id,
      empleado_id
    FROM ventas_por_empleado
    ORDER BY local_id, ventas_count DESC
  )
  
  -- Query principal: Consolidar todas las métricas
  SELECT
    vp.local_nombre::VARCHAR(100),
    COALESCE(SUM(vp.total), 0)::NUMERIC(12, 2) AS total_ventas,
    COUNT(DISTINCT vp.venta_id)::BIGINT AS cantidad_ordenes,
    COALESCE(ROUND(AVG(vp.total), 2), 0)::NUMERIC(12, 2) AS ticket_promedio,
    COALESCE(MAX(mp.metodo_nombre), 'N/A')::VARCHAR(40) AS metodo_pago_principal,
    COALESCE(MAX(e.nombre || ' ' || e.apellido1), 'N/A')::VARCHAR(200) AS empleado_top
  FROM ventas_periodo vp
  LEFT JOIN metodo_principal mp ON vp.local_id = mp.local_id
  LEFT JOIN empleados_top et ON vp.local_id = et.local_id
  LEFT JOIN empleado e ON et.empleado_id = e.id
  GROUP BY vp.local_id, vp.local_nombre
  ORDER BY total_ventas DESC;
END;
$$;

-- =============================================================================
-- Fin del stored procedure: sp_reporte_ventas_periodo
-- =============================================================================
