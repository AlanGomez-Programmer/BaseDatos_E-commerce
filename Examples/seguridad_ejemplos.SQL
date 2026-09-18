-- Ejemplo 13. (vista de clientes básica)
SELECT * FROM v_info_clientes_basica;

-- Ejemplo de verificación general (usuarios bloqueados, si los hubiera):
SELECT user, host FROM mysql.user WHERE account_locked = 'Y';

-- Ejemplo 16. (verificar que no exista root remoto antes de dropearlo)
SELECT user, host FROM mysql.user WHERE user = 'root';

-- Ejemplo 19. (ver cada vista de sucursal)
SELECT * FROM v_ventas_sucursal_guatemala_central;
SELECT * FROM v_ventas_sucursal_antigua;
SELECT * FROM v_ventas_sucursal_bogota;

-- Ejemplo general de verificación de permisos otorgados:
SHOW GRANTS FOR 'inventory_user'@'localhost';
SHOW GRANTS FOR 'data_analyst_user'@'localhost';