# Esquema de directorios del repositorio

> Mapa de referencia del repo `rtsppoo` (Tesis PPOO — Egresos Hospitalarios Chile). Objetivo: evitar exploración repetida del árbol. Mantener actualizado cuando cambie la estructura.
>
> **No es un paquete R** (ver `CLAUDE.md`): `DESCRIPTION`/`NAMESPACE` son heredados; la carga es por `source("R/cargar_funciones.R")`.

Última actualización: 2026-07-16.

---

## Raíz

```
rtsppoo/
├── CLAUDE.md                     # Instrucciones del proyecto (fuente de verdad)
├── README.md · LICENSE · CITATION.cff
├── DESCRIPTION · NAMESPACE        # Heredados (no se usan como paquete)
├── GITTESIS.Rproj                 # Proyecto RStudio
├── renv.lock · renv/              # Dependencias (renv)
│
├── BBDD_homologados.RData         # Base principal (gitignored) — datos_homologados, ~21M reg., 29 cols
├── BBDD_datos_preparados.RData    # Etapa intermedia (gitignored)
├── BBDD_ordenados.RData           # Etapa intermedia (gitignored)
├── base_reducida.RData            # Subset (gitignored)
│
├── R/                             # Funciones utilitarias (source, no library)
├── analisis/                      # QMDs de análisis por tema
├── docs/                          # Documentación del proyecto (este archivo, rúbricas, specs)
├── DOCUMENTOS TESIS/              # Manuscritos, guías, orientaciones (gitignored)
├── preparacion/                   # Scripts de limpieza/homologación de fuentes
├── resultados_tesis/              # Figuras y tablas finales
├── output_qmd/                    # HTMLs publicables por QMD
├── html/                          # Renders locales recientes (gitignored)
├── Lock_sensible/                 # Datos sensibles y tablas CIE-10 (gitignored)
├── DATOS ABIERTOS/                # Fuentes públicas (DEIS, Censo)
├── ICD_2019/                      # Recursos CIE-10
├── archivo/                       # Documentación legacy / exploración anterior
├── vignettes/ · man/              # Heredados de estructura de paquete
└── _extensions/                   # Extensiones Quarto
```

### Archivos sueltos en la raíz (a limpiar)

Hay HTMLs y RData de salida, PDFs de formularios PAHO, y scripts temporales dispersos en la raíz
(`*.html`, `perfiles_diagnosticos*.html`, `paho_authorship_*.pdf`, `test_ciecl_bug.R`, `_render_figura4.R`,
`temp_*.txt`, `nul`, `BBDD_homologados_BACKUP_CORRUPTO.RData`). Candidatos a mover a `output_qmd/`,
`archivo/` o eliminar. No son parte de la estructura estable.

---

## `R/` — funciones (cargadas por `R/cargar_funciones.R`)

| Subcarpeta | Contenido |
|---|---|
| `R/graficos/` | Visualizaciones ggplot2 (tendencias, perfiles, disparidades, paletas). |
| `R/analisis/` | Funciones estadísticas y EDA (pertenencia, CIE-10 top, disparidades). |
| `R/concordancias/` | CCC de Lin con `DescTools` (usar `calcular_ccc_desagregacion()`, no `calcular_ccc_detallado()`). |
| `R/perfiles/` | Perfiles diagnósticos CIE-10 PO vs PG (Obj 4). |
| `R/tablas/` | Exportación con `flextable`. |
| `R/utilidades/` | Helpers (clasificar grupo, regiones, paletas). |
| `R/funciones/` | Misceláneas: `ordenar_regiones()`, `visualizaciones_cie10.R` (figuras de journal). |

---

## `analisis/` — QMDs por tema

| Carpeta | QMD principal | Objetivo |
|---|---|---|
| `00_descriptivos/` | `cuadro_descriptivo_egresos.qmd` | Descriptivos base |
| `01_descriptivos/` | `E_descriptiva_modular.qmd`, `datos_descriptivos_modular.qmd` | Estadística descriptiva general |
| `02_tendencias/` | `grafico_pertenencia_modular.qmd` | Tendencias de pertenencia PO |
| `03_concordancia/` | `Concord_nuevas_modular.qmd` | **CCC principal** (Obj 1–3) |
| `04_sociodemografico/` | `graf_cie_prev_modular.qmd` | CIE-10 por previsión |
| `05_perfiles_cie10/` | `perfiles_diagnosticos_*.qmd` | Perfiles CIE-10 PO vs PG (Obj 4) |

Cada subcarpeta tiene su `resultados_tesis/` con figuras/tablas generadas y carpetas `*_files/` de renders (gitignored).

---

## `docs/` — documentación del proyecto

| Archivo | Contenido |
|---|---|
| `estructura_repositorio.md` | Este mapa. |
| `rubrica_documento_tesis.md` | Rúbrica oficial + checklist del documento escrito de tesis. |
| `rubrica_ppt_defensa.md` | Rúbrica Anexo 4 + guion de láminas para la defensa. |
| `guia_defensa_oral.md` | Reglas del Examen de Grado + banco de preguntas. |
| `superpowers/specs/` | Specs de diseño (brainstorming) fechados. |

---

## `DOCUMENTOS TESIS/` — manuscritos y guías (gitignored)

> Carpeta densa. La organización por **estado** de documento vive en `docs/estado_documentos_tesis.md`
> (mapa de qué archivo está vigente, enviado, respaldo, auditoría, insumo o temporal).

Referencias clave que no cambian de ubicación:

| Archivo | Rol |
|---|---|
| `FINAL-TESIS/ORIENTACIONES_PROCESO_TESIS_AFE_2025.md` | Orientaciones oficiales MSP (Anexos 1–4). Fuente de las rúbricas. |
| `FINAL-TESIS/ESTRUCTURA_TESIS.md` | Decisión del autor sobre composición del documento final (Parte 1 + Cap.1 + Cap.2). |
| `FINAL-TESIS/FUTURO DOC TESIS con updates.docx` | **Documento activo** de la tesis (en edición). |
| `FINAL-TESIS/9_Limitaciones_propuesta.md` | Sección de limitaciones (integrándose al documento activo). |
| `GUIA_PAPER_TESIS.md`, `FINAL-TESIS/GUIA_TESIS_COMPLETA.md` | Guías de referencia. |
| `referencias_tesis.bib`, `vancouver-superscript.csl` | Bibliografía y estilo de citas. |
| `PDF_Referencias/` | ~134 PDFs de literatura de respaldo. |
