-- Ejemplo 1.
CALL sp_RealizarNuevaVenta(1, 1, 2, 1);

-- Ejemplo 2.
CALL sp_AgregarNuevoProducto(1, 1, 'Cargador Rapido USB-C', 'Cargador 65W', 25.00, 12.00, 0.30, 50, 'Pasillo A, Estante 5');

-- Ejemplo 3.
CALL sp_ActualizarDireccionCliente(1, 3, 'Nueva direccion de prueba 5-55, Zona 3');
SELECT * FROM direcciones_clientes WHERE cliente_id = 1;

-- Ejemplo 4.
CALL sp_ProcesarDevolucion(1, 2, 1, 'Producto llego con empaque dañado');
SELECT * FROM devoluciones ORDER BY id_devolucion DESC LIMIT 1;

-- Ejemplo 5.
CALL sp_ObtenerHistorialComprasCliente(4);

-- Ejemplo 6.
CALL sp_AjustarNivelStock(5, 40, 'Conteo fisico de inventario', 'admin_user');
SELECT * FROM log_ajustes_stock ORDER BY id_log DESC LIMIT 1;

-- Ejemplo 7.
CALL sp_EliminarClienteDeFormaSegura(54);
SELECT id_cliente, nombre, apellido, email, activo FROM Clientes WHERE id_cliente = 54;

-- Ejemplo 8.
SELECT nombre, precio FROM Productos WHERE categoria_id = 2;
CALL sp_AplicarDescuentoPorCategoria(2, 10.00);
SELECT nombre, precio FROM Productos WHERE categoria_id = 2;

-- Ejemplo 9.
CALL sp_GenerarReporteMensualVentas(2026, 8);

-- Ejemplo 10.
CALL sp_CambiarEstadoPedido(9, 3);
SELECT * FROM auditoria_cambio_estado_venta ORDER BY id_auditoria DESC;

-- Ejemplo 11.
CALL sp_RegistrarNuevoCliente('Marco', 'Ruiz', 'marco.ruiz.test@email.com', 'Clave123$', '1995-05-10');

-- Ejemplo 12.
CALL sp_ObtenerDetallesProductoCompleto(1);

-- Ejemplo 14.
CALL sp_AsignarProductoAProveedor(1, 2);
SELECT id_producto, proveedor_id FROM Productos WHERE id_producto = 1;

-- Ejemplo 15.
CALL sp_BuscarProductos('Mouse', NULL, NULL, NULL);
CALL sp_BuscarProductos(NULL, 1, 50, 500);

-- Ejemplo 16.
CALL sp_ObtenerDashboardAdmin();

-- Ejemplo 17.
CALL sp_ProcesarPago(29);
SELECT id_venta, estado_id FROM Ventas WHERE id_venta = 29;

-- Ejemplo 18.
CALL sp_AnadirResenaProducto(4, 1, 5, 'Excelente laptop, muy rapida');
SELECT * FROM resenas;

-- Ejemplo 19.
CALL sp_ObtenerProductosRelacionados(2);