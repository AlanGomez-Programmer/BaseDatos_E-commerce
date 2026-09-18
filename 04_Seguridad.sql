-- Vista requerida por el item 13, necesaria antes del rol Atencion_Cliente.
CREATE VIEW v_info_clientes_basica AS
SELECT id_cliente, nombre, apellido, nivel_lealtad, activo
FROM Clientes;
-- Nota: se excluyen email, contrasenia, fecha_nacimiento y total_gastado,
-- que son los datos sensibles de un cliente.

-- 1. Crear el rol Administrador_Sistema con todos los privilegios.
CREATE ROLE IF NOT EXISTS 'Administrador_Sistema';
GRANT ALL PRIVILEGES ON E_commerce.* TO 'Administrador_Sistema';

-- 2. Crear el rol Gerente_Marketing con acceso de solo lectura a ventas y clientes.
CREATE ROLE 'Gerente_Marketing';
GRANT SELECT ON E_commerce.Ventas TO 'Gerente_Marketing';
GRANT SELECT ON E_commerce.Detalles_ventas TO 'Gerente_Marketing';
GRANT SELECT ON E_commerce.Clientes TO 'Gerente_Marketing';

-- 3. Crear el rol Analista_Datos con acceso de solo lectura a todas las
--    tablas, excepto a las de auditoría.
CREATE ROLE 'Analista_Datos';
GRANT SELECT ON E_commerce.* TO 'Analista_Datos';
REVOKE SELECT ON E_commerce.auditoria_precio_producto FROM 'Analista_Datos';
REVOKE SELECT ON E_commerce.auditoria_nuevo_cliente FROM 'Analista_Datos';
REVOKE SELECT ON E_commerce.auditoria_cambio_estado_venta FROM 'Analista_Datos';
REVOKE SELECT ON E_commerce.auditoria_permisos FROM 'Analista_Datos';
REVOKE SELECT ON E_commerce.auditoria_login_fallido FROM 'Analista_Datos';

-- 4. Crear el rol Empleado_Inventario que solo pueda modificar la tabla
--    productos (stock y ubicación).
CREATE ROLE 'Empleado_Inventario';
GRANT SELECT ON E_commerce.Productos TO 'Empleado_Inventario';
GRANT UPDATE (stock, ubicacion) ON E_commerce.Productos TO 'Empleado_Inventario';

-- 5. Crear el rol Atencion_Cliente que pueda ver clientes y ventas, pero
--    no modificar precios.
CREATE ROLE 'Atencion_Cliente';
GRANT SELECT ON E_commerce.v_info_clientes_basica TO 'Atencion_Cliente';
GRANT SELECT ON E_commerce.Ventas TO 'Atencion_Cliente';
GRANT SELECT ON E_commerce.Detalles_ventas TO 'Atencion_Cliente';
GRANT SELECT ON E_commerce.Productos TO 'Atencion_Cliente';

-- 6. Crear el rol Auditor_Financiero con acceso de solo lectura a ventas,
--    productos y logs de precios.
CREATE ROLE 'Auditor_Financiero';
GRANT SELECT ON E_commerce.Ventas TO 'Auditor_Financiero';
GRANT SELECT ON E_commerce.Detalles_ventas TO 'Auditor_Financiero';
GRANT SELECT ON E_commerce.Productos TO 'Auditor_Financiero';
GRANT SELECT ON E_commerce.auditoria_precio_producto TO 'Auditor_Financiero';

-- 17. Crear un rol Visitante que solo pueda ver la tabla productos.
CREATE ROLE 'Visitante';
GRANT SELECT ON E_commerce.Productos TO 'Visitante';

-- 7. Crear un usuario admin_user y asignarle el rol de administrador.
CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'Admin$2026Seguro';
-- 8. Crear un usuario marketing_user y asignarle el rol de marketing.
CREATE USER 'marketing_user'@'localhost' IDENTIFIED BY 'Marketing$2026Seguro';
-- 9. Crear un usuario inventory_user y asignarle el rol de inventario.
CREATE USER 'inventory_user'@'localhost' IDENTIFIED BY 'Inventario$2026Seguro';
-- 10. Crear un usuario support_user y asignarle el rol de atención al cliente.
CREATE USER 'support_user'@'localhost' IDENTIFIED BY 'Soporte$2026Seguro';

-- Usuarios adicionales para poder probar los roles 3, 6 y 17 (no tenian
-- ningun usuario propio en la lista original), y para el item 18.
CREATE USER 'data_analyst_user'@'localhost' IDENTIFIED BY 'Analista$2026Seguro';
CREATE USER 'auditor_user'@'localhost' IDENTIFIED BY 'Auditor$2026Seguro';
CREATE USER 'visitor_user'@'localhost' IDENTIFIED BY 'Visitante$2026Seguro';

GRANT 'Administrador_Sistema' TO 'admin_user'@'localhost';
GRANT 'Gerente_Marketing' TO 'marketing_user'@'localhost';
GRANT 'Empleado_Inventario' TO 'inventory_user'@'localhost';
GRANT 'Atencion_Cliente' TO 'support_user'@'localhost';
GRANT 'Analista_Datos' TO 'data_analyst_user'@'localhost';
GRANT 'Auditor_Financiero' TO 'auditor_user'@'localhost';
GRANT 'Visitante' TO 'visitor_user'@'localhost';

-- Un rol otorgado con GRANT no se activa solo; cada usuario necesita que su
-- rol sea el rol por defecto al conectarse, o tendria que hacer "SET ROLE"
-- manualmente en cada sesion.
SET DEFAULT ROLE 'Administrador_Sistema' TO 'admin_user'@'localhost';
SET DEFAULT ROLE 'Gerente_Marketing' TO 'marketing_user'@'localhost';
SET DEFAULT ROLE 'Empleado_Inventario' TO 'inventory_user'@'localhost';
SET DEFAULT ROLE 'Atencion_Cliente' TO 'support_user'@'localhost';
SET DEFAULT ROLE 'Analista_Datos' TO 'data_analyst_user'@'localhost';
SET DEFAULT ROLE 'Auditor_Financiero' TO 'auditor_user'@'localhost';
SET DEFAULT ROLE 'Visitante' TO 'visitor_user'@'localhost';

-- 11. Impedir que el rol Analista_Datos pueda ejecutar comandos DELETE o TRUNCATE.
REVOKE DELETE, DROP ON E_commerce.* FROM 'Analista_Datos';

-- 12. Otorgar al rol Gerente_Marketing permiso para ejecutar procedimientos
--     almacenados de reportes de marketing.
GRANT EXECUTE ON PROCEDURE E_commerce.sp_GenerarReporteMensualVentas TO 'Gerente_Marketing';
GRANT EXECUTE ON PROCEDURE E_commerce.sp_ObtenerDashboardAdmin TO 'Gerente_Marketing';

-- 14. Revocar el permiso de UPDATE sobre la columna precio de la tabla
--     productos al rol Empleado_Inventario.
REVOKE UPDATE (precio) ON E_commerce.Productos FROM 'Empleado_Inventario';

-- 15. Implementar una política de contraseñas seguras para todos los usuarios.
SET GLOBAL validate_password.policy = 'STRONG';
SET GLOBAL validate_password.length = 12;
ALTER USER 'admin_user'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;
ALTER USER 'marketing_user'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;
ALTER USER 'inventory_user'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;
ALTER USER 'support_user'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;
ALTER USER 'data_analyst_user'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;
ALTER USER 'auditor_user'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;
ALTER USER 'visitor_user'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;

-- 16. Asegurar que el usuario root no pueda ser usado desde conexiones remotas.
DROP USER IF EXISTS 'root'@'%';

-- 18. Limitar el número de consultas por hora para el rol Analista_Datos
--     para evitar sobrecarga.
-- Nota: MySQL no permite asociar limites de recursos a un ROLE, solo a un
-- USER individual, por eso se aplica directo al usuario que tiene ese rol.
ALTER USER 'data_analyst_user'@'localhost' WITH MAX_QUERIES_PER_HOUR 100;

-- 19. Asegurar que los usuarios solo puedan ver las ventas de la sucursal
--     a la que pertenecen.
-- CORRECCIÓN: se quitó un "}" suelto que quedó después del primer CREATE VIEW.
CREATE VIEW v_ventas_sucursal_guatemala_central AS
SELECT * FROM Ventas WHERE sucursal_id = 1;

CREATE VIEW v_ventas_sucursal_antigua AS
SELECT * FROM Ventas WHERE sucursal_id = 2;

CREATE VIEW v_ventas_sucursal_bogota AS
SELECT * FROM Ventas WHERE sucursal_id = 3;