-- =============================================================================
-- Vista: vw_ventas_por_local_dia
-- =============================================================================
-- Propósito:
--   Proporciona un resumen diario de ventas por local, incluyendo métricas
--   clave de negocio como cantidad de órdenes, ingresos y cargos aplicados.
--
-- Descripción:
--   Esta vista agrega las ventas completadas (estado 'pagada') agrupándolas
--   por local y fecha, facilitando el análisis de rendimiento diario de cada
--   sucursal. Excluye ventas abiertas o anuladas para reflejar únicamente
--   transacciones consumadas.
--
-- Métricas incluidas:
--   - total_ordenes: Cantidad de ventas completadas en el día
--   - ingresos_brutos: Suma de subtotales antes de descuentos e impuestos
--   - total_descuentos: Monto total de descuentos aplicados
--   - total_impuestos: Monto total de impuestos cobrados
--   - ingresos_netos: Monto final recaudado (subtotal - descuentos + impuestos)
--
-- Uso:
--   SELECT * FROM vw_ventas_por_local_dia
--   WHERE fecha >= '2026-01-01'
--     AND local_id = 1
--   ORDER BY fecha DESC;
--
-- Dependencias:
--   - Tabla: venta
--   - Tabla: local (para nombres de locales en consultas con JOIN)
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE VIEW vw_ventas_por_local_dia AS
SELECT
  -- Dimensiones de agrupación
  l.id AS local_id,
  l.nombre AS local_nombre,
  DATE(v.fecha_hora) AS fecha,
    
  -- Métricas de volumen
  COUNT(v.id) AS total_ordenes,
    
  -- Métricas financieras
  COALESCE(SUM(v.subtotal), 0) AS ingresos_brutos,
  COALESCE(SUM(v.descuento), 0) AS total_descuentos,
  COALESCE(SUM(v.impuesto), 0) AS total_impuestos,
  COALESCE(SUM(v.total), 0) AS ingresos_netos
    
FROM venta v
INNER JOIN local l ON l.id = v.local_id
WHERE v.estado = 'pagada'
GROUP BY l.id, l.nombre, DATE(v.fecha_hora)
ORDER BY fecha DESC, l.nombre;

-- =============================================================================
-- Índices sugeridos en tabla base para optimizar rendimiento
-- =============================================================================
-- Los siguientes índices en la tabla venta mejorarían el rendimiento de esta vista:
-- 
-- CREATE INDEX IF NOT EXISTS idx_venta_local_fecha 
--   ON venta(local_id, fecha_hora);
--
-- CREATE INDEX IF NOT EXISTS idx_venta_estado_fecha 
--   ON venta(estado, fecha_hora);
-- =============================================================================
