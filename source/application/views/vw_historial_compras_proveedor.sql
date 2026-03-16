-- =============================================================================
-- Vista: vw_historial_compras_proveedor
-- =============================================================================
-- Propósito:
--   Análisis del historial de relaciones comerciales con proveedores para
--   evaluación de desempeño, negociación de contratos y optimización de
--   la cadena de suministro.
--
-- Descripción:
--   Esta vista consolida el historial de compras agrupado por proveedor,
--   mostrando métricas clave como cantidad de órdenes de compra realizadas,
--   inversión total acumulada, fecha de la última compra y el local con
--   mayor volumen de compras a ese proveedor.
--
-- Métricas incluidas:
--   - total_ordenes: Cantidad de órdenes de compra completadas
--   - total_invertido: Suma histórica de montos de compra
--   - ultima_compra: Fecha de la transacción más reciente
--   - local_principal: Local con mayor inversión en ese proveedor
--
-- Criterios de inclusión:
--   - proveedor.activo = TRUE
--   - Solo proveedores con al menos una compra (HAVING COUNT > 0)
--   - Ordenado por inversión total descendente
--
-- Uso:
--   -- Top proveedores por inversión
--   SELECT * FROM vw_historial_compras_proveedor
--   ORDER BY total_invertido DESC
--   LIMIT 10;
--
--   -- Proveedores sin compras recientes (>90 días)
--   SELECT * FROM vw_historial_compras_proveedor
--   WHERE ultima_compra < NOW() - INTERVAL '90 days'
--   ORDER BY ultima_compra;
--
--   -- Análisis de concentración de compras
--   SELECT proveedor_id,
--          razon_social,
--          total_invertido,
--          ROUND(
--            total_invertido * 100.0 / SUM(total_invertido) OVER(),
--            2
--          ) AS porcentaje_del_total
--   FROM vw_historial_compras_proveedor;
--
--   -- Proveedores frecuentes (>20 órdenes)
--   SELECT * FROM vw_historial_compras_proveedor
--   WHERE total_ordenes > 20
--   ORDER BY total_ordenes DESC;
--
-- Dependencias:
--   - Tabla: proveedor
--   - Tabla: compra
--   - Tabla: local
--
-- Nota de negocio:
--   Esta vista es fundamental para:
--   - Negociación de descuentos por volumen
--   - Evaluación de proveedores estratégicos
--   - Análisis de riesgo de concentración
--   - Planificación de contratos anuales
--
-- Limitación:
--   La vista agrupa por proveedor y muestra solo UN local_principal.
--   Para análisis detallado por local, se debe consultar directamente
--   la tabla compra con GROUP BY adicional.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE VIEW vw_historial_compras_proveedor AS
WITH compras_por_local AS (
    -- Calcula el total invertido por cada proveedor en cada local
    SELECT 
        c.proveedor_id,
        c.local_id,
        SUM(c.total) AS total_local,
        ROW_NUMBER() OVER (
            PARTITION BY c.proveedor_id 
            ORDER BY SUM(c.total) DESC
        ) AS rn
    FROM 
        compra c
    WHERE 
        c.estado = 'recibida'
    GROUP BY 
        c.proveedor_id,
        c.local_id
),
local_principal_cte AS (
    -- Selecciona el local con mayor inversión por proveedor
    SELECT 
        cpl.proveedor_id,
        l.nombre AS local_principal,
        cpl.total_local AS inversion_local_principal
    FROM 
        compras_por_local cpl
    INNER JOIN 
        local l ON l.id = cpl.local_id
    WHERE 
        cpl.rn = 1
)
SELECT 
    -- Identificación del proveedor
    pr.id AS proveedor_id,
    pr.razon_social,
    pr.cedula_juridica,
    
    -- Información de contacto
    pr.telefono,
    pr.email,
    
    -- Métricas de historial
    COUNT(c.id) AS total_ordenes,
    COALESCE(SUM(c.total), 0) AS total_invertido,
    MAX(c.fecha_compra) AS ultima_compra,
    
    -- Información del local principal
    lp.local_principal,
    lp.inversion_local_principal,
    
    -- Métricas calculadas adicionales
    ROUND(COALESCE(AVG(c.total), 0), 2) AS promedio_por_orden,
    
    -- Días desde última compra
    EXTRACT(DAY FROM (NOW() - MAX(c.fecha_compra)))::INTEGER AS dias_sin_comprar,
    
    -- Indicador de proveedor frecuente
    CASE 
        WHEN COUNT(c.id) >= 20 THEN 'Frecuente'
        WHEN COUNT(c.id) >= 10 THEN 'Regular'
        ELSE 'Ocasional'
    END AS clasificacion

FROM 
    proveedor pr
    
INNER JOIN 
    compra c ON c.proveedor_id = pr.id
    
LEFT JOIN 
    local_principal_cte lp ON lp.proveedor_id = pr.id

WHERE 
    -- Solo proveedores activos
    pr.activo = TRUE
    
    -- Solo compras completadas
    AND c.estado = 'recibida'

GROUP BY 
    pr.id,
    pr.razon_social,
    pr.cedula_juridica,
    pr.telefono,
    pr.email,
    lp.local_principal,
    lp.inversion_local_principal

HAVING 
    -- Solo proveedores con al menos una compra
    COUNT(c.id) > 0

ORDER BY 
    total_invertido DESC;

-- =============================================================================
-- Índices sugeridos en tablas base para optimizar rendimiento
-- =============================================================================
-- Los siguientes índices mejorarían el rendimiento de esta vista:
-- 
-- CREATE INDEX IF NOT EXISTS idx_compra_proveedor_fecha 
--   ON compra(proveedor_id, fecha_compra, estado);
--
-- CREATE INDEX IF NOT EXISTS idx_compra_estado_recibida 
--   ON compra(proveedor_id, estado, total) 
--   WHERE estado = 'recibida';
--
-- CREATE INDEX IF NOT EXISTS idx_proveedor_activo 
--   ON proveedor(activo, id) WHERE activo = TRUE;
-- =============================================================================
