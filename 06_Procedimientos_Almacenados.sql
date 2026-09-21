-- 1. Procesa una nueva venta de forma transaccional.
DELIMITER $$
CREATE PROCEDURE sp_RealizarNuevaVenta(
    IN p_cliente_id INT,
    IN p_sucursal_id INT,
    IN p_producto_id INT,
    IN p_cantidad INT
)
BEGIN
    DECLARE v_id_venta INT;
    DECLARE v_existe_cliente INT DEFAULT NULL;
    DECLARE v_precio_actual DECIMAL(10,2) DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT id_cliente INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_cliente_id;
    IF v_existe_cliente IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el cliente no existe';
    END IF;

    SELECT precio INTO v_precio_actual FROM Productos WHERE id_producto = p_producto_id;
    IF v_precio_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el producto no existe';
    END IF;

    START TRANSACTION;

    INSERT INTO Ventas (cliente_id, sucursal_id, estado_id, total) VALUES (p_cliente_id, p_sucursal_id, 1, 0);
    SET v_id_venta = LAST_INSERT_ID();

    INSERT INTO Detalles_ventas (venta_id, producto_id, cantidad, precio_unitario_congelado)
    VALUES (v_id_venta, p_producto_id, p_cantidad, v_precio_actual);

    COMMIT;

    SELECT v_id_venta AS 'ID Venta Generada';
END $$
DELIMITER ;

-- 2. Inserta un nuevo producto y sus atributos iniciales.
DELIMITER $$
CREATE PROCEDURE sp_AgregarNuevoProducto(
    IN p_categoria_id INT,
    IN p_proveedor_id INT,
    IN p_nombre VARCHAR(100),
    IN p_descripcion VARCHAR(200),
    IN p_precio DECIMAL(10,2),
    IN p_costo DECIMAL(10,2),
    IN p_peso_lb DECIMAL(6,2),
    IN p_stock_inicial INT,
    IN p_ubicacion VARCHAR(100)
)
BEGIN
    DECLARE v_sku VARCHAR(12);

    SET v_sku = fn_GenerarSKU(p_nombre, p_categoria_id);

    INSERT INTO Productos (categoria_id, proveedor_id, nombre, descripcion, precio, costo, peso_lb, stock, ubicacion, sku)
    VALUES (p_categoria_id, p_proveedor_id, p_nombre, p_descripcion, p_precio, p_costo, p_peso_lb, p_stock_inicial, p_ubicacion, v_sku);

    SELECT LAST_INSERT_ID() AS 'ID Producto Creado', v_sku AS 'SKU Generado';
END $$
DELIMITER ;

-- 3. Actualiza la dirección de un cliente en todas las tablas relevantes.
DELIMITER $$
CREATE PROCEDURE sp_ActualizarDireccionCliente(
    IN p_cliente_id INT,
    IN p_ciudad_id INT,
    IN p_direccion VARCHAR(150)
)
BEGIN
    DECLARE v_existe_cliente INT DEFAULT NULL;
    DECLARE v_id_direccion_principal INT DEFAULT NULL;

    SELECT id_cliente INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_cliente_id;
    IF v_existe_cliente IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el cliente no existe';
    END IF;

    SELECT id_direccion INTO v_id_direccion_principal
    FROM direcciones_clientes
    WHERE cliente_id = p_cliente_id AND es_principal = 1
    LIMIT 1;

    IF v_id_direccion_principal IS NULL THEN
        INSERT INTO direcciones_clientes (cliente_id, ciudad_id, direccion, es_principal)
        VALUES (p_cliente_id, p_ciudad_id, p_direccion, 1);
    ELSE
        UPDATE direcciones_clientes
        SET ciudad_id = p_ciudad_id, direccion = p_direccion
        WHERE id_direccion = v_id_direccion_principal;
    END IF;
END $$
DELIMITER ;

-- 4. Gestiona la devolución de un producto, ajustando el stock y generando un crédito.
DELIMITER $$
CREATE PROCEDURE sp_ProcesarDevolucion(
    IN p_venta_id INT,
    IN p_producto_id INT,
    IN p_cantidad INT,
    IN p_motivo VARCHAR(255)
)
BEGIN
    DECLARE v_cantidad_comprada INT DEFAULT 0;
    DECLARE v_precio_congelado DECIMAL(10,2) DEFAULT 0;

    SELECT cantidad, precio_unitario_congelado INTO v_cantidad_comprada, v_precio_congelado
    FROM Detalles_ventas
    WHERE venta_id = p_venta_id AND producto_id = p_producto_id;

    IF v_cantidad_comprada IS NULL OR v_cantidad_comprada = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, ese producto no forma parte de esa venta';
    ELSEIF p_cantidad > v_cantidad_comprada THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, la cantidad a devolver excede la cantidad comprada';
    ELSE
        INSERT INTO devoluciones (venta_id, producto_id, cantidad, motivo, monto_credito)
        VALUES (p_venta_id, p_producto_id, p_cantidad, p_motivo, p_cantidad * v_precio_congelado);

        UPDATE Productos
        SET stock = stock + p_cantidad
        WHERE id_producto = p_producto_id;
    END IF;
END $$
DELIMITER ;

-- 5. Devuelve el historial completo de compras de un cliente.
DELIMITER $$
CREATE PROCEDURE sp_ObtenerHistorialComprasCliente(IN p_cliente_id INT)
BEGIN
    DECLARE v_existe_cliente INT DEFAULT NULL;

    SELECT id_cliente INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_cliente_id;
    IF v_existe_cliente IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el cliente no existe';
    END IF;

    SELECT V.id_venta AS 'ID Venta', V.fecha_venta AS 'Fecha', E.nombre_estado AS 'Estado',
           P.nombre AS 'Producto', DV.cantidad AS 'Cantidad',
           CONCAT('$ ', FORMAT(DV.precio_unitario_congelado, 2)) AS 'Precio Unitario',
           CONCAT('$ ', FORMAT(DV.cantidad * DV.precio_unitario_congelado, 2)) AS 'Subtotal'
    FROM Ventas V
    INNER JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
    INNER JOIN Productos P ON P.id_producto = DV.producto_id
    INNER JOIN Estados E ON E.id_estado = V.estado_id
    WHERE V.cliente_id = p_cliente_id
    ORDER BY V.fecha_venta DESC;
END $$
DELIMITER ;

-- 6. Permite ajustar manualmente el stock de un producto, registrando el motivo.
DELIMITER $$
CREATE PROCEDURE sp_AjustarNivelStock(
    IN p_producto_id INT,
    IN p_nuevo_stock INT,
    IN p_motivo VARCHAR(255),
    IN p_usuario VARCHAR(100)
)
BEGIN
    DECLARE v_stock_anterior INT DEFAULT NULL;

    SELECT stock INTO v_stock_anterior FROM Productos WHERE id_producto = p_producto_id;
    IF v_stock_anterior IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el producto no existe';
    END IF;

    INSERT INTO log_ajustes_stock (producto_id, stock_anterior, stock_nuevo, motivo, usuario_ejecuto)
    VALUES (p_producto_id, v_stock_anterior, p_nuevo_stock, p_motivo, p_usuario);

    UPDATE Productos SET stock = p_nuevo_stock WHERE id_producto = p_producto_id;
END $$
DELIMITER ;

-- 7. Anonimiza los datos de un cliente en lugar de borrarlos.
DELIMITER $$
CREATE PROCEDURE sp_EliminarClienteDeFormaSegura(IN p_cliente_id INT)
BEGIN
    DECLARE v_existe_cliente INT DEFAULT NULL;

    SELECT id_cliente INTO v_existe_cliente FROM Clientes WHERE id_cliente = p_cliente_id;
    IF v_existe_cliente IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el cliente no existe';
    END IF;

    UPDATE Clientes
    SET nombre = 'Cliente', apellido = 'Eliminado',
        email = CONCAT('eliminado.', id_cliente, '@anonimo.com'),
        contrasenia = '', fecha_nacimiento = NULL, activo = 0
    WHERE id_cliente = p_cliente_id;

    DELETE FROM direcciones_clientes WHERE cliente_id = p_cliente_id;
END $$
DELIMITER ;

-- 8. Aplica un descuento a todos los productos de una categoría específica.
DELIMITER $$
CREATE PROCEDURE sp_AplicarDescuentoPorCategoria(
    IN p_categoria_id INT,
    IN p_descuento_pct DECIMAL(5,2)
)
BEGIN
    DECLARE v_existe_categoria INT DEFAULT NULL;

    SELECT id_categoria INTO v_existe_categoria FROM Categorias WHERE id_categoria = p_categoria_id;
    IF v_existe_categoria IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, la categoria no existe';
    ELSEIF p_descuento_pct <= 0 OR p_descuento_pct >= 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el descuento debe estar entre 0 y 100';
    ELSE
        UPDATE Productos
        SET precio = ROUND(precio - (precio * p_descuento_pct / 100), 2)
        WHERE categoria_id = p_categoria_id;
    END IF;
END $$
DELIMITER ;

-- 9. Genera un reporte completo de ventas para un mes y año dados.
DELIMITER $$
CREATE PROCEDURE sp_GenerarReporteMensualVentas(
    IN p_anio INT,
    IN p_mes INT
)
BEGIN
    SELECT COUNT(DISTINCT V.id_venta) AS 'Total Ventas',
           COALESCE(SUM(DV.cantidad), 0) AS 'Unidades Vendidas',
           CONCAT('$ ', FORMAT(COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0), 2)) AS 'Total Recaudado'
    FROM Ventas V
    INNER JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
    WHERE V.estado_id IN (3, 4)
      AND YEAR(V.fecha_venta) = p_anio AND MONTH(V.fecha_venta) = p_mes;
END $$
DELIMITER ;

-- 10. Cambia el estado de un pedido.
DELIMITER $$
CREATE PROCEDURE sp_CambiarEstadoPedido(
    IN p_venta_id INT,
    IN p_nuevo_estado_id INT
)
BEGIN
    DECLARE v_existe_venta INT DEFAULT NULL;
    DECLARE v_existe_estado INT DEFAULT NULL;

    SELECT id_venta INTO v_existe_venta FROM Ventas WHERE id_venta = p_venta_id;
    SELECT id_estado INTO v_existe_estado FROM Estados WHERE id_estado = p_nuevo_estado_id;

    IF v_existe_venta IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, la venta no existe';
    ELSEIF v_existe_estado IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el estado no existe';
    ELSE
        UPDATE Ventas SET estado_id = p_nuevo_estado_id WHERE id_venta = p_venta_id;
    END IF;
END $$
DELIMITER ;

-- 11. Registra un nuevo cliente validando que el email no exista.
DELIMITER $$
CREATE PROCEDURE sp_RegistrarNuevoCliente(
    IN p_nombre VARCHAR(50),
    IN p_apellido VARCHAR(50),
    IN p_email VARCHAR(320),
    IN p_contrasenia VARCHAR(255),
    IN p_fecha_nacimiento DATE
)
BEGIN
    DECLARE v_existe_email INT DEFAULT 0;

    SELECT COUNT(*) INTO v_existe_email FROM Clientes WHERE email = p_email;
    IF v_existe_email > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, ese correo ya esta registrado';
    ELSE
        INSERT INTO Clientes (nombre, apellido, email, contrasenia, fecha_nacimiento)
        VALUES (p_nombre, p_apellido, p_email, p_contrasenia, p_fecha_nacimiento);

        SELECT LAST_INSERT_ID() AS 'ID Cliente Creado';
    END IF;
END $$
DELIMITER ;

-- 12. Devuelve toda la información de un producto, incluyendo datos de su proveedor y categoría.
DELIMITER $$
CREATE PROCEDURE sp_ObtenerDetallesProductoCompleto(IN p_producto_id INT)
BEGIN
    DECLARE v_existe_producto INT DEFAULT NULL;

    SELECT id_producto INTO v_existe_producto FROM Productos WHERE id_producto = p_producto_id;
    IF v_existe_producto IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el producto no existe';
    END IF;

    SELECT P.id_producto AS 'ID Producto', P.nombre AS 'Nombre', P.descripcion AS 'Descripcion',
           CONCAT('$ ', FORMAT(P.precio, 2)) AS 'Precio', P.stock AS 'Stock', P.ubicacion AS 'Ubicacion',
           P.sku AS 'SKU', P.activo AS 'Activo',
           C.nombre AS 'Categoria', PR.nombre AS 'Proveedor', PR.email_contacto AS 'Email Proveedor'
    FROM Productos P
    INNER JOIN Categorias C ON C.id_categoria = P.categoria_id
    INNER JOIN Proveedores PR ON PR.id_proveedor = P.proveedor_id
    WHERE P.id_producto = p_producto_id;
END $$
DELIMITER ;

-- 14. Asigna o cambia el proveedor de un producto.
DELIMITER $$
CREATE PROCEDURE sp_AsignarProductoAProveedor(
    IN p_producto_id INT,
    IN p_proveedor_id INT
)
BEGIN
    DECLARE v_existe_producto INT DEFAULT NULL;
    DECLARE v_existe_proveedor INT DEFAULT NULL;

    SELECT id_producto INTO v_existe_producto FROM Productos WHERE id_producto = p_producto_id;
    SELECT id_proveedor INTO v_existe_proveedor FROM Proveedores WHERE id_proveedor = p_proveedor_id;

    IF v_existe_producto IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el producto no existe';
    ELSEIF v_existe_proveedor IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el proveedor no existe';
    ELSE
        UPDATE Productos SET proveedor_id = p_proveedor_id WHERE id_producto = p_producto_id;
    END IF;
END $$
DELIMITER ;

-- 15. Realiza una búsqueda avanzada de productos con filtros por nombre, categoría, rango de precios, etc.
DELIMITER $$
CREATE PROCEDURE sp_BuscarProductos(
    IN p_nombre VARCHAR(100),
    IN p_categoria_id INT,
    IN p_precio_min DECIMAL(10,2),
    IN p_precio_max DECIMAL(10,2)
)
BEGIN
    SELECT P.id_producto AS 'ID Producto', P.nombre AS 'Nombre', C.nombre AS 'Categoria',
           CONCAT('$ ', FORMAT(P.precio, 2)) AS 'Precio', P.stock AS 'Stock'
    FROM Productos P
    INNER JOIN Categorias C ON C.id_categoria = P.categoria_id
    WHERE (p_nombre IS NULL OR P.nombre LIKE CONCAT('%', p_nombre, '%'))
      AND (p_categoria_id IS NULL OR P.categoria_id = p_categoria_id)
      AND (p_precio_min IS NULL OR P.precio >= p_precio_min)
      AND (p_precio_max IS NULL OR P.precio <= p_precio_max)
      AND P.activo = 1
    ORDER BY P.nombre ASC;
END $$
DELIMITER ;

-- 16. Devuelve un conjunto de KPIs para un panel de administración.
DELIMITER $$
CREATE PROCEDURE sp_ObtenerDashboardAdmin()
BEGIN
    SELECT
        (SELECT COUNT(*) FROM Ventas WHERE DATE(fecha_venta) = CURDATE() AND estado_id IN (3,4)) AS 'Ventas de Hoy',
        (SELECT COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0)
         FROM Ventas V INNER JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
         WHERE DATE(V.fecha_venta) = CURDATE() AND V.estado_id IN (3,4)) AS 'Recaudado Hoy',
        (SELECT COUNT(*) FROM Clientes WHERE DATE(fecha_registro) = CURDATE()) AS 'Nuevos Clientes Hoy',
        (SELECT COUNT(*) FROM Clientes WHERE activo = 1) AS 'Clientes Activos',
        (SELECT COUNT(*) FROM Productos WHERE stock < 20 AND activo = 1) AS 'Productos con Bajo Stock',
        (SELECT COUNT(*) FROM Ventas WHERE estado_id = 1) AS 'Pedidos Pendientes de Pago';
END $$
DELIMITER ;

-- 17. Simula el procesamiento de un pago para una venta, actualizando su estado.
DELIMITER $$
CREATE PROCEDURE sp_ProcesarPago(IN p_venta_id INT)
BEGIN
    DECLARE v_estado_actual INT DEFAULT NULL;

    SELECT estado_id INTO v_estado_actual FROM Ventas WHERE id_venta = p_venta_id;

    IF v_estado_actual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, la venta no existe';
    ELSEIF v_estado_actual <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, esta venta no esta pendiente de pago';
    ELSE
        UPDATE Ventas SET estado_id = 2 WHERE id_venta = p_venta_id;
    END IF;
END $$
DELIMITER ;

-- 18. Permite a un cliente añadir una reseña y calificación a un producto que ha comprado.
DELIMITER $$
CREATE PROCEDURE sp_AnadirResenaProducto(
    IN p_cliente_id INT,
    IN p_producto_id INT,
    IN p_calificacion TINYINT,
    IN p_comentario VARCHAR(500)
)
BEGIN
    DECLARE v_lo_compro INT DEFAULT 0;
    DECLARE v_ya_reseno INT DEFAULT 0;

    SELECT COUNT(*) INTO v_lo_compro
    FROM Detalles_ventas DV
    INNER JOIN Ventas V ON V.id_venta = DV.venta_id
    WHERE V.cliente_id = p_cliente_id AND DV.producto_id = p_producto_id AND V.estado_id IN (3, 4);

    SELECT COUNT(*) INTO v_ya_reseno
    FROM resenas
    WHERE cliente_id = p_cliente_id AND producto_id = p_producto_id;

    IF v_lo_compro = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, solo puedes reseñar productos que hayas comprado';
    ELSEIF v_ya_reseno > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, ya has reseñado este producto';
    ELSE
        INSERT INTO resenas (cliente_id, producto_id, calificacion, comentario)
        VALUES (p_cliente_id, p_producto_id, p_calificacion, p_comentario);
    END IF;
END $$
DELIMITER ;

-- 19. Devuelve una lista de productos relacionados a uno dado, basándose en compras de otros clientes.
DELIMITER $$
CREATE PROCEDURE sp_ObtenerProductosRelacionados(IN p_producto_id INT)
BEGIN
    SELECT P2.id_producto AS 'ID Producto', P2.nombre AS 'Producto Relacionado', COUNT(*) AS 'Veces Comprado Junto'
    FROM Detalles_ventas DV1
    INNER JOIN Detalles_ventas DV2 ON DV2.venta_id = DV1.venta_id AND DV2.producto_id <> DV1.producto_id
    INNER JOIN Productos P2 ON P2.id_producto = DV2.producto_id
    WHERE DV1.producto_id = p_producto_id
    GROUP BY P2.id_producto, P2.nombre
    ORDER BY COUNT(*) DESC
    LIMIT 5;
END $$
DELIMITER ;