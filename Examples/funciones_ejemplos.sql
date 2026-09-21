-- Ejemplo 1.
SET @id_venta = 1;
SELECT CONCAT('$ ',fn_CalcularTotalVenta(@id_venta)) AS 'Total Venta';

-- Ejemplo 2.
SET @id_producto = 1;
SELECT fn_VerificarDisponibilidadStock(@id_producto) AS 'Respuesta Disponible';

-- Ejemplo 3.
SET @id_producto = 2;
SELECT fn_ObtenerPrecioProducto(@id_producto) AS 'Precio Producto';

-- Ejemplo 4.
SET @fecha_nacimiento = '2008-12-29';
SELECT fn_CalcularEdadCliente(@fecha_nacimiento) AS 'Edad';

-- Ejemplo 4b.
SET @id_cliente = 4;
SELECT fn_CalcularEdadClientePorId(@id_cliente) AS 'Edad';

-- Ejemplo 5.
SET @id_cliente = 3;
SELECT fn_FormatearNombreCompleto(@id_cliente) AS 'Nombre Completo Formateado';

-- Ejemplo 6.
SET @id_cliente = 54;
SELECT fn_EsClienteNuevo(@id_cliente) AS 'Compra en 30 Días';

-- Ejemplo 7.
SET @id_venta = 1;
SELECT CONCAT('$ ', fn_CalcularCostoEnvio(@id_venta)) as 'Costo Envío';

-- Ejemplo 8.
SET @cantidad = 800;
SELECT CONCAT('$ ', fn_AplicarDescuento(@cantidad)) as 'Total con descuento aplicado';

-- Ejemplo 9.
SET @id_cliente = 24;
SELECT fn_ObtenerUltimaFechaCompra(@id_cliente) as 'Fecha Última Compra';

-- Ejemplo 10.
SET @correo = 'alanqgmail.com';
SELECT fn_ValidarFormatoEmail(@correo) as 'Correo Valido';

-- Ejemplo 11.
SET @id_producto = 70;
SELECT fn_ObtenerNombreCategoria(@id_producto) as 'Nombre Categoría';

-- Ejemplo 12.
SET @id_cliente = 56;
SELECT fn_ContarVentasCliente(@id_cliente) AS 'Total de Compras Cliente';

-- Ejemplo 13.
SET @id_cliente = 2;
SELECT fn_CalcularDiasDesdeUltimaCompra(@id_cliente) AS 'No. Días sin comprar';

-- Ejemplo 14.
SET @id_cliente = 4;
SELECT fn_DeterminarEstadoLealtad(@id_cliente) AS 'Estado Lealtad';

-- Ejemplo 15.
SET @nombre = 'Cargador Rápido USB-C';
SET @categoria = 1;
SELECT fn_GenerarSKU(@nombre, @categoria) AS 'SKU Generado';

-- Ejemplo 16.
SET @id_venta = 1;
SELECT CONCAT('$ ', fn_CalcularIVA(@id_venta)) AS 'IVA de la Venta';

-- Ejemplo 17.
SET @categoria = 1;
SELECT fn_ObtenerStockTotalPorCategoria(@categoria) AS 'Stock Total Categoría';

-- Ejemplo 18.
SET @id_venta = 117;
SELECT fn_EstimarFechaEntrega(@id_venta) AS 'Fecha Estimada de Entrega';

-- Ejemplo 19.
SET @monto = 100;
SET @id_pais = 1; -- Guatemala
SELECT fn_ConvertirMoneda(@monto, @id_pais) AS 'Monto Convertido';

SET @id_pais = 2; -- Colombia
SELECT fn_ConvertirMoneda(@monto, @id_pais) AS 'Monto Convertido';

-- Ejemplo 19b.
SET @monto = 100;
SET @tasa = 7.75; -- Ejemplo: USD a GTQ
SELECT CONCAT('Q ', fn_ConvertirMonedaTasaFija(@monto, @tasa)) AS 'Monto Convertido';

-- Ejemplo 20.
SET @contrasenia = 'Segura$123!';
SELECT fn_ValidarComplejidadContrasenia(@contrasenia) AS 'Resultado';