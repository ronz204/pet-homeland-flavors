-- =============================================================================
-- Vista: vw_inventario_bajo_minimo
-- =============================================================================
-- Propósito:
--   Sistema de alerta temprana para prevenir desabastecimiento de ingredientes
--   en las operaciones de cada local.
--
-- Descripción:
--   Esta vista identifica todos los ingredientes cuyo stock actual ha caído
--   por debajo del nivel mínimo configurado, mostrando la cantidad faltante
--   para alcanzar el umbral de seguridad. Permite tomar acciones preventivas
--   antes de quedarse sin inventario crítico.
--
-- Métricas incluidas:
--   - cantidad_actual: Stock disponible en el inventario
--   - cantidad_minima: Nivel mínimo configurado de seguridad
--   - faltante: Diferencia entre mínimo y actual (siempre positivo)
--   - ultima_actualizacion: Última modificación del inventario
--
-- Criterios de inclusión:
--   - Solo ingredientes con cantidad_actual < cantidad_minima
--   - Ordenado por faltante descendente (emergencias primero)
--
-- Uso:
--   -- Ingredientes críticos (faltante > 50)
--   SELECT * FROM vw_inventario_bajo_minimo
--   WHERE faltante > 50;
--
--   -- Alertas de un local específico
--   SELECT * FROM vw_inventario_bajo_minimo
--   WHERE local_id = 1
--   ORDER BY faltante DESC;
--
--   -- Ingredientes perecederos en riesgo
--   SELECT v.*, i.perecedero
--   FROM vw_inventario_bajo_minimo v
--   INNER JOIN ingrediente i ON i.id = v.ingrediente_id
--   WHERE i.perecedero = TRUE;
--
-- Dependencias:
--   - Tabla: inventario_local
--   - Tabla: local
--   - Tabla: ingrediente
--   - Tabla: unidad_medida
--
-- Nota de operación:
--   Esta vista debe revisarse diariamente por los administradores de cada
--   local para programar compras o traslados internos oportunos.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE VIEW vw_inventario_bajo_minimo AS
SELECT 
    -- Identificación del local
    l.id AS local_id,
    l.nombre AS local_nombre,
    
    -- Identificación del ingrediente
    i.id AS ingrediente_id,
    i.nombre AS ingrediente_nombre,
    
    -- Métricas de inventario
    inv.cantidad_actual,
    inv.cantidad_minima,
    (inv.cantidad_minima - inv.cantidad_actual) AS faltante,
    
    -- Unidad de medida
    um.simbolo AS unidad,
    
    -- Información temporal
    inv.ultima_actualizacion,
    
    -- Días desde última actualización
    EXTRACT(DAY FROM (NOW() - inv.ultima_actualizacion))::INTEGER AS dias_sin_actualizar

FROM 
    inventario_local inv
    
INNER JOIN 
    local l ON l.id = inv.local_id
    
INNER JOIN 
    ingrediente i ON i.id = inv.ingrediente_id
    
INNER JOIN 
    unidad_medida um ON um.id = i.unidad_medida_id

WHERE 
    -- Solo ingredientes bajo el mínimo
    inv.cantidad_actual < inv.cantidad_minima

ORDER BY 
    faltante DESC,
    l.nombre,
    i.nombre;

-- =============================================================================
-- Índices sugeridos en tablas base para optimizar rendimiento
-- =============================================================================
-- Los siguientes índices mejorarían el rendimiento de esta vista:
-- 
-- CREATE INDEX IF NOT EXISTS idx_inventario_local_cantidad 
--   ON inventario_local(local_id, cantidad_actual, cantidad_minima);
--
-- CREATE INDEX IF NOT EXISTS idx_inventario_bajo_minimo 
--   ON inventario_local(local_id) 
--   WHERE cantidad_actual < cantidad_minima;
-- =============================================================================
