-- Esteban E. Arias Garzón.
-- Script Completo.


DROP DATABASE IF EXISTS auto_factory;

CREATE DATABASE auto_factory;

USE auto_factory;


-- =====================================================
-- 1. MODELO DE VEHÍCULO

CREATE TABLE modelo_vehiculo
(
    ID_mod INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(20) NOT NULL,
    versiones_dispon VARCHAR(255) NOT NULL,
    especificaciones TEXT NOT NULL,
    tiempo_ensamblaje DECIMAL(6,2) NOT NULL
);


-- =====================================================
-- 2. LÍNEA DE PRODUCCIÓN

CREATE TABLE linea_produccion
(
    ID_linea INT PRIMARY KEY,
    numero_linea INT NOT NULL UNIQUE,
    tipo_vehiculo VARCHAR(30) NOT NULL,
    capacidad_diaria INT NOT NULL,
    numero_estaciones INT NOT NULL,
    supervisor VARCHAR(100) NOT NULL,
    turno_activo VARCHAR(30) NOT NULL,
    estado_operativo VARCHAR(30) NOT NULL
);


-- =====================================================
-- 3. ESTACIÓN DE TRABAJO

CREATE TABLE estacion_trabajo
(
    ID_estacion INT PRIMARY KEY,
    ID_linea INT NOT NULL,
    codigo_estacion VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    descripcion_operaciones TEXT NOT NULL,
    herramientas_requeridas TEXT NOT NULL,
    tiempo_operacion DECIMAL(6,2) NOT NULL,
    operarios_asignados INT NOT NULL,

    FOREIGN KEY (ID_linea)
        REFERENCES linea_produccion(ID_linea)
        ON DELETE CASCADE
);


-- =====================================================
-- 4. PROVEEDOR

CREATE TABLE proveedor
(
    ID_proveedor INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(100),
    direccion VARCHAR(150)
);


-- =====================================================
-- 5. COMPONENTE

CREATE TABLE componente
(
    ID_componente INT PRIMARY KEY,
    codigo_componente VARCHAR(30) NOT NULL UNIQUE,
    descripcion VARCHAR(255) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    especificaciones_tecnicas TEXT NOT NULL,
    ID_proveedor INT NOT NULL,
    tiempo_entrega_promedio DECIMAL(6,2) NOT NULL,
    costo_unitario DECIMAL(12,2) NOT NULL,
    stock_minimo INT NOT NULL,

    FOREIGN KEY (ID_proveedor)
        REFERENCES proveedor(ID_proveedor)
);


-- =====================================================
-- 6. INVENTARIO

CREATE TABLE inventario
(
    ID_inventario INT PRIMARY KEY,
    ID_componente INT NOT NULL,
    cantidad_disponible INT NOT NULL,
    ubicacion_almacen VARCHAR(100) NOT NULL,
    fecha_ultima_entrada DATE NOT NULL,
    calidad VARCHAR(20) NOT NULL,

    FOREIGN KEY (ID_componente)
        REFERENCES componente(ID_componente)
        ON DELETE CASCADE
);


-- =====================================================
-- 7. RELACIÓN MODELO-COMPONENTE

CREATE TABLE modelo_componente
(
    ID_mod INT NOT NULL,
    ID_componente INT NOT NULL,
    cantidad_requerida INT NOT NULL,

    PRIMARY KEY (ID_mod, ID_componente),

    FOREIGN KEY (ID_mod)
        REFERENCES modelo_vehiculo(ID_mod)
        ON DELETE CASCADE,

    FOREIGN KEY (ID_componente)
        REFERENCES componente(ID_componente)
        ON DELETE CASCADE
);


-- =====================================================
-- 8. VEHÍCULO FABRICADO

CREATE TABLE vehiculo
(
    ID_vehiculo INT PRIMARY KEY,
    ID_mod INT NOT NULL,
    ID_linea INT NOT NULL,
    codigo_vehiculo VARCHAR(30) NOT NULL UNIQUE,
    fecha_fabricacion DATE NOT NULL,
    tiempo_produccion DECIMAL(6,2) NOT NULL,

    FOREIGN KEY (ID_mod)
        REFERENCES modelo_vehiculo(ID_mod),

    FOREIGN KEY (ID_linea)
        REFERENCES linea_produccion(ID_linea)
);


-- =====================================================
-- 9. EMPLEADO

CREATE TABLE empleado
(
    ID_empleado INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    habilidades TEXT NOT NULL
);

-- =====================================================
-- 10. ASIGNACIÓN A ESTACIONES

CREATE TABLE asignacion_estacion
(
    ID_asignacion INT PRIMARY KEY,
    ID_empleado INT NOT NULL,
    ID_estacion INT NOT NULL,
    fecha_asignacion DATE NOT NULL,
    estado VARCHAR(20) NOT NULL,

    FOREIGN KEY (ID_empleado)
        REFERENCES empleado(ID_empleado),

    FOREIGN KEY (ID_estacion)
        REFERENCES estacion_trabajo(ID_estacion)
);

-- =====================================================
-- 11. CONTROL DE CALIDAD

CREATE TABLE control_calidad
(
    ID_control INT PRIMARY KEY,
    ID_vehiculo INT NOT NULL,
    ID_estacion INT NOT NULL,
    ID_inspector INT NOT NULL,
    fecha_control DATE NOT NULL,
    resultado VARCHAR(20) NOT NULL,
    numero_defectos INT NOT NULL,

    FOREIGN KEY (ID_vehiculo)
        REFERENCES vehiculo(ID_vehiculo),

    FOREIGN KEY (ID_estacion)
        REFERENCES estacion_trabajo(ID_estacion),

    FOREIGN KEY (ID_inspector)
        REFERENCES empleado(ID_empleado)
);

-- =====================================================
-- 12. ORDEN DE COMPRA

CREATE TABLE orden_compra
(
    ID_orden INT PRIMARY KEY,
    ID_proveedor INT NOT NULL,
    ID_componente INT NOT NULL,
    cantidad INT NOT NULL,
    fecha_orden DATE NOT NULL,
    fecha_entrega_estimada DATE NOT NULL,
    estado VARCHAR(20) NOT NULL,

    FOREIGN KEY (ID_proveedor)
        REFERENCES proveedor(ID_proveedor),

    FOREIGN KEY (ID_componente)
        REFERENCES componente(ID_componente)
);

-- =====================================================
-- INSERTS: MODELOS DE VEHÍCULOS

INSERT INTO modelo_vehiculo
VALUES
(1, 'ECO Sedan 1.6', 'Sedan', 'Base, Comfort, Premium',
 'Motor 1.6L, 120 HP, transmisión manual', 8.50),

(2, 'ECO Sedan 2.0', 'Sedan', 'Comfort, Premium',
 'Motor 2.0L, 150 HP, transmisión automática', 9.20),

(3, 'Urban SUV 1.5', 'SUV', 'Base, Comfort, Premium',
 'Motor 1.5L Turbo, 160 HP', 10.00),

(4, 'Urban SUV 2.0', 'SUV', 'Comfort, Premium',
 'Motor 2.0L Turbo, 190 HP, tracción integral', 11.50),

(5, 'Max SUV 2.5', 'SUV', 'Premium, Limited',
 'Motor 2.5L, 200 HP', 12.00),

(6, 'Work Pickup 2.0', 'Pickup', 'Base, Work, Premium',
 'Motor 2.0L Turbo Diesel, 180 HP, 4x4', 10.80),

(7, 'Work Pickup 2.5', 'Pickup', 'Work, Premium',
 'Motor 2.5L Turbo Diesel, 210 HP', 11.30),

(8, 'Sport Sedan 2.0', 'Sedan', 'Sport, Premium',
 'Motor 2.0L Turbo, 220 HP', 9.80);

-- =====================================================
-- INSERTS: LÍNEAS DE PRODUCCIÓN

INSERT INTO linea_produccion
VALUES
(1, 101, 'Sedan', 50, 2, 'Carlos Ramírez', 'Mañana', 'Activa'),
(2, 102, 'SUV', 40, 2, 'Laura Gómez', 'Tarde', 'Activa'),
(3, 103, 'Pickup', 30, 2, 'Andrés Torres', 'Noche', 'Activa');

-- =====================================================
-- INSERTS: ESTACIONES DE TRABAJO


INSERT INTO estacion_trabajo
VALUES
(1, 1, 'EST-001', 'Montaje de motor',
 'Instalación del motor', 'Grúa, llaves dinamométricas', 2.50, 3),

(2, 1, 'EST-002', 'Pintura',
 'Pintura y acabado de carrocería', 'Pistolas de pintura', 3.00, 2),

(3, 2, 'EST-003', 'Ensamblaje SUV',
 'Ensamblaje general de SUV', 'Herramientas neumáticas', 3.50, 4),

(4, 2, 'EST-004', 'Control final SUV',
 'Inspección final de SUV', 'Escáner, herramientas de medición', 1.50, 2),

(5, 3, 'EST-005', 'Montaje Pickup',
 'Montaje de componentes de pickup', 'Grúa, llaves', 3.20, 3),

(6, 3, 'EST-006', 'Inspección Pickup',
 'Inspección final de pickup', 'Escáner de diagnóstico', 1.80, 0);

-- =====================================================
-- INSERTS: PROVEEDORES

INSERT INTO proveedor
VALUES
(1, 'TecnoMotores SAS', '6041111111', 'ventas@tecnomotores.com', 'Medellín'),
(2, 'Frenos Colombia', '6042222222', 'ventas@frenoscol.com', 'Envigado'),
(3, 'ElectroAuto SAS', '6043333333', 'contacto@electroauto.com', 'Itagüí'),
(4, 'Ruedas del Valle', '6044444444', 'ventas@ruedasvalle.com', 'Cali'),
(5, 'Carrocerías Andinas', '6045555555', 'info@carrocerias.com', 'Bogotá'),
(6, 'Filtros Industriales', '6046666666', 'ventas@filtros.com', 'Rionegro');

-- =====================================================
-- INSERTS: COMPONENTES

INSERT INTO componente
VALUES
(1, 'COMP-001', 'Sistema de frenos', 'Seguridad',
 'Sistema de frenos ABS', 2, 5.00, 850000, 20),

(2, 'COMP-002', 'Motor estándar', 'Motor',
 'Motor de combustión', 1, 10.00, 4500000, 10),

(3, 'COMP-003', 'Batería', 'Eléctrico',
 'Batería automotriz de 12V', 3, 4.00, 350000, 15),

(4, 'COMP-004', 'Juego de llantas', 'Rodamiento',
 'Llantas radiales', 4, 6.00, 1200000, 20),

(5, 'COMP-005', 'Carrocería', 'Estructura',
 'Estructura metálica', 5, 12.00, 3200000, 8),

(6, 'COMP-006', 'Filtro de aire', 'Filtración',
 'Filtro de aire automotriz', 6, 3.00, 80000, 30);

-- =====================================================
-- INSERTS: INVENTARIO

INSERT INTO inventario
VALUES
(1, 1, 100, 'A-01', CURDATE() - INTERVAL 5 DAY, 'Aprobado'),
(2, 2, 30, 'A-02', CURDATE() - INTERVAL 8 DAY, 'Aprobado'),
(3, 3, 80, 'B-01', CURDATE() - INTERVAL 3 DAY, 'Aprobado'),
(4, 4, 60, 'B-02', CURDATE() - INTERVAL 4 DAY, 'Aprobado'),
(5, 5, 20, 'C-01', CURDATE() - INTERVAL 6 DAY, 'En revisión'),
(6, 6, 150, 'C-02', CURDATE() - INTERVAL 2 DAY, 'Aprobado');

-- =====================================================
-- INSERTS: MODELOS Y COMPONENTES
-- El sistema de frenos se usa en los 8 modelos.

INSERT INTO modelo_componente
VALUES
(1, 1, 1), (2, 1, 1), (3, 1, 1), (4, 1, 1),
(5, 1, 1), (6, 1, 1), (7, 1, 1), (8, 1, 1),

(1, 2, 1), (2, 2, 1), (3, 2, 1), (4, 2, 1),
(5, 2, 1), (6, 2, 1), (7, 2, 1), (8, 2, 1),

(1, 3, 1), (2, 3, 1), (3, 3, 1), (4, 3, 1),
(5, 3, 1), (6, 3, 1), (7, 3, 1), (8, 3, 1),

(1, 4, 4), (2, 4, 4), (3, 4, 4), (4, 4, 4),
(5, 4, 4), (6, 4, 4), (7, 4, 4), (8, 4, 4),

(1, 5, 1), (2, 5, 1), (3, 5, 1), (4, 5, 1),
(5, 5, 1), (6, 5, 1), (7, 5, 1), (8, 5, 1),

(1, 6, 1), (2, 6, 1), (3, 6, 1), (4, 6, 1),
(5, 6, 1), (6, 6, 1), (7, 6, 1), (8, 6, 1);

-- =====================================================
-- INSERTS: VEHÍCULOS FABRICADOS
-- Las fechas permiten consultar el último mes.

INSERT INTO vehiculo
VALUES
(1, 1, 1, 'VEH-001', CURDATE() - INTERVAL 2 DAY, 8.20),
(2, 2, 1, 'VEH-002', CURDATE() - INTERVAL 5 DAY, 9.00),
(3, 8, 1, 'VEH-003', CURDATE() - INTERVAL 10 DAY, 9.50),
(4, 1, 1, 'VEH-004', CURDATE() - INTERVAL 15 DAY, 8.40),
(5, 2, 1, 'VEH-005', CURDATE() - INTERVAL 20 DAY, 9.40),

(6, 3, 2, 'VEH-006', CURDATE() - INTERVAL 3 DAY, 9.80),
(7, 4, 2, 'VEH-007', CURDATE() - INTERVAL 7 DAY, 11.00),
(8, 5, 2, 'VEH-008', CURDATE() - INTERVAL 12 DAY, 11.50),
(9, 3, 2, 'VEH-009', CURDATE() - INTERVAL 18 DAY, 10.20),
(10, 4, 2, 'VEH-010', CURDATE() - INTERVAL 25 DAY, 11.80),

(11, 6, 3, 'VEH-011', CURDATE() - INTERVAL 4 DAY, 10.50),
(12, 7, 3, 'VEH-012', CURDATE() - INTERVAL 9 DAY, 11.00),
(13, 6, 3, 'VEH-013', CURDATE() - INTERVAL 14 DAY, 10.70),
(14, 7, 3, 'VEH-014', CURDATE() - INTERVAL 22 DAY, 11.60),
(15, 6, 3, 'VEH-015', CURDATE() - INTERVAL 35 DAY, 12.00),
(16, 8, 1, 'VEH-016', CURDATE() - INTERVAL 1 DAY, 9.60);

-- =====================================================
-- INSERTS: EMPLEADOS

INSERT INTO empleado
VALUES
(1, 'Juan Pérez', 'Operario', 'Soldadura, ensamblaje'),
(2, 'María López', 'Operaria', 'Pintura, acabado'),
(3, 'Pedro Gómez', 'Operario', 'Mecánica, motores'),
(4, 'Ana Torres', 'Inspectora', 'Control de calidad, diagnóstico'),
(5, 'Luis Ramírez', 'Operario', 'Ensamblaje, electricidad'),
(6, 'Sofía Castro', 'Inspectora', 'Calidad, inspección'),
(7, 'Diego Martínez', 'Operario', 'Soldadura, carrocería');

-- =====================================================
-- INSERTS: ASIGNACIONES
-- La estación 6 no tiene asignaciones activas.

INSERT INTO asignacion_estacion
VALUES
(1, 1, 1, CURDATE() - INTERVAL 30 DAY, 'Activo'),
(2, 3, 1, CURDATE() - INTERVAL 20 DAY, 'Activo'),
(3, 2, 2, CURDATE() - INTERVAL 25 DAY, 'Activo'),
(4, 5, 3, CURDATE() - INTERVAL 15 DAY, 'Activo'),
(5, 4, 4, CURDATE() - INTERVAL 10 DAY, 'Activo'),
(6, 7, 5, CURDATE() - INTERVAL 12 DAY, 'Activo'),
(7, 1, 2, CURDATE() - INTERVAL 60 DAY, 'Inactivo');

-- =====================================================
-- INSERTS: CONTROLES DE CALIDAD

INSERT INTO control_calidad
VALUES
(1, 1, 1, 4, CURDATE() - INTERVAL 2 DAY, 'Aprobado', 0),
(2, 2, 2, 6, CURDATE() - INTERVAL 5 DAY, 'Aprobado', 0),
(3, 3, 1, 4, CURDATE() - INTERVAL 10 DAY, 'Rechazado', 2),
(4, 4, 2, 6, CURDATE() - INTERVAL 15 DAY, 'Aprobado', 0),
(5, 6, 3, 4, CURDATE() - INTERVAL 3 DAY, 'Aprobado', 0),
(6, 7, 4, 6, CURDATE() - INTERVAL 7 DAY, 'Rechazado', 1),
(7, 8, 4, 4, CURDATE() - INTERVAL 12 DAY, 'Aprobado', 0),
(8, 11, 5, 6, CURDATE() - INTERVAL 4 DAY, 'Aprobado', 0),
(9, 12, 6, 4, CURDATE() - INTERVAL 9 DAY, 'Aprobado', 0),
(10, 13, 5, 6, CURDATE() - INTERVAL 14 DAY, 'Rechazado', 3);

-- =====================================================
-- INSERTS: ÓRDENES DE COMPRA
-- Hay entregas previstas dentro de los próximos 15 días.

INSERT INTO orden_compra
VALUES
(1, 2, 1, 50, CURDATE() - INTERVAL 5 DAY,
 CURDATE() + INTERVAL 3 DAY, 'Pendiente'),

(2, 1, 2, 20, CURDATE() - INTERVAL 2 DAY,
 CURDATE() + INTERVAL 7 DAY, 'Pendiente'),

(3, 3, 3, 40, CURDATE() - INTERVAL 1 DAY,
 CURDATE() + INTERVAL 12 DAY, 'Pendiente'),

(4, 4, 4, 30, CURDATE() - INTERVAL 20 DAY,
 CURDATE() + INTERVAL 20 DAY, 'En tránsito'),

(5, 5, 5, 10, CURDATE() - INTERVAL 3 DAY,
 CURDATE() + INTERVAL 5 DAY, 'Pendiente'),

(6, 6, 6, 100, CURDATE() - INTERVAL 10 DAY,
 CURDATE() + INTERVAL 2 DAY, 'Pendiente');

-- 10 CONSULTAS:

-- 1. Vehículos de un modelo específico que pasaron control de calidad sin defectos.

SELECT
    v.codigo_vehiculo,
    m.nombre AS modelo,
    cc.resultado,
    cc.numero_defectos
FROM vehiculo v
INNER JOIN modelo_vehiculo m
    ON v.ID_mod = m.ID_mod
INNER JOIN control_calidad cc
    ON v.ID_vehiculo = cc.ID_vehiculo
WHERE m.nombre = 'ECO Sedan 1.6'
  AND cc.resultado = 'Aprobado'
  AND cc.numero_defectos = 0;

-- 2. Líneas de producción y vehículos fabricados durante el último mes.

SELECT
    lp.numero_linea,
    lp.tipo_vehiculo,
    v.codigo_vehiculo,
    v.fecha_fabricacion
FROM linea_produccion lp
LEFT JOIN vehiculo v
    ON lp.ID_linea = v.ID_linea
    AND v.fecha_fabricacion >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
ORDER BY v.fecha_fabricacion;

-- 3. Componentes utilizados en más de 5 modelos y cantidad total utilizada.

SELECT
    c.codigo_componente,
    c.descripcion,
    COUNT(DISTINCT mc.ID_mod) AS total_modelos,
    SUM(mc.cantidad_requerida) AS cantidad_total
FROM modelo_componente mc
RIGHT JOIN componente c
    ON mc.ID_componente = c.ID_componente
GROUP BY c.ID_componente, c.codigo_componente, c.descripcion
HAVING COUNT(DISTINCT mc.ID_mod) > 5;

-- 4. Controles de calidad realizados en un período específico.

SELECT
    cc.ID_control,
    v.codigo_vehiculo,
    m.nombre AS modelo,
    et.nombre AS estacion,
    e.nombre AS inspector,
    cc.fecha_control,
    cc.resultado
FROM control_calidad cc
INNER JOIN vehiculo v
    ON cc.ID_vehiculo = v.ID_vehiculo
INNER JOIN modelo_vehiculo m
    ON v.ID_mod = m.ID_mod
INNER JOIN estacion_trabajo et
    ON cc.ID_estacion = et.ID_estacion
INNER JOIN empleado e
    ON cc.ID_inspector = e.ID_empleado
WHERE cc.fecha_control BETWEEN DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                            AND CURDATE()
ORDER BY cc.fecha_control;

-- 5. Estaciones de trabajo que no tienen operadores actualmente asignados.

SELECT
    et.ID_estacion,
    et.codigo_estacion,
    et.nombre AS estacion,
    lp.numero_linea
FROM estacion_trabajo et
INNER JOIN linea_produccion lp
    ON et.ID_linea = lp.ID_linea
LEFT JOIN asignacion_estacion ae
    ON et.ID_estacion = ae.ID_estacion
    AND ae.estado = 'Activo'
WHERE ae.ID_asignacion IS NULL;

-- 6. Proveedores que suministran componentes para determinados modelos.

SELECT DISTINCT
    p.nombre AS proveedor,
    c.descripcion AS componente,
    m.nombre AS modelo
FROM proveedor p
INNER JOIN componente c
    ON p.ID_proveedor = c.ID_proveedor
INNER JOIN modelo_componente mc
    ON c.ID_componente = mc.ID_componente
INNER JOIN modelo_vehiculo m
    ON mc.ID_mod = m.ID_mod
WHERE m.nombre IN
(
    'ECO Sedan 1.6',
    'Urban SUV 1.5',
    'Work Pickup 2.0'
)
ORDER BY p.nombre;

-- 7. Tiempo promedio de producción por modelo y línea de producción.

SELECT
    m.nombre AS modelo,
    lp.numero_linea,
    AVG(v.tiempo_produccion) AS promedio_produccion
FROM vehiculo v
INNER JOIN modelo_vehiculo m
    ON v.ID_mod = m.ID_mod
INNER JOIN linea_produccion lp
    ON v.ID_linea = lp.ID_linea
GROUP BY m.ID_mod, m.nombre, lp.numero_linea
ORDER BY m.nombre;

-- 8. Empleados con determinada habilidad y estaciones donde están asignados.

SELECT
    e.nombre AS empleado,
    e.habilidades,
    et.nombre AS estacion,
    ae.estado
FROM empleado e
INNER JOIN asignacion_estacion ae
    ON e.ID_empleado = ae.ID_empleado
INNER JOIN estacion_trabajo et
    ON ae.ID_estacion = et.ID_estacion
WHERE e.habilidades LIKE '%Soldadura%'
  AND ae.estado = 'Activo';

-- 9. Modelos con tiempo de producción inferior al promedio de su categoría.

SELECT
    m.nombre AS modelo,
    m.categoria,
    AVG(v.tiempo_produccion) AS promedio_modelo
FROM modelo_vehiculo m
INNER JOIN vehiculo v
    ON m.ID_mod = v.ID_mod
GROUP BY m.ID_mod, m.nombre, m.categoria
HAVING AVG(v.tiempo_produccion) <
(
    SELECT AVG(v2.tiempo_produccion)
    FROM vehiculo v2
    INNER JOIN modelo_vehiculo m2
        ON v2.ID_mod = m2.ID_mod
    WHERE m2.categoria = m.categoria
);

-- 10. Órdenes de compra con componentes cuya entrega está prevista
-- para los próximos 15 días.

SELECT
    oc.ID_orden,
    c.descripcion AS componente,
    oc.cantidad,
    oc.fecha_entrega_estimada,
    p.nombre AS proveedor,
    p.telefono,
    oc.estado
FROM orden_compra oc
LEFT JOIN proveedor p
    ON oc.ID_proveedor = p.ID_proveedor
LEFT JOIN componente c
    ON oc.ID_componente = c.ID_componente
WHERE oc.fecha_entrega_estimada
      BETWEEN CURDATE()
      AND DATE_ADD(CURDATE(), INTERVAL 15 DAY)
ORDER BY oc.fecha_entrega_estimada;