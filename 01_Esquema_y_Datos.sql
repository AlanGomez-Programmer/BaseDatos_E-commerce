-- DDL
-- Estructura para la creación de la base de datos

-- Creación de base de datos
CREATE DATABASE IF NOT EXISTS E_commerce;
USE E_commerce;

-- Creación de tablas
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
    Primary key (id_producto),
    FOREIGN KEY (categoria_id) REFERENCES Categorias(id_categoria),
    FOREIGN KEY (proveedor_id) REFERENCES Proveedores(id_proveedor)
);

CREATE TABLE Clientes(
    id_cliente INT AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(320) UNIQUE NOT NULL,
    contrasenia VARCHAR(255) NOT NULL,
    direccion_envio VARCHAR(100) NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cliente)
);

CREATE TABLE Estados(
    id_estado INT AUTO_INCREMENT,
    nombre_estado VARCHAR(25) NOT NULL,
    PRIMARY KEY (id_estado)
);

CREATE TABLE Ventas(
    id_venta INT AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado_id INT NOT NULL DEFAULT 1,
    total DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id_venta),
    FOREIGN KEY (cliente_id) REFERENCES Clientes(id_cliente)
)  PARTITION BY RANGE (YEAR(fecha_venta)) (
        PARTITION p2025 VALUES LESS THAN (2026),
        PARTITION p2026 VALUES LESS THAN (2027)
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
-- Insertación de los datos

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

INSERT INTO Clientes (nombre, apellido, email, contrasenia, direccion_envio) VALUES
('Carlos', 'Mendoza', 'carlos.mendoza@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a1', 'Calle 12 #4-56, Zona 1'),
('Ana', 'García', 'ana.garcia@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a2', 'Avenida Reforma 8-90, Zona 10'),
('Luis', 'Martínez', 'luis.martinez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a3', 'Diagonal 6 12-42, Zona 10'),
('María', 'Rodríguez', 'maria.rodriguez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a4', 'Calle Los Olivos #15, Zona 15'),
('Juan', 'López', 'juan.lopez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a5', 'Bulevar Principal 4-11, Zona 14'),
('Sofía', 'Hernández', 'sofia.hernandez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a6', 'Calzada Roosevelt 22-00, Zona 11'),
('Pedro', 'Gómez', 'pedro.gomez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a7', 'Avenida Las Américas 10-20, Zona 13'),
('Lucía', 'Pérez', 'lucia.perez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a8', 'Calle Real 5-33, Zona 2'),
('Diego', 'Sánchez', 'diego.sanchez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8a9', 'Bulevar San Cristóbal 14-02, Mixto'),
('Elena', 'Ramírez', 'elena.ramirez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b1', 'Calle del Sol 8-88, Zona 9'),
('Javier', 'Torres', 'javier.torres@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b2', 'Avenida La Castellana 3-12, Zona 8'),
('Laura', 'Flores', 'laura.flores@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b3', 'Calle 5 10-01, Zona 7'),
('Fernando', 'Díaz', 'fernando.diaz@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b4', 'Avenida Bolívar 18-50, Zona 1'),
('Gabriela', 'Vásquez', 'gabriela.vasquez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b5', 'Calle Mariscal 9-40, Zona 11'),
('Ricardo', 'Castro', 'ricardo.castro@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b6', 'Bulevar Vista Hermosa 2-15, Zona 15'),
('Patricia', 'Morales', 'patricia.morales@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b7', 'Avenida Hincapié 11-05, Zona 13'),
('Hugo', 'Álvarez', 'hugo.alvarez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b8', 'Callejn del Carmen #4, Zona 1'),
('Natalia', 'Romero', 'natalia.romero@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8b9', 'Avenida Simeón Cañas 6-12, Zona 2'),
('Oscar', 'Ruiz', 'oscar.ruiz@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c1', 'Calzada Atanasio Tzul 44-10, Zona 12'),
('Andrea', 'Suárez', 'andrea.suarez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c2', 'Calle Los Pinos 7-21, Zona 16'),
('Manuel', 'Reyes', 'manuel.reyes@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c3', 'Avenida Petapa 31-00, Zona 12'),
('Claudia', 'Jiménez', 'claudia.jimenez@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c4', 'Bulevar Austriaco 1-01, Zona 16'),
('Roberto', 'Molina', 'roberto.molina@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c5', 'Calle 14 3-55, Zona 10'),
('Vanessa', 'Delgado', 'vanessa.delgado@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c6', 'Avenida Elena 12-30, Zona 3'),
('Gabriel', 'Ortiz', 'gabriel.ortiz@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c7', 'Calle Martí 15-80, Zona 6'),
('Daniela', 'Marroquín', 'daniela.marroquin@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c8', 'Calzada Aguilar Batres 29-00, Zona 11'),
('Alejandro', 'Mejía', 'alejandro.mejia@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8c9', 'Avenida La Floresta 8-10, Zona 9'),
('Sofia', 'Echeverría', 'sofia.echeverria@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d1', 'Calle San Juan 4-99, Zona 7'),
('Esteban', 'Castillo', 'esteban.castillo@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d2', 'Bulevar Los Próceres 18-01, Zona 10'),
('Monika', 'Estrada', 'monika.estrada@email.com', '$2b$10$e834jKx9Z2W45aK0G1u9aO2L8d3', 'Calle San José 11-23, Zona 18');

INSERT INTO Estados (nombre_estado) VALUES
('Pendiente de Pago'),
('Procesando'),
('Enviado'),
('Entregado'),
('Cancelado');

INSERT INTO Ventas (cliente_id, fecha_venta, estado_id, total) VALUES
-- --- Registros del año actual (2026) ---
(1, '2026-01-15 10:30:00', 4, 1225.00),
(2, '2026-01-18 14:20:00', 4, 60.00),
(3, '2026-02-02 09:15:00', 3, 220.00),
(4, '2026-02-10 16:45:00', 2, 90.00),
(5, '2026-02-14 11:00:00', 1, 150.00),
(6, '2026-03-01 08:30:00', 4, 50.00),
(7, '2026-03-05 17:10:00', 5, 80.00),
(8, '2026-03-12 12:00:00', 4, 45.00),
(9, '2026-03-20 15:25:00', 3, 110.00),
(10, '2026-04-02 10:05:00', 2, 70.00),
(11, '2026-04-11 13:40:00', 4, 35.00),
(12, '2026-04-18 18:15:00', 1, 60.00),
(13, '2026-05-03 09:50:00', 4, 18.00),
(14, '2026-05-09 11:30:00', 3, 90.00),
(15, '2026-05-15 16:00:00', 4, 22.00),
(16, '2026-05-22 14:10:00', 2, 120.00),
(17, '2026-06-01 10:00:00', 5, 25.00),
(18, '2026-06-08 15:45:00', 4, 40.00),
(19, '2026-06-14 12:20:00', 3, 130.00),
(20, '2026-06-25 17:35:00', 1, 40.00),
(21, '2026-07-02 08:50:00', 4, 12.00),
(22, '2026-07-10 11:15:00', 4, 70.00),
(23, '2026-07-19 16:40:00', 2, 10.00),
(24, '2026-08-01 13:00:00', 4, 225.00),
(25, '2026-08-08 10:25:00', 3, 95.00),
(26, '2026-08-14 14:50:00', 4, 30.00),
(27, '2026-08-22 09:10:00', 5, 1200.00),
(28, '2026-08-29 18:00:00', 4, 45.00),
(29, '2026-09-02 11:40:00', 2, 105.00),
(30, '2026-09-10 15:00:00', 1, 15.00),

-- --- Registros del año pasado (2025) ---
(1, '2025-01-10 09:00:00', 4, 90.00),
(3, '2025-02-14 14:30:00', 4, 110.00),
(5, '2025-03-01 11:15:00', 4, 35.00),
(2, '2025-03-20 16:40:00', 4, 15.00),
(8, '2025-04-05 10:20:00', 4, 220.00),
(10, '2025-04-18 13:10:00', 5, 1200.00),
(12, '2025-05-10 15:50:00', 4, 75.00),
(14, '2025-05-25 12:00:00', 4, 40.00),
(15, '2025-06-12 08:45:00', 4, 50.00),
(17, '2025-06-30 17:30:00', 4, 95.00),
(19, '2025-07-11 11:00:00', 4, 25.00),
(20, '2025-07-28 14:15:00', 4, 130.00),
(22, '2025-08-04 09:30:00', 4, 45.00),
(24, '2025-08-19 16:10:00', 4, 60.00),
(25, '2025-09-02 10:00:00', 4, 30.00),
(27, '2025-10-15 13:45:00', 4, 150.00),
(28, '2025-11-20 18:20:00', 4, 80.00),
(29, '2025-11-28 11:05:00', 4, 225.00),
(30, '2025-12-10 15:40:00', 4, 70.00),
(6, '2025-12-24 10:00:00', 4, 18.00);

INSERT INTO Detalles_ventas (venta_id, producto_id, cantidad, precio_unitario_congelado) VALUES
-- Ventas de 2026 (id_venta 1 a 30)
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

-- Ventas de 2025 (id_venta 31 a 50)
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
(50, 17, 1, 18.00);