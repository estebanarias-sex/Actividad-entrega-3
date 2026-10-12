# AutoFactory — Triggers y funciones (ASP-03-05)

## Descripción general
AutoFactory es una base de datos relacional para administrar una fábrica de vehículos. Incluye modelos, líneas de producción, estaciones, proveedores, componentes, inventario, vehículos fabricados, empleados, controles de calidad y órdenes de compra.

Este repositorio complementa la base de datos del módulo anterior mediante cinco triggers y cinco funciones de MySQL.

## Archivos
- `AutoFactory_Base.sql`: script original para crear la base de datos y cargar sus datos.
- `AutoFactory_Triggers_Funciones.sql`: tablas auxiliares, cinco triggers, cinco funciones y consultas de prueba.
- `Actividad_AutoFactory_Resuelta.docx`: documento de explicación y entrega.

## Requisitos
- MySQL 8.0 o compatible.
- MySQL Workbench u otro cliente SQL.
- Permisos para crear triggers y funciones.

## Cómo ejecutar
1. Si ya tienes la base `auto_factory` del módulo anterior con sus datos, **no ejecutes `AutoFactory_Base.sql`**, porque contiene `DROP DATABASE IF EXISTS` y recrea la base. Haz una copia de seguridad antes de cualquier cambio.
2. Selecciona la base existente y ejecuta `AutoFactory_Triggers_Funciones.sql`.
3. La adición del campo `VIN` y la creación del índice único deben ejecutarse una sola vez. Si el campo o el índice ya existen, omite esas instrucciones al volver a ejecutar el archivo.
4. `AutoFactory_Base.sql` se incluye únicamente como referencia o para montar una instalación nueva desde cero.
5. Para probar las funciones, ejecuta por ejemplo:

```sql
USE auto_factory;
SELECT FN_CalcularEficienciaLinea(1);
SELECT FN_EstimarTiempoProduccion(1, 10);
SELECT FN_ObtenerDisponibilidadComponentes(1);
SELECT FN_CalcularCostoProduccionVehiculo(1);
SELECT FN_ObtenerIndicadoresCalidad(
  1, DATE_SUB(CURDATE(), INTERVAL 30 DAY), CURDATE()
);
```

## Triggers incluidos
1. `TR_ActualizarInventarioComponentes`: actualiza el inventario cuando una orden cambia a `Recibida`.
2. `TR_VerificarCalidadProveedores`: actualiza indicadores acumulados de calidad de proveedores después de insertar un control de calidad.
3. `TR_ActualizarEstadisticasProduccion`: acumula unidades y tiempos por modelo y línea al insertar un vehículo.
4. `TR_ControlarTiemposEstaciones`: genera una alerta si una operación supera en más del 20 % el tiempo de referencia.
5. `TR_AsignarVIN`: genera un VIN interno al insertar un vehículo que no tenga uno asignado.

## Funciones incluidas
1. `FN_CalcularEficienciaLinea(ID_linea)`: porcentaje de capacidad diaria utilizada.
2. `FN_EstimarTiempoProduccion(ID_mod, cantidad)`: estimación de horas de ensamblaje para una cantidad.
3. `FN_ObtenerDisponibilidadComponentes(ID_mod)`: indica si hay componentes suficientes para fabricar una unidad.
4. `FN_CalcularCostoProduccionVehiculo(ID_mod)`: costo de componentes para una unidad del modelo.
5. `FN_ObtenerIndicadoresCalidad(ID_mod, fecha_inicio, fecha_fin)`: porcentaje de controles aprobados en un periodo.

## Tablas complementarias
- `evaluacion_proveedor`: resumen de resultados de calidad por proveedor.
- `estadisticas_produccion`: estadísticas por modelo y línea.
- `registro_operacion`: tiempos reales de operación.
- `alerta_tiempo_estacion`: alertas de desviaciones de tiempo.

## Consideraciones
- El indicador de calidad del proveedor es aproximado: los controles se relacionan con los proveedores de componentes asociados al modelo del vehículo, porque la base original no vincula un defecto con un componente específico.
- El costo calculado considera componentes, pero no mano de obra, energía ni depreciación, ya que esos costos no existen en el esquema original.
- `FN_CalcularEficienciaLinea` mide la utilización diaria de capacidad, no el OEE industrial completo.
- El número de ejercicio asignado por lista no se pudo verificar; se trabajó con AutoFactory porque es la base de datos disponible.
