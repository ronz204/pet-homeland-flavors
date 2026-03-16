-- =============================================================================
-- FASE 1 - ENTIDADES MAESTRAS / CATÁLOGOS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Provincia (catálogo costarricense)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS provincia (
  id     SMALLINT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(50)  NOT NULL UNIQUE
);

-- -----------------------------------------------------------------------------
-- Cantón (catálogo costarricense)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS canton (
  id           SMALLINT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  provincia_id SMALLINT     NOT NULL,
  nombre       VARCHAR(80)  NOT NULL,

  CONSTRAINT fk_canton_provincia FOREIGN KEY (provincia_id)
    REFERENCES provincia(id) ON UPDATE CASCADE,

  CONSTRAINT uq_canton_nombre UNIQUE (provincia_id, nombre)
);

-- -----------------------------------------------------------------------------
-- Distrito (catálogo costarricense)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS distrito (
  id        SMALLINT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  canton_id SMALLINT     NOT NULL,
  nombre    VARCHAR(80)  NOT NULL,

  CONSTRAINT fk_distrito_canton FOREIGN KEY (canton_id)
    REFERENCES canton(id) ON UPDATE CASCADE,

  CONSTRAINT uq_distrito_nombre UNIQUE (canton_id, nombre)
);

-- -----------------------------------------------------------------------------
-- Unidad de medida
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unidad_medida (
  id      SMALLINT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre  VARCHAR(30)  NOT NULL UNIQUE,  -- ej: kilogramo, litro, unidad
  simbolo VARCHAR(10)  NOT NULL UNIQUE   -- ej: kg, L, u
);

-- -----------------------------------------------------------------------------
-- Categoría de plato
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categoria_plato (
  id          SMALLINT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre      VARCHAR(60)  NOT NULL UNIQUE,
  descripcion TEXT
);

-- -----------------------------------------------------------------------------
-- Categoría de ingrediente
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categoria_ingrediente (
  id     SMALLINT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(60)  NOT NULL UNIQUE
);

-- -----------------------------------------------------------------------------
-- Rol de empleado
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rol (
  id          SMALLINT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre      VARCHAR(50)  NOT NULL UNIQUE,  -- administrador, cajero, cocinero, mesero
  descripcion TEXT
);

-- -----------------------------------------------------------------------------
-- Método de pago
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS metodo_pago (
  id     SMALLINT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(40)  NOT NULL UNIQUE  -- efectivo, tarjeta_credito, SINPE, etc.
);

-- =============================================================================
-- FASE 2 - LOCAL (SUCURSAL)
-- =============================================================================

CREATE TABLE IF NOT EXISTS local (
  id             INT           GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre         VARCHAR(100)  NOT NULL,
  telefono       VARCHAR(20),
  email          VARCHAR(120),
  direccion      TEXT          NOT NULL,
  distrito_id    SMALLINT      NOT NULL,
  activo         BOOLEAN       NOT NULL DEFAULT TRUE,
  fecha_apertura DATE          NOT NULL,

  CONSTRAINT fk_local_distrito FOREIGN KEY (distrito_id)
    REFERENCES distrito(id) ON UPDATE CASCADE
);

-- =============================================================================
-- FASE 3 - EMPLEADO
-- =============================================================================

CREATE TABLE IF NOT EXISTS empleado (
  id            INT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cedula        CHAR(9)      NOT NULL UNIQUE,  -- cédula CR: 9 dígitos
  nombre        VARCHAR(80)  NOT NULL,
  apellido1     VARCHAR(60)  NOT NULL,
  apellido2     VARCHAR(60),
  telefono      VARCHAR(20),
  email         VARCHAR(120),
  fecha_ingreso DATE         NOT NULL DEFAULT CURRENT_DATE,
  fecha_salida  DATE,
  activo        BOOLEAN      NOT NULL DEFAULT TRUE,

  CONSTRAINT ck_empleado_salida CHECK (fecha_salida IS NULL OR fecha_salida >= fecha_ingreso)
);

-- Un empleado puede trabajar en un local con un rol específico (historial)
CREATE TABLE IF NOT EXISTS empleado_local (
  id           INT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  empleado_id  INT      NOT NULL,
  local_id     INT      NOT NULL,
  rol_id       SMALLINT NOT NULL,
  fecha_inicio DATE     NOT NULL DEFAULT CURRENT_DATE,
  fecha_fin    DATE,
  activo       BOOLEAN  NOT NULL DEFAULT TRUE,

  CONSTRAINT fk_el_empleado FOREIGN KEY (empleado_id)
    REFERENCES empleado(id) ON UPDATE CASCADE,

  CONSTRAINT fk_el_local FOREIGN KEY (local_id)
    REFERENCES local(id) ON UPDATE CASCADE,

  CONSTRAINT fk_el_rol FOREIGN KEY (rol_id)
    REFERENCES rol(id) ON UPDATE CASCADE,

  CONSTRAINT ck_el_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

-- =============================================================================
-- FASE 4 - CLIENTE
-- =============================================================================

CREATE TABLE IF NOT EXISTS cliente (
  id               INT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  identificacion   VARCHAR(20)  NOT NULL UNIQUE,  -- cédula física, jurídica, pasaporte o DIMEX
  tipo_id          VARCHAR(20)  NOT NULL DEFAULT 'cedula_fisica'
                   CHECK (tipo_id IN ('cedula_fisica', 'cedula_juridica', 'pasaporte', 'dimex')),
  nombre           VARCHAR(100) NOT NULL,
  apellido1        VARCHAR(60),
  apellido2        VARCHAR(60),
  telefono         VARCHAR(20),
  email            VARCHAR(120),
  fecha_registro   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  activo           BOOLEAN      NOT NULL DEFAULT TRUE
);

-- Programa de fidelización: puntos acumulados por cliente
CREATE TABLE IF NOT EXISTS fidelizacion (
  id             INT  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cliente_id     INT  NOT NULL UNIQUE,
  puntos_totales INT  NOT NULL DEFAULT 0 CHECK (puntos_totales >= 0),
  fecha_registro DATE NOT NULL DEFAULT CURRENT_DATE,

  CONSTRAINT fk_fid_cliente FOREIGN KEY (cliente_id)
    REFERENCES cliente(id) ON UPDATE CASCADE
);

-- Historial de movimiento de puntos (auditoría)
CREATE TABLE IF NOT EXISTS fidelizacion_movimiento (
  id              BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  fidelizacion_id INT          NOT NULL,
  puntos          INT          NOT NULL,  -- positivo: acumulación; negativo: canje
  descripcion     VARCHAR(200),
  fecha           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_fm_fidelizacion FOREIGN KEY (fidelizacion_id)
    REFERENCES fidelizacion(id) ON UPDATE CASCADE,

  CONSTRAINT ck_fm_puntos CHECK (puntos <> 0)
);

-- =============================================================================
-- FASE 5 - INGREDIENTE & PROVEEDOR
-- =============================================================================

CREATE TABLE IF NOT EXISTS ingrediente (
  id                       INT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre                   VARCHAR(100) NOT NULL UNIQUE,
  categoria_ingrediente_id SMALLINT     NOT NULL,
  unidad_medida_id         SMALLINT     NOT NULL,
  perecedero               BOOLEAN      NOT NULL DEFAULT FALSE,
  activo                   BOOLEAN      NOT NULL DEFAULT TRUE,

  CONSTRAINT fk_ing_categoria FOREIGN KEY (categoria_ingrediente_id)
    REFERENCES categoria_ingrediente(id) ON UPDATE CASCADE,

  CONSTRAINT fk_ing_unidad FOREIGN KEY (unidad_medida_id)
    REFERENCES unidad_medida(id) ON UPDATE CASCADE
);

-- Inventario por local (stock actual)
CREATE TABLE IF NOT EXISTS inventario_local (
  id                   BIGINT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  local_id             INT             NOT NULL,
  ingrediente_id       INT             NOT NULL,
  cantidad_actual      NUMERIC(12, 3)  NOT NULL DEFAULT 0 CHECK (cantidad_actual >= 0),
  cantidad_minima      NUMERIC(12, 3)  NOT NULL DEFAULT 0 CHECK (cantidad_minima >= 0),
  ultima_actualizacion TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_inv_local_ing UNIQUE (local_id, ingrediente_id),

  CONSTRAINT fk_inv_local FOREIGN KEY (local_id)
    REFERENCES local(id) ON UPDATE CASCADE,

  CONSTRAINT fk_inv_ingrediente FOREIGN KEY (ingrediente_id)
    REFERENCES ingrediente(id) ON UPDATE CASCADE
);

-- Movimientos de inventario (trazabilidad completa)
CREATE TABLE IF NOT EXISTS movimiento_inventario (
  id                  BIGINT                  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  inventario_local_id BIGINT                  NOT NULL,
  tipo_movimiento     tipo_movimiento_inv     NOT NULL,
  cantidad            NUMERIC(12, 3)          NOT NULL CHECK (cantidad > 0),
  fecha               TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
  referencia_id       BIGINT,                 -- ID de compra, venta o traslado según contexto
  referencia_tipo     VARCHAR(30),            -- 'compra','venta','traslado','ajuste'
  observacion         TEXT,
  empleado_id         INT,

  CONSTRAINT fk_mi_inventario FOREIGN KEY (inventario_local_id)
    REFERENCES inventario_local(id) ON UPDATE CASCADE,

  CONSTRAINT fk_mi_empleado FOREIGN KEY (empleado_id)
    REFERENCES empleado(id) ON UPDATE CASCADE
);

-- Proveedor
CREATE TABLE IF NOT EXISTS proveedor (
  id              INT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  razon_social    VARCHAR(150) NOT NULL,
  cedula_juridica VARCHAR(20)  NOT NULL UNIQUE,
  telefono        VARCHAR(20),
  email           VARCHAR(120),
  direccion       TEXT,
  activo          BOOLEAN      NOT NULL DEFAULT TRUE
);

-- Ingredientes que puede proveer cada proveedor (con precio de referencia)
CREATE TABLE IF NOT EXISTS proveedor_ingrediente (
  id                     INT            GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  proveedor_id           INT            NOT NULL,
  ingrediente_id         INT            NOT NULL,
  precio_unitario        NUMERIC(10, 2) NOT NULL CHECK (precio_unitario > 0),
  es_proveedor_principal BOOLEAN        NOT NULL DEFAULT FALSE,

  CONSTRAINT uq_prov_ing UNIQUE (proveedor_id, ingrediente_id),

  CONSTRAINT fk_pi_prov FOREIGN KEY (proveedor_id)
    REFERENCES proveedor(id) ON UPDATE CASCADE,

  CONSTRAINT fk_pi_ing FOREIGN KEY (ingrediente_id)
    REFERENCES ingrediente(id) ON UPDATE CASCADE
);

-- =============================================================================
-- FASE 6 - COMPRA
-- =============================================================================

CREATE TABLE IF NOT EXISTS compra (
  id              INT            GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  local_id        INT            NOT NULL,
  proveedor_id    INT            NOT NULL,
  empleado_id     INT            NOT NULL,  -- quien realizó la compra
  fecha_compra    TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  fecha_recepcion TIMESTAMPTZ,
  estado          estado_compra  NOT NULL DEFAULT 'pendiente',
  total           NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (total >= 0),
  observacion     TEXT,

  CONSTRAINT fk_compra_local FOREIGN KEY (local_id)
    REFERENCES local(id) ON UPDATE CASCADE,

  CONSTRAINT fk_compra_proveedor FOREIGN KEY (proveedor_id)
    REFERENCES proveedor(id) ON UPDATE CASCADE,

  CONSTRAINT fk_compra_empleado FOREIGN KEY (empleado_id)
    REFERENCES empleado(id) ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS compra_detalle (
  id              BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  compra_id       INT            NOT NULL,
  ingrediente_id  INT            NOT NULL,
  cantidad        NUMERIC(12, 3) NOT NULL CHECK (cantidad > 0),
  precio_unitario NUMERIC(10, 2) NOT NULL CHECK (precio_unitario > 0),
  subtotal        NUMERIC(12, 2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,

  CONSTRAINT uq_compra_det UNIQUE (compra_id, ingrediente_id),

  CONSTRAINT fk_cd_compra FOREIGN KEY (compra_id)
    REFERENCES compra(id) ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT fk_cd_ingrediente FOREIGN KEY (ingrediente_id)
    REFERENCES ingrediente(id) ON UPDATE CASCADE
);

-- =============================================================================
-- FASE 7 - TRASLADO INTERNO ENTRE LOCALES
-- =============================================================================

CREATE TABLE IF NOT EXISTS traslado_interno (
  id              INT              GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  local_origen_id INT              NOT NULL,
  local_destino_id INT             NOT NULL,
  empleado_id     INT              NOT NULL,
  fecha_solicitud TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  fecha_recepcion TIMESTAMPTZ,
  estado          estado_traslado  NOT NULL DEFAULT 'solicitado',
  observacion     TEXT,

  CONSTRAINT ck_traslado_locales_distintos CHECK (local_origen_id <> local_destino_id),

  CONSTRAINT fk_tr_origen FOREIGN KEY (local_origen_id)
    REFERENCES local(id) ON UPDATE CASCADE,

  CONSTRAINT fk_tr_destino FOREIGN KEY (local_destino_id)
    REFERENCES local(id) ON UPDATE CASCADE,

  CONSTRAINT fk_tr_empleado FOREIGN KEY (empleado_id)
    REFERENCES empleado(id) ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS traslado_detalle (
  id             BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  traslado_id    INT            NOT NULL,
  ingrediente_id INT            NOT NULL,
  cantidad       NUMERIC(12, 3) NOT NULL CHECK (cantidad > 0),

  CONSTRAINT uq_traslado_det UNIQUE (traslado_id, ingrediente_id),

  CONSTRAINT fk_td_traslado FOREIGN KEY (traslado_id)
    REFERENCES traslado_interno(id) ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT fk_td_ingrediente FOREIGN KEY (ingrediente_id)
    REFERENCES ingrediente(id) ON UPDATE CASCADE
);

-- =============================================================================
-- FASE 8 - PLATO & RECETA
-- =============================================================================

CREATE TABLE IF NOT EXISTS plato (
  id                 INT            GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre             VARCHAR(120)   NOT NULL UNIQUE,
  descripcion        TEXT,
  categoria_plato_id SMALLINT       NOT NULL,
  precio_base        NUMERIC(10, 2) NOT NULL CHECK (precio_base > 0),
  imagen_url         TEXT,
  es_regional        BOOLEAN        NOT NULL DEFAULT FALSE,
  activo             BOOLEAN        NOT NULL DEFAULT TRUE,

  CONSTRAINT fk_plato_categoria FOREIGN KEY (categoria_plato_id)
    REFERENCES categoria_plato(id) ON UPDATE CASCADE
);

-- Disponibilidad de platos por local (para platos regionales)
-- Si es_regional=FALSE, el plato está en todos los locales;
-- esta tabla solo es relevante cuando es_regional=TRUE
CREATE TABLE IF NOT EXISTS plato_local (
  id         INT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  plato_id   INT     NOT NULL,
  local_id   INT     NOT NULL,
  disponible BOOLEAN NOT NULL DEFAULT TRUE,

  CONSTRAINT uq_plato_local UNIQUE (plato_id, local_id),

  CONSTRAINT fk_pl_plato FOREIGN KEY (plato_id)
    REFERENCES plato(id) ON UPDATE CASCADE,

  CONSTRAINT fk_pl_local FOREIGN KEY (local_id)
    REFERENCES local(id) ON UPDATE CASCADE
);

-- Versión de receta (para historial de cambios y costo por versión)
CREATE TABLE IF NOT EXISTS receta (
  id           INT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  plato_id     INT      NOT NULL,
  version      SMALLINT NOT NULL DEFAULT 1,
  fecha_inicio DATE     NOT NULL DEFAULT CURRENT_DATE,
  fecha_fin    DATE,
  vigente      BOOLEAN  NOT NULL DEFAULT TRUE,
  descripcion  TEXT,

  CONSTRAINT uq_receta_version UNIQUE (plato_id, version),

  CONSTRAINT fk_receta_plato FOREIGN KEY (plato_id)
    REFERENCES plato(id) ON UPDATE CASCADE,

  CONSTRAINT ck_receta_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

-- Ingredientes de cada receta con cantidades exactas
CREATE TABLE IF NOT EXISTS receta_ingrediente (
  id               BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  receta_id        INT            NOT NULL,
  ingrediente_id   INT            NOT NULL,
  cantidad         NUMERIC(10, 4) NOT NULL CHECK (cantidad > 0),
  unidad_medida_id SMALLINT       NOT NULL,
  es_opcional      BOOLEAN        NOT NULL DEFAULT FALSE,

  CONSTRAINT uq_ri_receta_ing UNIQUE (receta_id, ingrediente_id),

  CONSTRAINT fk_ri_receta FOREIGN KEY (receta_id)
    REFERENCES receta(id) ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT fk_ri_ingrediente FOREIGN KEY (ingrediente_id)
    REFERENCES ingrediente(id) ON UPDATE CASCADE,

  CONSTRAINT fk_ri_unidad FOREIGN KEY (unidad_medida_id)
    REFERENCES unidad_medida(id) ON UPDATE CASCADE
);

-- =============================================================================
-- FASE 9 - MENU DEL DIA
-- =============================================================================

CREATE TABLE IF NOT EXISTS menu_dia (
  id       INT     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  local_id INT     NOT NULL,
  fecha    DATE    NOT NULL,
  activo   BOOLEAN NOT NULL DEFAULT TRUE,

  CONSTRAINT uq_menu_dia_local_fecha UNIQUE (local_id, fecha),

  CONSTRAINT fk_md_local FOREIGN KEY (local_id)
    REFERENCES local(id) ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS menu_dia_plato (
  id              INT            GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  menu_dia_id     INT            NOT NULL,
  plato_id        INT            NOT NULL,
  precio_especial NUMERIC(10, 2),  -- NULL = usar precio_base del plato

  CONSTRAINT uq_mdp_menu_plato UNIQUE (menu_dia_id, plato_id),

  CONSTRAINT fk_mdp_menu FOREIGN KEY (menu_dia_id)
    REFERENCES menu_dia(id) ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT fk_mdp_plato FOREIGN KEY (plato_id)
    REFERENCES plato(id) ON UPDATE CASCADE
);

-- =============================================================================
-- FASE 10 - RESERVA
-- =============================================================================

CREATE TABLE IF NOT EXISTS reserva (
  id             INT            GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  local_id       INT            NOT NULL,
  cliente_id     INT            NOT NULL,
  empleado_id    INT,                        -- quién registró la reserva
  fecha_reserva  TIMESTAMPTZ    NOT NULL,     -- fecha y hora del evento
  num_personas   SMALLINT       NOT NULL CHECK (num_personas > 0),
  estado         estado_reserva NOT NULL DEFAULT 'pendiente',
  descripcion    TEXT,                        -- tipo de evento, requerimientos
  fecha_registro TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_res_local FOREIGN KEY (local_id)
    REFERENCES local(id) ON UPDATE CASCADE,

  CONSTRAINT fk_res_cliente FOREIGN KEY (cliente_id)
    REFERENCES cliente(id) ON UPDATE CASCADE,

  CONSTRAINT fk_res_empleado FOREIGN KEY (empleado_id)
    REFERENCES empleado(id) ON UPDATE CASCADE
);

-- =============================================================================
-- FASE 11 - VENTA (ORDEN / FACTURA)
-- =============================================================================

CREATE TABLE IF NOT EXISTS venta (
  id               BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  local_id         INT            NOT NULL,
  empleado_id      INT            NOT NULL,  -- cajero o mesero que procesó
  cliente_id       INT,                       -- NULL si cliente no registrado
  reserva_id       INT,                       -- NULL si no es de una reserva
  tipo_servicio    tipo_servicio  NOT NULL,
  fecha_hora       TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  subtotal         NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
  descuento        NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (descuento >= 0),
  impuesto         NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (impuesto >= 0),
  total            NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (total >= 0),
  puntos_ganados   INT            NOT NULL DEFAULT 0 CHECK (puntos_ganados >= 0),
  puntos_canjeados INT            NOT NULL DEFAULT 0 CHECK (puntos_canjeados >= 0),
  estado           estado_venta   NOT NULL DEFAULT 'abierta',
  observacion      TEXT,

  CONSTRAINT fk_venta_local FOREIGN KEY (local_id)
    REFERENCES local(id) ON UPDATE CASCADE,

  CONSTRAINT fk_venta_empleado FOREIGN KEY (empleado_id)
    REFERENCES empleado(id) ON UPDATE CASCADE,

  CONSTRAINT fk_venta_cliente FOREIGN KEY (cliente_id)
    REFERENCES cliente(id) ON UPDATE CASCADE,

  CONSTRAINT fk_venta_reserva FOREIGN KEY (reserva_id)
    REFERENCES reserva(id) ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS venta_detalle (
  id              BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  venta_id        BIGINT         NOT NULL,
  plato_id        INT            NOT NULL,
  receta_id       INT            NOT NULL,  -- versión de receta usada
  cantidad        SMALLINT       NOT NULL CHECK (cantidad > 0),
  precio_unitario NUMERIC(10, 2) NOT NULL CHECK (precio_unitario > 0),
  descuento_linea NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (descuento_linea >= 0),
  subtotal_linea  NUMERIC(12, 2) GENERATED ALWAYS AS
                  ((cantidad * precio_unitario) - descuento_linea) STORED,
  nota            TEXT,

  CONSTRAINT fk_vd_venta FOREIGN KEY (venta_id)
    REFERENCES venta(id) ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT fk_vd_plato FOREIGN KEY (plato_id)
    REFERENCES plato(id) ON UPDATE CASCADE,

  CONSTRAINT fk_vd_receta FOREIGN KEY (receta_id)
    REFERENCES receta(id) ON UPDATE CASCADE
);

-- Pagos de una venta (puede ser pago mixto: efectivo + SINPE)
CREATE TABLE IF NOT EXISTS venta_pago (
  id             BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  venta_id       BIGINT         NOT NULL,
  metodo_pago_id SMALLINT       NOT NULL,
  monto          NUMERIC(12, 2) NOT NULL CHECK (monto > 0),
  referencia     VARCHAR(100),  -- número de transacción SINPE, voucher tarjeta, etc.

  CONSTRAINT fk_vp_venta FOREIGN KEY (venta_id)
    REFERENCES venta(id) ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT fk_vp_metodo_pago FOREIGN KEY (metodo_pago_id)
    REFERENCES metodo_pago(id) ON UPDATE CASCADE
);

-- =============================================================================
-- FASE 12 - FACTURA ELECTRONICA (HACIENDA - COSTA RICA)
-- =============================================================================

CREATE TABLE IF NOT EXISTS factura_electronica (
  id                 BIGINT              GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  venta_id           BIGINT              NOT NULL UNIQUE,
  tipo_documento     tipo_documento_fe   NOT NULL DEFAULT 'factura_electronica',
  tipo_receptor      tipo_receptor_fe    NOT NULL,
  identificacion     VARCHAR(20)         NOT NULL,
  nombre_receptor    VARCHAR(150)        NOT NULL,
  email_receptor     VARCHAR(120),
  clave_hacienda     VARCHAR(50),        -- clave numérica 50 dígitos (Hacienda CR)
  numero_consecutivo VARCHAR(20),
  fecha_emision      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
  estado_hacienda    estado_hacienda_fe  NOT NULL DEFAULT 'pendiente',
  xml_url            TEXT,               -- URL del XML firmado

  CONSTRAINT fk_fe_venta FOREIGN KEY (venta_id)
    REFERENCES venta(id) ON UPDATE CASCADE
);

-- =============================================================================
-- FASE 13 - TABLAS DE AUDITORÍA
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Auditoría de cambios de precio de platos
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auditoria_precio_plato (
  id               BIGINT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  plato_id         INT            NOT NULL,
  precio_anterior  NUMERIC(10, 2) NOT NULL,
  precio_nuevo     NUMERIC(10, 2) NOT NULL,
  usuario_db       VARCHAR(100)   NOT NULL,
  fecha_cambio     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

  CONSTRAINT fk_app_plato FOREIGN KEY (plato_id)
    REFERENCES plato(id) ON UPDATE CASCADE
);
