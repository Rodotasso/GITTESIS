# Esquema de directorios del repositorio

> Mapa de referencia del repo `rtsppoo` (Tesis PPOO — Egresos Hospitalarios Chile). Objetivo: evitar exploración repetida del árbol. Mantener actualizado cuando cambie la estructura.
>
> **No es un paquete R** (ver `CLAUDE.md`): `DESCRIPTION`/`NAMESPACE` son heredados; la carga es por `source("R/cargar_funciones.R")`.

Última actualización: 2026-10-11 (ordenamiento estructural: carpeta `resultados_tesis/VIGENTES/`, archivo de HTML pre-corrección, loader `R/cargar_funciones.R` completo).

---

## Raíz

```
rtsppoo/
├── CLAUDE.md                     # Instrucciones del proyecto (fuente de verdad)
├── AGENTS.md · gemini.md         # Instrucciones para otras herramientas de agente (gemini.md gitignored)
├── README.md · LICENSE · CITATION.cff · .zenodo.json
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
├── benchmark/                     # Benchmarks del paquete ciecl (público; sus CSV eximidos en .gitignore)
├── docs/                          # Documentación del proyecto (este archivo, rúbricas, specs)
├── DOCUMENTOS TESIS/              # Manuscritos, guías e insumos (gitignored)
├── preparacion/                   # Scripts de limpieza/homologación de fuentes
├── resultados_tesis/              # Resultados; solo VIGENTES/ se publica (ver sección propia)
├── html/                          # Renders locales de trabajo (gitignored)
├── 99_TEMP/                       # Scratch, volcados y respaldos temporales (gitignored; incluye temp_lote1/)
├── temp_read/                     # Scratch de auditorías (gitignored). NO consolidado en 99_TEMP/: lo referencian los scripts de sesgo RSH/CONADI y QMDs activos
├── Lock_sensible/                 # Datos sensibles y tablas CIE-10 (gitignored)
├── DATOS ABIERTOS/                # Fuentes públicas (DEIS, Censo)
├── ICD_2019/                      # Recursos CIE-10
├── archivo/                       # Legacy + html_precorreccion/ + resultados_raiz_pre-2026/ (gitignored)
├── vignettes/ · man/              # Heredados de estructura de paquete
└── _extensions/                   # Extensiones Quarto
```

### Archivos sueltos en la raíz (a limpiar)

**Resuelta el 2026-10-11.** Ya no quedan HTML en la raíz: los renders pre-corrección se
movieron a `archivo/html_precorreccion/`; los scripts y logs de diagnóstico (`diag_*`,
`render_*`, `test_ciecl_bug.R`, `_render_figura4.R`, `_diff_vancouver_check.py`,
`*_check.md`, `glimpse_bbdd.html`) a `archivo/`; y el scratch (`nul`, `Rplots.pdf`,
`temp_*.txt`, `.adversarial_report.json`) a `99_TEMP/`. `output_qmd/` quedó archivado
completo en `archivo/html_precorreccion/output_qmd/`.

Residuales que permanecen en la raíz, fuera de la estructura estable (todos gitignored):

- Bases y subsets: `BBDD_*.RData`, `base_reducida.RData`, `datos_resumen_modificado.RData`.
- Planillas de insumo: `717508813-Establecimientos-ChileDEIS-...xlsx`, `Poblacion-censada-...Censo-2017.xlsx`.
- `perfiles_diagnosticos.rmarkdown` (artefacto de render intermedio).

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
| `R/funciones/` | Misceláneas: `ordenar_regiones()`, `visualizaciones_cie10.R` (figuras de journal). **No las carga el loader**: carga manual donde se usan. |

Política de carga (2026-10-11): `R/cargar_funciones.R` carga 62 scripts (todas las
subcarpetas salvo `funciones/`). De carga manual, documentados en el propio loader:

- `R/analisis/generar_tablas_na_y_tbe_regional.R`: script ejecutable (lee fuentes y
  escribe CSV finales al correrse); uso: `Rscript R/analisis/generar_tablas_na_y_tbe_regional.R`.
- `R/funciones/ordenar_regiones.R` y `R/funciones/visualizaciones_cie10.R`.

Los 3 scripts de sesgo RSH/CONADI en `R/graficos/` (`fig_sesgo_supervivencia_*`,
`fig_distribucion_enlace_*`, `grafico_S6_*`) sí los carga el loader: son autocontenidos,
verifican paquetes al cargar y su `main()` solo corre cuando se ejecutan directos.

---

## `analisis/` — QMDs por tema

| Carpeta | QMD principal | Objetivo |
|---|---|---|
| `00_descriptivos/` | `cuadro_descriptivo_egresos.qmd` | Descriptivos base |
| `01_descriptivos/` | `E_descriptiva_modular.qmd`, `datos_descriptivos_modular.qmd` | Estadística descriptiva general |
| `02_tendencias/` | `grafico_pertenencia_modular.qmd` | Tendencias de pertenencia PO |
| `03_concordancia/` | `Concord_nuevas_modular.qmd` | **CCC principal** (Obj 1–3) |
| `04_sociodemografico/` | `graf_cie_prev_modular.qmd` | CIE-10 por previsión |
| `05_perfiles_cie10/` | `perfiles_diagnosticos_*.qmd`, `tli_ajustada_edad.qmd`, `figuras_tesis_*.qmd` | Perfiles CIE-10 PO vs PG (Obj 4) |

Nota (2026-10-11): `06_comentarios_tania/` se disolvió por tema
(`tli_ajustada_edad.qmd` + html/_files → `05_perfiles_cie10/`;
`caracterizacion_prevision_po_pg.qmd` + html → `04_sociodemografico/`;
`contraste_regional_tbe_censo.qmd` → `02_tendencias/`) y `_loteC/` se archivó
completo en `archivo/loteC_20260922/` (scripts one-off y QMD de respaldo del
Anexo 4, con correctivo del denominador PG pendiente).

Cada subcarpeta tiene su `resultados_tesis/` con figuras/tablas generadas y carpetas `*_files/` de renders (gitignored).

---

## `resultados_tesis/` — resultados (solo `VIGENTES/` se publica)

Regla en `.gitignore` (2026-10-11): `resultados_tesis/*` ignora todo el contenido y la
excepción `!resultados_tesis/VIGENTES/` + `!resultados_tesis/VIGENTES/**` (al final del
archivo, para prevalecer sobre las reglas globales `*.csv`, `*.docx` y `*.html`)
re-incluye solo la carpeta canónica. Verificado con `git check-ignore`.

| Subcarpeta | Estado |
|---|---|
| `VIGENTES/` | **Publicable.** Solo HTML autocontenido (figuras embebidas) + CSV + `INDICE.md`, organizado por temas: `concordancia/`, `indicadores/`, `perfiles/`, `sesgo_supervivencia/`. Sin DOCX ni figuras sueltas (decisión 2026-10-11). |
| `concordancias/`, `resultados_concordancia/`, `indicadores_epidemiologicos*/` (incluye `anexo4_etario/`, ex-loteC), `perfiles*/`, `top20*/`, `sesgo_supervivencia/`, `comentarios_tania/`, `final_resultados/` | Material local de trabajo (gitignored). Los originales de lo copiado a `VIGENTES/` permanecen aquí. |

Ordenamiento 2026-10-11: los PNG/JPG sueltos de la raíz de `resultados_tesis/` (182
archivos, dic-2025 a may-2026) se archivaron en `archivo/resultados_raiz_pre-2026/`; los
HTML pre-corrección (raíz del repo, `concordancias/`, `html/`, `output_qmd/`,
`analisis/*/resultados_tesis/` de 00 a 04, y los de la carpeta anidada eliminada
`resultados_tesis/resultados_tesis/`) quedaron en `archivo/html_precorreccion/`; los
huérfanos de concordancia en `archivo/huerfanos_concordancias/`.

Residual suelto en la raíz de `resultados_tesis/` (pendiente de clasificar en una
iteración futura): tablas HTML/DOCX sueltas (`tabla_*.html/docx`, `top_cie10_*.html`) y
carpetas sueltas (`tabla_*_anual/`, `tabla_*_promedio/`, `top_patologias_po/`).

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
| `04_INSUMOS/` | Insumos del proceso (actas de aprobación, formularios, templates de revista). Detalle y estado en `docs/estado_documentos_tesis.md`. |
