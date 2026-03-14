-- -----------------------------------------------------------------------------
-- Provincias de Costa Rica
-- -----------------------------------------------------------------------------
INSERT INTO provincia (nombre) VALUES
  ('San José'), ('Alajuela'), ('Cartago'),
  ('Heredia'), ('Guanacaste'), ('Puntarenas'), ('Limón');

-- -----------------------------------------------------------------------------
-- Unidades de medida comunes en cocina
-- -----------------------------------------------------------------------------
INSERT INTO unidad_medida (nombre, simbolo) VALUES
  ('kilogramo',   'kg'),
  ('gramo',       'g'),
  ('litro',       'L'),
  ('mililitro',   'ml'),
  ('unidad',      'u'),
  ('taza',        'tz'),
  ('cucharada',   'cda'),
  ('cucharadita', 'cdta');

-- -----------------------------------------------------------------------------
-- Roles de empleado
-- -----------------------------------------------------------------------------
INSERT INTO rol (nombre, descripcion) VALUES
  ('administrador', 'Administrador del local'),
  ('cajero',        'Responsable de cobros y facturación'),
  ('cocinero',      'Personal de cocina'),
  ('mesero',        'Servicio al cliente en salón');

-- -----------------------------------------------------------------------------
-- Categorías de plato
-- -----------------------------------------------------------------------------
INSERT INTO categoria_plato (nombre) VALUES
  ('Entradas'), ('Platos fuertes'), ('Sopas y caldos'),
  ('Arroces'), ('Postres'), ('Bebidas'), ('Menú del día');

-- -----------------------------------------------------------------------------
-- Categorías de ingrediente
-- -----------------------------------------------------------------------------
INSERT INTO categoria_ingrediente (nombre) VALUES
  ('Carnes y aves'), ('Mariscos y pescados'), ('Vegetales y tubérculos'),
  ('Granos y cereales'), ('Lácteos'), ('Especias y condimentos'),
  ('Aceites y grasas'), ('Frutas'), ('Bebidas e insumos');

-- -----------------------------------------------------------------------------
-- Métodos de pago usuales en Costa Rica
-- -----------------------------------------------------------------------------
INSERT INTO metodo_pago (nombre) VALUES
  ('Efectivo colones'), ('Efectivo dólares'),
  ('Tarjeta crédito'), ('Tarjeta débito'),
  ('SINPE Móvil'), ('Transferencia bancaria');
