-- =============================================================================
-- Vista: vw_menu_dia_activo
-- =============================================================================
-- Propósito:
--   Proporcionar el catálogo de platos disponibles en el menú del día para
--   cada local, facilitando la consulta por parte del sistema de pedidos,
--   pantallas digitales y aplicaciones de cliente.
--
-- Descripción:
--   Esta vista muestra el menú del día vigente (fecha actual) por local,
--   incluyendo los platos disponibles con su precio efectivo (especial si
--   fue configurado, o el precio base del plato), categoría y descripción.
--   Solo incluye menús y platos marcados como activos.
--
-- Lógica de precio:
--   - Si menu_dia_plato.precio_especial IS NOT NULL, se usa ese precio
--   - Si es NULL, se usa el precio_base del plato
--   - Esto permite promociones especiales sin modificar el precio base
--
-- Criterios de inclusión:
--   - menu_dia.fecha = CURRENT_DATE
--   - menu_dia.activo = TRUE
--   - plato.activo = TRUE
--
-- Uso:
--   -- Menú del día de un local específico
--   SELECT * FROM vw_menu_dia_activo
--   WHERE local_id = 1
--   ORDER BY categoria, plato_nombre;
--
--   -- Platos con precio especial (promociones)
--   SELECT * FROM vw_menu_dia_activo
--   WHERE precio_efectivo < precio_base_original;
--
--   -- Menús disponibles hoy en todos los locales
--   SELECT local_nombre, COUNT(*) AS total_platos
--   FROM vw_menu_dia_activo
--   GROUP BY local_nombre
--   ORDER BY local_nombre;
--
--   -- Platos por categoría para mostrar en pantalla
--   SELECT categoria,
--          JSON_AGG(
--            JSON_BUILD_OBJECT(
--              'id', plato_id,
--              'nombre', plato_nombre,
--              'precio', precio_efectivo,
--              'descripcion', plato_descripcion
--            )
--          ) AS platos
--   FROM vw_menu_dia_activo
--   WHERE local_id = 1
--   GROUP BY categoria;
--
-- Dependencias:
--   - Tabla: menu_dia
--   - Tabla: menu_dia_plato
--   - Tabla: local
--   - Tabla: plato
--   - Tabla: categoria_plato
--
-- Nota de operación:
--   Esta vista debe ser la fuente principal para sistemas de pedidos (POS,
--   app móvil, pantallas digitales). Se actualiza automáticamente cada día.
--
-- Fecha creación: 2026-03-16
-- =============================================================================

CREATE OR REPLACE VIEW vw_menu_dia_activo AS
SELECT 
    -- Información del local
    l.id AS local_id,
    l.nombre AS local_nombre,
    l.telefono AS local_telefono,
    
    -- Fecha del menú
    md.fecha,
    
    -- Información del plato
    p.id AS plato_id,
    p.nombre AS plato_nombre,
    
    -- Categoría
    cp.id AS categoria_id,
    cp.nombre AS categoria,
    
    -- Precios
    COALESCE(mdp.precio_especial, p.precio_base) AS precio_efectivo,
    p.precio_base AS precio_base_original,
    
    -- Indicador de promoción
    CASE 
        WHEN mdp.precio_especial IS NOT NULL 
             AND mdp.precio_especial < p.precio_base 
        THEN TRUE 
        ELSE FALSE 
    END AS es_promocion,
    
    -- Porcentaje de descuento si aplica
    CASE 
        WHEN mdp.precio_especial IS NOT NULL 
             AND mdp.precio_especial < p.precio_base 
        THEN ROUND(
            ((p.precio_base - mdp.precio_especial) / p.precio_base * 100)::NUMERIC,
            0
        )
        ELSE 0 
    END AS descuento_porcentaje,
    
    -- Descripción del plato
    p.descripcion AS plato_descripcion,
    
    -- Información adicional
    p.imagen_url,
    p.es_regional

FROM 
    menu_dia md
    
INNER JOIN 
    local l ON l.id = md.local_id
    
INNER JOIN 
    menu_dia_plato mdp ON mdp.menu_dia_id = md.id
    
INNER JOIN 
    plato p ON p.id = mdp.plato_id
    
INNER JOIN 
    categoria_plato cp ON cp.id = p.categoria_plato_id

WHERE 
    -- Solo menú de hoy
    md.fecha = CURRENT_DATE
    
    -- Solo menús activos
    AND md.activo = TRUE
    
    -- Solo platos activos
    AND p.activo = TRUE

ORDER BY 
    l.nombre,
    cp.nombre,
    p.nombre;

-- =============================================================================
-- Índices sugeridos en tablas base para optimizar rendimiento
-- =============================================================================
-- Los siguientes índices mejorarían el rendimiento de esta vista:
-- 
-- CREATE INDEX IF NOT EXISTS idx_menu_dia_fecha_activo 
--   ON menu_dia(fecha, activo) WHERE activo = TRUE;
--
-- CREATE INDEX IF NOT EXISTS idx_menu_dia_fecha_actual 
--   ON menu_dia(local_id, fecha) WHERE fecha = CURRENT_DATE;
--
-- CREATE INDEX IF NOT EXISTS idx_plato_activo_categoria 
--   ON plato(activo, categoria_plato_id) WHERE activo = TRUE;
-- =============================================================================
