# CATÁLOGO DE FUNCIONES - PROYECTO TESIS PUEBLOS ORIGINARIOS

Este directorio contiene todas las funciones personalizadas del proyecto de análisis de pertenencia a pueblos originarios en datos de egresos hospitalarios (2010-2022).

## Estructura de Directorios

```
R/
├── graficos/          # Funciones de generación de gráficos
├── tablas/            # Funciones de creación y exportación de tablas
├── analisis/          # Funciones de análisis estadístico y descriptivo
├── concordancia/      # Funciones de análisis de concordancia (Kappa, CCC)
├── censo/             # Funciones de extracción y procesamiento de datos del censo
├── utilidades/        # Funciones auxiliares y de propósito general
└── cargar_funciones.R # Script maestro para cargar todas las funciones
```

## Cómo Usar

Para cargar todas las funciones en tu sesión de R:

```r
source("R/cargar_funciones.R")
```

## Funciones por Categoría

### 📊 GRÁFICOS (`graficos/`)

#### `guardar_multiformato()`
- **Archivo**: `graficos/guardar_multiformato.R`
- **Origen**: `grafico_pertenencia.qmd`
- **Descripción**: Guarda gráficos ggplot en formato JPG con fondo blanco
- **Parámetros**:
  - `grafico`: Objeto ggplot
  - `nombre_base`: Nombre del archivo (sin extensión)
  - `ancho`: Ancho en pulgadas (default: 10)
  - `alto`: Alto en pulgadas (default: 6)
  - `dpi`: Resolución (default: 300)
- **Retorna**: Invisible NULL (guarda archivo en `resultados_tesis/`)
- **Dependencias**: `ggplot2`
- **Ejemplo**:
  ```r
  p <- ggplot(data, aes(x, y)) + geom_point()
  guardar_multiformato(p, "mi_grafico", ancho=12, alto=8)
  ```

#### `grafico_comparativo_fuentes()`
- **Archivo**: `graficos/grafico_comparativo_fuentes.R`
- **Origen**: `grafico_pertenencia.qmd`
- **Descripción**: Genera gráfico comparativo de evolución temporal de pertenencia según diferentes fuentes (RSH, CONADI, Egresos, Variable Enriquecida)
- **Parámetros**:
  - `data`: Data frame con variables `AÑO`, `RSH`, `CONADI`, `PUEBLO_ORIGINARIO_BIN`, `PERTENENCIA2`
- **Retorna**: Lista con `$grafico` (ggplot) y `$datos` (data frame procesado)
- **Dependencias**: `dplyr`, `ggplot2`, `tidyr`
- **Colores**:
  - RSH: `#E41A1C` (rojo)
  - CONADI: `#4DAF4A` (verde)
  - Egresos Hospitalarios: `#377EB8` (azul)
  - Variable Enriquecida: `#FF7F00` (naranja)
- **Ejemplo**:
  ```r
  resultado <- grafico_comparativo_fuentes(datos_ordenados)
  print(resultado$grafico)
  View(resultado$datos)
  ```

#### `grafico_tendencia_pertenencia()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `grafico_pertenencia.qmd`
- **Descripción**: Gráfico de tendencia solo para pertenencia (sin puntos)

#### `grafico_tendencia_completa()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `grafico_pertenencia.qmd`
- **Descripción**: Gráfico con ambas líneas (pertenece y no pertenece)

#### `generar_graficos_tendencia_mensual()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `grafico_pertenencia.qmd`
- **Descripción**: Genera un gráfico por año mostrando tendencia mensual de las 4 fuentes

#### `grafico_prevision_po()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `graf_cie_prev.qmd`
- **Descripción**: Gráfico de previsión solo para pueblos originarios

#### `grafico_diagnosticos_po()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `graf_cie_prev.qmd`
- **Descripción**: Gráfico de diagnósticos unificado para pueblos originarios

#### `grafico_cie10_po()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `graf_cie_prev.qmd`
- **Descripción**: Gráfico de grupos CIE-10 para pueblos originarios

#### `grafico_evolucion_prevision_po()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `graf_cie_prev.qmd`
- **Descripción**: Evolución anual de previsión en pueblos originarios

#### `grafico_promedio_prevision_po()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `graf_cie_prev.qmd`
- **Descripción**: Promedio anual de previsión en pueblos originarios

---

### 🔬 ANÁLISIS (`analisis/`)

#### `analizar_pertenencia()`
- **Archivo**: `analisis/analizar_pertenencia.R`
- **Origen**: `grafico_pertenencia.qmd`
- **Descripción**: Análisis completo de pertenencia con distribución anual y promedios
- **Parámetros**:
  - `data`: Data frame con datos de egresos
  - `var_nombre`: Nombre de variable (e.g., "RSH", "CONADI", "PUEBLO_ORIGINARIO_BIN", "PERTENENCIA2")
  - `var_etiqueta`: Etiqueta descriptiva para gráficos
- **Retorna**: Lista con:
  - `$anual`: Gráfico de barras por año
  - `$promedio`: Gráfico de promedios
  - `$datos_anual`: Data frame con datos anuales
  - `$datos_promedio`: Data frame con promedios
  - `$nota`: Texto explicativo
- **Dependencias**: `dplyr`, `ggplot2`, `ggpubr`
- **Variables globales requeridas**: `colores_analisis`
- **Ejemplo**:
  ```r
  resultado <- analizar_pertenencia(datos_ordenados, "RSH", "Registro Social de Hogares")
  print(resultado$anual)
  print(resultado$promedio)
  ```

#### `analizar_pertenencia_sexo()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `grafico_pertenencia.qmd`
- **Descripción**: Análisis de pertenencia desagregado por sexo

#### `analizar_variable()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `graf_cie_prev.qmd`, `E_descriptiva2.qmd`
- **Descripción**: Análisis genérico de variables con top valores
- **Nota**: Existe en 2 archivos con implementación similar

#### `analizar_cie10_top()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `E_descriptiva2.qmd`
- **Descripción**: Análisis de top 20 grupos CIE-10 por pertenencia y año

#### `analizar_por_sexo()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `E_descriptiva2.qmd`
- **Descripción**: Análisis específico desagregado por sexo

#### `analizar_variable_solo_po()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `graf_cie_prev.qmd`
- **Descripción**: Análisis solo para pueblos originarios con gráficos facetados

---

### 📋 TABLAS (`tablas/`)

#### `guardar_como_jpg()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `Concord_nuevas.qmd`
- **Descripción**: Convierte flextables a JPG mediante HTML temporal y webshot2

#### `crear_tabla_resumen_horizontal()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `E_descriptiva.qmd`
- **Descripción**: Crea tablas resumen con formato horizontal

#### `flex_to_df()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `E_descriptiva2.qmd`
- **Descripción**: Convierte flextable a data frame

#### `save_flex_as_html()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `E_descriptiva2.qmd`
- **Descripción**: Guarda flextables como HTML

#### `guardar_tabla_html()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `E_descriptiva2.qmd`
- **Descripción**: Función mejorada para guardar tablas HTML con manejo de errores

---

### 🤝 CONCORDANCIA (`concordancia/`)

#### `calcular_concordancia_desctools()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `Concord_nuevas.qmd`
- **Descripción**: Calcula Cohen's Kappa usando DescTools con IC al 95%

#### `formatear_resultado_ccc()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `Concord_nuevas.qmd`
- **Descripción**: Formatea resultados de Lin's CCC con interpretación

---

### 📊 CENSO (`censo/`)

#### `extraer_datos_censo()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `Concord_nuevas.qmd`
- **Descripción**: Extrae datos del Censo 2017 con múltiples desagregaciones (región, sexo, edad)

#### `extraer_datos_variable_enriquecida()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `Concord_nuevas.qmd`
- **Descripción**: Extrae y procesa datos de PERTENENCIA2 (variable enriquecida)

---

### 🛠️ UTILIDADES (`utilidades/`)

#### `clasificar_grupo()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `BBDD Limpia.qmd`
- **Descripción**: Clasifica códigos CIE-10 en grupos temáticos

#### `crear_grafico_tendencia()` (PENDIENTE)
- **Archivo**: TBD
- **Origen**: `codigo de graficos.qmd`, `Prueba de graficos.qmd`
- **Descripción**: Crea gráficos de tendencia genéricos
- **Nota**: Existe en 2 archivos con código similar

---

## Dependencias Globales del Proyecto

### Paquetes R Requeridos

```r
# Manipulación de datos
library(dplyr)
library(tidyr)

# Visualización
library(ggplot2)
library(ggpubr)
library(RColorBrewer)
library(scales)

# Tablas
library(flextable)
library(knitr)

# Exportación
library(officer)      # Exportar a Word
library(webshot2)     # Exportar a JPG

# Estadística
library(DescTools)    # Cohen's Kappa, Lin's CCC

# Fechas
library(lubridate)    # Manejo de fechas en análisis mensual

# Base de datos
library(DBI)          # Conexión a censo SQLite
library(RSQLite)
```

### Variables Globales Requeridas

```r
# Paleta de colores para análisis de pertenencia
colores_analisis <- c(
  "Pertenece a Pueblos Originarios" = "#E69F00",
  "Población General" = "#0072B2"
)

# Paleta de colores para fuentes de datos
colores_fuentes <- c(
  "RSH" = "#E41A1C",
  "CONADI" = "#4DAF4A",
  "Egresos Hospitalarios" = "#377EB8",
  "Variable Enriquecida" = "#FF7F00"
)
```

---

## Estado del Proyecto

### ✅ COMPLETADO (3 funciones)
- `guardar_multiformato`
- `grafico_comparativo_fuentes`
- `analizar_pertenencia`

### 🔄 PENDIENTE (28 funciones)
- 7 funciones de gráficos adicionales
- 5 funciones de análisis
- 5 funciones de tablas
- 2 funciones de concordancia
- 2 funciones de censo
- 2 funciones de utilidades

---

## Convenciones de Código

1. **Nombres de funciones**: `snake_case`
2. **Nombres de archivos**: Igual al nombre de la función principal
3. **Documentación**: Encabezado con descripción, parámetros, retorno, dependencias
4. **Ejemplo de uso**: Incluido en cada archivo
5. **Manejo de errores**: Validación de parámetros con mensajes claros
6. **Retornos**: Listas nombradas para múltiples salidas

---

## Notas Importantes

- **NO BORRAR FUNCIONES ORIGINALES**: Este proceso es solo de extracción. Los .qmd originales permanecen intactos.
- **Pruebas**: Cada función debe probarse después de extraerla
- **Versionado**: Usar Git para control de cambios
- **Directorio de salida**: La mayoría de funciones exportan a `resultados_tesis/`

---

## Autor

Proyecto GITTESIS - Análisis de Pertenencia a Pueblos Originarios  
Magíster en Estadística  
Enero 2025

---

## Licencia

Uso académico - Proyecto de Tesis
