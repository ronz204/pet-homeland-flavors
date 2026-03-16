-- =============================================================================
-- Vista: vw_clientes_frecuentes
-- =============================================================================
-- Propósito:
--   Proporciona un ranking de clientes basado en su nivel de actividad y
--   comportamiento de compra, identificando a los clientes más valiosos
--   del negocio.
--
-- Descripción:
--   Esta vista lista clientes activos ordenados por su historial de compras,
--   mostrando métricas clave de actividad: visitas realizadas, gasto total
--   acumulado y puntos de fidelización. Solo incluye clientes físicos
--   (personas naturales) que han realizado al menos una compra.
--
-- Métricas incluidas:
--   - total_visitas: Cantidad de ventas completadas por el cliente
--   - total_gastado: Suma histórica de montos pagados
--   - puntos_fidelizacion: Puntos acumulados en programa de lealtad
--
-- Criterios de inclusión:
--   - Cliente debe estar activo (activo = TRUE)
--   - Cliente debe ser persona física (apellido1 IS NOT NULL)
--   - Cliente debe tener al menos una venta pagada
--
-- Uso:
--   -- Top 10 clientes más valiosos
--   SELECT * FROM vw_clientes_frecuentes LIMIT 10;
--
--   -- Clientes con más de 50,000 colones gastados
--   SELECT * FROM vw_clientes_frecuentes 
--   WHERE total_gastado > 50000;
--
--   -- Clientes con alta frecuencia
--   SELECT * FROM vw_clientes_frecuentes 
--   WHERE total_visitas >= 10
--   ORDER BY total_visitas DESC;
--
-- Dependencias:
--   - Tabla: cliente
--   - Tabla: venta
--   - Tabla: fidelizacion
--
-- Nota de negocio:
--   Los clientes sin apellido (apellido1 IS NULL) se consideran clientes
--   jurídicos o cuentas especiales y se excluyen de este análisis.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE VIEW vw_clientes_frecuentes AS
SELECT 
  -- Identificación del cliente
  c.id AS cliente_id,
  c.identificacion,
  c.tipo_id,
    
  -- Información personal
  c.nombre,
  c.apellido1,
  c.apellido2,
    
  -- Información de contacto
  c.telefono,
  c.email,
    
  -- Métricas de actividad
  COUNT(v.id) AS total_visitas,
  COALESCE(SUM(v.total), 0) AS total_gastado,
  COALESCE(MAX(f.puntos_totales), 0) AS puntos_fidelizacion,
    
  -- Métricas calculadas adicionales
  COALESCE(ROUND(AVG(v.total), 2), 0) AS ticket_promedio,
  MAX(v.fecha_hora) AS ultima_visita,
  MIN(v.fecha_hora) AS primera_visita,
    
  -- Días desde última visita
  COALESCE(
    EXTRACT(DAY FROM (NOW() - MAX(v.fecha_hora)))::INTEGER, NULL
  ) AS dias_desde_ultima_visita

FROM  cliente c
LEFT JOIN venta v ON v.cliente_id = c.id AND v.estado = 'pagada'    
LEFT JOIN fidelizacion f ON f.cliente_id = c.id
WHERE
  c.activo = TRUE
  AND c.apellido1 IS NOT NULL
GROUP BY 
  c.id,
  c.identificacion,
  c.tipo_id,
  c.nombre,
  c.apellido1,
  c.apellido2,
  c.telefono,
  c.email
HAVING 
  COUNT(v.id) > 0
ORDER BY 
    total_gastado DESC,
    total_visitas DESC;

-- =============================================================================
-- Índices sugeridos en tablas base para optimizar rendimiento
-- =============================================================================
-- Los siguientes índices mejorarían el rendimiento de esta vista:
-- 
-- CREATE INDEX IF NOT EXISTS idx_venta_cliente_estado 
--   ON venta(cliente_id, estado);
--
-- CREATE INDEX IF NOT EXISTS idx_venta_cliente_fecha 
--   ON venta(cliente_id, fecha_hora);
--
-- CREATE INDEX IF NOT EXISTS idx_cliente_activo_apellido 
--   ON cliente(activo, apellido1) WHERE activo = TRUE;
-- =============================================================================
