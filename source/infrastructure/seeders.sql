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

-- -----------------------------------------------------------------------------
-- Cantones de Costa Rica (principales)
-- -----------------------------------------------------------------------------
INSERT INTO canton (provincia_id, nombre) VALUES
  -- San José (id=1)
  (1, 'San José'), (1, 'Escazú'), (1, 'Desamparados'), (1, 'Puriscal'),
  (1, 'Tarrazú'), (1, 'Aserrí'), (1, 'Mora'), (1, 'Goicoechea'),
  (1, 'Santa Ana'), (1, 'Alajuelita'), (1, 'Vázquez de Coronado'),
  -- Alajuela (id=2)
  (2, 'Alajuela'), (2, 'San Ramón'), (2, 'Grecia'), (2, 'San Mateo'),
  (2, 'Atenas'), (2, 'Naranjo'), (2, 'Palmares'), (2, 'Poás'),
  -- Cartago (id=3)
  (3, 'Cartago'), (3, 'Paraíso'), (3, 'La Unión'), (3, 'Jiménez'),
  (3, 'Turrialba'), (3, 'Alvarado'), (3, 'Oreamuno'),
  -- Heredia (id=4)
  (4, 'Heredia'), (4, 'Barva'), (4, 'Santo Domingo'), (4, 'Santa Bárbara'),
  (4, 'San Rafael'), (4, 'San Isidro'), (4, 'Belén'), (4, 'Flores'),
  -- Guanacaste (id=5)
  (5, 'Liberia'), (5, 'Nicoya'), (5, 'Santa Cruz'), (5, 'Bagaces'),
  (5, 'Carrillo'), (5, 'Cañas'), (5, 'Tilarán'),
  -- Puntarenas (id=6)
  (6, 'Puntarenas'), (6, 'Esparza'), (6, 'Buenos Aires'), (6, 'Montes de Oro'),
  (6, 'Osa'), (6, 'Quepos'), (6, 'Golfito'),
  -- Limón (id=7)
  (7, 'Limón'), (7, 'Pococí'), (7, 'Siquirres'), (7, 'Talamanca'),
  (7, 'Matina'), (7, 'Guácimo');

-- -----------------------------------------------------------------------------
-- Distritos de Costa Rica (selección representativa)
-- -----------------------------------------------------------------------------
INSERT INTO distrito (canton_id, nombre) VALUES
  -- San José (canton_id=1)
  (1, 'Carmen'), (1, 'Merced'), (1, 'Hospital'), (1, 'Catedral'),
  (1, 'Zapote'), (1, 'San Francisco de Dos Ríos'),
  -- Escazú (canton_id=2)
  (2, 'Escazú'), (2, 'San Antonio'), (2, 'San Rafael'),
  -- Desamparados (canton_id=3)
  (3, 'Desamparados'), (3, 'San Miguel'), (3, 'San Juan de Dios'),
  -- Alajuela (canton_id=12)
  (12, 'Alajuela'), (12, 'San José'), (12, 'Carrizal'), (12, 'Desamparados'),
  -- Heredia (canton_id=27)
  (27, 'Heredia'), (27, 'Mercedes'), (27, 'San Francisco'),
  -- Liberia (canton_id=35)
  (35, 'Liberia'), (35, 'Cañas Dulces'),
  -- Puntarenas (canton_id=42)
  (42, 'Puntarenas'), (42, 'Pitahaya'), (42, 'Chacarita'),
  -- Limón (canton_id=49)
  (49, 'Limón'), (49, 'Valle La Estrella');

-- -----------------------------------------------------------------------------
-- Locales (Sucursales del restaurante)
-- -----------------------------------------------------------------------------
INSERT INTO local (nombre, telefono, email, direccion, distrito_id, activo, fecha_apertura) VALUES
  ('Pet Homeland Flavors - San José Centro', '2222-1234', 'sanjose@pethomeland.cr', 
   'Avenida Central, frente al Teatro Nacional', 1, TRUE, '2023-01-15'),
  ('Pet Homeland Flavors - Escazú', '2228-5678', 'escazu@pethomeland.cr',
   'Multiplaza Escazú, segundo nivel', 7, TRUE, '2023-06-20'),
  ('Pet Homeland Flavors - Alajuela Centro', '2441-9876', 'alajuela@pethomeland.cr',
   'Calle 2, Avenida 3, edificio Alajuela Plaza', 16, TRUE, '2024-02-10'),
  ('Pet Homeland Flavors - Heredia', '2237-4321', 'heredia@pethomeland.cr',
   'Paseo de las Flores, local 205', 21, TRUE, '2024-08-05'),
  ('Pet Homeland Flavors - Liberia', '2666-8888', 'liberia@pethomeland.cr',
   'Centro Comercial Plaza Liberia', 23, TRUE, '2025-01-12');

-- -----------------------------------------------------------------------------
-- Empleados
-- -----------------------------------------------------------------------------
INSERT INTO empleado (cedula, nombre, apellido1, apellido2, telefono, email, fecha_ingreso, activo) VALUES
  ('102340567', 'Carlos', 'Ramírez', 'Solís', '8765-4321', 'carlos.ramirez@pethomeland.cr', '2023-01-10', TRUE),
  ('203451678', 'María', 'González', 'Mora', '8876-5432', 'maria.gonzalez@pethomeland.cr', '2023-01-10', TRUE),
  ('304562789', 'José', 'Hernández', 'Castro', '8987-6543', 'jose.hernandez@pethomeland.cr', '2023-06-15', TRUE),
  ('405673890', 'Ana', 'Vargas', 'Rojas', '7098-7654', 'ana.vargas@pethomeland.cr', '2023-06-15', TRUE),
  ('506784901', 'Luis', 'Madrigal', 'Arias', '7109-8765', 'luis.madrigal@pethomeland.cr', '2024-02-01', TRUE),
  ('607895012', 'Carmen', 'Jiménez', 'Salas', '7210-9876', 'carmen.jimenez@pethomeland.cr', '2024-02-01', TRUE),
  ('708906123', 'Roberto', 'Quesada', 'Vega', '7321-0987', 'roberto.quesada@pethomeland.cr', '2024-08-01', TRUE),
  ('109017234', 'Patricia', 'Montero', 'Campos', '7432-1098', 'patricia.montero@pethomeland.cr', '2024-08-01', TRUE),
  ('110128345', 'Fernando', 'Solano', 'Pérez', '7543-2109', 'fernando.solano@pethomeland.cr', '2025-01-08', TRUE),
  ('111239456', 'Sofía', 'Rojas', 'Blanco', '7654-3210', 'sofia.rojas@pethomeland.cr', '2025-01-08', TRUE),
  ('112340567', 'Diego', 'Alfaro', 'Monge', '7765-4321', 'diego.alfaro@pethomeland.cr', '2023-02-01', TRUE),
  ('113451678', 'Laura', 'Chacón', 'Núñez', '7876-5432', 'laura.chacon@pethomeland.cr', '2023-07-01', TRUE),
  ('114562789', 'Alberto', 'Mora', 'Gutiérrez', '7987-6543', 'alberto.mora@pethomeland.cr', '2024-03-01', TRUE),
  ('115673890', 'Gabriela', 'Sanchez', 'Fonseca', '6098-7654', 'gabriela.sanchez@pethomeland.cr', '2024-09-01', TRUE),
  ('116784901', 'Andrés', 'Villalobos', 'Cordero', '6109-8765', 'andres.villalobos@pethomeland.cr', '2025-02-01', TRUE),
  ('117895012', 'Elena', 'Bonilla', 'Aguilar', '6210-9876', 'elena.bonilla@pethomeland.cr', '2023-03-15', TRUE),
  ('118906123', 'Mauricio', 'Carmona', 'Espinoza', '6321-0987', 'mauricio.carmona@pethomeland.cr', '2023-08-10', TRUE),
  ('119017234', 'Natalia', 'Zúñiga', 'Méndez', '6432-1098', 'natalia.zuniga@pethomeland.cr', '2024-04-15', TRUE),
  ('120128345', 'Ricardo', 'Barrantes', 'Silva', '6543-2109', 'ricardo.barrantes@pethomeland.cr', '2024-10-20', TRUE),
  ('121239456', 'Valeria', 'Ocampo', 'Ortiz', '6654-3210', 'valeria.ocampo@pethomeland.cr', '2025-03-01', TRUE);

-- -----------------------------------------------------------------------------
-- Empleado-Local (asignaciones de empleados a locales con roles)
-- -----------------------------------------------------------------------------
INSERT INTO empleado_local (empleado_id, local_id, rol_id, fecha_inicio, activo) VALUES
  -- Local 1 (San José Centro)
  (1, 1, 1, '2023-01-10', TRUE),  -- Carlos administrador
  (2, 1, 2, '2023-01-10', TRUE),  -- María cajera
  (11, 1, 3, '2023-02-01', TRUE), -- Diego cocinero
  (16, 1, 4, '2023-03-15', TRUE), -- Elena mesera
  -- Local 2 (Escazú)
  (3, 2, 1, '2023-06-15', TRUE),  -- José administrador
  (4, 2, 2, '2023-06-15', TRUE),  -- Ana cajera
  (12, 2, 3, '2023-07-01', TRUE), -- Laura cocinera
  (17, 2, 4, '2023-08-10', TRUE), -- Mauricio mesero
  -- Local 3 (Alajuela)
  (5, 3, 1, '2024-02-01', TRUE),  -- Luis administrador
  (6, 3, 2, '2024-02-01', TRUE),  -- Carmen cajera
  (13, 3, 3, '2024-03-01', TRUE), -- Alberto cocinero
  (18, 3, 4, '2024-04-15', TRUE), -- Natalia mesera
  -- Local 4 (Heredia)
  (7, 4, 1, '2024-08-01', TRUE),  -- Roberto administrador
  (8, 4, 2, '2024-08-01', TRUE),  -- Patricia cajera
  (14, 4, 3, '2024-09-01', TRUE), -- Gabriela cocinera
  (19, 4, 4, '2024-10-20', TRUE), -- Ricardo mesero
  -- Local 5 (Liberia)
  (9, 5, 1, '2025-01-08', TRUE),  -- Fernando administrador
  (10, 5, 2, '2025-01-08', TRUE), -- Sofía cajera
  (15, 5, 3, '2025-02-01', TRUE), -- Andrés cocinero
  (20, 5, 4, '2025-03-01', TRUE); -- Valeria mesera

-- -----------------------------------------------------------------------------
-- Clientes
-- -----------------------------------------------------------------------------
INSERT INTO cliente (identificacion, tipo_id, nombre, apellido1, apellido2, telefono, email, activo) VALUES
  ('108760543', 'cedula_fisica', 'Juan', 'Pérez', 'López', '8345-6789', 'juan.perez@email.com', TRUE),
  ('209871654', 'cedula_fisica', 'Sandra', 'Murillo', 'Sánchez', '8456-7890', 'sandra.murillo@email.com', TRUE),
  ('310982765', 'cedula_fisica', 'Miguel', 'Castro', 'Villalobos', '8567-8901', 'miguel.castro@email.com', TRUE),
  ('411093876', 'cedula_fisica', 'Rosa', 'Vega', 'Calderón', '8678-9012', 'rosa.vega@email.com', TRUE),
  ('512104987', 'cedula_fisica', 'Pedro', 'Solís', 'Mata', '8789-0123', 'pedro.solis@email.com', TRUE),
  ('613216098', 'cedula_fisica', 'Lucía', 'Araya', 'Chinchilla', '8890-1234', 'lucia.araya@email.com', TRUE),
  ('714327109', 'cedula_fisica', 'Rodrigo', 'Brenes', 'Fallas', '8901-2345', 'rodrigo.brenes@email.com', TRUE),
  ('115438210', 'cedula_fisica', 'Silvia', 'Monge', 'Umaña', '7012-3456', 'silvia.monge@email.com', TRUE),
  ('116549321', 'cedula_fisica', 'Tomás', 'Guzmán', 'Paniagua', '7123-4567', 'tomas.guzman@email.com', TRUE),
  ('117650432', 'cedula_fisica', 'Andrea', 'Salazar', 'Marín', '7234-5678', 'andrea.salazar@email.com', TRUE),
  ('3102456789', 'cedula_juridica', 'Grupo Empresarial TechCR', NULL, NULL, '2222-9999', 'ventas@techcr.com', TRUE),
  ('3102567890', 'cedula_juridica', 'Corporación Innovar SA', NULL, NULL, '2233-8888', 'contacto@innovar.cr', TRUE),
  ('118761543', 'cedula_fisica', 'Esteban', 'Navarro', 'Cordero', '7345-6789', 'esteban.navarro@email.com', TRUE),
  ('119872654', 'cedula_fisica', 'Daniela', 'Esquivel', 'Salas', '7456-7890', 'daniela.esquivel@email.com', TRUE),
  ('120983765', 'cedula_fisica', 'Julio', 'Fernández', 'Quirós', '7567-8901', 'julio.fernandez@email.com', TRUE),
  ('121094876', 'cedula_fisica', 'Melissa', 'Ulate', 'Díaz', '7678-9012', 'melissa.ulate@email.com', TRUE),
  ('122105987', 'cedula_fisica', 'Fabián', 'Bolaños', 'Herrera', '7789-0123', 'fabian.bolanos@email.com', TRUE),
  ('123217098', 'cedula_fisica', 'Carolina', 'Coto', 'Alvarado', '7890-1234', 'carolina.coto@email.com', TRUE),
  ('124328109', 'cedula_fisica', 'Sebastián', 'Ruiz', 'Vargas', '7901-2345', 'sebastian.ruiz@email.com', TRUE),
  ('125439210', 'cedula_fisica', 'Paola', 'Guevara', 'Acosta', '6012-3456', 'paola.guevara@email.com', TRUE);

-- -----------------------------------------------------------------------------
-- Fidelización (programa de puntos)
-- -----------------------------------------------------------------------------
INSERT INTO fidelizacion (cliente_id, puntos_totales, fecha_registro) VALUES
  (1, 450, '2023-02-01'), (2, 1280, '2023-03-15'), (3, 320, '2023-05-20'),
  (4, 890, '2023-07-10'), (5, 150, '2024-01-05'), (6, 2340, '2023-04-12'),
  (7, 670, '2024-03-18'), (8, 1450, '2023-08-25'), (9, 220, '2024-06-30'),
  (10, 980, '2024-02-14'), (13, 530, '2024-09-05'), (14, 1890, '2023-11-20'),
  (15, 410, '2024-12-10'), (16, 760, '2024-04-22'), (17, 1120, '2024-07-08');

-- -----------------------------------------------------------------------------
-- Movimientos de fidelización (historial de puntos)
-- -----------------------------------------------------------------------------
INSERT INTO fidelizacion_movimiento (fidelizacion_id, puntos, descripcion, fecha) VALUES
  (1, 500, 'Puntos bienvenida', '2023-02-01 10:00:00-06'),
  (1, 120, 'Compra venta #1001', '2023-02-15 12:30:00-06'),
  (1, -170, 'Canje descuento', '2023-03-10 14:00:00-06'),
  (2, 500, 'Puntos bienvenida', '2023-03-15 11:00:00-06'),
  (2, 450, 'Compra venta #1045', '2023-04-20 13:45:00-06'),
  (2, 330, 'Compra venta #1123', '2023-06-05 19:20:00-06'),
  (3, 500, 'Puntos bienvenida', '2023-05-20 09:30:00-06'),
  (3, -180, 'Canje postre gratis', '2023-07-14 16:15:00-06'),
  (4, 500, 'Puntos bienvenida', '2023-07-10 10:45:00-06'),
  (4, 390, 'Compra venta #1234', '2023-08-22 12:00:00-06'),
  (5, 150, 'Puntos bienvenida', '2024-01-05 11:30:00-06'),
  (6, 500, 'Puntos bienvenida', '2023-04-12 10:00:00-06'),
  (6, 920, 'Compra evento especial', '2023-05-30 20:00:00-06'),
  (6, 560, 'Compra venta #1567', '2023-09-12 13:30:00-06'),
  (6, 360, 'Compra venta #1789', '2023-11-25 18:45:00-06');

-- -----------------------------------------------------------------------------
-- Ingredientes
-- -----------------------------------------------------------------------------
INSERT INTO ingrediente (nombre, categoria_ingrediente_id, unidad_medida_id, perecedero, activo) VALUES
  -- Carnes y aves (cat 1)
  ('Pollo entero', 1, 1, TRUE, TRUE),
  ('Pechuga de pollo', 1, 1, TRUE, TRUE),
  ('Carne molida res', 1, 1, TRUE, TRUE),
  ('Costilla de cerdo', 1, 1, TRUE, TRUE),
  ('Chorizo costarricense', 1, 5, TRUE, TRUE),
  -- Mariscos y pescados (cat 2)
  ('Filete de tilapia', 2, 1, TRUE, TRUE),
  ('Camarones', 2, 1, TRUE, TRUE),
  ('Corvina', 2, 1, TRUE, TRUE),
  -- Vegetales y tubérculos (cat 3)
  ('Tomate', 3, 1, TRUE, TRUE),
  ('Cebolla blanca', 3, 1, TRUE, TRUE),
  ('Chile dulce', 3, 1, TRUE, TRUE),
  ('Culantro', 3, 5, TRUE, TRUE),
  ('Plátano maduro', 3, 5, TRUE, TRUE),
  ('Papa', 3, 1, TRUE, TRUE),
  ('Yuca', 3, 1, TRUE, TRUE),
  ('Zanahoria', 3, 1, TRUE, TRUE),
  ('Repollo', 3, 1, TRUE, TRUE),
  ('Lechuga', 3, 5, TRUE, TRUE),
  ('Aguacate', 3, 5, TRUE, TRUE),
  ('Chayote', 3, 1, TRUE, TRUE),
  -- Granos y cereales (cat 4)
  ('Arroz blanco', 4, 1, FALSE, TRUE),
  ('Frijoles negros', 4, 1, FALSE, TRUE),
  ('Frijoles rojos', 4, 1, FALSE, TRUE),
  ('Harina de maíz', 4, 1, FALSE, TRUE),
  ('Harina de trigo', 4, 1, FALSE, TRUE),
  ('Pasta spaguetti', 4, 1, FALSE, TRUE),
  -- Lácteos (cat 5)
  ('Leche entera', 5, 3, TRUE, TRUE),
  ('Queso tierno', 5, 1, TRUE, TRUE),
  ('Natilla', 5, 1, TRUE, TRUE),
  ('Mantequilla', 5, 1, TRUE, TRUE),
  ('Crema dulce', 5, 3, TRUE, TRUE),
  -- Especias y condimentos (cat 6)
  ('Sal', 6, 1, FALSE, TRUE),
  ('Pimienta negra', 6, 1, FALSE, TRUE),
  ('Comino', 6, 1, FALSE, TRUE),
  ('Consomé de pollo', 6, 1, FALSE, TRUE),
  ('Salsa inglesa', 6, 3, FALSE, TRUE),
  ('Salsa Lizano', 6, 3, FALSE, TRUE),
  ('Ajo', 6, 1, TRUE, TRUE),
  -- Aceites y grasas (cat 7)
  ('Aceite vegetal', 7, 3, FALSE, TRUE),
  ('Aceite de oliva', 7, 3, FALSE, TRUE),
  -- Frutas (cat 8)
  ('Limón ácido', 8, 5, TRUE, TRUE),
  ('Naranja', 8, 5, TRUE, TRUE),
  ('Sandía', 8, 1, TRUE, TRUE),
  ('Melón', 8, 1, TRUE, TRUE),
  ('Piña', 8, 5, TRUE, TRUE),
  ('Cas', 8, 1, TRUE, TRUE),
  -- Bebidas e insumos (cat 9)
  ('Agua embotellada', 9, 5, FALSE, TRUE),
  ('Café molido', 9, 1, FALSE, TRUE),
  ('Azúcar blanco', 9, 1, FALSE, TRUE),
  ('Chocolate en polvo', 9, 1, FALSE, TRUE);

-- -----------------------------------------------------------------------------
-- Proveedores
-- -----------------------------------------------------------------------------
INSERT INTO proveedor (razon_social, cedula_juridica, telefono, email, direccion, activo) VALUES
  ('Distribuidora de Alimentos La Cosecha SA', '3101234567', '2290-1111', 'ventas@lacosecha.cr', 
   'San José, Pavas, Bodega 12', TRUE),
  ('Carnes Premium del Valle SA', '3101345678', '2291-2222', 'pedidos@carnespremium.cr',
   'Alajuela, zona industrial', TRUE),
  ('Mariscos y Pescados del Pacífico', '3101456789', '2661-3333', 'info@mariscospac.cr',
   'Puntarenas, Muelle de pescadores', TRUE),
  ('Verduras Frescas Agrícola Hermanos Quesada', '3101567890', '2292-4444', 'ventas@verdurasfrescas.cr',
   'Cartago, Tierra Blanca', TRUE),
  ('Granos y Cereales El Trigal SA', '3101678901', '2293-5555', 'contacto@eltrigal.cr',
   'Heredia, zona franca', TRUE),
  ('Lácteos de Altura Cooperativa', '3101789012', '2294-6666', 'pedidos@lacteosaltura.cr',
   'Cartago, Tierra Blanca', TRUE),
  ('Especias y Condimentos del Mundo', '3101890123', '2295-7777', 'ventas@especiasmundo.cr',
   'San José, Guadalupe', TRUE),
  ('Aceites Industriales CostaRica SA', '3101901234', '2296-8888', 'info@aceitescr.cr',
   'Alajuela, zona industrial', TRUE);

-- -----------------------------------------------------------------------------
-- Proveedor-Ingrediente (relación con precios)
-- -----------------------------------------------------------------------------
INSERT INTO proveedor_ingrediente (proveedor_id, ingrediente_id, precio_unitario, es_proveedor_principal) VALUES
  -- Carnes Premium
  (2, 1, 2500.00, TRUE), (2, 2, 3200.00, TRUE), (2, 3, 3800.00, TRUE),
  (2, 4, 4200.00, TRUE), (2, 5, 1800.00, TRUE),
  -- Mariscos Pacífico
  (3, 6, 4500.00, TRUE), (3, 7, 8900.00, TRUE), (3, 8, 5200.00, TRUE),
  -- Verduras Frescas
  (4, 9, 850.00, TRUE), (4, 10, 920.00, TRUE), (4, 11, 780.00, TRUE),
  (4, 12, 450.00, TRUE), (4, 13, 350.00, TRUE), (4, 14, 680.00, TRUE),
  (4, 15, 720.00, TRUE), (4, 16, 590.00, TRUE), (4, 17, 650.00, TRUE),
  (4, 18, 420.00, TRUE), (4, 19, 950.00, TRUE), (4, 20, 580.00, TRUE),
  -- Granos El Trigal
  (5, 21, 1250.00, TRUE), (5, 22, 1850.00, TRUE), (5, 23, 1900.00, TRUE),
  (5, 24, 1100.00, TRUE), (5, 25, 980.00, TRUE), (5, 26, 1680.00, TRUE),
  -- Lácteos Altura
  (6, 27, 1200.00, TRUE), (6, 28, 3500.00, TRUE), (6, 29, 2200.00, TRUE),
  (6, 30, 2800.00, TRUE), (6, 31, 1800.00, TRUE),
  -- Especias del Mundo
  (7, 32, 450.00, TRUE), (7, 33, 2200.00, TRUE), (7, 34, 1800.00, TRUE),
  (7, 35, 980.00, TRUE), (7, 36, 1250.00, TRUE), (7, 37, 1450.00, TRUE),
  (7, 38, 520.00, TRUE),
  -- Aceites CR
  (8, 39, 2800.00, TRUE), (8, 40, 4500.00, TRUE),
  -- La Cosecha (distribuidor general - precios secundarios)
  (1, 41, 320.00, TRUE), (1, 42, 450.00, TRUE), (1, 43, 1800.00, FALSE),
  (1, 44, 1950.00, FALSE), (1, 45, 680.00, TRUE), (1, 46, 1200.00, TRUE),
  (1, 47, 850.00, TRUE), (1, 48, 520.00, TRUE), (1, 49, 4500.00, TRUE),
  (1, 50, 890.00, TRUE);

-- -----------------------------------------------------------------------------
-- Inventario por local (stock inicial)
-- -----------------------------------------------------------------------------
INSERT INTO inventario_local (local_id, ingrediente_id, cantidad_actual, cantidad_minima) VALUES
  -- Local 1 (San José Centro) - inventario completo
  (1, 1, 25.000, 10.000), (1, 2, 30.000, 15.000), (1, 3, 20.000, 10.000),
  (1, 4, 15.000, 8.000), (1, 5, 40.000, 20.000), (1, 6, 18.000, 10.000),
  (1, 7, 12.000, 5.000), (1, 8, 15.000, 8.000), (1, 9, 10.000, 5.000),
  (1, 10, 8.000, 4.000), (1, 11, 6.000, 3.000), (1, 12, 50.000, 20.000),
  (1, 13, 80.000, 30.000), (1, 14, 25.000, 12.000), (1, 15, 30.000, 15.000),
  (1, 16, 12.000, 6.000), (1, 17, 10.000, 5.000), (1, 18, 60.000, 25.000),
  (1, 19, 45.000, 20.000), (1, 20, 8.000, 4.000), (1, 21, 150.000, 50.000),
  (1, 22, 100.000, 40.000), (1, 23, 80.000, 30.000), (1, 24, 50.000, 20.000),
  (1, 25, 60.000, 25.000), (1, 27, 40.000, 15.000), (1, 28, 20.000, 10.000),
  (1, 29, 15.000, 8.000), (1, 30, 12.000, 5.000), (1, 32, 10.000, 3.000),
  (1, 33, 2.000, 0.500), (1, 35, 5.000, 2.000), (1, 37, 8.000, 3.000),
  (1, 38, 5.000, 2.000), (1, 39, 20.000, 8.000), (1, 41, 200.000, 80.000),
  (1, 49, 20.000, 8.000), (1, 50, 15.000, 5.000),
  -- Local 2 (Escazú)
  (2, 1, 28.000, 10.000), (2, 2, 35.000, 15.000), (2, 3, 22.000, 10.000),
  (2, 6, 20.000, 10.000), (2, 7, 15.000, 5.000), (2, 9, 12.000, 5.000),
  (2, 10, 9.000, 4.000), (2, 11, 7.000, 3.000), (2, 13, 90.000, 30.000),
  (2, 14, 28.000, 12.000), (2, 21, 160.000, 50.000), (2, 22, 110.000, 40.000),
  (2, 28, 22.000, 10.000), (2, 39, 22.000, 8.000), (2, 49, 22.000, 8.000),
  -- Local 3 (Alajuela)
  (3, 1, 22.000, 10.000), (3, 2, 28.000, 15.000), (3, 3, 18.000, 10.000),
  (3, 9, 9.000, 5.000), (3, 10, 7.000, 4.000), (3, 14, 22.000, 12.000),
  (3, 21, 140.000, 50.000), (3, 22, 95.000, 40.000), (3, 28, 18.000, 10.000),
  (3, 39, 18.000, 8.000),
  -- Local 4 (Heredia)
  (4, 1, 24.000, 10.000), (4, 2, 30.000, 15.000), (4, 3, 19.000, 10.000),
  (4, 9, 10.000, 5.000), (4, 14, 24.000, 12.000), (4, 21, 145.000, 50.000),
  (4, 22, 98.000, 40.000), (4, 28, 19.000, 10.000), (4, 39, 19.000, 8.000),
  -- Local 5 (Liberia)
  (5, 1, 20.000, 10.000), (5, 2, 26.000, 15.000), (5, 3, 16.000, 10.000),
  (5, 9, 8.000, 5.000), (5, 14, 20.000, 12.000), (5, 21, 130.000, 50.000),
  (5, 22, 90.000, 40.000), (5, 28, 16.000, 10.000), (5, 39, 16.000, 8.000);

-- -----------------------------------------------------------------------------
-- Compras a proveedores
-- -----------------------------------------------------------------------------
INSERT INTO compra (local_id, proveedor_id, empleado_id, fecha_compra, fecha_recepcion, estado, total, observacion) VALUES
  (1, 2, 1, '2026-03-01 09:00:00-06', '2026-03-01 14:30:00-06', 'recibida', 185000.00, 'Pedido semanal carnes'),
  (1, 4, 1, '2026-03-02 10:15:00-06', '2026-03-02 15:00:00-06', 'recibida', 78500.00, 'Vegetales frescos'),
  (1, 5, 1, '2026-03-03 08:30:00-06', '2026-03-03 16:00:00-06', 'recibida', 295000.00, 'Granos mensuales'),
  (2, 2, 3, '2026-03-01 10:00:00-06', '2026-03-01 15:00:00-06', 'recibida', 165000.00, 'Pedido carnes Escazú'),
  (2, 3, 3, '2026-03-04 11:00:00-06', '2026-03-04 16:30:00-06', 'recibida', 145000.00, 'Mariscos frescos'),
  (3, 2, 5, '2026-03-05 09:30:00-06', '2026-03-05 14:00:00-06', 'recibida', 125000.00, 'Pedido Alajuela'),
  (4, 2, 7, '2026-03-06 10:00:00-06', '2026-03-06 15:30:00-06', 'recibida', 135000.00, 'Pedido Heredia'),
  (5, 2, 9, '2026-03-07 08:00:00-06', '2026-03-07 13:00:00-06', 'recibida', 115000.00, 'Pedido Liberia'),
  (1, 6, 1, '2026-03-08 09:00:00-06', '2026-03-08 11:00:00-06', 'recibida', 89000.00, 'Lácteos semanales'),
  (1, 1, 1, '2026-03-10 10:00:00-06', NULL, 'pendiente', 125000.00, 'Pedido frutas y bebidas');

-- -----------------------------------------------------------------------------
-- Detalle de compras
-- -----------------------------------------------------------------------------
INSERT INTO compra_detalle (compra_id, ingrediente_id, cantidad, precio_unitario) VALUES
  -- Compra 1 (carnes local 1)
  (1, 1, 15.000, 2500.00), (1, 2, 20.000, 3200.00), (1, 3, 12.000, 3800.00),
  -- Compra 2 (vegetales local 1)
  (2, 9, 25.000, 850.00), (2, 10, 18.000, 920.00), (2, 11, 15.000, 780.00),
  (2, 14, 30.000, 680.00), (2, 16, 20.000, 590.00),
  -- Compra 3 (granos local 1)
  (3, 21, 100.000, 1250.00), (3, 22, 80.000, 1850.00),
  -- Compra 4 (carnes local 2)
  (4, 1, 18.000, 2500.00), (4, 2, 22.000, 3200.00),
  -- Compra 5 (mariscos local 2)
  (5, 6, 15.000, 4500.00), (5, 7, 8.000, 8900.00),
  -- Compra 6 (local 3)
  (6, 1, 12.000, 2500.00), (6, 2, 18.000, 3200.00), (6, 3, 10.000, 3800.00),
  -- Compra 7 (local 4)
  (7, 1, 14.000, 2500.00), (7, 2, 19.000, 3200.00), (7, 3, 11.000, 3800.00),
  -- Compra 8 (local 5)
  (8, 1, 11.000, 2500.00), (8, 2, 16.000, 3200.00), (8, 3, 9.000, 3800.00),
  -- Compra 9 (lácteos local 1)
  (9, 27, 25.000, 1200.00), (9, 28, 12.000, 3500.00), (9, 29, 8.000, 2200.00),
  -- Compra 10 (pendiente)
  (10, 45, 30.000, 680.00), (10, 46, 20.000, 1200.00), (10, 49, 15.000, 4500.00);

-- -----------------------------------------------------------------------------
-- Movimientos de inventario (entrada por compras)
-- -----------------------------------------------------------------------------
INSERT INTO movimiento_inventario (inventario_local_id, tipo_movimiento, cantidad, fecha, referencia_id, referencia_tipo, empleado_id) VALUES
  -- Entradas por compra 1
  (1, 'entrada', 15.000, '2026-03-01 14:30:00-06', 1, 'compra', 1),
  (2, 'entrada', 20.000, '2026-03-01 14:30:00-06', 1, 'compra', 1),
  (3, 'entrada', 12.000, '2026-03-01 14:30:00-06', 1, 'compra', 1),
  -- Entradas por compra 2
  (9, 'entrada', 25.000, '2026-03-02 15:00:00-06', 2, 'compra', 1),
  (10, 'entrada', 18.000, '2026-03-02 15:00:00-06', 2, 'compra', 1),
  -- Entradas por compra 3
  (21, 'entrada', 100.000, '2026-03-03 16:00:00-06', 3, 'compra', 1),
  (22, 'entrada', 80.000, '2026-03-03 16:00:00-06', 3, 'compra', 1),
  -- Salidas por producción (ejemplo)
  (1, 'salida', 2.500, '2026-03-08 12:00:00-06', NULL, 'produccion', 11),
  (2, 'salida', 3.200, '2026-03-08 12:30:00-06', NULL, 'produccion', 11),
  (9, 'salida', 1.500, '2026-03-08 13:00:00-06', NULL, 'produccion', 11);

-- -----------------------------------------------------------------------------
-- Traslados internos entre locales
-- -----------------------------------------------------------------------------
INSERT INTO traslado_interno (local_origen_id, local_destino_id, empleado_id, fecha_solicitud, fecha_recepcion, estado, observacion) VALUES
  (1, 3, 1, '2026-03-09 10:00:00-06', '2026-03-10 09:00:00-06', 'recibido', 
   'Traslado de excedente a Alajuela'),
  (1, 2, 1, '2026-03-11 11:00:00-06', '2026-03-11 16:00:00-06', 'recibido',
   'Apoyo inventario Escazú'),
  (2, 4, 3, '2026-03-12 10:30:00-06', NULL, 'en_transito',
   'Traslado a Heredia');

-- -----------------------------------------------------------------------------
-- Detalle de traslados
-- -----------------------------------------------------------------------------
INSERT INTO traslado_detalle (traslado_id, ingrediente_id, cantidad) VALUES
  (1, 21, 20.000), (1, 22, 15.000), (1, 32, 2.000),
  (2, 1, 5.000), (2, 2, 8.000), (2, 28, 4.000),
  (3, 9, 3.000), (3, 10, 2.500), (3, 14, 5.000);

-- -----------------------------------------------------------------------------
-- Platos del menú
-- -----------------------------------------------------------------------------
INSERT INTO plato (nombre, descripcion, categoria_plato_id, precio_base, es_regional, activo) VALUES
  -- Entradas (cat 1)
  ('Pico de gallo con tostadas', 'Tomate, cebolla, culantro con tortillas tostadas', 1, 3500.00, FALSE, TRUE),
  ('Patacones con frijoles molidos', 'Plátano verde frito con frijoles y natilla', 1, 4200.00, FALSE, TRUE),
  ('Tamal de cerdo', 'Tamal tradicional costarricense envuelto en hoja de plátano', 1, 4800.00, FALSE, TRUE),
  -- Platos fuertes (cat 2)
  ('Casado tradicional', 'Arroz, frijoles, plátano maduro, ensalada, picadillo y carne a elegir', 2, 7500.00, FALSE, TRUE),
  ('Arroz con pollo', 'Arroz amarillo con pollo y vegetales, acompañado de ensalada', 2, 6800.00, FALSE, TRUE),
  ('Olla de carne', 'Sopa espesa con carne, yuca, papa, chayote, plátano y vegetales', 2, 8200.00, FALSE, TRUE),
  ('Gallo pinto con natilla', 'Mezcla de arroz y frijoles, acompañado de natilla y tortillas', 2, 5500.00, FALSE, TRUE),
  ('Chifrijo', 'Arroz, frijoles, chicharrón, pico de gallo y aguacate', 2, 6500.00, TRUE, TRUE),
  ('Picadillo de papa con carne', 'Papa picada con carne molida y culantro', 2, 5800.00, FALSE, TRUE),
  ('Bistec encebollado', 'Bistec de res con cebolla salteada, arroz y frijoles', 2, 8900.00, FALSE, TRUE),
  -- Sopas y caldos (cat 3)
  ('Sopa negra', 'Sopa de frijoles negros con huevo duro y vegetales', 3, 4500.00, FALSE, TRUE),
  ('Sopa de mondongo', 'Caldo de panza de res con vegetales y especias', 3, 7200.00, FALSE, TRUE),
  ('Sopa de mariscos', 'Caldo de pescado con camarones y vegetales', 3, 9500.00, TRUE, TRUE),
  -- Arroces (cat 4)
  ('Arroz con camarones', 'Arroz salteado con camarones al ajillo', 4, 9800.00, TRUE, TRUE),
  ('Arroz con palmito', 'Arroz con palmito picado y vegetales', 4, 7200.00, FALSE, TRUE),
  -- Postres (cat 5)
  ('Tres leches', 'Queque empapado en tres tipos de leche', 5, 3800.00, FALSE, TRUE),
  ('Flan de coco', 'Flan casero con coco rallado', 5, 3200.00, FALSE, TRUE),
  ('Arroz con leche', 'Postre tradicional de arroz con canela', 5, 2800.00, FALSE, TRUE),
  -- Bebidas (cat 6)
  ('Refresco natural de cas', 'Bebida refrescante de fruta cas', 6, 1800.00, FALSE, TRUE),
  ('Agua de pipa', 'Agua de coco natural', 6, 2200.00, TRUE, TRUE),
  ('Café chorreado', 'Café costarricense preparado en chorreador', 6, 1500.00, FALSE, TRUE),
  ('Horchata', 'Bebida de arroz con canela', 6, 1800.00, FALSE, TRUE),
  -- Menú del día (cat 7)
  ('Menú ejecutivo', 'Plato fuerte del día con bebida y postre incluido', 7, 6500.00, FALSE, TRUE);

-- -----------------------------------------------------------------------------
-- Platos regionales disponibles por local
-- -----------------------------------------------------------------------------
INSERT INTO plato_local (plato_id, local_id, disponible) VALUES
  -- Chifrijo disponible en todos los locales
  (8, 1, TRUE), (8, 2, TRUE), (8, 3, TRUE), (8, 4, TRUE), (8, 5, TRUE),
  -- Sopa de mariscos solo en locales cercanos al mar (Puntarenas-Liberia)
  (13, 5, TRUE),
  -- Arroz con camarones en locales selectos
  (14, 1, TRUE), (14, 2, TRUE), (14, 5, TRUE),
  -- Agua de pipa en todos
  (20, 1, TRUE), (20, 2, TRUE), (20, 3, TRUE), (20, 4, TRUE), (20, 5, TRUE);

-- -----------------------------------------------------------------------------
-- Recetas (versiones de cada plato)
-- -----------------------------------------------------------------------------
INSERT INTO receta (plato_id, version, fecha_inicio, vigente, descripcion) VALUES
  (1, 1, '2023-01-15', TRUE, 'Receta original pico de gallo'),
  (2, 1, '2023-01-15', TRUE, 'Receta original patacones'),
  (3, 1, '2023-01-15', TRUE, 'Receta tradicional tamal'),
  (4, 1, '2023-01-15', TRUE, 'Casado estándar'),
  (5, 1, '2023-01-15', TRUE, 'Arroz con pollo tradicional'),
  (6, 1, '2023-01-15', TRUE, 'Olla de carne completa'),
  (7, 1, '2023-01-15', TRUE, 'Gallo pinto clásico'),
  (8, 1, '2023-06-20', TRUE, 'Chifrijo original'),
  (9, 1, '2023-01-15', TRUE, 'Picadillo tradicional'),
  (10, 1, '2023-01-15', TRUE, 'Bistec encebollado estándar'),
  (11, 1, '2023-01-15', TRUE, 'Sopa negra tradicional'),
  (12, 1, '2023-01-15', TRUE, 'Mondongo casero'),
  (13, 1, '2023-01-15', TRUE, 'Sopa de mariscos del Pacífico'),
  (14, 1, '2023-01-15', TRUE, 'Arroz con camarones al ajillo'),
  (15, 1, '2023-01-15', TRUE, 'Arroz con palmito básico'),
  (16, 1, '2023-01-15', TRUE, 'Tres leches clásico'),
  (17, 1, '2023-01-15', TRUE, 'Flan de coco casero'),
  (18, 1, '2023-01-15', TRUE, 'Arroz con leche tradicional'),
  (19, 1, '2023-01-15', TRUE, 'Refresco de cas natural'),
  (20, 1, '2023-01-15', TRUE, 'Agua de pipa fresca'),
  (21, 1, '2023-01-15', TRUE, 'Café chorreado costarricense'),
  (22, 1, '2023-01-15', TRUE, 'Horchata casera'),
  (23, 1, '2023-01-15', TRUE, 'Menú ejecutivo variable');

-- -----------------------------------------------------------------------------
-- Ingredientes de cada receta
-- -----------------------------------------------------------------------------
INSERT INTO receta_ingrediente (receta_id, ingrediente_id, cantidad, unidad_medida_id, es_opcional) VALUES
  -- Receta 1: Pico de gallo
  (1, 9, 0.300, 1, FALSE), (1, 10, 0.100, 1, FALSE), (1, 12, 0.050, 1, FALSE),
  (1, 41, 0.020, 1, FALSE), (1, 32, 0.005, 1, FALSE),
  -- Receta 2: Patacones
  (2, 13, 2.000, 5, FALSE), (2, 22, 0.150, 1, FALSE), (2, 29, 0.100, 1, FALSE),
  (2, 39, 0.100, 3, FALSE), (2, 32, 0.005, 1, FALSE),
  -- Receta 4: Casado tradicional
  (4, 21, 0.150, 1, FALSE), (4, 22, 0.100, 1, FALSE), (4, 13, 1.000, 5, FALSE),
  (4, 2, 0.200, 1, FALSE), (4, 9, 0.080, 1, FALSE), (4, 17, 0.060, 1, FALSE),
  (4, 14, 0.150, 1, FALSE), (4, 32, 0.008, 1, FALSE), (4, 39, 0.030, 3, FALSE),
  -- Receta 5: Arroz con pollo
  (5, 21, 0.200, 1, FALSE), (5, 1, 0.300, 1, FALSE), (5, 11, 0.080, 1, FALSE),
  (5, 10, 0.060, 1, FALSE), (5, 35, 0.010, 1, FALSE), (5, 32, 0.008, 1, FALSE),
  (5, 39, 0.040, 3, FALSE),
  -- Receta 7: Gallo pinto
  (7, 21, 0.150, 1, FALSE), (7, 22, 0.100, 1, FALSE), (7, 10, 0.040, 1, FALSE),
  (7, 11, 0.030, 1, FALSE), (7, 37, 0.015, 3, FALSE), (7, 29, 0.080, 1, FALSE),
  (7, 32, 0.006, 1, FALSE), (7, 39, 0.030, 3, FALSE),
  -- Receta 8: Chifrijo
  (8, 21, 0.120, 1, FALSE), (8, 22, 0.100, 1, FALSE), (8, 4, 0.150, 1, FALSE),
  (8, 9, 0.080, 1, FALSE), (8, 10, 0.040, 1, FALSE), (8, 12, 0.020, 1, FALSE),
  (8, 19, 0.500, 5, FALSE),
  -- Receta 11: Sopa negra
  (11, 22, 0.200, 1, FALSE), (11, 10, 0.060, 1, FALSE), (11, 11, 0.040, 1, FALSE),
  (11, 12, 0.030, 1, FALSE), (11, 35, 0.010, 1, FALSE), (11, 32, 0.008, 1, FALSE),
  -- Receta 13: Sopa de mariscos
  (13, 8, 0.200, 1, FALSE), (13, 7, 0.150, 1, FALSE), (13, 9, 0.100, 1, FALSE),
  (13, 10, 0.060, 1, FALSE), (13, 11, 0.050, 1, FALSE), (13, 12, 0.030, 1, FALSE),
  -- Receta 16: Tres leches
  (16, 25, 0.120, 1, FALSE), (16, 27, 0.300, 3, FALSE), (16, 31, 0.200, 3, FALSE),
  (16, 50, 0.080, 1, FALSE), (16, 49, 0.100, 1, FALSE),
  -- Receta 19: Refresco de cas
  (19, 47, 0.250, 1, FALSE), (19, 49, 0.080, 1, FALSE), (19, 48, 1.000, 3, FALSE),
  -- Receta 21: Café chorreado
  (21, 49, 0.020, 1, FALSE), (21, 48, 0.250, 3, FALSE);

-- -----------------------------------------------------------------------------
-- Menú del día
-- -----------------------------------------------------------------------------
INSERT INTO menu_dia (local_id, fecha, activo) VALUES
  (1, '2026-03-14', TRUE), (1, '2026-03-15', TRUE), (1, '2026-03-16', TRUE),
  (2, '2026-03-14', TRUE), (2, '2026-03-15', TRUE), (2, '2026-03-16', TRUE),
  (3, '2026-03-14', TRUE), (3, '2026-03-15', TRUE), (3, '2026-03-16', TRUE),
  (4, '2026-03-14', TRUE), (4, '2026-03-15', TRUE), (4, '2026-03-16', TRUE),
  (5, '2026-03-14', TRUE), (5, '2026-03-15', TRUE), (5, '2026-03-16', TRUE);

-- -----------------------------------------------------------------------------
-- Platos del menú del día
-- -----------------------------------------------------------------------------
INSERT INTO menu_dia_plato (menu_dia_id, plato_id, precio_especial) VALUES
  -- 14 de marzo
  (1, 4, 6500.00), (1, 5, 5800.00), (1, 11, 3800.00), (1, 16, 2500.00),
  (4, 4, 6500.00), (4, 6, 7200.00), (4, 18, 2000.00),
  -- 15 de marzo
  (2, 5, 5800.00), (2, 10, 7900.00), (2, 11, 3800.00), (2, 17, 2500.00),
  (5, 5, 5800.00), (5, 9, 4900.00), (5, 16, 2500.00),
  -- 16 de marzo (hoy)
  (3, 4, 6200.00), (3, 6, 7500.00), (3, 11, 3800.00), (3, 16, 2500.00),
  (6, 7, 4500.00), (6, 10, 7900.00), (6, 18, 2000.00);

-- -----------------------------------------------------------------------------
-- Reservas
-- -----------------------------------------------------------------------------
INSERT INTO reserva (local_id, cliente_id, empleado_id, fecha_reserva, num_personas, estado, descripcion) VALUES
  (1, 11, 2, '2026-03-20 19:00:00-06', 15, 'confirmada', 'Evento corporativo Grupo TechCR'),
  (1, 6, 2, '2026-03-18 13:00:00-06', 8, 'confirmada', 'Almuerzo familiar celebración cumpleaños'),
  (2, 12, 4, '2026-03-22 20:00:00-06', 25, 'confirmada', 'Cena empresarial Corporación Innovar'),
  (1, 3, 2, '2026-03-17 12:30:00-06', 4, 'confirmada', 'Almuerzo de negocios'),
  (3, 8, 6, '2026-03-21 18:30:00-06', 6, 'pendiente', 'Cena familiar'),
  (2, 14, 4, '2026-03-19 12:00:00-06', 10, 'confirmada', 'Almuerzo reunión trabajo'),
  (4, 15, 8, '2026-03-23 19:30:00-06', 5, 'pendiente', 'Cena amigos');

-- -----------------------------------------------------------------------------
-- Ventas
-- -----------------------------------------------------------------------------
INSERT INTO venta (local_id, empleado_id, cliente_id, reserva_id, tipo_servicio, fecha_hora, subtotal, descuento, impuesto, total, puntos_ganados, estado, observacion) VALUES
  (1, 2, 1, NULL, 'salon', '2026-03-14 12:30:00-06', 15000.00, 0, 1950.00, 16950.00, 170, 'pagada', NULL),
  (1, 2, 2, NULL, 'salon', '2026-03-14 13:15:00-06', 28500.00, 1000.00, 3575.00, 31075.00, 311, 'pagada', 'Descuento cliente frecuente'),
  (1, 16, 3, NULL, 'salon', '2026-03-14 19:45:00-06', 45200.00, 0, 5876.00, 51076.00, 511, 'pagada', NULL),
  (2, 4, NULL, NULL, 'para_llevar', '2026-03-14 14:20:00-06', 12800.00, 0, 1664.00, 14464.00, 0, 'pagada', 'Cliente sin registro'),
  (2, 17, 4, NULL, 'salon', '2026-03-14 20:30:00-06', 32400.00, 0, 4212.00, 36612.00, 366, 'pagada', NULL),
  (1, 2, 5, NULL, 'salon', '2026-03-15 12:00:00-06', 18900.00, 0, 2457.00, 21357.00, 214, 'pagada', NULL),
  (1, 16, 6, NULL, 'salon', '2026-03-15 13:45:00-06', 51200.00, 2000.00, 6396.00, 55596.00, 556, 'pagada', 'Canje 200 puntos'),
  (3, 6, 7, NULL, 'salon', '2026-03-15 12:30:00-06', 24600.00, 0, 3198.00, 27798.00, 278, 'pagada', NULL),
  (4, 8, 8, NULL, 'salon', '2026-03-15 19:00:00-06', 38700.00, 0, 5031.00, 43731.00, 437, 'pagada', NULL),
  (1, 2, 9, NULL, 'para_llevar', '2026-03-16 11:30:00-06', 15600.00, 0, 2028.00, 17628.00, 176, 'pagada', NULL),
  (2, 4, 10, NULL, 'salon', '2026-03-16 12:15:00-06', 29800.00, 0, 3874.00, 33674.00, 337, 'pagada', NULL),
  (1, 2, NULL, NULL, 'para_llevar', '2026-03-16 13:00:00-06', 22400.00, 0, 2912.00, 25312.00, 0, 'pagada', 'Sin registro cliente'),
  (3, 6, 13, NULL, 'salon', '2026-03-16 12:45:00-06', 19500.00, 0, 2535.00, 22035.00, 220, 'pagada', NULL),
  (1, 16, 14, NULL, 'salon', '2026-03-16 19:30:00-06', 42600.00, 0, 5538.00, 48138.00, 481, 'pagada', NULL),
  (2, 17, 15, NULL, 'salon', '2026-03-16 20:00:00-06', 35900.00, 0, 4667.00, 40567.00, 406, 'abierta', 'Mesa activa');

-- -----------------------------------------------------------------------------
-- Detalle de ventas
-- -----------------------------------------------------------------------------
INSERT INTO venta_detalle (venta_id, plato_id, receta_id, cantidad, precio_unitario, descuento_linea, nota) VALUES
  -- Venta 1
  (1, 4, 4, 2, 7500.00, 0, NULL),
  -- Venta 2
  (2, 5, 5, 3, 6800.00, 0, NULL), (2, 16, 16, 2, 3800.00, 0, NULL),
  -- Venta 3
  (3, 10, 10, 4, 8900.00, 0, NULL), (3, 21, 21, 4, 1500.00, 0, NULL),
  (3, 16, 16, 2, 3800.00, 0, NULL),
  -- Venta 4
  (4, 7, 7, 2, 5500.00, 0, NULL), (4, 19, 19, 2, 1800.00, 0, NULL),
  -- Venta 5
  (5, 4, 4, 3, 7500.00, 0, NULL), (5, 6, 6, 1, 8200.00, 0, NULL),
  (5, 18, 18, 2, 2800.00, 0, NULL),
  -- Venta 6
  (6, 5, 5, 2, 6800.00, 0, NULL), (6, 11, 11, 1, 4500.00, 0, NULL),
  (6, 21, 21, 1, 1500.00, 0, 'Sin azúcar'),
  -- Venta 7
  (7, 4, 4, 5, 7500.00, 0, NULL), (7, 10, 10, 2, 8900.00, 0, 'Término medio'),
  (7, 16, 16, 3, 3800.00, 0, NULL), (7, 19, 19, 4, 1800.00, 0, NULL),
  -- Venta 8
  (8, 4, 4, 3, 7500.00, 0, NULL), (8, 19, 19, 3, 1800.00, 0, NULL),
  -- Venta 9
  (9, 8, 8, 4, 6500.00, 0, NULL), (9, 22, 22, 2, 1800.00, 0, NULL),
  (9, 17, 17, 2, 3200.00, 0, NULL),
  -- Venta 10
  (10, 7, 7, 2, 5500.00, 0, NULL), (10, 2, 2, 1, 4200.00, 0, NULL),
  (10, 19, 19, 1, 1800.00, 0, NULL),
  -- Venta 11
  (11, 4, 4, 3, 7500.00, 0, NULL), (11, 16, 16, 2, 3800.00, 0, NULL),
  (11, 21, 21, 2, 1500.00, 0, NULL),
  -- Venta 12
  (12, 5, 5, 2, 6800.00, 0, NULL), (12, 6, 6, 1, 8200.00, 0, NULL),
  (12, 19, 19, 1, 1800.00, 0, NULL),
  -- Venta 13
  (13, 4, 4, 2, 7500.00, 0, NULL), (13, 11, 11, 1, 4500.00, 0, NULL),
  -- Venta 14
  (14, 10, 10, 3, 8900.00, 0, 'Término 3/4'), (14, 5, 5, 2, 6800.00, 0, NULL),
  (14, 16, 16, 2, 3800.00, 0, NULL),
  -- Venta 15 (abierta)
  (15, 4, 4, 4, 7500.00, 0, NULL), (15, 21, 21, 4, 1500.00, 0, NULL),
  (15, 16, 16, 2, 3800.00, 0, NULL);

-- -----------------------------------------------------------------------------
-- Pagos de ventas
-- -----------------------------------------------------------------------------
INSERT INTO venta_pago (venta_id, metodo_pago_id, monto, referencia) VALUES
  (1, 1, 16950.00, NULL),
  (2, 5, 31075.00, 'SINPE-20250314-001'),
  (3, 3, 51076.00, 'VISA-****1234'),
  (4, 1, 14464.00, NULL),
  (5, 4, 36612.00, 'DEBITO-****5678'),
  (6, 1, 21357.00, NULL),
  (7, 3, 55596.00, 'VISA-****9012'),
  (8, 1, 27798.00, NULL),
  (9, 5, 43731.00, 'SINPE-20250315-002'),
  (10, 1, 17628.00, NULL),
  (11, 4, 33674.00, 'DEBITO-****3456'),
  (12, 1, 15000.00, NULL), (12, 4, 10312.00, 'DEBITO-****7890'),
  (13, 1, 22035.00, NULL),
  (14, 3, 48138.00, 'MASTER-****4567');

-- -----------------------------------------------------------------------------
-- Facturas electrónicas
-- -----------------------------------------------------------------------------
INSERT INTO factura_electronica (venta_id, tipo_documento, tipo_receptor, identificacion, nombre_receptor, email_receptor, clave_hacienda, numero_consecutivo, estado_hacienda) VALUES
  (1, 'factura_electronica', 'persona_fisica', '108760543', 'Juan Pérez López', 
   'juan.perez@email.com', '50614032500010100001234567890123456789012345678901', '00100001000000000001', 'aceptado'),
  (2, 'factura_electronica', 'persona_fisica', '209871654', 'Sandra Murillo Sánchez',
   'sandra.murillo@email.com', '50614032500010100001234567890123456789012345678902', '00100001000000000002', 'aceptado'),
  (3, 'factura_electronica', 'persona_fisica', '310982765', 'Miguel Castro Villalobos',
   'miguel.castro@email.com', '50614032500010100001234567890123456789012345678903', '00100001000000000003', 'aceptado'),
  (4, 'tiquete_electronico', 'persona_fisica', '000000000', 'Cliente Contado',
   NULL, '50614032500010100001234567890123456789012345678904', '00100001000000000004', 'aceptado'),
  (5, 'factura_electronica', 'persona_fisica', '411093876', 'Rosa Vega Calderón',
   'rosa.vega@email.com', '50614032500010100001234567890123456789012345678905', '00100001000000000005', 'aceptado'),
  (6, 'factura_electronica', 'persona_fisica', '512104987', 'Pedro Solís Mata',
   'pedro.solis@email.com', '50614032500010100001234567890123456789012345678906', '00100001000000000006', 'aceptado'),
  (7, 'factura_electronica', 'persona_fisica', '613216098', 'Lucía Araya Chinchilla',
   'lucia.araya@email.com', '50614032500010100001234567890123456789012345678907', '00100001000000000007', 'aceptado'),
  (8, 'factura_electronica', 'persona_fisica', '714327109', 'Rodrigo Brenes Fallas',
   'rodrigo.brenes@email.com', '50614032500010100001234567890123456789012345678908', '00100001000000000008', 'aceptado'),
  (9, 'factura_electronica', 'persona_fisica', '115438210', 'Silvia Monge Umaña',
   'silvia.monge@email.com', '50614032500010100001234567890123456789012345678909', '00100001000000000009', 'aceptado'),
  (10, 'factura_electronica', 'persona_fisica', '116549321', 'Tomás Guzmán Paniagua',
   'tomas.guzman@email.com', '50614032500010100001234567890123456789012345678910', '00100001000000000010', 'aceptado'),
  (11, 'factura_electronica', 'persona_fisica', '117650432', 'Andrea Salazar Marín',
   'andrea.salazar@email.com', '50614032500010100001234567890123456789012345678911', '00100001000000000011', 'aceptado'),
  (12, 'tiquete_electronico', 'persona_fisica', '000000000', 'Cliente Contado',
   NULL, '50614032500010100001234567890123456789012345678912', '00100001000000000012', 'aceptado'),
  (13, 'factura_electronica', 'persona_fisica', '118761543', 'Esteban Navarro Cordero',
   'esteban.navarro@email.com', '50614032500010100001234567890123456789012345678913', '00100001000000000013', 'aceptado'),
  (14, 'factura_electronica', 'persona_fisica', '119872654', 'Daniela Esquivel Salas',
   'daniela.esquivel@email.com', '50614032500010100001234567890123456789012345678914', '00100001000000000014', 'aceptado');