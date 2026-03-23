# Análisis — Documentos Quarto Reproducibles

Documentos organizados por sección del artículo académico.

## Estructura

```
analisis/
├── 00_descriptivos/    # Cuadro descriptivo general de egresos
├── 01_descriptivos/    # Cuadro I - Completitud
├── 02_tendencias/      # Figura 1 - Tendencia temporal
├── 03_concordancia/    # Cuadro II - Concordancia
├── 04_sociodemografico/# Figura 2 - Previsión
└── 05_perfiles_cie10/  # Figura 3 - Perfiles diagnósticos
```

## Secciones

### 00_descriptivos/
**Cuadro descriptivo general**

| Archivo | Descripcion |
|---------|-------------|
| `cuadro_descriptivo_egresos.qmd` | Cuadro descriptivo completo de egresos hospitalarios |

### 01_descriptivos/
**Cuadro I — Completitud de la variable de pertenencia**

| Archivo | Descripcion |
|---------|-------------|
| `E_descriptiva_modular.qmd` | Análisis descriptivo con tablas de completitud por fuente |
| `datos_descriptivos_modular.qmd` | Estadísticas para primer párrafo de resultados |

### 02_tendencias/
**Figura 1 — Tendencia temporal de pertenencia (2012–2022)**

| Archivo | Descripcion |
|---------|-------------|
| `grafico_pertenencia_modular.qmd` | Gráficos de evolución temporal por fuente |

### 03_concordancia/
**Cuadro II — Concordancia entre fuentes (Kappa y CCC)**

| Archivo | Descripcion |
|---------|-------------|
| `Concord_nuevas_modular.qmd` | Índice Kappa (VE vs Egresos) y CCC (vs Censo 2017) |

### 04_sociodemografico/
**Figura 2 — Distribución por previsión de salud**

| Archivo | Descripcion |
|---------|-------------|
| `graf_cie_prev_modular.qmd` | Gráficos CIE-10 por tipo de previsión |

### 05_perfiles_cie10/
**Figura 3 — Perfiles diagnósticos CIE-10 PO vs PG**

| Archivo | Descripcion |
|---------|-------------|
| `perfiles_diagnosticos_modular.qmd` | Perfiles epidemiológicos PO vs PG (versión base) |
| `perfiles_diagnosticos_OPTIMIZADO.qmd` | Versión optimizada con sistema modular completo |
| `perfiles_diagnosticos_ciecl.qmd` | Versión usando exclusivamente paquete ciecl |
| `perfiles_simples.qmd` | Perfiles simplificados para revisión rápida |
| `perfiles_simples_ve.qmd` | Perfiles con variable enriquecida |
| `perfiles_simples_ve_sin_op.qmd` | Perfiles VE sin período de orientación |
| `indicadores_epidemiologicos.qmd` | Tasas, RR e IC 95% por capítulo CIE-10 |
| `indicadores_epidemiologicos_sin_op.qmd` | Indicadores sin período de orientación |
| `indicadores_personas_ano.qmd` | Indicadores por persona-año |
| `indicadores_personas_unicas.qmd` | Indicadores por personas únicas |
| `analisis_complementario_rr.qmd` | Análisis complementario de razones de riesgo |
| `top20_patologias_desgloses.qmd` | Top 20 patologías con desglose por fuente |
| `top20_patologias_desgloses_sin_op.qmd` | Top 20 patologías sin período de orientación |

## Uso

Todos los QMDs cargan funciones y datos con rutas relativas:
```r
source("../../R/cargar_funciones.R")
load("../../BBDD_homologados.RData")
```

Para renderizar desde la raíz del proyecto:
```bash
quarto render analisis/01_descriptivos/E_descriptiva_modular.qmd
```
