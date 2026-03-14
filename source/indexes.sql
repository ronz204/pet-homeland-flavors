-- =============================================================================
-- ÍNDICES para mejorar rendimiento de consultas frecuentes
-- =============================================================================

-- Búsqueda de ventas por local y fecha
CREATE INDEX idx_venta_local_fecha      ON venta (local_id, fecha_hora DESC);
-- Búsqueda de ventas por cliente
CREATE INDEX idx_venta_cliente          ON venta (cliente_id) WHERE cliente_id IS NOT NULL;
-- Detalle de venta
CREATE INDEX idx_venta_detalle_venta    ON venta_detalle (venta_id);
-- Inventario por local
CREATE INDEX idx_inventario_local       ON inventario_local (local_id);
-- Movimientos de inventario por fecha
CREATE INDEX idx_movimiento_inv_fecha   ON movimiento_inventario (fecha DESC);
-- Empleados por local activos
CREATE INDEX idx_empleado_local_activo  ON empleado_local (local_id, activo);
-- Reservas por local y fecha
CREATE INDEX idx_reserva_local_fecha    ON reserva (local_id, fecha_reserva);
-- Recetas vigentes
CREATE INDEX idx_receta_vigente         ON receta (plato_id) WHERE vigente = TRUE;
-- Menú del día por local y fecha
CREATE INDEX idx_menu_dia_local_fecha   ON menu_dia (local_id, fecha);
-- Fidelización por cliente
CREATE INDEX idx_fidelizacion_cliente   ON fidelizacion (cliente_id);
