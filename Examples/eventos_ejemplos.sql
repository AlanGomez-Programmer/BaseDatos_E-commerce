-- Verificar que el programador de eventos este activo:
SHOW VARIABLES LIKE 'event_scheduler';

-- Ejemplo 1.
INSERT INTO reportes_semanales (fecha_inicio, fecha_fin, total_ventas, monto_recaudado)
SELECT DATE_SUB(CURDATE(), INTERVAL 7 DAY), CURDATE(), COUNT(DISTINCT V.id_venta),
       COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0)
FROM Ventas V INNER JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
WHERE V.estado_id IN (3, 4) AND V.fecha_venta >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
SELECT * FROM reportes_semanales ORDER BY id_reporte DESC LIMIT 1;

-- Ejemplo 4.
SELECT id_promocion, nombre_promocion, fecha_fin, activa FROM Promociones;
UPDATE Promociones SET activa = 0 WHERE activa = 1 AND fecha_fin < CURDATE();
SELECT id_promocion, nombre_promocion, fecha_fin, activa FROM Promociones;

-- Ejemplo 5.
UPDATE Clientes SET nivel_lealtad = CASE
	WHEN total_gastado > 5000 THEN 'Oro'
	WHEN total_gastado > 1000 THEN 'Plata'
	ELSE 'Bronce'
END;
SELECT id_cliente, total_gastado, nivel_lealtad FROM Clientes ORDER BY total_gastado DESC LIMIT 5;

-- Ejemplo 6.
INSERT INTO alertas_stock (producto_id, stock_actual)
SELECT id_producto, stock FROM Productos WHERE stock < 20;
SELECT * FROM alertas_stock ORDER BY id_alerta DESC LIMIT 5;

-- Ejemplo 7.
OPTIMIZE TABLE Ventas;

-- Ejemplo 8.
SELECT id_cliente, fecha_ultimo_pedido, fecha_registro, activo FROM Clientes WHERE id_cliente = 34;
UPDATE Clientes SET activo = 0
WHERE activo = 1 AND ((fecha_ultimo_pedido IS NOT NULL AND fecha_ultimo_pedido < DATE_SUB(CURDATE(), INTERVAL 1 YEAR))
                    OR (fecha_ultimo_pedido IS NULL AND fecha_registro < DATE_SUB(CURDATE(), INTERVAL 1 YEAR)));
SELECT id_cliente, activo FROM Clientes WHERE id_cliente = 34;

-- Ejemplo 9.
INSERT INTO resumen_ventas_diario (fecha, total_ventas, unidades_vendidas, monto_recaudado)
SELECT '2026-09-12', COUNT(DISTINCT V.id_venta), COALESCE(SUM(DV.cantidad), 0), COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0)
FROM Ventas V INNER JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
WHERE V.estado_id IN (3, 4) AND DATE(V.fecha_venta) = '2026-09-12';
SELECT * FROM resumen_ventas_diario;

-- Ejemplo 10.
INSERT INTO log_inconsistencias (descripcion, referencia_id)
SELECT CONCAT('Venta sin ningun detalle asociado: id_venta ', V.id_venta), V.id_venta
FROM Ventas V LEFT JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
WHERE DV.id_detalle IS NULL;
SELECT * FROM log_inconsistencias ORDER BY id_log DESC LIMIT 5;

-- Ejemplo 11.
INSERT INTO cupones_cumpleanos (cliente_id, codigo_cupon)
SELECT id_cliente, CONCAT('CUMPLE-', id_cliente, '-', YEAR(CURDATE()))
FROM Clientes WHERE MONTH(fecha_nacimiento) = MONTH(CURDATE()) AND DAY(fecha_nacimiento) = DAY(CURDATE());
SELECT * FROM cupones_cumpleanos ORDER BY id_cupon DESC LIMIT 5;

-- Ejemplo 12.
INSERT INTO ranking_productos (producto_id, posicion, unidades_vendidas)
SELECT producto_id, posicion, unidades_vendidas FROM (
    SELECT DV.producto_id, ROW_NUMBER() OVER (ORDER BY SUM(DV.cantidad) DESC) AS posicion, SUM(DV.cantidad) AS unidades_vendidas
    FROM Detalles_ventas DV INNER JOIN Ventas V ON V.id_venta = DV.venta_id
    WHERE V.estado_id IN (3, 4) GROUP BY DV.producto_id
) AS ranking LIMIT 10;
SELECT * FROM ranking_productos ORDER BY id_ranking DESC LIMIT 10;

-- Ejemplo 14.
SELECT id_venta, estado_id, fecha_venta FROM Ventas WHERE estado_id = 1;
UPDATE Ventas SET estado_id = 5 WHERE estado_id = 1 AND fecha_venta < DATE_SUB(NOW(), INTERVAL 72 HOUR);

-- Ejemplo 18.
SELECT cliente_id, COUNT(*) FROM Ventas WHERE estado_id = 5 GROUP BY cliente_id HAVING COUNT(*) >= 3;

-- Ejemplo 19.
SELECT * FROM reportes_proveedores;

-- Ejemplo 20.
SELECT id_producto, activo, fecha_modificacion FROM Productos WHERE activo = 0;