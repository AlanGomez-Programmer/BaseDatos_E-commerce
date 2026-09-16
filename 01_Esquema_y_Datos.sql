DROP DATABASE IF EXISTS E_commerce;
CREATE DATABASE E_commerce;
USE E_commerce;

-- DDL

CREATE TABLE Paises(
    id_pais INT AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    PRIMARY KEY (id_pais)
);

CREATE TABLE Regiones(
    id_region INT AUTO_INCREMENT,
    pais_id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_region),
    FOREIGN KEY (pais_id) REFERENCES Paises(id_pais),
    UNIQUE KEY uq_region_pais (pais_id, nombre)
);

CREATE TABLE Ciudades(
    id_ciudad INT AUTO_INCREMENT,
    region_id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_ciudad),
    FOREIGN KEY (region_id) REFERENCES Regiones(id_region),
    UNIQUE KEY uq_ciudad_region (region_id, nombre)
);

CREATE TABLE Categorias(
    id_categoria INT AUTO_INCREMENT,
    nombre VARCHAR(75) UNIQUE NOT NULL,
    descripcion VARCHAR(200),
    PRIMARY KEY (id_categoria)
);

CREATE TABLE Proveedores(
    id_proveedor INT AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    email_contacto VARCHAR(320) UNIQUE NOT NULL,
    telefono_contacto VARCHAR(15) NOT NULL,
    PRIMARY KEY (id_proveedor)
);

CREATE TABLE Productos(
    id_producto INT AUTO_INCREMENT,
    categoria_id INT NOT NULL,
    proveedor_id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(200),
    precio DECIMAL(10, 2) NOT NULL CHECK(precio > 0),
    costo DECIMAL(10, 2) NOT NULL CHECK(costo >= 0),
    stock INT NOT NULL CHECK(stock >= 0) DEFAULT 0,
    sku VARCHAR(12) NOT NULL UNIQUE,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (id_producto),
    FOREIGN KEY (categoria_id) REFERENCES Categorias(id_categoria),
    FOREIGN KEY (proveedor_id) REFERENCES Proveedores(id_proveedor)
);

CREATE TABLE Clientes(
    id_cliente INT AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(320) UNIQUE NOT NULL,
    contrasenia VARCHAR(255) NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cliente)
);

CREATE TABLE Direcciones_Envio(
    id_direccion INT AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    ciudad_id INT NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    es_principal TINYINT NOT NULL DEFAULT 1,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_direccion),
    FOREIGN KEY (cliente_id) REFERENCES Clientes(id_cliente),
    FOREIGN KEY (ciudad_id) REFERENCES Ciudades(id_ciudad)
);

CREATE TABLE Estados(
    id_estado INT AUTO_INCREMENT,
    nombre_estado VARCHAR(25) NOT NULL,
    PRIMARY KEY (id_estado)
);

CREATE TABLE Promociones(
    id_promocion INT AUTO_INCREMENT,
    producto_id INT NOT NULL,
    nombre_promocion VARCHAR(100) NOT NULL,
    descuento_pct DECIMAL(5,2) NOT NULL CHECK (descuento_pct > 0 AND descuento_pct <= 100),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    PRIMARY KEY (id_promocion),
    FOREIGN KEY (producto_id) REFERENCES Productos(id_producto),
    CHECK (fecha_fin > fecha_inicio)
);

CREATE TABLE Ventas(
    id_venta INT AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    direccion_id INT NULL,
    fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado_id INT NOT NULL DEFAULT 1,
    total DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id_venta),
    FOREIGN KEY (cliente_id) REFERENCES Clientes(id_cliente),
    FOREIGN KEY (direccion_id) REFERENCES Direcciones_Envio(id_direccion),
    FOREIGN KEY (estado_id) REFERENCES Estados(id_estado)
);

CREATE TABLE Detalles_ventas(
    id_detalle INT AUTO_INCREMENT,
    venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT CHECK (cantidad > 0) NOT NULL,
    precio_unitario_congelado DECIMAL(10, 2) NOT NULL CHECK(precio_unitario_congelado >= 0),
    PRIMARY KEY (id_detalle),
    FOREIGN KEY (venta_id) REFERENCES Ventas(id_venta),
    FOREIGN KEY (producto_id) REFERENCES Productos(id_producto)
);

-- DML

-- Geografia
INSERT INTO Paises (nombre) VALUES ('Guatemala'), ('Colombia');

INSERT INTO Regiones (pais_id, nombre) VALUES
(1, 'Guatemala'),
(1, 'Sacatepéquez'),
(1, 'Quetzaltenango'),
(1, 'Escuintla'),
(1, 'Alta Verapaz'),
(2, 'Cundinamarca'),
(2, 'Antioquia'),
(2, 'Valle del Cauca');

INSERT INTO Ciudades (region_id, nombre) VALUES
(1, 'Ciudad de Guatemala'),  -- id_ciudad 1
(1, 'Mixco'),                -- id_ciudad 2
(1, 'Villa Nueva'),          -- id_ciudad 3
(2, 'Antigua Guatemala'),    -- id_ciudad 4
(3, 'Quetzaltenango'),       -- id_ciudad 5
(4, 'Escuintla'),            -- id_ciudad 6
(5, 'Cobán'),                -- id_ciudad 7
(6, 'Bogotá'),               -- id_ciudad 8
(7, 'Medellín'),             -- id_ciudad 9
(8, 'Cali');                 -- id_ciudad 10

-- Catalogo
INSERT INTO Categorias (nombre, descripcion) VALUES
('Electrónica', 'Dispositivos y gadgets tecnológicos'),
('Ropa', 'Prenda de vestir para hombres y mujeres'),
('Calzado', 'Zapatos, tenis y sandalias'),
('Hogar', 'Artículos para decoración y cocina'),
('Deportes', 'Equipamiento e indumentaria deportiva'),
('Cuidado Personal', 'Productos de belleza y aseo'),
('Juguetería', 'Juegos y juguetes para todas las edades'),
('Libros', 'Libros físicos y material de lectura'),
('Herramientas', 'Equipos e instrumentos para reparación'),
('Automotriz', 'Accesorios y repuestos para vehículos');

INSERT INTO Proveedores (nombre, email_contacto, telefono_contacto) VALUES
('TechSupply Co.', 'contacto@techsupply.com', '5551001'),
('Moda Global S.A.', 'ventas@modaglobal.com', '5551002'),
('Distribuidora del Sur', 'info@delsur.com', '5551003'),
('Importadora Central', 'ventas@icentral.com', '5551004'),
('Deportes Total', 'contacto@deportestotal.com', '5551005'),
('Belleza y Salud Corp', 'info@bellezasalud.com', '5551006'),
('Hogar Moderno', 'ventas@hogarmoderno.com', '5551007'),
('Librería Nacional', 'contacto@librerianacional.com', '5551008'),
('Ferretería Industrial', 'ventas@ferreindustrial.com', '5551009'),
('AutoPartes Express', 'info@autopartesexp.com', '5551010');

INSERT INTO Productos (categoria_id, proveedor_id, nombre, descripcion, precio, costo, stock, sku) VALUES
(1, 1, 'Laptop Gaming X15', 'Laptop de alto rendimiento 16GB RAM', 1200.00, 850.00, 15, 'LAP-GAM-001'),
(1, 1, 'Mouse Inalámbrico Pro', 'Mouse ergonómico óptico', 25.00, 12.00, 50, 'MOU-INA-002'),
(1, 1, 'Teclado Mecánico RGB', 'Teclado retroiluminado switch azul', 75.00, 40.00, 30, 'TEC-MEC-003'),
(1, 1, 'Monitor 27 Pulgadas', 'Monitor IPS 144Hz 1080p', 220.00, 150.00, 20, 'MON-27P-004'),
(2, 2, 'Camiseta Algodón Negra', 'Camiseta básica 100% algodón', 15.00, 6.00, 100, 'CAM-ALG-005'),
(2, 2, 'Pantalón Jean Clásico', 'Corte recto color azul', 45.00, 22.00, 60, 'PAN-JEA-006'),
(2, 2, 'Chaqueta Impermeable', 'Chaqueta con capucha para lluvia', 80.00, 45.00, 25, 'CHA-IMP-007'),
(3, 3, 'Tenis Deportivos Running', 'Calzado ligero para correr', 90.00, 50.00, 40, 'TEN-DEP-008'),
(3, 3, 'Zapato Casual de Cuero', 'Zapato elegante de vestir', 110.00, 65.00, 18, 'ZAP-CAS-009'),
(4, 4, 'Juego de Sartenes 3Pcs', 'Sartenes antiadherentes de aluminio', 50.00, 28.00, 35, 'JUE-SAR-010'),
(4, 4, 'Cafetera de Goteo', 'Capacidad 12 tazas programable', 40.00, 22.00, 22, 'CAF-GOT-011'),
(4, 4, 'Lámpara de Escritorio LED', 'Luz regulable con puerto USB', 30.00, 14.00, 45, 'LAM-ESC-012'),
(5, 5, 'Balón de Fútbol Profesional', 'Tamaño 5 termo-sellado', 35.00, 18.00, 50, 'BAL-FUT-013'),
(5, 5, 'Mancuernas 10kg Par', 'Mancuernas de hierro recubiertas', 60.00, 35.00, 15, 'MAN-10K-014'),
(5, 5, 'Tapete para Yoga', 'Antideslizante de 6mm', 20.00, 9.00, 80, 'TAP-YOG-015'),
(6, 6, 'Set de Cremas Faciales', 'Hidratante día y noche', 45.00, 20.00, 30, 'SET-CRE-016'),
(6, 6, 'Shampoo Orgánico 500ml', 'Sin sulfatos ni parabenos', 18.00, 8.00, 65, 'SHA-ORG-017'),
(7, 7, 'Set de Bloques de Construcción', 'Juego educativo 500 piezas', 35.00, 16.00, 40, 'SET-BLO-018'),
(7, 7, 'Carro a Control Remoto', 'Batería recargable 4x4', 55.00, 28.00, 25, 'CAR-CON-019'),
(8, 8, 'Novela Ficción Bestseller', 'Edición tapa dura', 22.00, 10.00, 50, 'NOV-FIC-020'),
(8, 8, 'Aprende SQL en 30 Días', 'Guía práctica para principiantes', 30.00, 12.00, 40, 'APR-SQL-021'),
(9, 9, 'Taladro Percutor 750W', 'Incluye maletín y accesorios', 95.00, 55.00, 20, 'TAL-PER-022'),
(9, 9, 'Juego de Destornilladores', 'Set de 12 piezas magnéticas', 25.00, 11.00, 55, 'JUE-DES-023'),
(10, 10, 'Aceite Sintético para Motor', 'Galón 5W-30', 40.00, 22.00, 70, 'ACE-SIN-024'),
(10, 10, 'Kit de Limpieza para Auto', 'Champú, cera y microfibras', 30.00, 14.00, 45, 'KIT-LIM-025'),
(1, 1, 'Auriculares Bluetooth', 'Cancelación de ruido activa', 130.00, 75.00, 35, 'AUR-BLU-026'),
(2, 2, 'Sudadera con Capucha', 'Talla L color gris', 40.00, 18.00, 50, 'SUD-CAP-027'),
(3, 3, 'Sandalias de Playa', 'Talla variada antideslizantes', 12.00, 4.00, 90, 'SAN-PLA-028'),
(4, 4, 'Licuadora de Alta Potencia', 'Vaso de vidrio 1.5L', 70.00, 40.00, 18, 'LIC-ALT-029'),
(5, 5, 'Cuerda para Saltar', 'Rápida con rodamientos', 10.00, 3.50, 110, 'CUE-SAL-030');

-- Clientes
INSERT INTO Clientes (nombre, apellido, email, contrasenia, fecha_registro) VALUES
('Carlos', 'Mendoza', 'carlos.mendoza@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a1', '2019-03-14'),
('Ana', 'García', 'ana.garcia@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a2', '2019-07-22'),
('Luis', 'Martínez', 'luis.martinez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a3', '2019-11-05'),
('María', 'Rodríguez', 'maria.rodriguez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a4', '2020-01-18'),
('Juan', 'López', 'juan.lopez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a5', '2020-04-09'),
('Sofía', 'Hernández', 'sofia.hernandez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a6', '2020-06-30'),
('Pedro', 'Gómez', 'pedro.gomez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a7', '2020-09-12'),
('Lucía', 'Pérez', 'lucia.perez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a8', '2020-12-01'),
('Diego', 'Sánchez', 'diego.sanchez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a9', '2021-02-15'),
('Elena', 'Ramírez', 'elena.ramirez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b1', '2021-05-20'),
('Javier', 'Torres', 'javier.torres@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b2', '2021-08-08'),
('Laura', 'Flores', 'laura.flores@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b3', '2021-10-25'),
('Fernando', 'Díaz', 'fernando.diaz@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b4', '2022-01-10'),
('Gabriela', 'Vásquez', 'gabriela.vasquez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b5', '2022-03-19'),
('Ricardo', 'Castro', 'ricardo.castro@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b6', '2022-06-02'),
('Patricia', 'Morales', 'patricia.morales@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b7', '2022-08-14'),
('Hugo', 'Álvarez', 'hugo.alvarez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b8', '2022-11-07'),
('Natalia', 'Romero', 'natalia.romero@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b9', '2023-01-22'),
('Oscar', 'Ruiz', 'oscar.ruiz@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c1', '2023-04-05'),
('Andrea', 'Suárez', 'andrea.suarez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c2', '2023-06-18'),
('Manuel', 'Reyes', 'manuel.reyes@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c3', '2023-09-01'),
('Claudia', 'Jiménez', 'claudia.jimenez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c4', '2023-11-20'),
('Roberto', 'Molina', 'roberto.molina@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c5', '2024-01-15'),
('Vanessa', 'Delgado', 'vanessa.delgado@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c6', '2024-03-10'),
('Gabriel', 'Ortiz', 'gabriel.ortiz@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c7', '2024-05-05'),
('Daniela', 'Marroquín', 'daniela.marroquin@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c8', '2024-07-22'),
('Alejandro', 'Mejía', 'alejandro.mejia@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c9', '2024-09-14'),
('Sofia', 'Echeverría', 'sofia.echeverria@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d1', '2024-11-02'),
('Esteban', 'Castillo', 'esteban.castillo@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d2', '2025-01-05'),
('Monika', 'Estrada', 'monika.estrada@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d3', '2025-03-10'),
('Mateo', 'Salazar', 'mateo.salazar@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d4', '2026-01-08'),
('Valentina', 'Cruz', 'valentina.cruz@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d5', '2026-01-22'),
('Emilio', 'Paredes', 'emilio.paredes@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d6', '2026-02-08'),
('Camila', 'Rivas', 'camila.rivas@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d7', '2026-02-22'),
('Nicolás', 'Aguilar', 'nicolas.aguilar@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d8', '2026-03-08'),
('Isabella', 'Cordón', 'isabella.cordon@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d9', '2026-03-22'),
('Sebastián', 'Duarte', 'sebastian.duarte@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8e1', '2026-04-08'),
('Renata', 'Villagrán', 'renata.villagran@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8e2', '2026-04-22'),
('Adrián', 'Contreras', 'adrian.contreras@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8e3', '2026-05-08'),
('Ximena', 'Barrios', 'ximena.barrios@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8e4', '2026-05-22'),
('Tomás', 'Escobar', 'tomas.escobar@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8e5', '2026-06-08'),
('Paola', 'Guzmán', 'paola.guzman@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8e6', '2026-06-22'),
('Ismael', 'Cabrera', 'ismael.cabrera@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8e7', '2026-07-08'),
('Fabiola', 'Recinos', 'fabiola.recinos@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8e8', '2026-07-22'),
('Rodrigo', 'Peña', 'rodrigo.pena@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8e9', '2026-08-08'),
('Alejandra', 'Lemus', 'alejandra.lemus@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8f1', '2026-08-22'),
('Emmanuel', 'Cifuentes', 'emmanuel.cifuentes@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8f2', '2026-09-08'),
('Michelle', 'Orellana', 'michelle.orellana@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8f3', '2026-09-14'),
('Cristian', 'Bautista', 'cristian.bautista@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8f4', '2026-10-08'),
('Melissa', 'Zúñiga', 'melissa.zuniga@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8f5', '2026-10-22'),
('Kevin', 'Maldonado', 'kevin.maldonado@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8f6', '2026-11-08'),
('Wendy', 'Villatoro', 'wendy.villatoro@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8f7', '2026-11-22'),
('Jorge', 'Solórzano', 'jorge.solorzano@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8f8', '2026-12-08'),
('Karen', 'Ixchop', 'karen.ixchop@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8f9', '2026-12-22');

-- Direcciones de envio 
INSERT INTO Direcciones_Envio (cliente_id, ciudad_id, direccion) VALUES
(1, 1, 'Calle 12 #4-56, Zona 1'),
(2, 1, 'Avenida Reforma 8-90, Zona 10'),
(3, 1, 'Diagonal 6 12-42, Zona 10'),
(4, 1, 'Calle Los Olivos #15, Zona 15'),
(5, 1, 'Bulevar Principal 4-11, Zona 14'),
(6, 1, 'Calzada Roosevelt 22-00, Zona 11'),
(7, 1, 'Avenida Las Américas 10-20, Zona 13'),
(8, 1, 'Calle Real 5-33, Zona 2'),
(9, 2, 'Bulevar San Cristóbal 14-02'),
(10, 1, 'Calle del Sol 8-88, Zona 9'),
(11, 1, 'Avenida La Castellana 3-12, Zona 8'),
(12, 1, 'Calle 5 10-01, Zona 7'),
(13, 1, 'Avenida Bolívar 18-50, Zona 1'),
(14, 1, 'Calle Mariscal 9-40, Zona 11'),
(15, 1, 'Bulevar Vista Hermosa 2-15, Zona 15'),
(16, 1, 'Avenida Hincapié 11-05, Zona 13'),
(17, 1, 'Callejón del Carmen #4, Zona 1'),
(18, 1, 'Avenida Simeón Cañas 6-12, Zona 2'),
(19, 1, 'Calzada Atanasio Tzul 44-10, Zona 12'),
(20, 1, 'Calle Los Pinos 7-21, Zona 16'),
(21, 1, 'Avenida Petapa 31-00, Zona 12'),
(22, 1, 'Bulevar Austriaco 1-01, Zona 16'),
(23, 3, 'Calle 14 3-55'),
(24, 5, 'Avenida Elena 12-30'),
(25, 6, 'Calle Martí 15-80'),
(26, 7, 'Calzada Aguilar Batres 29-00'),
(27, 4, 'Avenida La Floresta 8-10'),
(28, 8, 'Carrera 15 #93-47'),
(29, 9, 'Calle 10 #43-12'),
(30, 10, 'Avenida 6N #23-45'),
-- Direcciones de los clientes registrados en 2026
(31, 1, 'Avenida Reforma 22-10, Zona 9'),
(32, 1, 'Calle Martí 5-40, Zona 3'),
(33, 2, 'Colonia El Milagro 3-21'),
(34, 1, 'Boulevard Los Próceres 18-30, Zona 10'),
(35, 5, 'Avenida Las Américas 4-15'),
(36, 1, 'Calle 18 #6-77, Zona 4'),
(37, 3, 'Colonia Villalobos 2-08'),
(38, 1, 'Avenida Elena 9-50, Zona 12'),
(39, 4, 'Calle del Arco 5-12'),
(40, 1, 'Calzada San Juan 14-60, Zona 7'),
(41, 6, 'Avenida Centroamérica 8-20'),
(42, 1, 'Calle Montúfar 3-19, Zona 9'),
(43, 1, 'Avenida Simón Bolívar 7-88, Zona 8'),
(44, 7, 'Calle Real 2-33'),
(45, 1, 'Bulevar Liberación 6-40, Zona 13'),
(46, 1, 'Calle Rodolfo Robles 15-22, Zona 10'),
(47, 8, 'Carrera 7 #22-14'),
(48, 1, 'Avenida las Rosas 9-15, Zona 11'),
(49, 9, 'Calle 33 #45-67'),
(50, 1, 'Calle Toledo 8-24, Zona 12'),
(51, 10, 'Avenida 4N #12-30'),
(52, 1, 'Bulevar Rafael Landívar 2-11, Zona 16'),
(53, 2, 'Colonia Lo de Bran 4-50'),
(54, 1, 'Calle Los Álamos 3-70, Zona 15');

-- Estados de pedido
INSERT INTO Estados (nombre_estado) VALUES
('Pendiente de Pago'),
('Procesando'),
('Enviado'),
('Entregado'),
('Cancelado');

-- Promociones
INSERT INTO Promociones (producto_id, nombre_promocion, descuento_pct, fecha_inicio, fecha_fin) VALUES
(1, 'Mayo Tech Sale - Laptops',   10.00, '2026-05-01', '2026-05-31'),
(4, 'Marzo Monitores al 20%',     20.00, '2026-03-01', '2026-03-15');

-- Ventas
INSERT INTO Ventas (cliente_id, direccion_id, fecha_venta, estado_id, total) VALUES
-- 2026 
(1, 1, '2026-01-15 10:30:00', 4, 1225.00),
(2, 2, '2026-01-18 14:20:00', 4, 60.00),
(3, 3, '2026-02-02 09:15:00', 3, 220.00),
(4, 4, '2026-02-10 16:45:00', 2, 90.00),
(5, 5, '2026-02-14 11:00:00', 1, 150.00),
(6, 6, '2026-03-01 08:30:00', 4, 50.00),
(7, 7, '2026-03-05 17:10:00', 5, 80.00),
(8, 8, '2026-03-12 12:00:00', 4, 45.00),
(9, 9, '2026-03-20 15:25:00', 3, 110.00),
(10, 10, '2026-04-02 10:05:00', 2, 70.00),
(11, 11, '2026-04-11 13:40:00', 4, 35.00),
(12, 12, '2026-04-18 18:15:00', 1, 60.00),
(13, 13, '2026-05-03 09:50:00', 4, 18.00),
(14, 14, '2026-05-09 11:30:00', 3, 90.00),
(15, 15, '2026-05-15 16:00:00', 4, 22.00),
(16, 16, '2026-05-22 14:10:00', 2, 120.00),
(17, 17, '2026-06-01 10:00:00', 5, 25.00),
(18, 18, '2026-06-08 15:45:00', 4, 40.00),
(19, 19, '2026-06-14 12:20:00', 3, 130.00),
(20, 20, '2026-06-25 17:35:00', 1, 40.00),
(21, 21, '2026-07-02 08:50:00', 4, 12.00),
(22, 22, '2026-07-10 11:15:00', 4, 70.00),
(23, 23, '2026-07-19 16:40:00', 2, 10.00),
(24, 24, '2026-08-01 13:00:00', 4, 225.00),
(25, 25, '2026-08-08 10:25:00', 3, 95.00),
(26, 26, '2026-08-14 14:50:00', 4, 30.00),
(27, 27, '2026-08-22 09:10:00', 5, 1200.00),
(28, 28, '2026-08-29 18:00:00', 4, 45.00),
(29, 29, '2026-09-02 11:40:00', 2, 105.00),
(30, 30, '2026-09-10 15:00:00', 1, 15.00),

-- 2025
(1, 1, '2025-01-10 09:00:00', 4, 90.00),
(3, 3, '2025-02-14 14:30:00', 4, 110.00),
(5, 5, '2025-03-01 11:15:00', 4, 35.00),
(2, 2, '2025-03-20 16:40:00', 4, 15.00),
(8, 8, '2025-04-05 10:20:00', 4, 220.00),
(10, 10, '2025-04-18 13:10:00', 5, 1200.00),
(12, 12, '2025-05-10 15:50:00', 4, 75.00),
(14, 14, '2025-05-25 12:00:00', 4, 40.00),
(15, 15, '2025-06-12 08:45:00', 4, 50.00),
(17, 17, '2025-06-30 17:30:00', 4, 95.00),
(19, 19, '2025-07-11 11:00:00', 4, 25.00),
(20, 20, '2025-07-28 14:15:00', 4, 130.00),
(22, 22, '2025-08-04 09:30:00', 4, 45.00),
(24, 24, '2025-08-19 16:10:00', 4, 60.00),
(25, 25, '2025-09-02 10:00:00', 4, 30.00),
(27, 27, '2025-10-15 13:45:00', 4, 150.00),
(28, 28, '2025-11-20 18:20:00', 4, 80.00),
(29, 29, '2025-11-28 11:05:00', 4, 225.00),
(30, 30, '2025-12-10 15:40:00', 4, 70.00),
(6, 6, '2025-12-24 10:00:00', 4, 18.00),

-- pares comprados juntos frecuentemente 
(2, 2, '2026-01-20 10:00:00', 4, 100.00),
(5, 5, '2026-02-05 11:30:00', 4, 100.00),
(9, 9, '2026-03-15 09:45:00', 3, 100.00),
(14, 14, '2026-04-10 16:20:00', 4, 100.00),
(6, 6, '2026-02-18 12:00:00', 4, 110.00),
(11, 11, '2026-05-02 15:10:00', 4, 110.00),
(19, 19, '2026-06-20 10:40:00', 2, 110.00),
(3, 3, '2026-01-25 09:20:00', 4, 52.00),
(8, 8, '2026-03-08 14:00:00', 4, 52.00),
(16, 16, '2026-07-14 11:15:00', 4, 52.00),

-- alrededor de las promociones (id_venta 61-68)
(7, 7, '2026-04-20 10:00:00', 4, 1200.00),   -- antes promo laptop
(4, 4, '2026-05-10 11:00:00', 4, 1080.00),   -- durante promo laptop
(12, 12, '2026-05-20 09:30:00', 3, 1080.00), -- durante promo laptop
(21, 21, '2026-06-05 13:00:00', 4, 1200.00), -- despues promo laptop
(10, 10, '2026-03-05 10:15:00', 4, 176.00),  -- durante promo monitor
(17, 17, '2026-03-12 16:00:00', 3, 176.00),  -- durante promo monitor
(23, 23, '2026-04-08 09:00:00', 4, 220.00),  -- despues promo monitor
(28, 28, '2026-04-22 14:30:00', 2, 220.00),  -- despues promo monitor

-- Nuevas: ventas generales (id_venta 69-100)
(1, 1, '2025-01-05 09:00:00', 4, 45.00),
(27, 27, '2025-02-10 10:30:00', 4, 50.00),
(2, 2, '2025-03-15 11:00:00', 4, 30.00),
(28, 28, '2025-04-01 09:45:00', 4, 55.00),
(3, 3, '2025-05-05 12:00:00', 4, 80.00),
(29, 29, '2025-06-10 13:15:00', 4, 110.00),
(4, 4, '2025-07-15 08:50:00', 4, 40.00),
(30, 30, '2025-08-20 10:00:00', 4, 45.00),
(5, 5, '2025-09-05 11:20:00', 4, 30.00),
(6, 6, '2025-10-10 14:00:00', 4, 70.00),
(7, 7, '2025-11-15 09:30:00', 4, 80.00),
(8, 8, '2025-12-05 15:00:00', 4, 40.00),
(27, 27, '2026-01-08 10:00:00', 3, 130.00),
(9, 9, '2026-01-22 11:45:00', 2, 35.00),
(28, 28, '2026-02-14 09:15:00', 4, 95.00),
(10, 10, '2026-02-28 13:00:00', 4, 30.00),
(29, 29, '2026-03-20 10:30:00', 3, 60.00),
(11, 11, '2026-04-05 12:15:00', 4, 30.00),
(30, 30, '2026-04-25 14:45:00', 4, 75.00),
(12, 12, '2026-05-14 09:00:00', 2, 22.00),
(13, 13, '2026-05-28 11:30:00', 4, 40.00),
(14, 14, '2026-06-12 10:00:00', 4, 45.00),
(15, 15, '2026-06-25 15:20:00', 3, 70.00),
(16, 16, '2026-07-05 09:40:00', 4, 110.00),
(17, 17, '2026-07-20 13:10:00', 4, 90.00),
(18, 18, '2026-08-02 10:50:00', 1, 30.00),
(19, 19, '2026-08-15 12:00:00', 4, 25.00),
(20, 20, '2026-08-28 14:20:00', 4, 40.00),
(22, 22, '2026-09-01 09:00:00', 2, 50.00),
(24, 24, '2026-09-05 10:15:00', 1, 36.00),
(25, 25, '2026-09-08 11:40:00', 2, 35.00),
(26, 26, '2026-09-12 15:00:00', 1, 1200.00),


(31, 31, '2026-01-20 10:15:00', 4, 25.00),
(32, 32, '2026-02-03 11:00:00', 3, 36.00),
(33, 33, '2026-02-20 09:30:00', 4, 110.00),
(34, 34, '2026-03-06 14:00:00', 2, 45.00),
(35, 35, '2026-03-20 10:45:00', 4, 50.00),
(36, 36, '2026-04-03 16:20:00', 4, 22.00),
(37, 37, '2026-04-20 09:00:00', 1, 40.00),
(38, 38, '2026-05-05 12:30:00', 4, 75.00),
(39, 39, '2026-05-20 11:10:00', 3, 35.00),
(40, 40, '2026-06-03 15:00:00', 4, 80.00),
(41, 41, '2026-06-18 10:20:00', 4, 30.00),
(42, 42, '2026-07-02 13:45:00', 2, 55.00),
(43, 43, '2026-07-19 09:15:00', 4, 90.00),
(44, 44, '2026-08-02 14:50:00', 4, 24.00),
(45, 45, '2026-08-18 11:30:00', 5, 95.00),
(46, 46, '2026-09-01 10:00:00', 4, 45.00),
(47, 47, '2026-09-14 09:40:00', 3, 30.00),
(48, 48, '2026-09-16 12:00:00', 2, 40.00),
(49, 49, '2026-10-15 10:30:00', 4, 1200.00),
(50, 50, '2026-10-29 16:00:00', 4, 130.00),
(51, 51, '2026-11-15 11:20:00', 4, 220.00),
(52, 52, '2026-11-29 09:50:00', 1, 40.00),
(53, 53, '2026-12-15 14:10:00', 4, 25.00),
(54, 54, '2026-12-29 10:00:00', 3, 60.00);

-- Detalles de venta 
INSERT INTO Detalles_ventas (venta_id, producto_id, cantidad, precio_unitario_congelado) VALUES
-- Ventas 2026 originales (1-30)
(1, 1, 1, 1200.00), (1, 2, 1, 25.00),
(2, 5, 4, 15.00),
(3, 4, 1, 220.00),
(4, 8, 1, 90.00),
(5, 10, 3, 50.00),
(6, 10, 1, 50.00),
(7, 7, 1, 80.00),
(8, 6, 1, 45.00),
(9, 9, 1, 110.00),
(10, 29, 1, 70.00),
(11, 13, 1, 35.00),
(12, 14, 1, 60.00),
(13, 17, 1, 18.00),
(14, 8, 1, 90.00),
(15, 20, 1, 22.00),
(16, 14, 2, 60.00),
(17, 23, 1, 25.00),
(18, 11, 1, 40.00),
(19, 26, 1, 130.00),
(20, 24, 1, 40.00),
(21, 28, 1, 12.00),
(22, 29, 1, 70.00),
(23, 30, 1, 10.00),
(24, 3, 3, 75.00),
(25, 22, 1, 95.00),
(26, 21, 1, 30.00),
(27, 1, 1, 1200.00),
(28, 16, 1, 45.00),
(29, 18, 3, 35.00),
(30, 5, 1, 15.00),

-- Ventas 2025 originales (31-50)
(31, 8, 1, 90.00),
(32, 9, 1, 110.00),
(33, 13, 1, 35.00),
(34, 5, 1, 15.00),
(35, 4, 1, 220.00),
(36, 1, 1, 1200.00),
(37, 3, 1, 75.00),
(38, 11, 1, 40.00),
(39, 10, 1, 50.00),
(40, 22, 1, 95.00),
(41, 2, 1, 25.00),
(42, 26, 1, 130.00),
(43, 16, 1, 45.00),
(44, 14, 1, 60.00),
(45, 21, 1, 30.00),
(46, 10, 3, 50.00),
(47, 7, 1, 80.00),
(48, 3, 3, 75.00),
(49, 29, 1, 70.00),
(50, 17, 1, 18.00),

-- Pares comprados juntos frecuentemente 
(51, 2, 1, 25.00), (51, 3, 1, 75.00),
(52, 2, 1, 25.00), (52, 3, 1, 75.00),
(53, 2, 1, 25.00), (53, 3, 1, 75.00),
(54, 2, 1, 25.00), (54, 3, 1, 75.00),
(55, 8, 1, 90.00), (55, 15, 1, 20.00),
(56, 8, 1, 90.00), (56, 15, 1, 20.00),
(57, 8, 1, 90.00), (57, 15, 1, 20.00),
(58, 20, 1, 22.00), (58, 21, 1, 30.00),
(59, 20, 1, 22.00), (59, 21, 1, 30.00),
(60, 20, 1, 22.00), (60, 21, 1, 30.00),

-- Alrededor de las promociones 
(61, 1, 1, 1200.00),
(62, 1, 1, 1080.00),
(63, 1, 1, 1080.00),
(64, 1, 1, 1200.00),
(65, 4, 1, 176.00),
(66, 4, 1, 176.00),
(67, 4, 1, 220.00),
(68, 4, 1, 220.00),

-- Ventas generales 
(69, 6, 1, 45.00),
(70, 2, 2, 25.00),
(71, 12, 1, 30.00),
(72, 19, 1, 55.00),
(73, 24, 2, 40.00),
(74, 9, 1, 110.00),
(75, 27, 1, 40.00),
(76, 16, 1, 45.00),
(77, 25, 1, 30.00),
(78, 13, 2, 35.00),
(79, 7, 1, 80.00),
(80, 11, 1, 40.00),
(81, 26, 1, 130.00),
(82, 18, 1, 35.00),
(83, 22, 1, 95.00),
(84, 30, 3, 10.00),
(85, 14, 1, 60.00),
(86, 5, 2, 15.00),
(87, 3, 1, 75.00),
(88, 20, 1, 22.00),
(89, 15, 2, 20.00),
(90, 6, 1, 45.00),
(91, 29, 1, 70.00),
(92, 9, 1, 110.00),
(93, 8, 1, 90.00),
(94, 21, 1, 30.00),
(95, 2, 1, 25.00),
(96, 27, 1, 40.00),
(97, 10, 1, 50.00),
(98, 17, 2, 18.00),
(99, 13, 1, 35.00),
(100, 1, 1, 1200.00),

(101, 2, 1, 25.00),
(102, 17, 2, 18.00),
(103, 9, 1, 110.00),
(104, 6, 1, 45.00),
(105, 12, 1, 30.00), (105, 15, 1, 20.00),
(106, 20, 1, 22.00),
(107, 24, 1, 40.00),
(108, 3, 1, 75.00),
(109, 13, 1, 35.00),
(110, 7, 1, 80.00),
(111, 25, 1, 30.00),
(112, 19, 1, 55.00),
(113, 8, 1, 90.00),
(114, 28, 2, 12.00),
(115, 22, 1, 95.00),
(116, 16, 1, 45.00),
(117, 5, 2, 15.00),
(118, 27, 1, 40.00),
(119, 1, 1, 1200.00),
(120, 26, 1, 130.00),
(121, 4, 1, 220.00),
(122, 11, 1, 40.00),
(123, 23, 1, 25.00),
(124, 14, 1, 60.00);