-- =============================================================================
-- Vista: vw_rentabilidad_por_plato
-- =============================================================================
-- Propósito:
--   Análisis de rentabilidad por plato mediante la comparación entre costo
--   de ingredientes y precio de venta, permitiendo optimizar el menú y
--   estrategias de pricing.
--
-- Descripción:
--   Esta vista calcula para cada plato activo el costo estimado de producción
--   según su receta vigente (suma de cantidad × precio del ingrediente del
--   proveedor principal) versus el precio base de venta, mostrando el margen
--   bruto en colones y como porcentaje.
--
-- Métricas incluidas:
--   - precio_venta: Precio base del plato
--   - costo_receta: Costo total de ingredientes según receta vigente
--   - margen_bruto: Diferencia entre precio de venta y costo
--   - porcentaje_margen: Margen como porcentaje del precio de venta
--
-- Consideraciones de cálculo:
--   - Se usa solo la receta vigente (vigente = TRUE)
--   - El costo se basa en el proveedor principal de cada ingrediente
--   - Platos sin receta vigente mostrarán costo_receta = 0
--
-- Uso:
--   -- Platos más rentables
--   SELECT * FROM vw_rentabilidad_por_plato
--   WHERE porcentaje_margen > 60
--   ORDER BY margen_bruto DESC;
--
--   -- Platos con margen bajo (candidatos a ajuste de precio)
--   SELECT * FROM vw_rentabilidad_por_plato
--   WHERE porcentaje_margen < 40
--   ORDER BY porcentaje_margen ASC;
--
--   -- Análisis por categoría
--   SELECT categoria, 
--          COUNT(*) AS total_platos,
--          AVG(porcentaje_margen) AS margen_promedio
--   FROM vw_rentabilidad_por_plato
--   GROUP BY categoria;
--
-- Dependencias:
--   - Tabla: plato
--   - Tabla: categoria_plato
--   - Tabla: receta
--   - Tabla: receta_ingrediente
--   - Tabla: ingrediente
--   - Tabla: proveedor_ingrediente
--
-- Nota de negocio:
--   Los costos son estimaciones basadas en precios de proveedores principales.
--   No incluyen costos de mano de obra, servicios o overhead operativo.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE VIEW vw_rentabilidad_por_plato AS
SELECT 
    -- Identificación del plato
    p.id AS plato_id,
    p.nombre AS plato_nombre,
    
    -- Categoría
    cp.nombre AS categoria,
    
    -- Métricas financieras
    p.precio_base AS precio_venta,
    COALESCE(SUM(ri.cantidad * pi.precio_unitario), 0) AS costo_receta,
    
    -- Análisis de rentabilidad
    (p.precio_base - COALESCE(SUM(ri.cantidad * pi.precio_unitario), 0)) AS margen_bruto,
    
    ROUND(
        ((p.precio_base - COALESCE(SUM(ri.cantidad * pi.precio_unitario), 0)) / 
         NULLIF(p.precio_base, 0) * 100)::NUMERIC,
        2
    ) AS porcentaje_margen,

FROM 
    plato p
    
INNER JOIN 
  categoria_plato cp ON cp.id = p.categoria_plato_id  

LEFT JOIN 
  receta r ON r.plato_id = p.id 
  AND r.vigente = TRUE

LEFT JOIN 
  receta_ingrediente ri ON ri.receta_id = r.id

LEFT JOIN 
  ingrediente i ON i.id = ri.ingrediente_id

LEFT JOIN 
  proveedor_ingrediente pi ON pi.ingrediente_id = i.id 
  AND pi.es_proveedor_principal = TRUE

WHERE 
  p.activo = TRUE

GROUP BY 
  p.id,
  p.nombre,
  cp.nombre,
  p.precio_base

ORDER BY 
  margen_bruto DESC;

-- =============================================================================
-- Índices sugeridos en tablas base para optimizar rendimiento
-- =============================================================================
-- Los siguientes índices mejorarían el rendimiento de esta vista:
-- 
-- CREATE INDEX IF NOT EXISTS idx_receta_plato_vigente 
--   ON receta(plato_id, vigente) WHERE vigente = TRUE;
--
-- CREATE INDEX IF NOT EXISTS idx_proveedor_ingrediente_principal 
--   ON proveedor_ingrediente(ingrediente_id, es_proveedor_principal) 
--   WHERE es_proveedor_principal = TRUE;
--
-- CREATE INDEX IF NOT EXISTS idx_plato_activo 
--   ON plato(activo, categoria_plato_id) WHERE activo = TRUE;
-- =============================================================================
