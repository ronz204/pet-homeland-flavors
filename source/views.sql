-- -----------------------------------------------------------------------------
-- 1. vw_ventas_por_local_dia
-- Resumen diario de ventas por local (órdenes, ingresos, descuentos, impuestos)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_ventas_por_local_dia AS
SELECT 
  l.id AS local_id,
  l.nombre AS local_nombre,
  DATE(v.fecha_hora) AS fecha,
  COUNT(v.id) AS total_ordenes,
  SUM(v.subtotal) AS ingresos_brutos,
  SUM(v.descuento) AS total_descuentos,
  SUM(v.impuesto) AS total_impuestos,
  SUM(v.total) AS ingresos_netos
FROM venta v
INNER JOIN local l ON l.id = v.local_id
WHERE v.estado = 'pagada'
GROUP BY l.id, l.nombre, DATE(v.fecha_hora)
ORDER BY fecha DESC, l.nombre;

-- -----------------------------------------------------------------------------
-- 2. vw_clientes_frecuentes
-- Ranking de clientes por actividad, gasto total y puntos acumulados
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_clientes_frecuentes AS
SELECT 
  c.id AS cliente_id,
  c.identificacion,
  c.nombre,
  c.apellido1,
  c.apellido2,
  COUNT(v.id) AS total_visitas,
  COALESCE(SUM(v.total), 0) AS total_gastado,
  COALESCE(f.puntos_totales, 0) AS puntos_fidelizacion
FROM cliente c
LEFT JOIN venta v ON v.cliente_id = c.id AND v.estado = 'pagada'
LEFT JOIN fidelizacion f ON f.cliente_id = c.id
WHERE c.activo = TRUE
GROUP BY c.id, c.identificacion, c.nombre, c.apellido1, c.apellido2, f.puntos_totales
ORDER BY total_gastado DESC;

-- -----------------------------------------------------------------------------
-- 3. vw_inventario_bajo_minimo
-- Alerta de ingredientes con stock por debajo del mínimo configurado
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_inventario_bajo_minimo AS
SELECT 
  l.id AS local_id,
  l.nombre AS local_nombre,
  i.id AS ingrediente_id,
  i.nombre AS ingrediente_nombre,
  inv.cantidad_actual,
  inv.cantidad_minima,
  (inv.cantidad_minima - inv.cantidad_actual) AS faltante,
  um.simbolo AS unidad,
  inv.ultima_actualizacion
FROM inventario_local inv
INNER JOIN local l ON l.id = inv.local_id
INNER JOIN ingrediente i ON i.id = inv.ingrediente_id
INNER JOIN unidad_medida um ON um.id = i.unidad_medida_id
WHERE inv.cantidad_actual < inv.cantidad_minima
ORDER BY faltante DESC, l.nombre, i.nombre;

-- -----------------------------------------------------------------------------
-- 4. vw_rentabilidad_por_plato
-- Análisis de costo vs precio de venta por plato según receta vigente
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_rentabilidad_por_plato AS
SELECT 
  p.id AS plato_id,
  p.nombre AS plato_nombre,
  cp.nombre AS categoria,
  p.precio_base AS precio_venta,
  COALESCE(SUM(ri.cantidad * pi.precio_unitario), 0) AS costo_receta,
  (p.precio_base - COALESCE(SUM(ri.cantidad * pi.precio_unitario), 0)) AS margen_bruto,
  ROUND(
    ((p.precio_base - COALESCE(SUM(ri.cantidad * pi.precio_unitario), 0)) / p.precio_base * 100)::NUMERIC,
    2
  ) AS porcentaje_margen
FROM plato p
INNER JOIN categoria_plato cp ON cp.id = p.categoria_plato_id
LEFT JOIN receta r ON r.plato_id = p.id AND r.vigente = TRUE
LEFT JOIN receta_ingrediente ri ON ri.receta_id = r.id
LEFT JOIN ingrediente i ON i.id = ri.ingrediente_id
LEFT JOIN proveedor_ingrediente pi ON pi.ingrediente_id = i.id AND pi.es_proveedor_principal = TRUE
WHERE p.activo = TRUE
GROUP BY p.id, p.nombre, cp.nombre, p.precio_base
ORDER BY margen_bruto DESC;

-- -----------------------------------------------------------------------------
-- 5. vw_reservas_activas
-- Listado de reservas pendientes o confirmadas programadas desde hoy
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_reservas_activas AS
SELECT 
  r.id AS reserva_id,
  l.nombre AS local_nombre,
  c.nombre AS cliente_nombre,
  c.apellido1 AS cliente_apellido1,
  c.telefono AS cliente_telefono,
  r.fecha_reserva,
  r.num_personas,
  r.estado,
  r.descripcion,
  e.nombre || ' ' || e.apellido1 AS registrado_por,
  r.fecha_registro
FROM reserva r
INNER JOIN local l ON l.id = r.local_id
INNER JOIN cliente c ON c.id = r.cliente_id
LEFT JOIN empleado e ON e.id = r.empleado_id
WHERE r.estado IN ('pendiente', 'confirmada')
  AND r.fecha_reserva >= NOW()
ORDER BY r.fecha_reserva ASC;

-- -----------------------------------------------------------------------------
-- 6. vw_desempeno_empleados
-- Desempeño de empleados en el mes actual (ventas procesadas y montos)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_desempeno_empleados AS
SELECT 
  e.id AS empleado_id,
  e.nombre || ' ' || e.apellido1 AS empleado_nombre,
  l.nombre AS local_nombre,
  r.nombre AS rol,
  COUNT(v.id) AS ventas_procesadas,
  COALESCE(SUM(v.total), 0) AS total_vendido,
  COALESCE(AVG(v.total), 0) AS promedio_por_venta
FROM empleado e
INNER JOIN empleado_local el ON el.empleado_id = e.id AND el.activo = TRUE
INNER JOIN local l ON l.id = el.local_id
INNER JOIN rol r ON r.id = el.rol_id
LEFT JOIN venta v ON v.empleado_id = e.id 
  AND v.estado = 'pagada'
  AND DATE_TRUNC('month', v.fecha_hora) = DATE_TRUNC('month', NOW())
WHERE e.activo = TRUE
GROUP BY e.id, e.nombre, e.apellido1, l.nombre, r.nombre
ORDER BY total_vendido DESC;

-- -----------------------------------------------------------------------------
-- 7. vw_menu_dia_activo
-- Menú del día vigente por local con platos y precios efectivos
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_menu_dia_activo AS
SELECT 
  l.id AS local_id,
  l.nombre AS local_nombre,
  md.fecha,
  p.id AS plato_id,
  p.nombre AS plato_nombre,
  cp.nombre AS categoria,
  COALESCE(mdp.precio_especial, p.precio_base) AS precio_efectivo,
  p.descripcion AS plato_descripcion
FROM menu_dia md
INNER JOIN local l ON l.id = md.local_id
INNER JOIN menu_dia_plato mdp ON mdp.menu_dia_id = md.id
INNER JOIN plato p ON p.id = mdp.plato_id
INNER JOIN categoria_plato cp ON cp.id = p.categoria_plato_id
WHERE md.fecha = CURRENT_DATE
  AND md.activo = TRUE
  AND p.activo = TRUE
ORDER BY l.nombre, cp.nombre, p.nombre;

-- -----------------------------------------------------------------------------
-- 8. vw_historial_compras_proveedor
-- Resumen de compras por proveedor (órdenes, inversión, última compra)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_historial_compras_proveedor AS
SELECT 
  pr.id AS proveedor_id,
  pr.razon_social,
  pr.cedula_juridica,
  COUNT(c.id) AS total_ordenes,
  SUM(c.total) AS total_invertido,
  MAX(c.fecha_compra) AS ultima_compra,
  l.nombre AS local_principal
FROM proveedor pr
INNER JOIN compra c ON c.proveedor_id = pr.id
INNER JOIN local l ON l.id = c.local_id
WHERE pr.activo = TRUE
GROUP BY pr.id, pr.razon_social, pr.cedula_juridica, l.nombre
HAVING COUNT(c.id) > 0
ORDER BY total_invertido DESC;
