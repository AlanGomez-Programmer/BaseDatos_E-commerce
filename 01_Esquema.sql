DROP DATABASE IF EXISTS E_commerce;
CREATE DATABASE E_commerce;
USE E_commerce;

-- SECCIÓN 1: GEOGRAFÍA (Paises -> Regiones -> Ciudades)

CREATE TABLE Paises(
    id_pais INT AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    PRIMARY KEY (id_pais)
);

CREATE TABLE Regiones(
    id_region INT AUTO_INCREMENT,
    pais_id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_region),
    FOREIGN KEY (pais_id) REFERENCES Paises(id_pais),
    UNIQUE KEY uq_region_pais (pais_id, nombre)
);

CREATE TABLE Ciudades(
    id_ciudad INT AUTO_INCREMENT,
    region_id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_ciudad),
    FOREIGN KEY (region_id) REFERENCES Regiones(id_region),
    UNIQUE KEY uq_ciudad_region (region_id, nombre)
);

-- SECCIÓN 2: CATÁLOGO (Categorias, Proveedores, Productos)

CREATE TABLE Categorias(
    id_categoria INT AUTO_INCREMENT,
    nombre VARCHAR(75) UNIQUE NOT NULL,
    descripcion VARCHAR(200),
    num_productos INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id_categoria)
);

CREATE TABLE Proveedores(
    id_proveedor INT AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    email_contacto VARCHAR(320) UNIQUE NOT NULL,
    telefono_contacto VARCHAR(15) NOT NULL,
    PRIMARY KEY (id_proveedor)
);

CREATE TABLE Productos(
    id_producto INT AUTO_INCREMENT,
    categoria_id INT NOT NULL,
    proveedor_id INT NOT NULL,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(200),
    precio DECIMAL(10, 2) NOT NULL CHECK(precio > 0),
    costo DECIMAL(10, 2) NOT NULL CHECK(costo >= 0),
    peso_lb DECIMAL(6, 2) NOT NULL DEFAULT 0 CHECK (peso_lb >= 0),
    stock INT NOT NULL CHECK(stock >= 0) DEFAULT 0,
    ubicacion VARCHAR(100),
    sku VARCHAR(12) NOT NULL UNIQUE,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME NULL,
    activo TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (id_producto),
    FOREIGN KEY (categoria_id) REFERENCES Categorias(id_categoria),
    FOREIGN KEY (proveedor_id) REFERENCES Proveedores(id_proveedor)
);

-- SECCIÓN 3: CLIENTES Y SUS DIRECCIONES

CREATE TABLE Clientes(
    id_cliente INT AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(320) UNIQUE NOT NULL,
    contrasenia VARCHAR(255) NOT NULL,
    fecha_nacimiento DATE NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_gastado DECIMAL(10, 2) NOT NULL DEFAULT 0,
    fecha_ultimo_pedido DATE NULL,
    nivel_lealtad VARCHAR(10) NOT NULL DEFAULT 'Bronce',
    activo TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (id_cliente)
);

CREATE TABLE direcciones_clientes(
    id_direccion INT AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    ciudad_id INT NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    es_principal TINYINT NOT NULL DEFAULT 1,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_direccion),
    FOREIGN KEY (cliente_id) REFERENCES Clientes(id_cliente),
    FOREIGN KEY (ciudad_id) REFERENCES Ciudades(id_ciudad)
);

-- SECCIÓN 4: SUCURSALES Y SUS DIRECCIONES

CREATE TABLE Sucursales(
    id_sucursal INT AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    PRIMARY KEY (id_sucursal)
);

CREATE TABLE direcciones_sucursales(
    id_direccion INT AUTO_INCREMENT,
    sucursal_id INT NOT NULL,
    ciudad_id INT NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    PRIMARY KEY (id_direccion),
    FOREIGN KEY (sucursal_id) REFERENCES Sucursales(id_sucursal),
    FOREIGN KEY (ciudad_id) REFERENCES Ciudades(id_ciudad)
);

-- SECCIÓN 5: VENTAS

CREATE TABLE Estados(
    id_estado INT AUTO_INCREMENT,
    nombre_estado VARCHAR(25) NOT NULL,
    PRIMARY KEY (id_estado)
);

CREATE TABLE Ventas(
    id_venta INT AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    sucursal_id INT NOT NULL,
    fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado_id INT NOT NULL DEFAULT 1,
    total DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id_venta),
    FOREIGN KEY (cliente_id) REFERENCES Clientes(id_cliente),
    FOREIGN KEY (sucursal_id) REFERENCES Sucursales(id_sucursal),
    FOREIGN KEY (estado_id) REFERENCES Estados(id_estado)
);


CREATE TABLE Detalles_ventas(
    id_detalle INT AUTO_INCREMENT,
    venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT CHECK (cantidad > 0) NOT NULL,
    precio_unitario_congelado DECIMAL(10, 2) NOT NULL CHECK(precio_unitario_congelado >= 0),
    PRIMARY KEY (id_detalle),
    FOREIGN KEY (venta_id) REFERENCES Ventas(id_venta) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES Productos(id_producto)
);


CREATE TABLE Promociones(
    id_promocion INT AUTO_INCREMENT,
    producto_id INT NOT NULL,
    nombre_promocion VARCHAR(100) NOT NULL,
    descuento_pct DECIMAL(5,2) NOT NULL CHECK (descuento_pct > 0 AND descuento_pct <= 100),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    activa TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (id_promocion),
    FOREIGN KEY (producto_id) REFERENCES Productos(id_producto),
    CHECK (fecha_fin > fecha_inicio)
);

-- SECCIÓN 6: TABLAS DE LOG / AUDITORÍA

CREATE TABLE ventas_eliminadas(
    id_registro INT AUTO_INCREMENT,
    id_venta_original INT NOT NULL,
    cliente_id INT NOT NULL,
    sucursal_id INT NOT NULL,
    fecha_venta DATETIME NOT NULL,
    estado_id INT NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    fecha_eliminacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_registro)
);

CREATE TABLE detalles_ventas_eliminados(
    id_registro INT AUTO_INCREMENT,
    id_detalle_original INT NOT NULL,
    id_venta_original INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario_congelado DECIMAL(10, 2) NOT NULL,
    fecha_eliminacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_registro)
);

CREATE TABLE auditoria_precio_producto(
    id_auditoria INT AUTO_INCREMENT,
    producto_id INT NOT NULL,
    precio_anterior DECIMAL(10, 2) NOT NULL,
    precio_nuevo DECIMAL(10, 2) NOT NULL,
    usuario_modifico VARCHAR(100) NOT NULL,
    fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_auditoria)
);

CREATE TABLE auditoria_nuevo_cliente(
    id_auditoria INT AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    fecha_evento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_auditoria)
);

CREATE TABLE auditoria_cambio_estado_venta(
    id_auditoria INT AUTO_INCREMENT,
    venta_id INT NOT NULL,
    estado_anterior_id INT NOT NULL,
    estado_nuevo_id INT NOT NULL,
    fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_auditoria)
);

CREATE TABLE alertas_stock(
    id_alerta INT AUTO_INCREMENT,
    producto_id INT NOT NULL,
    stock_actual INT NOT NULL,
    fecha_alerta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atendida TINYINT NOT NULL DEFAULT 0,
    PRIMARY KEY (id_alerta)
);

CREATE TABLE referidos(
    id_referido INT AUTO_INCREMENT,
    cliente_referente_id INT NOT NULL,
    cliente_referido_id INT NOT NULL,
    fecha_referido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_referido)
);

CREATE TABLE auditoria_permisos(
    id_auditoria INT AUTO_INCREMENT,
    usuario_afectado VARCHAR(100) NOT NULL,
    accion VARCHAR(50) NOT NULL,
    detalle VARCHAR(255),
    usuario_ejecuto VARCHAR(100) NOT NULL,
    fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_auditoria)
);

CREATE TABLE auditoria_login_fallido(
    id_auditoria INT AUTO_INCREMENT,
    usuario_intento VARCHAR(100) NOT NULL,
    host_origen VARCHAR(255),
    fecha_intento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_auditoria)
);

CREATE TABLE resenas(
    id_resena INT AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    producto_id INT NOT NULL,
    calificacion TINYINT NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    comentario VARCHAR(500),
    fecha_resena DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_resena)
);

CREATE TABLE devoluciones(
    id_devolucion INT AUTO_INCREMENT,
    venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    motivo VARCHAR(255) NOT NULL,
    monto_credito DECIMAL(10, 2) NOT NULL,
    fecha_devolucion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_devolucion)
);

CREATE TABLE log_ajustes_stock(
    id_log INT AUTO_INCREMENT,
    producto_id INT NOT NULL,
    stock_anterior INT NOT NULL,
    stock_nuevo INT NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    usuario_ejecuto VARCHAR(100) NOT NULL,
    fecha_ajuste DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_log)
);

CREATE TABLE log_inconsistencias(
    id_log INT AUTO_INCREMENT,
    descripcion VARCHAR(255) NOT NULL,
    referencia_id INT,
    fecha_deteccion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_log)
);

CREATE TABLE cupones_cumpleanos(
    id_cupon INT AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    codigo_cupon VARCHAR(30) NOT NULL,
    fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cupon)
);

-- SECCIÓN 7: TABLAS DE REPORTES (Eventos Programados)

CREATE TABLE reportes_semanales(
    id_reporte INT AUTO_INCREMENT,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    total_ventas INT NOT NULL,
    monto_recaudado DECIMAL(12, 2) NOT NULL,
    fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_reporte)
);

CREATE TABLE resumen_ventas_diario(
    id_resumen INT AUTO_INCREMENT,
    fecha DATE NOT NULL UNIQUE,
    total_ventas INT NOT NULL,
    unidades_vendidas INT NOT NULL,
    monto_recaudado DECIMAL(12, 2) NOT NULL,
    fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_resumen)
);

CREATE TABLE kpis_mensuales(
    id_kpi INT AUTO_INCREMENT,
    anio INT NOT NULL,
    mes INT NOT NULL,
    total_ventas INT NOT NULL,
    monto_recaudado DECIMAL(12, 2) NOT NULL,
    nuevos_clientes INT NOT NULL,
    ticket_promedio DECIMAL(10, 2) NOT NULL,
    fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_kpi),
    UNIQUE KEY uq_kpi_anio_mes (anio, mes)
);

CREATE TABLE ranking_productos(
    id_ranking INT AUTO_INCREMENT,
    nombre_producto VARCHAR(50) NOT NULL, 
    posicion INT NOT NULL,
    unidades_vendidas INT NOT NULL,
    fecha_calculo DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_ranking)
);

CREATE TABLE log_tamano_bd(
    id_log INT AUTO_INCREMENT,
    tamano_mb DECIMAL(10, 2) NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_log)
);

CREATE TABLE alertas_fraude(
    id_alerta INT AUTO_INCREMENT,
    cliente_id INT NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    fecha_deteccion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revisada TINYINT NOT NULL DEFAULT 0,
    PRIMARY KEY (id_alerta)
);

CREATE TABLE reportes_proveedores(
    id_reporte INT AUTO_INCREMENT,
    nombre_proveedor VARCHAR(50) NOT NULL,
    anio INT NOT NULL,
    mes INT NOT NULL,
    unidades_vendidas INT NOT NULL,
    monto_generado DECIMAL(12, 2) NOT NULL,
    fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_reporte)
);