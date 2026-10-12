-- ============================================================
-- AUTOFACTORY - ACTIVIDAD ASP-03-05
-- Implementación de 5 triggers y 5 funciones en MySQL 8+
-- Ejecutar DESPUÉS de crear la base de datos AutoFactory
-- y cargar las tablas/datos del módulo anterior.
-- Este archivo NO elimina ni recrea la base de datos.
-- ============================================================

USE auto_factory;

-- ------------------------------------------------------------
-- 1. ESTRUCTURAS AUXILIARES NECESARIAS PARA LA AUTOMATIZACIÓN
-- ------------------------------------------------------------

-- VIN: número de identificación único asignado al vehículo.
ALTER TABLE vehiculo
    ADD COLUMN VIN VARCHAR(30) NULL;

-- Un VIN debe ser único.
-- Ejecutar esta sección una sola vez sobre la base original.
CREATE UNIQUE INDEX uq_vehiculo_vin ON vehiculo (VIN);

-- Evaluación acumulada de proveedores a partir de controles de calidad.
CREATE TABLE IF NOT EXISTS evaluacion_proveedor (
    ID_proveedor INT PRIMARY KEY,
    total_controles INT NOT NULL DEFAULT 0,
    controles_aprobados INT NOT NULL DEFAULT 0,
    porcentaje_calidad DECIMAL(5,2) NOT NULL DEFAULT 0,
    fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_eval_proveedor
        FOREIGN KEY (ID_proveedor) REFERENCES proveedor(ID_proveedor)
);

-- Estadísticas acumuladas de producción por modelo y línea.
CREATE TABLE IF NOT EXISTS estadisticas_produccion (
    ID_mod INT NOT NULL,
    ID_linea INT NOT NULL,
    unidades_producidas INT NOT NULL DEFAULT 0,
    tiempo_total DECIMAL(12,2) NOT NULL DEFAULT 0,
    tiempo_promedio DECIMAL(8,2) NOT NULL DEFAULT 0,
    fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID_mod, ID_linea),
    FOREIGN KEY (ID_mod) REFERENCES modelo_vehiculo(ID_mod),
    FOREIGN KEY (ID_linea) REFERENCES linea_produccion(ID_linea)
);

-- Registro de tiempos reales de operación por estación.
CREATE TABLE IF NOT EXISTS registro_operacion (
    ID_registro INT AUTO_INCREMENT PRIMARY KEY,
    ID_estacion INT NOT NULL,
    fecha_operacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tiempo_real DECIMAL(8,2) NOT NULL,
    observaciones VARCHAR(255),
    FOREIGN KEY (ID_estacion) REFERENCES estacion_trabajo(ID_estacion),
    CHECK (tiempo_real >= 0)
);

-- Alertas de desviación de tiempos.
CREATE TABLE IF NOT EXISTS alerta_tiempo_estacion (
    ID_alerta INT AUTO_INCREMENT PRIMARY KEY,
    ID_registro INT NOT NULL,
    ID_estacion INT NOT NULL,
    tiempo_esperado DECIMAL(8,2) NOT NULL,
    tiempo_real DECIMAL(8,2) NOT NULL,
    desviacion DECIMAL(8,2) NOT NULL,
    fecha_alerta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ID_registro) REFERENCES registro_operacion(ID_registro),
    FOREIGN KEY (ID_estacion) REFERENCES estacion_trabajo(ID_estacion)
);

-- ------------------------------------------------------------
-- 2. TRIGGERS
-- ------------------------------------------------------------

DROP TRIGGER IF EXISTS TR_ActualizarInventarioComponentes;
DROP TRIGGER IF EXISTS TR_VerificarCalidadProveedores;
DROP TRIGGER IF EXISTS TR_ActualizarEstadisticasProduccion;
DROP TRIGGER IF EXISTS TR_ControlarTiemposEstaciones;
DROP TRIGGER IF EXISTS TR_AsignarVIN;

DELIMITER $$

-- Trigger 1:
-- Cuando una orden de compra cambia a "Recibida", suma su cantidad
-- al inventario. Solo se ejecuta en la transición hacia Recibida.
CREATE TRIGGER TR_ActualizarInventarioComponentes
AFTER UPDATE ON orden_compra
FOR EACH ROW
BEGIN
    IF NEW.estado = 'Recibida' AND OLD.estado <> 'Recibida' THEN
        IF EXISTS (
            SELECT 1 FROM inventario
            WHERE ID_componente = NEW.ID_componente
        ) THEN
            UPDATE inventario
            SET cantidad_disponible = cantidad_disponible + NEW.cantidad,
                fecha_ultima_entrada = CURDATE()
            WHERE ID_componente = NEW.ID_componente;
        ELSE
            INSERT INTO inventario
                (ID_inventario, ID_componente, cantidad_disponible,
                 ubicacion_almacen, fecha_ultima_entrada, calidad)
            VALUES (
                (SELECT COALESCE(MAX(i.ID_inventario), 0) + 1 FROM inventario i),
                NEW.ID_componente, NEW.cantidad,
                'Almacén principal', CURDATE(), 'Pendiente'
            );
        END IF;
    END IF;
END$$

-- Trigger 2:
-- Actualiza la evaluación de los proveedores de los componentes usados
-- por el modelo del vehículo que recibió el control de calidad.
CREATE TRIGGER TR_VerificarCalidadProveedores
AFTER INSERT ON control_calidad
FOR EACH ROW
BEGIN
    INSERT INTO evaluacion_proveedor
        (ID_proveedor, total_controles, controles_aprobados,
         porcentaje_calidad, fecha_actualizacion)
    SELECT DISTINCT
        c.ID_proveedor,
        1,
        IF(NEW.resultado = 'Aprobado', 1, 0),
        IF(NEW.resultado = 'Aprobado', 100.00, 0.00),
        NOW()
    FROM vehiculo v
    INNER JOIN modelo_componente mc ON mc.ID_mod = v.ID_mod
    INNER JOIN componente c ON c.ID_componente = mc.ID_componente
    WHERE v.ID_vehiculo = NEW.ID_vehiculo
    ON DUPLICATE KEY UPDATE
        total_controles = total_controles + 1,
        controles_aprobados = controles_aprobados +
            IF(NEW.resultado = 'Aprobado', 1, 0),
        porcentaje_calidad = ROUND(
            (controles_aprobados / total_controles) * 100, 2
        ),
        fecha_actualizacion = NOW();
END$$

-- Trigger 3:
-- Registra estadísticas al insertar un vehículo fabricado.
CREATE TRIGGER TR_ActualizarEstadisticasProduccion
AFTER INSERT ON vehiculo
FOR EACH ROW
BEGIN
    INSERT INTO estadisticas_produccion
        (ID_mod, ID_linea, unidades_producidas, tiempo_total,
         tiempo_promedio, fecha_actualizacion)
    VALUES
        (NEW.ID_mod, NEW.ID_linea, 1, NEW.tiempo_produccion,
         NEW.tiempo_produccion, NOW())
    ON DUPLICATE KEY UPDATE
        unidades_producidas = unidades_producidas + 1,
        tiempo_total = tiempo_total + NEW.tiempo_produccion,
        tiempo_promedio = ROUND(
            (tiempo_total + NEW.tiempo_produccion) /
            (unidades_producidas + 1), 2
        ),
        fecha_actualizacion = NOW();
END$$

-- Trigger 4:
-- Genera una alerta si el tiempo real supera en más de 20% el tiempo
-- configurado para la estación.
CREATE TRIGGER TR_ControlarTiemposEstaciones
AFTER INSERT ON registro_operacion
FOR EACH ROW
BEGIN
    DECLARE v_tiempo_esperado DECIMAL(8,2);

    SELECT tiempo_operacion
    INTO v_tiempo_esperado
    FROM estacion_trabajo
    WHERE ID_estacion = NEW.ID_estacion;

    IF NEW.tiempo_real > v_tiempo_esperado * 1.20 THEN
        INSERT INTO alerta_tiempo_estacion
            (ID_registro, ID_estacion, tiempo_esperado,
             tiempo_real, desviacion)
        VALUES
            (NEW.ID_registro, NEW.ID_estacion, v_tiempo_esperado,
             NEW.tiempo_real, ROUND(NEW.tiempo_real - v_tiempo_esperado, 2));
    END IF;
END$$

-- Trigger 5:
-- Asigna automáticamente un VIN si el vehículo se inserta sin uno.
CREATE TRIGGER TR_AsignarVIN
BEFORE INSERT ON vehiculo
FOR EACH ROW
BEGIN
    IF NEW.VIN IS NULL OR TRIM(NEW.VIN) = '' THEN
        SET NEW.VIN = CONCAT(
            'AF-', LPAD(NEW.ID_vehiculo, 8, '0'), '-',
            DATE_FORMAT(CURDATE(), '%y%m%d')
        );
    END IF;
END$$

DELIMITER ;

-- ------------------------------------------------------------
-- 3. FUNCIONES
-- ------------------------------------------------------------

DROP FUNCTION IF EXISTS FN_CalcularEficienciaLinea;
DROP FUNCTION IF EXISTS FN_EstimarTiempoProduccion;
DROP FUNCTION IF EXISTS FN_ObtenerDisponibilidadComponentes;
DROP FUNCTION IF EXISTS FN_CalcularCostoProduccionVehiculo;
DROP FUNCTION IF EXISTS FN_ObtenerIndicadoresCalidad;

DELIMITER $$

-- Función 1:
-- Calcula el porcentaje de la capacidad diaria usada por una línea,
-- según los vehículos fabricados hoy frente a su capacidad diaria.
CREATE FUNCTION FN_CalcularEficienciaLinea(p_ID_linea INT)
RETURNS DECIMAL(6,2)
READS SQL DATA
BEGIN
    DECLARE v_producidos INT DEFAULT 0;
    DECLARE v_capacidad INT DEFAULT 0;

    SELECT capacidad_diaria INTO v_capacidad
    FROM linea_produccion
    WHERE ID_linea = p_ID_linea;

    SELECT COUNT(*) INTO v_producidos
    FROM vehiculo
    WHERE ID_linea = p_ID_linea
      AND fecha_fabricacion = CURDATE();

    IF v_capacidad IS NULL OR v_capacidad = 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND((v_producidos / v_capacidad) * 100, 2);
END$$

-- Función 2:
-- Estima horas de producción para una cantidad de unidades de un modelo.
CREATE FUNCTION FN_EstimarTiempoProduccion(
    p_ID_mod INT,
    p_cantidad INT
)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_tiempo DECIMAL(6,2) DEFAULT 0;

    IF p_cantidad IS NULL OR p_cantidad < 0 THEN
        RETURN NULL;
    END IF;

    SELECT tiempo_ensamblaje INTO v_tiempo
    FROM modelo_vehiculo
    WHERE ID_mod = p_ID_mod;

    IF v_tiempo IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN ROUND(v_tiempo * p_cantidad, 2);
END$$

-- Función 3:
-- Devuelve "Disponible" si el stock alcanza para fabricar una unidad
-- del modelo; en caso contrario devuelve "Insuficiente".
CREATE FUNCTION FN_ObtenerDisponibilidadComponentes(p_ID_mod INT)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
    DECLARE v_faltantes INT DEFAULT 0;

    SELECT COUNT(*) INTO v_faltantes
    FROM modelo_componente mc
    LEFT JOIN (
        SELECT ID_componente, SUM(cantidad_disponible) AS stock_total
        FROM inventario
        GROUP BY ID_componente
    ) inv ON inv.ID_componente = mc.ID_componente
    WHERE mc.ID_mod = p_ID_mod
      AND COALESCE(inv.stock_total, 0) < mc.cantidad_requerida;

    IF v_faltantes = 0 THEN
        RETURN 'Disponible';
    END IF;

    RETURN 'Insuficiente';
END$$

-- Función 4:
-- Calcula el costo de componentes necesarios para producir una unidad
-- de un modelo de vehículo.
CREATE FUNCTION FN_CalcularCostoProduccionVehiculo(p_ID_mod INT)
RETURNS DECIMAL(14,2)
READS SQL DATA
BEGIN
    DECLARE v_costo DECIMAL(14,2) DEFAULT 0;

    SELECT COALESCE(SUM(mc.cantidad_requerida * c.costo_unitario), 0)
    INTO v_costo
    FROM modelo_componente mc
    INNER JOIN componente c ON c.ID_componente = mc.ID_componente
    WHERE mc.ID_mod = p_ID_mod;

    RETURN ROUND(v_costo, 2);
END$$

-- Función 5:
-- Devuelve el porcentaje de controles aprobados para un modelo
-- dentro de un rango de fechas (inclusive).
CREATE FUNCTION FN_ObtenerIndicadoresCalidad(
    p_ID_mod INT,
    p_fecha_inicio DATE,
    p_fecha_fin DATE
)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_aprobados INT DEFAULT 0;

    SELECT COUNT(*),
           COALESCE(SUM(CASE WHEN cc.resultado = 'Aprobado'
                             THEN 1 ELSE 0 END), 0)
    INTO v_total, v_aprobados
    FROM control_calidad cc
    INNER JOIN vehiculo v ON v.ID_vehiculo = cc.ID_vehiculo
    WHERE v.ID_mod = p_ID_mod
      AND cc.fecha_control BETWEEN p_fecha_inicio AND p_fecha_fin;

    IF v_total = 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND((v_aprobados / v_total) * 100, 2);
END$$

DELIMITER ;

-- ------------------------------------------------------------
-- 4. CONSULTAS DE PRUEBA
-- Ejecutar después de crear las estructuras, triggers y funciones.
-- ------------------------------------------------------------

-- 1. Eficiencia de la línea 1 para el día actual:
-- SELECT FN_CalcularEficienciaLinea(1);

-- 2. Estimación de tiempo para fabricar 10 unidades del modelo 1:
-- SELECT FN_EstimarTiempoProduccion(1, 10);

-- 3. Disponibilidad de componentes para el modelo 1:
-- SELECT FN_ObtenerDisponibilidadComponentes(1);

-- 4. Costo de componentes para una unidad del modelo 1:
-- SELECT FN_CalcularCostoProduccionVehiculo(1);

-- 5. Porcentaje de controles aprobados del modelo 1 durante el último mes:
-- SELECT FN_ObtenerIndicadoresCalidad(
--     1, DATE_SUB(CURDATE(), INTERVAL 30 DAY), CURDATE()
-- );

-- Ejemplo de prueba para el trigger de tiempos (use una estación existente):
-- INSERT INTO registro_operacion (ID_estacion, tiempo_real, observaciones)
-- VALUES (1, 999.00, 'Prueba de desviación de tiempo');
-- SELECT * FROM alerta_tiempo_estacion ORDER BY ID_alerta DESC;

-- IMPORTANTE:
-- 1) En orden_compra, usar estado 'Recibida' para activar el trigger 1.
-- 2) El trigger de calidad usa los proveedores de los componentes asociados
--    al modelo del vehículo inspeccionado como indicador indirecto de calidad.
-- 3) El costo calculado contempla componentes, no mano de obra, energía ni
--    depreciación, porque esos costos no existen en el esquema original.
