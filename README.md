# GITTESIS — Análisis Epidemiológico de Pueblos Originarios en Egresos Hospitalarios de Chile

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-%3E%3D4.0-blue?logo=r)](https://www.r-project.org/)
[![Quarto](https://img.shields.io/badge/Quarto-1.4+-purple?logo=quarto)](https://quarto.org/)
[![ciecl](https://img.shields.io/badge/ciecl-CRAN-green)](https://CRAN.R-project.org/package=ciecl)
[![Universidad de Chile](https://img.shields.io/badge/Universidad%20de%20Chile-MSP-red)](https://www.uchile.cl/)

Compendio de código reproducible para la tesis de Magíster en Salud Pública de la Universidad de Chile. Implementa el análisis de pertenencia a Pueblos Originarios (PO) en egresos hospitalarios de Chile (2012–2022), incluyendo evaluación de concordancia entre fuentes de datos y construcción de perfiles diagnósticos CIE-10.

**Estudiante:** Rodolfo José Tasso Suazo — rtasso@uchile.cl
**Profesora Guía:** Sandra Flores Alvarado
**Programa:** Magíster en Salud Pública, Universidad de Chile

---

## Pipeline de Análisis

```
preparacion/          → Limpieza y homologación de BBDD de egresos hospitalarios
analisis/
  00_descriptivos/    → Cuadro descriptivo general de egresos
  01_descriptivos/    → Estadística descriptiva: completitud y caracterización
  02_tendencias/      → Tendencias temporales de pertenencia étnica (2012–2022)
  03_concordancia/    → Concordancia CCC/Kappa entre EH, RSH, CONADI y Censo
  04_sociodemografico/→ Perfiles por previsión de salud
  05_perfiles_cie10/  → Perfiles diagnósticos PO vs Población General
```

---

## Estructura del Repositorio

```
GITTESIS/
├── README.md
├── DESCRIPTION                     # Metadatos del paquete R
├── LICENSE                         # MIT
├── NAMESPACE
├── renv.lock                       # Dependencias bloqueadas
│
├── R/                              # 61 funciones modulares
│   ├── cargar_funciones.R          # Carga todas las funciones
│   ├── analisis/                   # 10 funciones estadísticas
│   ├── concordancias/              # 9 funciones CCC/Kappa
│   ├── funciones/                  # Helpers (ordenar_regiones, visualizaciones_cie10)
│   ├── graficos/                   # 13 funciones de visualización
│   ├── perfiles/                   # 9 funciones epidemiológicas
│   ├── tablas/                     # 6 funciones de exportación
│   └── utilidades/                 # 5 funciones auxiliares
│
├── analisis/                       # Documentos Quarto reproducibles
│   ├── README.md                   # Índice de secciones
│   ├── 00_descriptivos/            # Cuadro descriptivo de egresos
│   ├── 01_descriptivos/            # Estadística descriptiva
│   ├── 02_tendencias/              # Tendencias temporales
│   ├── 03_concordancia/            # Concordancia CCC/Kappa
│   ├── 04_sociodemografico/        # Análisis por previsión
│   └── 05_perfiles_cie10/          # Perfiles diagnósticos PO vs PG
│
├── preparacion/                    # Limpieza y preparación de datos
│   ├── BBDD Limpia.qmd
│   └── Homologacion de establecimientos.qmd
│
└── vignettes/                      # Documentación formal
    ├── guia-rapida.Rmd
    └── flujo-analisis.Rmd
```

---

## Reproducibilidad

```r
# 1. Clonar repositorio
# git clone https://github.com/Rodotasso/GITTESIS.git

# 2. Abrir GITTESIS.Rproj en RStudio

# 3. Restaurar dependencias
renv::restore()

# 4. Cargar funciones
source("R/cargar_funciones.R")

# 5. Ejecutar QMDs en orden (ver analisis/README.md)
quarto::quarto_render("analisis/01_descriptivos/E_descriptiva_modular.qmd")
```

**Nota:** Los datos originales no están incluidos por razones de privacidad. Los identificadores personales están anonimizados.

---

## Funciones R (61 funciones, 7 módulos)

| Módulo | N | Funciones principales |
|--------|---|-----------------------|
| `graficos/` | 13 | `guardar_multiformato()`, `grafico_tendencia_pertenencia()`, `grafico_evolucion_disparidades()` |
| `analisis/` | 10 | `analizar_pertenencia()`, `calcular_tendencia_pertenencia2()`, `identificar_grupos_disparidad()` |
| `concordancias/` | 9 | `calcular_concordancia_desctools()`, `calcular_ccc_desagregacion()`, `crear_tabla_ccc()` |
| `perfiles/` | 9 | `calcular_perfil_diagnostico()`, `comparar_perfiles_po_pg()`, `calcular_indicadores_protocolo()` |
| `tablas/` | 6 | `guardar_tabla_png()`, `guardar_tabla_html()`, `flex_to_df()` |
| `utilidades/` | 5 | `concatenar_diag_ciecl()`, `paleta_colores()`, `crear_region_nuble()` |
| `funciones/` | 2 | `ordenar_regiones()`, visualizaciones para journal |

---

## Dependencias Principales

```r
library(tidyverse)    # Manipulación de datos
library(ggplot2)      # Visualización
library(flextable)    # Tablas formateadas
library(DescTools)    # CCC y Kappa
library(ciecl)        # Clasificación CIE-10 (CRAN)
library(quarto)       # Documentos reproducibles
```

---

## Consideraciones Éticas

- Los datos originales no se distribuyen (información sensible de salud)
- Identificadores personales (RUN) anonimizados de forma irreversible
- Variable de pueblo específico transformada a formato dicotómico
- Cumplimiento con Ley N° 19.628 de Protección de Datos Personales y Convenio 169 OIT

---

## Licencia

MIT — ver [LICENSE](LICENSE). Los datos utilizados están sujetos a restricciones de privacidad y no se distribuyen públicamente.
