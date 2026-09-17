-- 1. Calcula el monto total de una venta específica.
DELIMITER $$
CREATE FUNCTION fn_CalcularTotalVenta(p_id_venta INT)
RETURNS DECIMAL (10, 2)
DETERMINISTIC 
READS SQL DATA
BEGIN 
	-- Declaración de variables
	-- Declaramos Variable para encontrar el id de la venta
    DECLARE v_existe_venta INT DEFAULT 0;
    -- Declaramos Variable para almacenar el monto total
    DECLARE v_monto_total DECIMAL(10, 2) DEFAULT 0;
    
    -- Consulta para buscar el id ingresado
    SELECT V.id_venta INTO v_existe_venta
    FROM Ventas V
    WHERE V.id_venta = p_id_venta;
    
    IF p_id_venta <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se acbeptan valores igual o menores a 0';
	ELSEIF v_existe_venta = 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no existe el id que ingresaste';
    ELSE
		SELECT COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0) INTO v_monto_total
        FROM Detalles_ventas DV
        WHERE DV.venta_id = p_id_venta;
	END IF;
    RETURN v_monto_total;
END $$
DELIMITER ;

-- Ejemplo: 
SET @id_venta = 1;
SELECT fn_CalcularTotalVenta(@id_venta) AS 'Total Venta';

-- 2. Validar si hay stock suficiente para un producto.
DELIMITER $$
CREATE FUNCTION fn_VerificarDisponibilidadStock(p_id_producto INT)
RETURNS VARCHAR(50)
DETERMINISTIC
READS SQL DATA
BEGIN
	-- Declaración de variables
    -- Declaramos Variable para encontrar el id del producto
    DECLARE v_existe_producto INT DEFAULT NULL;
    -- Declaramos Variable para almacenar el texto a mostrar
    DECLARE V_texto_respuesta VARCHAR(50) DEFAULT '';
    
	-- Consulta para buscar el id ingresado
    SELECT P.id_producto INTO v_existe_producto
    FROM Productos P
    WHERE P.id_producto = p_id_producto;
    
    IF p_id_producto <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valores igual o menores a 0';
	ELSEIF v_existe_producto IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, id ingresado no existe';
	ELSE
		SELECT 
			CASE 
				WHEN P.stock > 20 THEN 'Si hay suficiente disponibilidad'
				ELSE 'No hay suficiente disponibilidad'
			END INTO V_texto_respuesta
		FROM Productos P
        WHERE P.id_producto = p_id_producto;
	END IF;
    RETURN V_texto_respuesta;
END $$
DELIMITER ;

-- Ejemplo:
SET @id_producto = 1;
SELECT fn_VerificarDisponibilidadStock(@id_producto) AS 'Respuesta Disponible';

-- 3. Devolver el precio actual de un producto.
DELIMITER $$
CREATE FUNCTION fn_ObtenerPrecioProducto(p_id_producto INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
	-- Declaración de variables
    -- Declaramos Variable para encontrar el id del producto
    DECLARE v_existe_producto INT DEFAULT NULL;
    -- Declaramos Variable para almacenar el precio del producto
    DECLARE v_precio_producto DECIMAL;
    
    -- Consulta para buscar el id ingresado
    SELECT P.id_producto INTO v_existe_producto
    FROM Productos P
    WHERE P.id_producto = p_id_producto;
    
    IF p_id_producto <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valores igual o menores a 0';
	ELSEIF v_existe_producto IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, id ingresado no existe';
	ELSE
		SELECT COALESCE(P.precio, 0) INTO v_precio_producto
        FROM Productos P
        WHERE P.id_producto = p_id_producto;
	END IF;
    RETURN v_precio_producto;
END $$
DELIMITER ;

-- Ejemplo:
SET @id_producto = 2;
SELECT fn_ObtenerPrecioProducto(@id_producto) AS 'Precio Producto';

-- 4. Calcular la edad de un cliente a partir de su fecha de nacimiento.
DELIMITER $$
CREATE FUNCTION fn_CalcularEdadCliente(p_fecha_nacimiento DATE)
RETURNS INT
NOT DETERMINISTIC
NO SQL
BEGIN
	-- Declaramos la Variable donde se almacenará la edad
    DECLARE v_edad INT;
    
    -- Validamos la fecha ingresada
    IF p_fecha_nacimiento > CURDATE() THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, has ingresado una fecha mayor a la actual';
	ELSE
        -- Realizamos el cálculo
		SET v_edad = TIMESTAMPDIFF(YEAR, p_fecha_nacimiento, CURDATE());
	END IF;
    RETURN v_edad;
END $$
DELIMITER ;

-- Ejemplo:
SET @fecha_nacimiento = '2008-12-29';
SELECT fn_CalcularEdadCliente(@fecha_nacimiento) AS 'Edad';

-- 5. Devuelve el nombre y apellido de un cliente en un formato estandarizado.
DELIMITER $$
CREATE FUNCTION fn_FormatearNombreCompleto(p_id_cliente INT)
RETURNS VARCHAR(50)
DETERMINISTIC
READS SQL DATA
BEGIN
	-- Declaración de variables
    -- Declaramos Variable para encontrar el id del cliente
    DECLARE v_existe_cliente INT DEFAULT NULL;
    -- Declaramos Variable para almacenar el texto a mostrar
    DECLARE v_nombre_formateado VARCHAR(50) DEFAULT '';
    
	-- Consulta para buscar el id ingresado
    SELECT C.id_cliente INTO v_existe_cliente
    FROM Clientes C
    WHERE C.id_cliente = p_id_cliente;

    IF p_id_cliente <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0';
    ELSEIF v_existe_cliente IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id que ingreso no existe';
	ELSE
		SELECT CONCAT(UPPER(LEFT(C.nombre, 1)),LOWER(SUBSTRING(C.nombre, 2)),' ', UPPER(LEFT(C.apellido, 1)),LOWER(SUBSTRING(C.apellido, 2)))
		INTO v_nombre_formateado
		FROM Clientes C
		WHERE C.id_cliente = p_id_cliente;
	END IF;
    RETURN v_nombre_formateado;
END $$
DELIMITER ;

-- Ejemplo:
SET @id_cliente = 3;
SELECT fn_FormatearNombreCompleto(@id_cliente) AS 'Nombre Completo Formateado';

-- 6. Devuelve VERDADERO si un cliente realizó su primera compra en los últimos 30 días.
DELIMITER $$
CREATE FUNCTION fn_EsClienteNuevo(p_id_cliente INT)
RETURNS TINYINT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
	-- Declaración de variables
	-- Declaramos Variable para encontrar el id del cliente
    DECLARE v_existe_cliente INT DEFAULT NULL;
    -- Declaramos Variable para almacenar la primera compra
    DECLARE v_primera_compra DATE DEFAULT NULL;
    -- Declaramos Variable
    DECLARE v_resultado TINYINT DEFAULT 0;
    
	-- Consulta para buscar el id ingresado
    SELECT C.id_cliente INTO v_existe_cliente
    FROM Clientes C
    WHERE C.id_cliente = p_id_cliente;
    
	IF p_id_cliente <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0';
    ELSEIF v_existe_cliente IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id que ingreso no existe';
	ELSE 
		SELECT MIN(V.fecha_venta) INTO v_primera_compra
        FROM Ventas V
        WHERE V.cliente_id = p_id_cliente AND V.estado_id IN (3, 4);
        
        IF v_primera_compra IS NOT NULL AND v_primera_compra >= DATE_SUB(CURDATE(), INTERVAL 30 DAY) THEN
			SET v_resultado = 1;
		END IF;
	END IF;
	RETURN v_resultado;
END $$
DELIMITER ;

-- Ejemplo:
SET @id_cliente = 54;
SELECT fn_EsClienteNuevo(@id_cliente) AS 'Compra en 30 Días';

-- 7. Calcula el costo de envío basado en el peso total de los productos de una venta.
DELIMITER $$
CREATE FUNCTION fn_CalcularCostoEnvio(p_id_venta INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    -- Declaramos variables para verificar existencia y almacenar resultados
    DECLARE v_existe_venta INT DEFAULT 0;
    DECLARE v_peso_total DECIMAL(10, 2) DEFAULT 0;
    DECLARE v_costo_envio DECIMAL(10, 2) DEFAULT 0;
    
    -- Verificamos que la venta exista
    SELECT COUNT(*) INTO v_existe_venta
    FROM Ventas
    WHERE id_venta = p_id_venta;

	IF p_id_venta <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valores menores o iguales a 0';
    ELSEIF v_existe_venta = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id ingresado no existe';
    ELSE
        -- Sumamos el peso de todos los productos de esa venta (cantidad * peso unitario)
        SELECT COALESCE(SUM(DV.cantidad * P.peso_kg), 0) INTO v_peso_total
        FROM Detalles_ventas DV
        INNER JOIN Productos P ON P.id_producto = DV.producto_id
        WHERE DV.venta_id = p_id_venta;

        -- Aplicamos la tarifa según el rango de peso
        SET v_costo_envio = CASE
            WHEN v_peso_total <= 1 THEN 15.00
            WHEN v_peso_total <= 5 THEN 30.00
            WHEN v_peso_total <= 10 THEN 50.00
            ELSE 50.00 + ((v_peso_total - 10) * 5.00)
        END;
    END IF;

    RETURN v_costo_envio;
END $$
DELIMITER ;
-- Nota: Explicando el precio y el porqué de la fórmula del ELSE.
-- Se definieron 3 tarifas fijas para los rangos de peso más comunes en el catálogo
-- (hasta 1kg, hasta 5kg, hasta 10kg), pero un envío pesado (más de 10kg),
-- no puede seguir cobrando un fijo de $50.00, ya que
-- el costo real de transporte sí crece proporcional al peso a partir de cierto punto.
-- Por eso, se toma la tarifa tope ($50.00, la de "hasta 10kg") como base,
-- y se le suma $5.00 por cada kg adicional que exceda esos 10kg:
-- 50.00 + ((peso_total - 10) * 5.00)

-- Ejemplo:
SET @id_venta = 1;
SELECT CONCAT('$ ', fn_CalcularCostoEnvio(@id_venta)) as 'Costo Envío'

-- 8. Aplica un porcentaje de descuento a un monto dado.
DELIMITER $$
CREATE FUNCTION fn_AplicarDescuento(p_monto DECIMAL(10, 2))
RETURNS DECIMAL(10, 2)
DETERMINISTIC
NO SQL
BEGIN
	-- Declaramos variables para Almacenar resultados
    DECLARE v_total_final DECIMAL(10, 2) DEFAULT 0;
    
	IF p_monto <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valores menores o iguales a 0';
	ELSE
		SET v_total_final = CASE
			WHEN p_monto >= 1000 THEN p_monto-(p_monto*0.1)
			WHEN p_monto >= 500 THEN p_monto-(p_monto*0.05)
			ELSE p_monto
		END;
    END IF;
    RETURN v_total_final;
END $$
DELIMITER ;
-- Nota: Los porcentajes se agregaron de la forma decimal para no agregar /100

-- Ejemplo:
SET @cantidad = 800;
SELECT CONCAT('$ ', fn_AplicarDescuento(@cantidad)) as 'Total con descuento aplicado';

-- 9. Devuelve la fecha de la última compra de un cliente
DELIMITER $$
CREATE FUNCTION fn_ObtenerUltimaFechaCompra(p_id_cliente INT)
RETURNS DATE
DETERMINISTIC
READS SQL DATA
BEGIN
	-- Declaración de variables
    -- Declaramos Variable para encontrar el id del cliente
    DECLARE v_existe_cliente INT DEFAULT NULL;
    -- Declaramos Variable para revisar si el cliente tiene compras
    DECLARE v_cantidad_compras INT DEFAULT 0;
    -- Declaramos Variable para almacenar la fecha
    DECLARE v_ultima_fecha DATE;
    
    IF p_id_cliente <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0';
	END IF;
    
	-- Consulta para buscar el id ingresado
    SELECT C.id_cliente INTO v_existe_cliente
    FROM Clientes C
    WHERE C.id_cliente = p_id_cliente;
    
    -- Consulta para contar compras
	SELECT COUNT(V.cliente_id) INTO v_cantidad_compras
    FROM Ventas V
    WHERE V.cliente_id = p_id_cliente AND V.estado_id IN (3, 4);
    
    IF v_existe_cliente IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id que ingreso no existe';
	ELSEIF v_cantidad_compras = 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el cliente existe pero no tiene compras';
	ELSE
		SELECT MAX(DATE(V.fecha_venta)) INTO v_ultima_fecha
        FROM Ventas V
        WHERE V.cliente_id = p_id_cliente AND V.estado_id IN (3, 4);
    END IF;
	RETURN v_ultima_fecha;
END $$
DELIMITER ;

-- Ejemplo:
SET @id_cliente = 24;
SELECT fn_ObtenerUltimaFechaCompra(@id_cliente) as 'Fecha Última Compra';

-- 10. Comprueba si una cadena de texto tiene un formato de correo electrónico válido.
DELIMITER $$
CREATE FUNCTION fn_ValidarFormatoEmail(p_correo VARCHAR(320))
RETURNS VARCHAR(50) 
DETERMINISTIC
NO SQL
BEGIN
	-- Declaramos Variable para almacenar el valor booleano
    DECLARE v_email_correcto TINYINT DEFAULT 0;
    DECLARE v_texto VARCHAR(50);
    
    SET v_email_correcto =  p_correo REGEXP '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$';
    SET v_texto = CASE WHEN v_email_correcto = 1 THEN 'El correo es válido' ELSE 'El correo no es válido' END;
    
    RETURN v_texto;
END $$
DELIMITER ;

-- Ejemplo:
SET @correo = 'alanqgmail.com';
SELECT fn_ValidarFormatoEmail(@correo) as 'Correo Valido';

-- 11. Devuelve el nombre de la categoría a partir del ID de un producto.
DELIMITER $$
CREATE FUNCTION fn_ObtenerNombreCategoria(p_id_producto INT)
RETURNS VARCHAR(50)
DETERMINISTIC
READS SQL DATA
BEGIN
	-- Declaración de variables
    -- Declaramos Variable para encontrar el id de producto y almacenar el nombre de la categoria
    DECLARE v_existe_producto INT DEFAULT NULL;
    DECLARE v_nombre_categoria VARCHAR(50) DEFAULT '';
    
    IF p_id_producto <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0';
	END IF;
    
    -- Consulta para buscar el id ingresado
    SELECT P.id_producto INTO v_existe_producto
    FROM Productos P
    WHERE P.id_producto = p_id_producto;
    
	IF v_existe_producto IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id que ingreso no existe';
	ELSE
		SELECT CONCAT(UPPER(LEFT(C.nombre, 1)),SUBSTRING(C.nombre, 2)) INTO v_nombre_categoria
        FROM Categorias C
        INNER JOIN Productos P ON P.categoria_id = C.id_categoria
        WHERE P.id_producto  = p_id_producto;
    END IF;
    RETURN v_nombre_categoria;
END $$
DELIMITER ;

-- Ejemplo:
SET @id_producto = 70;
SELECT fn_ObtenerNombreCategoria(@id_producto) as 'Nombre Categoría';

-- 12. Cuenta el número total de compras realizadas por un cliente.
DELIMITER $$
CREATE FUNCTION fn_ContarVentasCliente(p_id_cliente INT)
RETURNS INT 
DETERMINISTIC
READS SQL DATA
BEGIN 
	-- Declaración de variables
    -- Declaramos Variable para encontrar el id del cliente y almacenar la cantidad de compras
    DECLARE v_existe_cliente INT DEFAULT NULL;
    DECLARE v_total_compras INT DEFAULT 0;
    
     IF p_id_cliente <= 0 THEN
	    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0';
    END IF;

	-- Consulta para buscar el id ingresado
    SELECT C.id_cliente INTO v_existe_cliente
    FROM Clientes C
    WHERE C.id_cliente = p_id_cliente;
	
	IF v_existe_cliente IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id que ingreso no existe';
	ELSE
		SELECT COALESCE(COUNT(V.cliente_id), 0)INTO v_total_compras
		FROM Ventas V
        WHERE V.cliente_id = p_id_cliente AND V.estado_id IN (3, 4);
        
		IF v_total_compras = 0 THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el cliente existe pero no tiene compras';
		END IF;
        
	END IF;
    RETURN v_total_compras;
END $$
DELIMITER ;

-- Ejemplo:
SET @id_cliente = 56;
SELECT fn_ContarVentasCliente(@id_cliente) AS 'Total de Compras Cliente';

-- 13. Devuelve el número de días transcurridos desde la última compra de un cliente.
DELIMITER $$
CREATE FUNCTION fn_CalcularDiasDesdeUltimaCompra(p_id_cliente INT)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN 
    -- Declaración de variables
    -- Declaramos Variable para encontrar el id del cliente y almacenar el número de días
    DECLARE v_existe_cliente INT DEFAULT NULL;
    DECLARE v_dias INT DEFAULT 0;
    DECLARE v_cantidad_compras INT DEFAULT 0;

     IF p_id_cliente <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0';
    END IF;

    -- Consulta para buscar el id ingresado
    SELECT C.id_cliente INTO v_existe_cliente
    FROM Clientes C
    WHERE C.id_cliente = p_id_cliente;

    IF v_existe_cliente IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id que ingreso no existe';
    END IF;

       -- Consulta para contar compras
    SELECT COUNT(V.cliente_id) INTO v_cantidad_compras
    FROM Ventas V
    WHERE V.cliente_id = p_id_cliente AND V.estado_id IN (3, 4);

    IF v_cantidad_compras = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el cliente existe pero no tiene compras';
    ELSE
        SELECT TIMESTAMPDIFF(DAY, MAX(V.fecha_venta), NOW()) INTO v_dias
        FROM Ventas V
        WHERE V.cliente_id = p_id_cliente AND V.estado_id IN (3, 4);
    END IF;
    RETURN v_dias;
END $$
DELIMITER ;

-- Ejemplo:
SET @id_cliente = 2;
SELECT fn_CalcularDiasDesdeUltimaCompra(@id_cliente) AS 'No. Días sin comprar';

-- 14. Asigna un estado de lealtad (Bronce, Plata, Oro) a un cliente según su gasto total.
DELIMITER $$
CREATE FUNCTION fn_DeterminarEstadoLealtad(p_id_cliente INT)
RETURNS VARCHAR(25)
DETERMINISTIC
READS SQL DATA
BEGIN 
	-- Declaración de variables
    -- Declaramos Variable para encontrar el id del cliente, almacenar gasto total y almacenar el texto
    DECLARE v_existe_cliente INT DEFAULT NULL;
    DECLARE v_gasto_total DECIMAL(10, 2) DEFAULT 0;
    DECLARE v_estado_texto VARCHAR(25);
    
	IF p_id_cliente <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0';
    END IF;

    -- Consulta para buscar el id ingresado
    SELECT C.id_cliente INTO v_existe_cliente
    FROM Clientes C
    WHERE C.id_cliente = p_id_cliente;
    
    IF v_existe_cliente IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id que ingreso no existe';
	ELSE 
		SELECT COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0) INTO v_gasto_total
        FROM Detalles_ventas DV
        INNER JOIN Ventas V ON V.id_venta = DV.venta_id AND V.estado_id IN (3, 4)
        WHERE V.cliente_id = p_id_cliente;
        
        IF v_gasto_total = 0 THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el cliente existe pero no tiene compras';
		END IF;
        
        SET v_estado_texto = CASE
			WHEN v_gasto_total > 5000 THEN 'Oro'
            WHEN v_gasto_total > 1000 THEN 'Plata'
            ELSE'Bronce'
		END;
    END IF;
	RETURN v_estado_texto;
END $$
DELIMITER ;

-- Ejemplo:
SET @id_cliente = 4;
SELECT fn_DeterminarEstadoLealtad(@id_cliente) AS 'Estado Lealtad';

-- 15. Genera un código de producto (SKU) único basado en su nombre y categoría.
DELIMITER $$
CREATE FUNCTION fn_GenerarSKU(p_nombre VARCHAR(100), p_categoria_id INT)
RETURNS VARCHAR(12)
DETERMINISTIC
READS SQL DATA
BEGIN
    -- Declaración de variables
    -- Declaramos Variable para encontrar la categoría, armar el prefijo y el sku final
    DECLARE v_existe_categoria INT DEFAULT NULL;
    DECLARE v_prefijo_categoria VARCHAR(3);
    DECLARE v_prefijo_nombre VARCHAR(3);
    DECLARE v_consecutivo INT DEFAULT 0;
    DECLARE v_sku_final VARCHAR(12);

    IF p_categoria_id <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0';
    END IF;

    IF p_nombre IS NULL OR LENGTH(TRIM(p_nombre)) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el nombre del producto no puede estar vacío';
    END IF;

    -- Consulta para buscar el id ingresado
    SELECT C.id_categoria INTO v_existe_categoria
    FROM Categorias C
    WHERE C.id_categoria = p_categoria_id;

    IF v_existe_categoria IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id de categoría que ingreso no existe';
    ELSE
        -- Armamos el prefijo con las primeras 3 letras del nombre y de la categoría
        SET v_prefijo_nombre = UPPER(LEFT(TRIM(p_nombre), 3));

        SELECT UPPER(LEFT(C.nombre, 3)) INTO v_prefijo_categoria
        FROM Categorias C
        WHERE C.id_categoria = p_categoria_id;

        -- Contamos cuántos productos ya usan este mismo prefijo, para el consecutivo
        SELECT COUNT(*) INTO v_consecutivo
        FROM Productos P
        WHERE P.sku LIKE CONCAT(v_prefijo_nombre, '-', v_prefijo_categoria, '-%');

        SET v_sku_final = CONCAT(v_prefijo_nombre, '-', v_prefijo_categoria, '-', LPAD(v_consecutivo + 1, 3, '0'));
    END IF;

    RETURN v_sku_final;
END $$
DELIMITER ;

SET @nombre = 'Cargador Rápido USB-C';
SET @categoria = 1;
SELECT fn_GenerarSKU(@nombre, @categoria) AS 'SKU Generado';

-- 16. Calcula el impuesto (IVA) sobre el total de una venta.
DELIMITER $$
CREATE FUNCTION fn_CalcularIVA(p_id_venta INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    -- Declaración de variables
    -- Declaramos Variable para encontrar el id de la venta, el monto y el iva
    DECLARE v_existe_venta INT DEFAULT NULL;
    DECLARE v_monto_venta DECIMAL(10, 2) DEFAULT 0;
    DECLARE v_monto_sin_iva DECIMAL(10, 2) DEFAULT 0;
    DECLARE v_iva DECIMAL(10, 2) DEFAULT 0;

    IF p_id_venta <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0';
    END IF;

    -- Consulta para buscar el id ingresado
    SELECT V.id_venta INTO v_existe_venta
    FROM Ventas V
    WHERE V.id_venta = p_id_venta;

    IF v_existe_venta IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id que ingreso no existe';
    ELSE
        -- Sumamos el monto real de la venta a partir de sus detalles
        SELECT COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0) INTO v_monto_venta
        FROM Detalles_ventas DV
        WHERE DV.venta_id = p_id_venta;

		-- Se divide el monto total de las ventas por 1.12
		SET v_monto_sin_iva = v_monto_venta / 1.12;

        -- se usa 12%, la tasa de IVA de Guatemala para obetner el valor del IVA
        SET v_iva = v_monto_sin_iva * 0.12;
    END IF;

    RETURN v_iva;
END $$
DELIMITER ;
-- Notas Cálculo: 
-- Valor sin IVA = Valor de venta / 1.12
-- Cálculo del IVA = Valor sin IVA * 0.12
-- Nota: En esta función no es necesario si la venta fué cancelada o ya fué enviada

-- Ejemplo:
SET @id_venta = 1;
SELECT CONCAT('$ ', fn_CalcularIVA(@id_venta)) AS 'IVA de la Venta';

-- 17. Suma el stock de todos los productos de una categoría. 
DELIMITER $$
CREATE FUNCTION fn_ObtenerStockTotalPorCategoria(p_id_categoria INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    -- Declaración de variables
    -- Declaramos Variable para encontrar el id de categoría y almacenar el stock total
    DECLARE v_existe_categoria INT DEFAULT NULL;
    DECLARE v_stock_total INT DEFAULT 0;

    IF p_id_categoria <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0';
    END IF;

    -- Consulta para buscar el id ingresado
    SELECT C.id_categoria INTO v_existe_categoria
    FROM Categorias C
    WHERE C.id_categoria = p_id_categoria;

    IF v_existe_categoria IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id que ingreso no existe';
    ELSE
        SELECT COALESCE(SUM(P.stock), 0) INTO v_stock_total
        FROM Productos P
        WHERE P.categoria_id = p_id_categoria;
    END IF;

    RETURN v_stock_total;
END $$
DELIMITER ;

-- Ejemplo: 
SET @categoria = 1;
SELECT fn_ObtenerStockTotalPorCategoria(@categoria) AS 'Stock Total Categoría';

-- 18.  Calcula la fecha estimada de entrega de un pedido según la ubicación del cliente.
DELIMITER $$
CREATE FUNCTION fn_EstimarFechaEntrega(p_id_venta INT)
RETURNS DATE
DETERMINISTIC
READS SQL DATA
BEGIN
    -- Declaración de variables
    -- Declaramos Variable para encontrar el id de venta, el país del cliente y la fecha estimada
    DECLARE v_existe_venta INT DEFAULT NULL;
    DECLARE v_pais VARCHAR(50);
    DECLARE v_fecha_venta DATE;
    DECLARE v_dias_entrega INT DEFAULT 0;
    DECLARE v_fecha_estimada DATE;

    IF p_id_venta <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0';
    END IF;

    -- Consulta para buscar el id ingresado
    SELECT V.id_venta INTO v_existe_venta
    FROM Ventas V
    WHERE V.id_venta = p_id_venta;

    IF v_existe_venta IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id que ingreso no existe';
    ELSE
        -- Consulta para obtener el país del cliente y la fecha de la venta
        SELECT DATE(V.fecha_venta), PA.nombre INTO v_fecha_venta, v_pais
        FROM Ventas V
        INNER JOIN Direcciones_Envio DE ON DE.id_direccion = V.direccion_id
        INNER JOIN Ciudades CI ON CI.id_ciudad = DE.ciudad_id
        INNER JOIN Regiones R ON R.id_region = CI.region_id
        INNER JOIN Paises PA ON PA.id_pais = R.pais_id
        WHERE V.id_venta = p_id_venta;

        -- Definimos los días de entrega según el país (envío local vs internacional)
        SET v_dias_entrega = CASE
            WHEN v_pais = 'Guatemala' THEN 3
            WHEN v_pais = 'Colombia' THEN 7
            ELSE 10
        END;

        SET v_fecha_estimada = DATE_ADD(v_fecha_venta, INTERVAL v_dias_entrega DAY);
    END IF;

    RETURN v_fecha_estimada;
END $$
DELIMITER ;

-- Ejemplo:
SET @id_venta = 117;
SELECT fn_EstimarFechaEntrega(@id_venta) AS 'Fecha Estimada de Entrega';

-- 19. Convierte un monto a otra moneda usando una tasa de cambio fija. Primera Versión
DELIMITER $$
CREATE FUNCTION fn_ConvertirMoneda(p_monto DECIMAL(10, 2), p_id_pais INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    -- Declaración de variables
    -- Declaramos Variable para encontrar el id del país, el nombre del país y el monto convertido
    DECLARE v_existe_pais INT DEFAULT NULL;
    DECLARE v_pais VARCHAR(50);
    DECLARE v_tasa_cambio DECIMAL(10, 4) DEFAULT 0;
    DECLARE v_monto_convertido DECIMAL(10, 2) DEFAULT 0;

    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valores menores o iguales a 0 en el monto';
    END IF;

    IF p_id_pais <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valor igual o menor a 0 en el id de país';
    END IF;

    -- Consulta para buscar el id de país ingresado
    SELECT PA.id_pais, PA.nombre INTO v_existe_pais, v_pais
    FROM Paises PA
    WHERE PA.id_pais = p_id_pais;

    IF v_existe_pais IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, el id de país que ingreso no existe';
    ELSE
        -- Definimos la tasa de cambio según el país; si no está definida, se marca como error
        SET v_tasa_cambio = CASE
            WHEN v_pais = 'Guatemala' THEN 7.75    -- USD a Quetzales (GTQ)
            WHEN v_pais = 'Colombia' THEN 4000.00  -- USD a Pesos Colombianos (COP)
            ELSE 0
        END;

        IF v_tasa_cambio = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no existe una tasa de cambio configurada para ese país';
        ELSE
            SET v_monto_convertido = p_monto * v_tasa_cambio;
        END IF;
    END IF;

    RETURN v_monto_convertido;
END $$
DELIMITER ;
-- Nota: Se decidio indicar

-- Ejemplo:
SET @monto = 100;
SET @id_pais = 1; -- Guatemala
SELECT fn_ConvertirMoneda(@monto, @id_pais) AS 'Monto Convertido';

SET @id_pais = 2; -- Colombia
SELECT fn_ConvertirMoneda(@monto, @id_pais) AS 'Monto Convertido';

-- 19. Convierte un monto a otra moneda usando una tasa de cambio fija. Segunda Versión
DELIMITER $$
CREATE FUNCTION fn_ConvertirMoneda(p_monto DECIMAL(10, 2), p_tasa_cambio DECIMAL(10, 4))
RETURNS DECIMAL(10, 2)
DETERMINISTIC
NO SQL
BEGIN
    -- Declaramos Variable para almacenar el resultado
    DECLARE v_monto_convertido DECIMAL(10, 2) DEFAULT 0;

    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, no se aceptan valores menores o iguales a 0 en el monto';
    ELSEIF p_tasa_cambio <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lo sentimos, la tasa de cambio debe ser mayor a 0';
    ELSE
        SET v_monto_convertido = p_monto * p_tasa_cambio;
    END IF;

    RETURN v_monto_convertido;
END $$
DELIMITER ;

-- Ejemplo:
SET @monto = 100;
SET @tasa = 7.75; -- Ejemplo: USD a GTQ
SELECT CONCAT('Q ', fn_ConvertirMoneda(@monto, @tasa)) AS 'Monto Convertido';

-- 20. Verifica si una contraseña cumple con los criterios de seguridad (longitud, caracteres, etc.).
DELIMITER $$
CREATE FUNCTION fn_ValidarComplejidadContrasenia(p_contrasenia VARCHAR(255))
RETURNS VARCHAR(80)
DETERMINISTIC
NO SQL
BEGIN
    -- Declaramos Variable para almacenar el resultado
    DECLARE v_resultado VARCHAR(80);

    SET v_resultado = CASE
        WHEN p_contrasenia IS NULL OR LENGTH(p_contrasenia) < 8 THEN 'La contraseña debe tener al menos 8 caracteres'
        WHEN p_contrasenia NOT REGEXP '[A-Z]' THEN 'La contraseña debe tener al menos una mayúscula'
        WHEN p_contrasenia NOT REGEXP '[a-z]' THEN 'La contraseña debe tener al menos una minúscula'
        WHEN p_contrasenia NOT REGEXP '[0-9]' THEN 'La contraseña debe tener al menos un número'
        WHEN p_contrasenia NOT REGEXP '[^A-Za-z0-9]' THEN 'La contraseña debe tener al menos un carácter especial'
        ELSE 'La contraseña es segura'
    END;

    RETURN v_resultado;
END $$
DELIMITER ;
-- Nota: El usuario debe ingresar almenos una letra mayuscula, minuscula y números para que pueda tener una buena contraseña 

-- Ejemplo
SET @contrasenia = 'Segura$123!';
SELECT fn_ValidarComplejidadContrasenia(@contrasenia) AS 'Resultado';