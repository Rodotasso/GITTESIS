# GITTESIS - Análisis de Pertenencia a Pueblos Originarios en Egresos Hospitalarios de Chile

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-%3E%3D4.0-blue?logo=r)](https://www.r-project.org/)
[![Quarto](https://img.shields.io/badge/Quarto-1.4+-purple?logo=quarto)](https://quarto.org/)
[![Status](https://img.shields.io/badge/Status-En%20Desarrollo-orange)](https://github.com/Rodotasso/GITTESIS)
[![Universidad](https://img.shields.io/badge/Universidad%20de%20Chile-MSP-red)](https://www.uchile.cl/)
![Visitas](https://visitor-badge.laobi.icu/badge?page_id=Rodotasso.GITTESIS)

## Descripción General

Este repositorio contiene el código, análisis y documentación de la tesis de Magíster en Salud Pública de la Universidad de Chile:

**"Completitud y Representatividad del Registro de Pertenencia a Pueblos Originarios en Egresos Hospitalarios de Chile (2010-2022): Construcción de perfiles epidemiológicos en un Análisis Poblacional"**

**Estudiante:** Rodolfo José Tasso Suazo  
**Profesora Guía:** Sandra Flores Alvarado  
**Programa:** Magíster en Salud Pública  
**Universidad:** Universidad de Chile

---

## Objetivos del Estudio

### Objetivo General
Evaluar la relación entre la completitud y representatividad de los registros de pertenencia a pueblos originarios en Chile y construir perfiles epidemiológicos basados en estos datos.

### Objetivos Específicos
1. Describir los registros de pertenencia a pueblos indígenas en los registros de salud chilenos a partir de los registros de pertenencia en RSH, CONADI y Egresos Hospitalarios (MINSAL)
2. Comparar la completitud y representatividad de estos registros entre ellos y respecto al Censo Nacional de Población
3. Construir perfiles epidemiológicos de egresos hospitalarios de la población indígena a partir de las bases de datos disponibles
4. Comparar los perfiles epidemiológicos creados a partir de los diferentes registros de pertenencia

---

## Metodología

### Diseño del Estudio
- **Tipo:** Estudio observacional, descriptivo y longitudinal de tipo poblacional
- **Período:** 2010-2022
- **Población:** Todos los egresos hospitalarios registrados en el sistema nacional del DEIS-MINSAL

### Fuentes de Datos
- **Egresos Hospitalarios (MINSAL-DEIS):** Base principal con información clínica y sociodemográfica
- **Registro Social de Hogares (RSH):** Autoidentificación étnica autodeclarada
- **CONADI:** Certificación administrativa de pertenencia a pueblos originarios
- **Censo Nacional 2017:** Fuente de referencia para análisis de representatividad
- **Encuesta CASEN:** Fuente complementaria de caracterización socioeconómica

### Variables Principales
- Pertenencia a pueblo originario (variable dicotómica)
- Variables sociodemográficas: edad, sexo, región
- Variables epidemiológicas: diagnóstico CIE-10, grupo de enfermedad, letalidad

### Atributos de Calidad Evaluados
- **Completitud:** Proporción de registros con datos válidos
- **Concordancia interna:** Índice Kappa de Cohen entre fuentes
- **Concordancia externa:** Coeficiente de Lin con Censo 2017
- **Representatividad:** Comparación con distribución censal

---

## Estructura del Repositorio

```
GITTESIS/
├── README.md                           # Este archivo
├── DESCRIPTION                         # Metadatos del paquete R
├── renv.lock                           # Lock file de dependencias
│
├── articulo/                           # QMDs organizados por seccion del articulo
│   ├── README.md                       # Indice de secciones
│   ├── 01_descriptivos/                # Cuadro I - Completitud
│   │   ├── E_descriptiva_modular.qmd
│   │   └── datos_descriptivos_modular.qmd
│   ├── 02_tendencias/                  # Figura 1 - Tendencia temporal
│   │   └── grafico_pertenencia_modular.qmd
│   ├── 03_concordancia/                # Cuadro II - Kappa y CCC
│   │   └── Concord_nuevas_modular.qmd
│   ├── 04_sociodemografico/            # Figura 2 - Prevision
│   │   └── graf_cie_prev_modular.qmd
│   └── 05_perfiles_cie10/              # Figura 3 - Perfiles CIE-10
│       ├── perfiles_diagnosticos_modular.qmd
│       ├── perfiles_diagnosticos_OPTIMIZADO.qmd
│       ├── perfiles_diagnosticos_ciecl.qmd
│       └── top_patologias_po_ciecl.qmd
│
├── R/                                  # Funciones modulares (56 funciones)
│   ├── cargar_funciones.R              # Carga todas las funciones
│   ├── graficos/                       # 13 funciones de visualizacion
│   ├── analisis/                       # 10 funciones estadisticas
│   ├── concordancias/                  # 9 funciones CCC/Kappa
│   ├── perfiles/                       # 8 funciones epidemiologicas
│   ├── tablas/                         # 5 funciones exportacion
│   └── utilidades/                     # 5 funciones auxiliares
│
├── preparacion/                        # Preparacion y limpieza de datos
│   ├── BBDD Limpia.qmd
│   └── Homologacion de establecimientos.qmd
│
└── Configuracion:
    ├── .gitignore
    ├── .Rprofile
    └── renv/
```

### Mapeo Articulo → Codigo

| Seccion del Articulo | Figura/Cuadro | Carpeta |
|----------------------|---------------|---------|
| Material y Metodos | - | `preparacion/` |
| Completitud | Cuadro I | `articulo/01_descriptivos/` |
| Tendencia temporal | Figura 1 | `articulo/02_tendencias/` |
| Concordancia Kappa | Cuadro II-A | `articulo/03_concordancia/` |
| Concordancia CCC | Cuadro II-B | `articulo/03_concordancia/` |
| Prevision | Figura 2 | `articulo/04_sociodemografico/` |
| Perfiles CIE-10 | Figura 3 | `articulo/05_perfiles_cie10/` |

---

## Requisitos Técnicos

### Software Requerido
- **R** (versión ≥ 4.0.0)
- **RStudio** (recomendado para trabajar con archivos .qmd)
- **Quarto** (para renderizar documentos .qmd a HTML/PDF)

### Paquetes R Principales
```r
# Gestión de datos
library(tidyverse)      # Colección de paquetes para ciencia de datos
library(data.table)     # Manejo eficiente de datos grandes
library(dplyr)          # Manipulación de datos

# Análisis estadístico
library(gtsummary)      # Tablas de resumen estadístico
library(tableone)       # Tablas descriptivas
library(summarytools)   # Estadísticas descriptivas
library(tidymodels)     # Análisis de correlaciones
library(DescTools)      # Herramientas estadísticas

# Visualización
library(ggplot2)        # Gráficos avanzados
library(ggpubr)         # Composición de gráficos
library(flextable)      # Formateo de tablas
library(scales)         # Escalas en gráficos

# Datos específicos
library(censo2017)      # Datos del Censo Nacional 2017

# Gestión de bases de datos
library(DBI)            # Interface para bases de datos
library(readxl)         # Lectura de archivos Excel
```

### Instalación de Dependencias
```r
# Instalar renv si no está disponible
install.packages("renv")

# Restaurar el entorno de paquetes
renv::restore()
```

---

## Uso y Ejecución

### 1. Clonar el Repositorio
```bash
git clone https://github.com/Rodotasso/GITTESIS.git
cd GITTESIS
```

### 2. Configurar Entorno R
```r
# Abrir el proyecto en RStudio
# Restaurar dependencias
renv::restore()
```

### 3. Procesamiento de Datos
Los análisis siguen un flujo secuencial:

1. **Limpieza de datos:** `BBDD Limpia.qmd`
   - Carga de datos crudos de egresos hospitalarios
   - Creación de variables derivadas (grupos etarios, CIE-10)
   - Consolidación de variables de pertenencia
   - Genera: `base_reducida.RData`

2. **Homologación:** `Homologacion de establecimientos.qmd`
   - Estandarización de códigos de establecimientos de salud

3. **Análisis descriptivo:** `E_descriptiva.qmd` y `E_descriptiva2.qmd`
   - Caracterización sociodemográfica
   - Análisis de completitud
   - Perfiles epidemiológicos por grupo

4. **Análisis de concordancia:** `Concord_nuevas.qmd`
   - Evaluación de concordancia entre fuentes (RSH, CONADI, MINSAL)
   - Índices Kappa y Lin
   - Análisis de representatividad

### 4. Renderizar Documentos
```r
# Para un documento específico
quarto::quarto_render("E_descriptiva.qmd")

# O usar el botón "Render" en RStudio
```

---

## Consideraciones Éticas y de Privacidad

### Protección de Datos
-  **Los datos originales NO están incluidos en este repositorio** por contener información sensible
- Todos los identificadores personales (RUN) están anonimizados mediante códigos irreversibles
- La variable de pueblo específico fue transformada a formato dicotómico para proteger identidades colectivas

### Aspectos Éticos
- El protocolo será sometido a revisión del Comité Ético Científico de la Facultad de Medicina, Universidad de Chile
- Se respetan los principios de autodeterminación étnica (Convenio 169 de la Organización Internacional del Trabajo - OIT)
- Cumplimiento con Ley N° 19.628 de Protección de Datos Personales
- Los valores faltantes en pertenencia étnica NO se imputan en análisis principales

### Normativas Aplicadas
- Ley Indígena N° 19.253 (1993)
- Convenio 169 de la Organización Internacional del Trabajo (OIT)
- Norma Técnica N° 231 del MINSAL (2018)
- Decreto N° 21 del MINSAL (2023)

---

## Principales Análisis Realizados

### 1. Caracterización de Registros
- Completitud de la variable pertenencia en cada fuente
- Distribución temporal (2010-2022)
- Análisis por región, edad y sexo

### 2. Concordancia entre Fuentes
- Comparación RSH vs CONADI vs MINSAL
- Índice Kappa de Cohen (concordancia interna)
- Coeficiente de Lin (concordancia con Censo 2017)

### 3. Perfiles Epidemiológicos
- Tasas de egreso hospitalario
- Distribución por grupos CIE-10
- Letalidad intrahospitalaria
- Comparación población indígena vs no indígena

### 4. Representatividad
- Contraste con Censo Nacional 2017
- Evaluación de cobertura territorial
- Identificación de brechas

---

## Referencias Clave

- **Gracey, M., & King, M. (2009).** Indigenous health part 1: determinants and disease patterns. *The Lancet*, 374(9683), 65-75.
- **Oyarce, A., & Pedrero, M. (2009).** Una metodología innovadora para la caracterización de la situación de salud de las poblaciones indígenas de Chile. *Notas de Población*, (89), 119-145.
- **Sandoval, M.H., & Alvear Portaccio, M.E. (2022).** Death certificate: The urgent consideration of ethnic and racial origin in Chile. *The Lancet Regional Health - Americas*, 16, 100402.
- **OMS (2025).** Glossary of health data, statistics and public health indicators.

Ver lista completa de referencias en: `Protocolo Tesis RTS.md`

---

## Contribuciones y Colaboración

Este repositorio fue creado para:
- Facilitar la revisión por parte de profesores guía y evaluadores
- Documentar el proceso de análisis de forma transparente
- Implementar buenas prácticas de control de versiones con Git/GitHub
- Permitir la replicabilidad de los análisis

### Sugerencias y Comentarios
Si eres revisor o estás interesado en este trabajo:
- Abre un **Issue** para preguntas o sugerencias
- Los comentarios son bienvenidos mediante **Pull Requests**
- Para colaboraciones, contacta al autor

---

## Contacto

**Rodolfo José Tasso Suazo**  
Estudiante de Magíster en Salud Pública  
Universidad de Chile  
Email: rtasso@uchile.cl

**Profesora Guía:**  
Sandra Flores Alvarado  
Facultad de Medicina, Universidad de Chile

---

## Licencia

Este proyecto es parte de una tesis académica. El código está disponible bajo licencia MIT para fines educativos y de investigación. Los datos utilizados están sujetos a restricciones de privacidad y no se distribuyen públicamente.

---


## Historial de Versiones

- **Nov 2024:** Actualización de análisis de concordancia y estadística descriptiva
- **2024:** Desarrollo del análisis principal
- **2023-2024:** Preparación de datos y diseño metodológico

---

## Enlaces Útiles

*Nota: Los siguientes enlaces fueron verificados en noviembre 2024. Las URLs de sitios gubernamentales pueden cambiar con el tiempo.*

- [Protocolo Completo](./Protocolo%20Tesis%20RTS.md)
- [MINSAL - DEIS](https://deis.minsal.cl/) - Departamento de Estadísticas e Información de Salud
- [Registro Social de Hogares](https://www.registrosocial.gob.cl/)
- [CONADI](https://www.conadi.gob.cl/) - Corporación Nacional de Desarrollo Indígena
- [Censo 2017](https://www.ine.cl/estadisticas/sociales/censos-de-poblacion-y-vivienda/censo-de-poblacion-y-vivienda) - Instituto Nacional de Estadísticas

---

*Última actualización: Noviembre 2024*