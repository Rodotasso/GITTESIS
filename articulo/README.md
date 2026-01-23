# Articulo - Analisis de Pertenencia a Pueblos Originarios

Este directorio contiene los QMDs organizados segun la estructura del articulo academico.

## Estructura

```
articulo/
├── 01_descriptivos/        # Cuadro I - Completitud
├── 02_tendencias/          # Figura 1 - Tendencia temporal
├── 03_concordancia/        # Cuadro II - Concordancia
├── 04_sociodemografico/    # Figura 2 - Prevision
└── 05_perfiles_cie10/      # Figura 3 - Perfiles diagnosticos
```

## Secciones

### 01_descriptivos/
**Cuadro I - Completitud de la variable de pertenencia**

| Archivo | Descripcion |
|---------|-------------|
| `E_descriptiva_modular.qmd` | Analisis descriptivo completo con tablas de completitud |
| `datos_descriptivos_modular.qmd` | Estadisticas para primer parrafo de resultados |

### 02_tendencias/
**Figura 1 - Tendencia temporal de pertenencia**

| Archivo | Descripcion |
|---------|-------------|
| `grafico_pertenencia_modular.qmd` | Graficos de evolucion temporal 2012-2022 |

### 03_concordancia/
**Cuadro II - Concordancia entre fuentes (Kappa y CCC)**

| Archivo | Descripcion |
|---------|-------------|
| `Concord_nuevas_modular.qmd` | Analisis Kappa (VE vs Egresos) y CCC (vs Censo 2017) |

### 04_sociodemografico/
**Figura 2 - Distribucion por prevision**

| Archivo | Descripcion |
|---------|-------------|
| `graf_cie_prev_modular.qmd` | Graficos CIE-10 por tipo de prevision |

### 05_perfiles_cie10/
**Figura 3 - Perfiles diagnosticos CIE-10**

| Archivo | Descripcion |
|---------|-------------|
| `perfiles_diagnosticos_modular.qmd` | Perfiles epidemiologicos PO vs PG (version base) |
| `perfiles_diagnosticos_OPTIMIZADO.qmd` | Version optimizada con sistema modular completo |
| `perfiles_diagnosticos_ciecl.qmd` | Version usando exclusivamente paquete ciecl |
| `top_patologias_po_ciecl.qmd` | Top 5 patologias mas/menos prevalentes |

## Uso

Todos los QMDs cargan funciones y datos con rutas relativas:
```r
source("../../R/cargar_funciones.R")
load("../../BBDD_homologados.RData")
```

Para renderizar desde la raiz del proyecto:
```bash
quarto render articulo/01_descriptivos/E_descriptiva_modular.qmd
```
