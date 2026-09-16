-- 1. Top 10 Productos Más Vendidos: Generar un ranking con los 10 productos que han generado más ingresos.
SELECT P.id_producto AS 'ID Producto', P.sku AS 'SKU', P.nombre AS 'Nombre Producto', SUM(DV.cantidad)AS 'No. Unidades Vendidas', CONCAT('$ ', SUM(DV.cantidad * DV.precio_unitario_congelado)) AS 'Total Recaudado'
FROM Detalles_ventas DV
INNER JOIN Productos P ON P.id_producto = DV.producto_id                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
INNER JOIN Ventas V ON V.id_venta = DV.venta_id
WHERE V.estado_id IN (3,4)
GROUP BY P.id_producto, P.sku, P.nombre
ORDER BY SUM(DV.cantidad) DESC
LIMIT 10;
-- Nota: Se toman de los estados (Entregado y Enviado) ya que son datos reales de ventas
-- Mientras que los estado de Cancelado, Pendiente de Pago y Procesando no son ventas aseguradas.

-- 2. Productos con Bajas Ventas: Identificar los productos en el 10% inferior de ventas para considerar su descontinuación.
SELECT P.id_producto AS 'ID Producto', P.sku AS 'SKU', P.nombre AS 'Nombre Producto', 
	COALESCE(AVG(cantidad * 0.10), '0%') AS 'Promedio',
    COALESCE(SUM(DV.cantidad), 0) AS 'No. Unidades Vendidas', 
    CONCAT('$ ', FORMAT(COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0), 2)) AS 'Total Recaudado'
FROM Productos P
LEFT JOIN Detalles_ventas DV ON P.id_producto = DV.producto_id
LEFT JOIN Ventas V ON V.id_venta = DV.venta_id AND V.estado_id IN (3, 4)
GROUP BY P.id_producto, P.sku, P.nombre
HAVING COALESCE(SUM(DV.cantidad), 0) < (
    SELECT (AVG(cantidad) * 0.10) 
    FROM Detalles_ventas
)
ORDER BY `No. Unidades Vendidas` DESC;

-- 3. Clientes VIP: Listar los 5 clientes con el mayor valor de vida (LTV), basado en su gasto total histórico.
SELECT 	C.id_cliente AS 'ID Cliente', C.nombre AS 'Nombre', C.apellido AS 'Apellido',
		SUM(DV.cantidad) AS 'Total Productos adquiridos',
		CONCAT('$ ', SUM(DV.cantidad * DV.precio_unitario_congelado)) AS 'Total Gastado por el usuario'
FROM Detalles_ventas DV
INNER JOIN Ventas V ON V.id_venta = DV.venta_id AND V.estado_id IN (3, 4)
INNER JOIN Clientes C ON C.id_cliente =  V.cliente_id
GROUP BY C.id_cliente, C.nombre, C.apellido
ORDER BY SUM(DV.cantidad * DV.precio_unitario_congelado) DESC
LIMIT 5;
-- Nota: De la misma manera que en la primera consulta, se tomaron en cuenta los estados de entregado y enviado

-- 4. Análisis de Ventas Mensuales
SELECT YEAR(V.fecha_venta) AS 'Año', MONTH(V.fecha_venta) AS 'Num_Mes',
    DATE_FORMAT(V.fecha_venta, '%M') AS 'Mes',
    COALESCE(SUM(DV.cantidad), 0) AS 'Ventas Totales',
    CONCAT('$ ', FORMAT(COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0), 2)) AS 'Total Recaudado'
FROM Ventas V
INNER JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
WHERE V.estado_id IN (3, 4)
GROUP BY YEAR(V.fecha_venta), MONTH(V.fecha_venta), DATE_FORMAT(V.fecha_venta, '%M')
ORDER BY YEAR(V.fecha_venta) DESC, MONTH(V.fecha_venta) ASC;


-- 5. Crecimiento de Clientes 
SELECT sub.anio AS 'Año', sub.no_trimestre AS 'No. Trimestre', sub.nombre_trimestre AS 'Trimestre',
       COUNT(sub.id_cliente) AS 'No. Clientes'
FROM (
	SELECT C.id_cliente,
	       YEAR(fecha_registro) AS anio,
	       QUARTER(fecha_registro) AS no_trimestre,
		CASE QUARTER(fecha_registro)
			WHEN 1 THEN 'Primer Trimestre'
			WHEN 2 THEN 'Segundo Trimestre'
			WHEN 3 THEN 'Tercer Trimestre'
			WHEN 4 THEN 'Cuarto Trimestre'
        END AS nombre_trimestre
	FROM Clientes C
) AS sub
GROUP BY sub.anio, sub.no_trimestre, sub.nombre_trimestre
ORDER BY sub.anio ASC, sub.no_trimestre ASC;

-- 6. Tasa de Compra Repetida: Determinar qué porcentaje de clientes ha realizado más de una compra.
SELECT 
    CONCAT(
        ROUND(
            (
                SELECT COUNT(*) 
                FROM (
                    SELECT cliente_id 
                    FROM Ventas 
                    WHERE estado_id IN (3, 4) 
                    GROUP BY cliente_id 
                    HAVING COUNT(id_venta) > 1
                ) AS Recurrentes
            ) / COUNT(DISTINCT V.cliente_id) * 100, 
        2), 
        ' %'
    ) AS 'Tasa de Compra Repetida'
FROM Ventas V
WHERE V.estado_id IN (3, 4);

-- 7. Productos Comprados Juntos Frecuentemente: Identificar pares de productos que a menudo se compran en la misma transacción.
SELECT P1.nombre AS 'Producto 1', P2.nombre AS 'Producto 2', COUNT(V.id_venta) AS 'Frecuencia'
FROM Detalles_ventas DV1
INNER JOIN Detalles_ventas DV2 ON DV2.venta_id = DV1.venta_id
    AND DV1.producto_id < DV2.producto_id
INNER JOIN Ventas V ON V.id_venta = DV1.venta_id
INNER JOIN Productos P1 ON P1.id_producto = DV1.producto_id
INNER JOIN Productos P2 ON P2.id_producto = DV2.producto_id
WHERE V.estado_id IN (3, 4)
GROUP BY P1.nombre, P2.nombre
ORDER BY `Frecuencia` DESC;

-- 8. Rotación de Inventario: Calcular la tasa de rotación de stock para cada categoría de producto.
SELECT CT.id_categoria AS 'ID Categoría', CT.nombre AS 'Categoría',
    CONCAT('$ ', FORMAT(COALESCE(SUM(DV.cantidad * P.costo), 0), 2)) AS 'COGS (Costo de Ventas)',
    CONCAT('$ ', FORMAT(COALESCE(SUM(P.stock * P.costo), 0), 2)) AS 'Valor Inventario Actual',
    ROUND(COALESCE(SUM(DV.cantidad * P.costo), 0) / NULLIF(SUM(P.stock * P.costo), 0), 2) AS 'Tasa de Rotación'
FROM Categorias CT
LEFT JOIN Productos P ON P.categoria_id = CT.id_categoria
LEFT JOIN Detalles_ventas DV ON DV.producto_id = P.id_producto
LEFT JOIN Ventas V ON V.id_venta = DV.venta_id AND V.estado_id IN (3, 4)
GROUP BY CT.id_categoria, CT.nombre
ORDER BY `Tasa de Rotación` DESC;
-- Nota: No se saca el promedio del inventario ya que solo se tinene un único número de inventario

-- 9. Productos que Necesitan Reabastecimiento: Listar productos cuyo stock actual está por debajo de su umbral mínimo.
SELECT P.id_producto AS 'ID Producto', P.nombre AS 'Nombre Producto', C.nombre AS 'Categoria', P.stock AS 'Stock Actual'
FROM Productos P
INNER JOIN Categorias C ON C.id_categoria = P.categoria_id
WHERE P.stock < 20
ORDER BY P.stock ASC;

-- 10. Análisis de Carrito Abandonado (Simulado): Identificar clientes que agregaron productos pero no completaron una venta en un período determinado.
SELECT V.cliente_id AS 'ID Cliente', CONCAT(C.nombre, ' ', C.apellido) AS 'Nombre Completo', COUNT(DV.producto_id) 'No. Productos abandonados'
FROM Ventas V
LEFT JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
INNER JOIN Clientes C ON C.id_cliente = V.cliente_id
WHERE V.estado_id = 1 
AND V.fecha_venta >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY V.cliente_id;
-- Nota: Para este caso si el estado se encuentra en que no se pago, se tomara como que el usuario dejo el producto en el carrito

-- 11. Rendimiento de Proveedores: Clasificar a los proveedores según el volumen de ventas de sus productos.
SELECT PR.id_proveedor AS 'ID Proveedor', PR.nombre AS 'Proveedor', COALESCE(SUM(DV.cantidad), 0) AS 'Vol. Ventas',
	CASE 
		WHEN COALESCE(SUM(DV.cantidad), 0) > 10 THEN 'Alta'
        ELSE 'Baja'
	END AS 'Clasificacion'
FROM Proveedores PR
LEFT JOIN Productos P ON P.proveedor_id = PR.id_proveedor
LEFT JOIN Detalles_ventas DV ON DV.producto_id = P.id_producto
LEFT JOIN Ventas V ON V.id_venta = DV.venta_id AND V.estado_id IN (3, 4)
GROUP BY PR.id_proveedor, PR.nombre
ORDER BY `Vol. Ventas` DESC;

-- 12. Análisis Geográfico de Ventas: Agrupar las ventas por ciudad o región del cliente.
SELECT PA.nombre AS 'País', R.nombre AS 'Región', CI.nombre AS 'Ciudad',
    COUNT(DISTINCT V.id_venta) AS 'No. Ventas',
    COALESCE(SUM(DV.cantidad), 0) AS 'Unidades Vendidas',
    CONCAT('$ ', FORMAT(COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0), 2)) AS 'Total Recaudado'
FROM Ventas V
INNER JOIN Direcciones_Envio DE ON DE.id_direccion = V.direccion_id
INNER JOIN Ciudades CI ON CI.id_ciudad = DE.ciudad_id
INNER JOIN Regiones R ON R.id_region = CI.region_id
INNER JOIN Paises PA ON PA.id_pais = R.pais_id
INNER JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
WHERE V.estado_id IN (3, 4)
GROUP BY PA.nombre, R.nombre, CI.nombre
ORDER BY SUM(DV.cantidad * DV.precio_unitario_congelado) DESC;
-- Nota: De la misma manera que en la primera consulta, se tomaron en cuenta los estados de entregado y enviado


-- 13. Ventas por Hora del Día: Determinar las horas pico de compras para optimizar campañas de marketing.
SELECT HOUR(V.fecha_venta) AS 'Hora del Día',
    COUNT(DISTINCT V.id_venta) AS 'No. Ventas',
    COALESCE(SUM(DV.cantidad), 0) AS 'Unidades Vendidas',
    CONCAT('$ ', FORMAT(COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0), 2)) AS 'Total Recaudado'
FROM Ventas V
INNER JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
WHERE V.estado_id IN (3, 4)
GROUP BY HOUR(V.fecha_venta)
ORDER BY COUNT(DISTINCT V.id_venta) DESC;


-- 14. Impacto de Promociones: Comparar las ventas de un producto antes, durante y después de una campaña de descuento.
SELECT PRM.nombre_promocion AS 'Promoción', P.nombre AS 'Producto',
    CASE 
        WHEN V.fecha_venta < PRM.fecha_inicio THEN 'Antes'
        WHEN V.fecha_venta BETWEEN PRM.fecha_inicio AND PRM.fecha_fin THEN 'Durante'
        ELSE 'Después'
    END AS 'Período',
    COALESCE(SUM(DV.cantidad), 0) AS 'Unidades Vendidas',
    CONCAT('$ ', FORMAT(COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0), 2)) AS 'Total Recaudado'
FROM Promociones PRM
INNER JOIN Productos P ON P.id_producto = PRM.producto_id
INNER JOIN Detalles_ventas DV ON DV.producto_id = PRM.producto_id
INNER JOIN Ventas V ON V.id_venta = DV.venta_id AND V.estado_id IN (3, 4)
GROUP BY PRM.nombre_promocion, P.nombre, `Período`
ORDER BY PRM.nombre_promocion, FIELD(`Período`, 'Antes', 'Durante', 'Después');


-- 15. Análisis de Cohort: Analizar la retención de clientes mes a mes desde su primera compra.
SELECT DATE_FORMAT(sub.mes_cohorte, '%Y-%m') AS 'Mes de Cohorte',
    PERIOD_DIFF(DATE_FORMAT(V.fecha_venta, '%Y%m') + 0, DATE_FORMAT(sub.mes_cohorte, '%Y%m') + 0) AS 'Meses Desde Primera Compra',
    COUNT(DISTINCT V.cliente_id) AS 'No. Clientes Activos'
FROM Ventas V
INNER JOIN (
    SELECT cliente_id, MIN(fecha_venta) AS mes_cohorte
    FROM Ventas
    WHERE estado_id IN (3, 4)
    GROUP BY cliente_id
) AS sub ON sub.cliente_id = V.cliente_id
WHERE V.estado_id IN (3, 4)
GROUP BY `Mes de Cohorte`, `Meses Desde Primera Compra`
ORDER BY `Mes de Cohorte` ASC, `Meses Desde Primera Compra` ASC;
-- Nota: El "mes de cohorte" es el mes de la primera compra confirmada del cliente. Se agrupa por ese mes
-- y por cuántos meses después ocurrió cada compra posterior, para ver cuántos clientes de cada cohorte siguen activos.


-- 16. Margen de Beneficio por Producto: Calcular el margen de beneficio para cada producto.
SELECT P.id_producto AS 'ID Producto', P.nombre AS 'Nombre Producto',
    CONCAT('$ ', FORMAT(P.precio, 2)) AS 'Precio de Venta',
    CONCAT('$ ', FORMAT(P.costo, 2)) AS 'Costo',
    CONCAT('$ ', FORMAT(P.precio - P.costo, 2)) AS 'Margen por Unidad',
    CONCAT(ROUND(((P.precio - P.costo) / P.precio) * 100, 2), ' %') AS 'Margen de Beneficio'
FROM Productos P
ORDER BY ((P.precio - P.costo) / P.precio) DESC;

-- 17. Tiempo Promedio Entre Compras: Calcular el tiempo medio que tarda un cliente en volver a comprar.
SELECT C.id_cliente AS 'ID Cliente', CONCAT(C.nombre, ' ', C.apellido) AS 'Nombre Completo',
    COUNT(V.id_venta) AS 'No. Compras',
    ROUND(AVG(DATEDIFF(V.fecha_venta, sub.fecha_anterior)), 2) AS 'Promedio de Días Entre Compras'
FROM Ventas V
INNER JOIN Clientes C ON C.id_cliente = V.cliente_id
INNER JOIN (
    SELECT V1.id_venta, V1.cliente_id,
        (SELECT MAX(V2.fecha_venta)
         FROM Ventas V2
         WHERE V2.cliente_id = V1.cliente_id
           AND V2.estado_id IN (3, 4)
           AND V2.fecha_venta < V1.fecha_venta) AS fecha_anterior
    FROM Ventas V1
    WHERE V1.estado_id IN (3, 4)
) AS sub ON sub.id_venta = V.id_venta
WHERE V.estado_id IN (3, 4)
  AND sub.fecha_anterior IS NOT NULL
GROUP BY C.id_cliente, C.nombre, C.apellido
ORDER BY `Promedio de Días Entre Compras` ASC;


-- 18. Productos Más Vistos vs. Comprados (Simulado): Comparar los productos más visitados con los más comprados.
SELECT P.id_producto AS 'ID Producto', P.nombre AS 'Nombre Producto',
    COALESCE(SUM(DV.cantidad), 0) AS 'No. Veces Agregado (Simulado Visto)',
    COALESCE(SUM(CASE WHEN V.estado_id IN (3, 4) THEN DV.cantidad ELSE 0 END), 0) AS 'No. Unidades Compradas'
FROM Productos P
LEFT JOIN Detalles_ventas DV ON DV.producto_id = P.id_producto
LEFT JOIN Ventas V ON V.id_venta = DV.venta_id
GROUP BY P.id_producto, P.nombre
ORDER BY `No. Veces Agregado (Simulado Visto)` DESC;


-- 19. Segmentación de Clientes (RFM): Clasificar a los clientes en segmentos (Recencia, Frecuencia, Monetario).
SELECT sub.id_cliente AS 'ID Cliente', sub.nombre_completo AS 'Nombre Completo',
    sub.recencia AS 'Recencia (Días)',
    sub.frecuencia AS 'Frecuencia (No. Compras)',
    CONCAT('$ ', FORMAT(sub.monetario, 2)) AS 'Monetario (Total Gastado)',
    CASE 
        WHEN sub.recencia <= 90 AND sub.frecuencia >= 3 AND sub.monetario >= 500 THEN 'Cliente VIP'
        WHEN sub.recencia <= 180 AND sub.frecuencia >= 2 THEN 'Cliente Frecuente'
        WHEN sub.recencia > 365 THEN 'Cliente Inactivo'
        ELSE 'Cliente Ocasional'
    END AS 'Segmento RFM'
FROM (
    SELECT C.id_cliente,
        CONCAT(C.nombre, ' ', C.apellido) AS nombre_completo,
        DATEDIFF(CURRENT_DATE(), MAX(V.fecha_venta)) AS recencia,
        COUNT(DISTINCT V.id_venta) AS frecuencia,
        COALESCE(SUM(DV.cantidad * DV.precio_unitario_congelado), 0) AS monetario
    FROM Clientes C
    INNER JOIN Ventas V ON V.cliente_id = C.id_cliente AND V.estado_id IN (3, 4)
    INNER JOIN Detalles_ventas DV ON DV.venta_id = V.id_venta
    GROUP BY C.id_cliente, C.nombre, C.apellido
) AS sub
ORDER BY sub.monetario DESC;


-- 20. Predicción de Demanda Simple: Utilizar datos de ventas pasadas para proyectar las ventas del próximo mes para una categoría específica.
SELECT CT.id_categoria AS 'ID Categoría', CT.nombre AS 'Categoría',
    ROUND(AVG(sub.unidades_mes), 0) AS 'Proyección Próximo Mes (Unidades)'
FROM Categorias CT
INNER JOIN (
    SELECT P.categoria_id,
        YEAR(V.fecha_venta) AS anio,
        MONTH(V.fecha_venta) AS mes,
        SUM(DV.cantidad) AS unidades_mes
    FROM Detalles_ventas DV
    INNER JOIN Ventas V ON V.id_venta = DV.venta_id AND V.estado_id IN (3, 4)
    INNER JOIN Productos P ON P.id_producto = DV.producto_id
    GROUP BY P.categoria_id, YEAR(V.fecha_venta), MONTH(V.fecha_venta)
) AS sub ON sub.categoria_id = CT.id_categoria
GROUP BY CT.id_categoria, CT.nombre
ORDER BY `Proyección Próximo Mes (Unidades)` DESC;
