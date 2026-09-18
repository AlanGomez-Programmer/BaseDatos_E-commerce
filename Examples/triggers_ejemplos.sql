-- Ejemplo 1.
UPDATE Productos SET precio = precio + 10 WHERE id_producto = 1;
SELECT * FROM auditoria_precio_producto ORDER BY id_auditoria DESC LIMIT 1;

-- Ejemplo 2.
INSERT INTO Detalles_ventas (venta_id, producto_id, cantidad, precio_unitario_congelado) VALUES (59, 1, 1000, 1200);

-- Ejemplo 3.
SELECT stock FROM Productos WHERE id_producto = 2;
INSERT INTO Detalles_ventas (venta_id, producto_id, cantidad, precio_unitario_congelado) VALUES (59, 2, 5, 25.00);
SELECT stock FROM Productos WHERE id_producto = 2;

-- Ejemplo 4.
DELETE FROM Categorias WHERE id_categoria = 1;

-- Ejemplo 5.
INSERT INTO Clientes (nombre, apellido, email, contrasenia) VALUES ('Test', 'Prueba', 'test.prueba@email.com', 'Clave123$');
SELECT * FROM auditoria_nuevo_cliente ORDER BY id_auditoria DESC LIMIT 1;

-- Ejemplo 6.
SELECT id_cliente, total_gastado FROM Clientes WHERE id_cliente = 5;
UPDATE Ventas SET estado_id = 4 WHERE id_venta = 5;
SELECT id_cliente, total_gastado FROM Clientes WHERE id_cliente = 5;

-- Ejemplo 7.
UPDATE Productos SET stock = stock WHERE id_producto = 3;
SELECT id_producto, fecha_modificacion FROM Productos WHERE id_producto = 3;

-- Ejemplo 8.
UPDATE Productos SET stock = -5 WHERE id_producto = 1;

-- Ejemplo 9.
INSERT INTO Clientes (nombre, apellido, email, contrasenia) VALUES ('juan', 'pérez', 'juan.perez2@email.com', 'Clave123$');
SELECT nombre, apellido FROM Clientes WHERE email = 'juan.perez2@email.com';

-- Ejemplo 10.
SELECT total FROM Ventas WHERE id_venta = 6;
INSERT INTO Detalles_ventas (venta_id, producto_id, cantidad, precio_unitario_congelado) VALUES (6, 3, 1, 75.00);
SELECT total FROM Ventas WHERE id_venta = 6;

-- Ejemplo 11.
UPDATE Ventas SET estado_id = 3 WHERE id_venta = 7;
SELECT * FROM auditoria_cambio_estado_venta ORDER BY id_auditoria DESC LIMIT 1;

-- Ejemplo 12.
UPDATE Productos SET precio = 0 WHERE id_producto = 1;

-- Ejemplo 13.
UPDATE Productos SET stock = 15 WHERE id_producto = 9;
SELECT * FROM alertas_stock ORDER BY id_alerta DESC LIMIT 1;

-- Ejemplo 14.
DELETE FROM Ventas WHERE id_venta = 59;
SELECT * FROM ventas_eliminadas ORDER BY id_registro DESC LIMIT 1;
SELECT * FROM detalles_ventas_eliminados ORDER BY id_registro DESC LIMIT 5;

-- Ejemplo 15.
INSERT INTO Clientes (nombre, apellido, email, contrasenia) VALUES ('Test', 'Correo', 'correo-invalido', 'Clave123$');

-- Ejemplo 16.
SELECT id_cliente, fecha_ultimo_pedido FROM Clientes WHERE id_cliente = 12;
UPDATE Ventas SET estado_id = 4 WHERE id_venta = 12;
SELECT id_cliente, fecha_ultimo_pedido FROM Clientes WHERE id_cliente = 12;

-- Ejemplo 17.
INSERT INTO referidos (cliente_referente_id, cliente_referido_id) VALUES (1, 1);

-- Ejemplo 19.
INSERT INTO Productos (categoria_id, proveedor_id, nombre, precio, costo, sku) VALUES (NULL, 1, 'Producto Sin Categoria', 10.00, 5.00, 'PRU-GEN-001');
SELECT nombre, categoria_id FROM Productos WHERE sku = 'PRU-GEN-001';

-- Ejemplo 20.
SELECT id_categoria, num_productos FROM Categorias WHERE id_categoria = 1;
INSERT INTO Productos (categoria_id, proveedor_id, nombre, precio, costo, sku) VALUES (1, 1, 'Producto Prueba Contador', 20.00, 10.00, 'PRU-CNT-001');
SELECT id_categoria, num_productos FROM Categorias WHERE id_categoria = 1;