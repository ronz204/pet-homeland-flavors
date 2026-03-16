-- =============================================================================
-- ENUMERACIONES (tipos de dominio estáticos)
-- =============================================================================

CREATE TYPE tipo_servicio      AS ENUM ('salon', 'para_llevar', 'evento');

CREATE TYPE estado_venta       AS ENUM ('abierta', 'pagada', 'anulada');
CREATE TYPE estado_hacienda_fe AS ENUM ('pendiente', 'aceptado', 'rechazado', 'contingencia');

CREATE TYPE estado_reserva     AS ENUM ('pendiente', 'confirmada', 'cancelada', 'completada');
CREATE TYPE estado_compra      AS ENUM ('pendiente', 'recibida', 'cancelada');
CREATE TYPE estado_traslado    AS ENUM ('solicitado', 'en_transito', 'recibido', 'cancelado');

CREATE TYPE tipo_movimiento_inv AS ENUM ('entrada', 'salida', 'ajuste', 'traslado_salida', 'traslado_entrada');
CREATE TYPE tipo_documento_fe   AS ENUM ('factura_electronica', 'tiquete_electronico', 'nota_credito');
CREATE TYPE tipo_receptor_fe    AS ENUM ('persona_fisica', 'persona_juridica');
