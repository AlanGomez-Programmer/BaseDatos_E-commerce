-- 1. Guarda un log de cambios de precios.
DELIMITER $$
CREATE TRIGGER trg_audit_precio_producto_after_update
AFTER UPDATE ON Productos
FOR EACH ROW
BEGIN
	IF OLD.precio <> NEW.precio THEN
		INSERT INTO auditoria_precio_producto (producto_id, precio_anterior, precio_nuevo, usuario_modifico)
        VALUES (NEW.id_producto, OLD.precio, NEW.precio, USER());
	END IF;
END $$
DELIMITER ;

-- 2. Verifica el stock antes de registrar una venta.
DELIMITER $$
CREATE TRIGGER trg_check_stock_before_insert_venta
BEFORE INSERT ON Detalles_ventas
FOR EACH ROW
BEGIN
	DECLARE v_stock_actual INT DEFAULT 0;

	SELECT stock INTO v_stock_actual
	FROM Productos
	WHERE id_producto = NEW.producto_id;

	IF v_stock_actual < NEW.cantidad THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no hay stock suficiente para completar esta venta';
	END IF;
END $$
DELIMITER ;

-- 3. Decrementa el stock después de una venta.
DELIMITER $$
CREATE TRIGGER trg_update_stock_after_insert_venta
AFTER INSERT ON Detalles_ventas
FOR EACH ROW
BEGIN
	UPDATE Productos
	SET stock = stock - NEW.cantidad
	WHERE id_producto = NEW.producto_id;
END $$
DELIMITER ;

-- 4. Impide eliminar una categoría si tiene productos asociados.
DELIMITER $$
CREATE TRIGGER trg_prevent_delete_categoria_with_products
BEFORE DELETE ON Categorias
FOR EACH ROW
BEGIN
	DECLARE v_num_productos INT DEFAULT 0;

	SELECT COUNT(*) INTO v_num_productos
	FROM Productos
	WHERE categoria_id = OLD.id_categoria;

	IF v_num_productos > 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se puede eliminar una categoria que tiene productos asociados';
	END IF;
END $$
DELIMITER ;

-- 5. Registra en una tabla de auditoría cada vez que se crea un nuevo cliente.
DELIMITER $$
CREATE TRIGGER trg_log_new_customer_after_insert
AFTER INSERT ON Clientes
FOR EACH ROW
BEGIN
	INSERT INTO auditoria_nuevo_cliente (cliente_id)
	VALUES (NEW.id_cliente);
END $$
DELIMITER ;

-- 6. Actualiza un campo total_gastado en la tabla clientes después de cada compra.
DELIMITER $$
CREATE TRIGGER trg_update_total_gastado_cliente
AFTER UPDATE ON Ventas
FOR EACH ROW
BEGIN
	IF OLD.estado_id NOT IN (3, 4) AND NEW.estado_id IN (3, 4) THEN
		UPDATE Clientes
		SET total_gastado = total_gastado + NEW.total
		WHERE id_cliente = NEW.cliente_id;
	ELSEIF OLD.estado_id IN (3, 4) AND NEW.estado_id NOT IN (3, 4) THEN
		UPDATE Clientes
		SET total_gastado = total_gastado - OLD.total
		WHERE id_cliente = NEW.cliente_id;
	END IF;
END $$
DELIMITER ;

-- 7. Actualiza automáticamente la fecha de última modificación de un producto.
DELIMITER $$
CREATE TRIGGER trg_set_fecha_modificacion_producto
BEFORE UPDATE ON Productos
FOR EACH ROW
BEGIN
	SET NEW.fecha_modificacion = NOW();
END $$
DELIMITER ;

-- 8. Impide que el stock de un producto se actualice a un valor negativo.
DELIMITER $$
CREATE TRIGGER trg_prevent_negative_stock
BEFORE UPDATE ON Productos
FOR EACH ROW
BEGIN
	IF NEW.stock < 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el stock de un producto no puede quedar en un valor negativo';
	END IF;
END $$
DELIMITER ;

-- 9. Convierte a mayúscula la primera letra del nombre y apellido de un cliente al insertarlo.
DELIMITER $$
CREATE TRIGGER trg_capitalize_nombre_cliente
BEFORE INSERT ON Clientes
FOR EACH ROW
BEGIN
	SET NEW.nombre = CONCAT(UPPER(LEFT(NEW.nombre, 1)), LOWER(SUBSTRING(NEW.nombre, 2)));
	SET NEW.apellido = CONCAT(UPPER(LEFT(NEW.apellido, 1)), LOWER(SUBSTRING(NEW.apellido, 2)));
END $$
DELIMITER ;

-- 10. Recalcula el total en la tabla ventas si se modifica un detalle_venta.
DELIMITER $$
CREATE TRIGGER trg_recalcular_total_venta_on_insert
AFTER INSERT ON Detalles_ventas
FOR EACH ROW
BEGIN
	UPDATE Ventas
	SET total = (SELECT COALESCE(SUM(cantidad * precio_unitario_congelado), 0)
	             FROM Detalles_ventas WHERE venta_id = NEW.venta_id)
	WHERE id_venta = NEW.venta_id;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_recalcular_total_venta_on_update
AFTER UPDATE ON Detalles_ventas
FOR EACH ROW
BEGIN
	UPDATE Ventas
	SET total = (SELECT COALESCE(SUM(cantidad * precio_unitario_congelado), 0)
	             FROM Detalles_ventas WHERE venta_id = NEW.venta_id)
	WHERE id_venta = NEW.venta_id;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_recalcular_total_venta_on_delete
AFTER DELETE ON Detalles_ventas
FOR EACH ROW
BEGIN
	UPDATE Ventas
	SET total = (SELECT COALESCE(SUM(cantidad * precio_unitario_congelado), 0)
	             FROM Detalles_ventas WHERE venta_id = OLD.venta_id)
	WHERE id_venta = OLD.venta_id;
END $$
DELIMITER ;

-- 11. Audita cada cambio de estado en un pedido.
DELIMITER $$
CREATE TRIGGER trg_log_order_status_change
AFTER UPDATE ON Ventas
FOR EACH ROW
BEGIN
	IF OLD.estado_id <> NEW.estado_id THEN
		INSERT INTO auditoria_cambio_estado_venta (venta_id, estado_anterior_id, estado_nuevo_id)
		VALUES (NEW.id_venta, OLD.estado_id, NEW.estado_id);
	END IF;
END $$
DELIMITER ;

-- 12. Impide que el precio de un producto se establezca en cero o un valor negativo.
DELIMITER $$
CREATE TRIGGER trg_prevent_price_zero_or_less
BEFORE UPDATE ON Productos
FOR EACH ROW
BEGIN
	IF NEW.precio <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el precio de un producto no puede ser cero o negativo';
	END IF;
END $$
DELIMITER ;

-- 13. Inserta un registro en una tabla alertas si el stock baja de un umbral.
DELIMITER $$
CREATE TRIGGER trg_send_stock_alert_on_low_stock
AFTER UPDATE ON Productos
FOR EACH ROW
BEGIN
	IF NEW.stock < 20 AND OLD.stock >= 20 THEN
		INSERT INTO alertas_stock (producto_id, stock_actual)
		VALUES (NEW.id_producto, NEW.stock);
	END IF;
END $$
DELIMITER ;

-- 14. Mueve una venta eliminada a una tabla de archivo en lugar de borrarla permanentemente.
DELIMITER $$
CREATE TRIGGER trg_archive_deleted_venta
BEFORE DELETE ON Ventas
FOR EACH ROW
BEGIN
	INSERT INTO ventas_eliminadas (id_venta_original, cliente_id, sucursal_id, fecha_venta, estado_id, total)
	VALUES (OLD.id_venta, OLD.cliente_id, OLD.sucursal_id, OLD.fecha_venta, OLD.estado_id, OLD.total);
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_archive_deleted_detalle_venta
BEFORE DELETE ON Detalles_ventas
FOR EACH ROW
BEGIN
	INSERT INTO detalles_ventas_eliminados (id_detalle_original, id_venta_original, producto_id, cantidad, precio_unitario_congelado)
	VALUES (OLD.id_detalle, OLD.venta_id, OLD.producto_id, OLD.cantidad, OLD.precio_unitario_congelado);
END $$
DELIMITER ;

-- 15. Valida el formato del email antes de insertar o actualizar un cliente.
DELIMITER $$
CREATE TRIGGER trg_validate_email_format_on_customer_insert
BEFORE INSERT ON Clientes
FOR EACH ROW
BEGIN
	IF NEW.email NOT REGEXP '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$' THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el formato del correo no es valido';
	END IF;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_validate_email_format_on_customer_update
BEFORE UPDATE ON Clientes
FOR EACH ROW
BEGIN
	IF NEW.email NOT REGEXP '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$' THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el formato del correo no es valido';
	END IF;
END $$
DELIMITER ;

-- 16. Actualiza la fecha del último pedido en la tabla clientes.
DELIMITER $$
CREATE TRIGGER trg_update_last_order_date_customer
AFTER UPDATE ON Ventas
FOR EACH ROW
BEGIN
	IF OLD.estado_id NOT IN (3, 4) AND NEW.estado_id IN (3, 4) THEN
		UPDATE Clientes
		SET fecha_ultimo_pedido = DATE(NEW.fecha_venta)
		WHERE id_cliente = NEW.cliente_id
		  AND (fecha_ultimo_pedido IS NULL OR fecha_ultimo_pedido < DATE(NEW.fecha_venta));
	END IF;
END $$
DELIMITER ;

-- 17. Impide que un cliente se referencie a sí mismo en un programa de referidos.
DELIMITER $$
CREATE TRIGGER trg_prevent_self_referral
BEFORE INSERT ON referidos
FOR EACH ROW
BEGIN
	IF NEW.cliente_referente_id = NEW.cliente_referido_id THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, un cliente no puede referirse a si mismo';
	END IF;
END $$
DELIMITER ;

-- 18. Audita los cambios en los permisos de los usuarios.
-- No implementable como trigger real: MySQL no dispara triggers sobre
-- GRANT/REVOKE (son DCL, no DML).

-- 19. Asigna una categoría "General" si se inserta un producto sin categoría.
DELIMITER $$
CREATE TRIGGER trg_assign_default_category_on_null
BEFORE INSERT ON Productos
FOR EACH ROW
BEGIN
	IF NEW.categoria_id IS NULL THEN
		SET NEW.categoria_id = (SELECT id_categoria FROM Categorias WHERE nombre = 'General');
	END IF;
END $$
DELIMITER ;

-- 20. Mantiene un contador de cuántos productos hay en cada categoría.
DELIMITER $$
CREATE TRIGGER trg_producto_count_on_insert
AFTER INSERT ON Productos
FOR EACH ROW
BEGIN
	UPDATE Categorias
	SET num_productos = num_productos + 1
	WHERE id_categoria = NEW.categoria_id;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_producto_count_on_delete
AFTER DELETE ON Productos
FOR EACH ROW
BEGIN
	UPDATE Categorias
	SET num_productos = num_productos - 1
	WHERE id_categoria = OLD.categoria_id;
END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER trg_producto_count_on_update
AFTER UPDATE ON Productos
FOR EACH ROW
BEGIN
	IF OLD.categoria_id <> NEW.categoria_id THEN
		UPDATE Categorias SET num_productos = num_productos - 1 WHERE id_categoria = OLD.categoria_id;
		UPDATE Categorias SET num_productos = num_productos + 1 WHERE id_categoria = NEW.categoria_id;
	END IF;
END $$
DELIMITER ;