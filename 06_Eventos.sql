-- Prerrequisito: el programador de eventos debe estar activo.
SET GLOBAL event_scheduler = ON;

-- 1. Genera un reporte de ventas semanal.
DELIMITER $$
CREATE EVENT evt_generate_weekly_sales_report
ON SCHEDULE EVERY 1 WEEK STARTS CURRENT_TIMESTAMP
DO
BEGIN
	INSERT INTO reportes_semanales (fecha_inicio, fecha_fin, total_ventas, monto_recaudado)
	SELECT DATE_SUB(CURDATE(), INTERVAL 7 DAY), CURDATE(),
	       COUNT(DISTINCT V.id_venta),
	       COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0)
	FROM Ventas V
	INNER JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
	WHERE V.estado_id IN (3, 4)
	  AND V.fecha_venta >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
END $$
DELIMITER ;

-- 4. Desactiva códigos de descuento que han expirado.
DELIMITER $$
CREATE EVENT evt_deactivate_expired_promotions_hourly
ON SCHEDULE EVERY 1 HOUR STARTS CURRENT_TIMESTAMP
DO
	UPDATE Promociones
	SET activa = 0
	WHERE activa = 1 AND fecha_fin < CURDATE();
DELIMITER ;

-- 5. Recalcula el nivel de lealtad de los clientes cada noche.
DELIMITER $$
CREATE EVENT evt_recalculate_customer_loyalty_tiers_nightly
ON SCHEDULE EVERY 1 DAY STARTS CONCAT(CURDATE(), ' 02:00:00')
DO
	UPDATE Clientes
	SET nivel_lealtad = CASE
		WHEN total_gastado > 5000 THEN 'Oro'
		WHEN total_gastado > 1000 THEN 'Plata'
		ELSE 'Bronce'
	END;
DELIMITER ;

-- 6. Crea una lista de productos que necesitan ser reabastecidos.
-- Nota: reutiliza alertas_stock (mismo umbral que la consulta 9 y el trigger 13).
DELIMITER $$
CREATE EVENT evt_generate_reorder_list_daily
ON SCHEDULE EVERY 1 DAY STARTS CONCAT(CURDATE(), ' 03:00:00')
DO
	INSERT INTO alertas_stock (producto_id, stock_actual)
	SELECT id_producto, stock FROM Productos WHERE stock < 20;
DELIMITER ;

-- 7. Reconstruye los índices de las tablas más usadas para optimizar el rendimiento.
-- Nota: MySQL no tiene "REBUILD INDEX"; el equivalente es OPTIMIZE TABLE.
DELIMITER $$
CREATE EVENT evt_rebuild_indexes_weekly
ON SCHEDULE EVERY 1 WEEK STARTS CONCAT(CURDATE(), ' 04:00:00')
DO
BEGIN
	OPTIMIZE TABLE Ventas;
	OPTIMIZE TABLE Detalles_ventas;
	OPTIMIZE TABLE Productos;
	OPTIMIZE TABLE Clientes;
END $$
DELIMITER ;

-- 8. Desactiva cuentas de clientes sin actividad en más de un año.
DELIMITER $$
CREATE EVENT evt_suspend_inactive_accounts_quarterly
ON SCHEDULE EVERY 3 MONTH STARTS CURRENT_TIMESTAMP
DO
	UPDATE Clientes
	SET activo = 0
	WHERE activo = 1
	  AND (
	       (fecha_ultimo_pedido IS NOT NULL AND fecha_ultimo_pedido < DATE_SUB(CURDATE(), INTERVAL 1 YEAR))
	    OR (fecha_ultimo_pedido IS NULL AND fecha_registro < DATE_SUB(CURDATE(), INTERVAL 1 YEAR))
	  );
DELIMITER ;

-- 9. Agrega los datos de ventas del día en una tabla de resumen para acelerar reportes.
DELIMITER $$
CREATE EVENT evt_aggregate_daily_sales_data
ON SCHEDULE EVERY 1 DAY STARTS CONCAT(CURDATE(), ' 01:00:00')
DO
	INSERT INTO resumen_ventas_diario (fecha, total_ventas, unidades_vendidas, monto_recaudado)
	SELECT DATE_SUB(CURDATE(), INTERVAL 1 DAY),
	       COUNT(DISTINCT V.id_venta), COALESCE(SUM(DV.cantidad), 0), COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0)
	FROM Ventas V
	INNER JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
	WHERE V.estado_id IN (3, 4) AND DATE(V.fecha_venta) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)
	ON DUPLICATE KEY UPDATE
	    total_ventas = VALUES(total_ventas),
	    unidades_vendidas = VALUES(unidades_vendidas),
	    monto_recaudado = VALUES(monto_recaudado);
DELIMITER ;

-- 10. Busca inconsistencias en los datos (ej. ventas sin detalles).
DELIMITER $$
CREATE EVENT evt_check_data_consistency_nightly
ON SCHEDULE EVERY 1 DAY STARTS CONCAT(CURDATE(), ' 02:30:00')
DO
	INSERT INTO log_inconsistencias (descripcion, referencia_id)
	SELECT CONCAT('Venta sin ningun detalle asociado: id_venta ', V.id_venta), V.id_venta
	FROM Ventas V
	LEFT JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
	WHERE DV.id_detalle IS NULL;
DELIMITER ;

-- 11. Genera una lista de clientes que cumplen años para enviarles un cupón.
DELIMITER $$
CREATE EVENT evt_send_birthday_greetings_daily
ON SCHEDULE EVERY 1 DAY STARTS CONCAT(CURDATE(), ' 06:00:00')
DO
	INSERT INTO cupones_cumpleanos (cliente_id, codigo_cupon)
	SELECT id_cliente, CONCAT('CUMPLE-', id_cliente, '-', YEAR(CURDATE()))
	FROM Clientes
	WHERE MONTH(fecha_nacimiento) = MONTH(CURDATE()) AND DAY(fecha_nacimiento) = DAY(CURDATE());
DELIMITER ;

-- 12. Actualiza una tabla con el ranking de los productos más populares.
DELIMITER $$
CREATE EVENT evt_update_product_rankings_hourly
ON SCHEDULE EVERY 1 HOUR STARTS CURRENT_TIMESTAMP
DO
	INSERT INTO ranking_productos (producto_id, posicion, unidades_vendidas)
	SELECT producto_id, posicion, unidades_vendidas FROM (
	    SELECT DV.producto_id,
	           ROW_NUMBER() OVER (ORDER BY SUM(DV.cantidad) DESC) AS posicion,
	           SUM(DV.cantidad) AS unidades_vendidas
	    FROM Detalles_ventas DV
	    INNER JOIN Ventas V ON V.id_venta = DV.venta_id
	    WHERE V.estado_id IN (3, 4) AND V.fecha_venta >= DATE_SUB(NOW(), INTERVAL 30 DAY)
	    GROUP BY DV.producto_id
	) AS ranking
	LIMIT 10;
DELIMITER ;

-- 14. Vacía los carritos de compra abandonados hace más de 72 horas.
-- Nota: cancelar el pedido, no en borrarlo.
DELIMITER $$
CREATE EVENT evt_clear_abandoned_carts_daily
ON SCHEDULE EVERY 1 DAY STARTS CONCAT(CURDATE(), ' 05:00:00')
DO
	UPDATE Ventas
	SET estado_id = 5
	WHERE estado_id = 1 AND fecha_venta < DATE_SUB(NOW(), INTERVAL 72 HOUR);
DELIMITER ;

-- 18. Busca patrones de actividad sospechosa (ej. múltiples pedidos fallidos).
DELIMITER $$
CREATE EVENT evt_detect_fraudulent_activity_hourly
ON SCHEDULE EVERY 1 HOUR STARTS CURRENT_TIMESTAMP
DO
	INSERT INTO alertas_fraude (cliente_id, motivo)
	SELECT cliente_id, CONCAT(COUNT(*), ' pedidos cancelados en las ultimas 24 horas')
	FROM Ventas
	WHERE estado_id = 5 AND fecha_venta >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
	GROUP BY cliente_id
	HAVING COUNT(*) >= 3;
DELIMITER ;

-- 19. Crea un reporte mensual sobre el rendimiento de los proveedores.
DELIMITER $$
CREATE EVENT evt_generate_supplier_performance_report_monthly
ON SCHEDULE EVERY 1 MONTH STARTS CURRENT_TIMESTAMP
DO
	INSERT INTO reportes_proveedores (proveedor_id, anio, mes, unidades_vendidas, monto_generado)
	SELECT PR.id_proveedor,
	       YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)), MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)),
	       COALESCE(SUM(DV.cantidad), 0), COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0)
	FROM Proveedores PR
	LEFT JOIN Productos P ON P.proveedor_id = PR.id_proveedor
	LEFT JOIN Detalles_ventas DV ON DV.producto_id = P.id_producto
	LEFT JOIN Ventas V ON V.id_venta = DV.venta_id AND V.estado_id IN (3, 4)
	    AND YEAR(V.fecha_venta) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
	    AND MONTH(V.fecha_venta) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
	GROUP BY PR.id_proveedor;
DELIMITER ;

-- 20. Elimina permanentemente los registros marcados para borrado hace más de 30 días.
-- Nota: solo purga productos inactivos que jamas se hayan vendido, para no
-- romper la integridad referencial con Detalles_ventas.
DELIMITER $$
CREATE EVENT evt_purge_soft_deleted_records_weekly
ON SCHEDULE EVERY 1 WEEK STARTS CURRENT_TIMESTAMP
DO
	DELETE FROM Productos
	WHERE activo = 0
	  AND fecha_modificacion < DATE_SUB(CURDATE(), INTERVAL 30 DAY)
	  AND NOT EXISTS (SELECT 1 FROM Detalles_ventas DV WHERE DV.producto_id = Productos.id_producto);
DELIMITER ;