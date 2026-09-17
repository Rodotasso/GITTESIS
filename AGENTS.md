# AGENTS.md : Tesis PPOO · Egresos Hospitalarios Chile (contexto para agentes)

Consolidación de `CLAUDE.md` y `gemini.md` para agentes en este workspace.
Las reglas globales (`~/.omp/agent/AGENTS.md` + `RULES.md`) siguen activas; este archivo agrega lo específico del proyecto. Fuente de verdad para reglas externas: los originales.

---

## 1. Naturaleza del repositorio

- **NO es un paquete R.** `DESCRIPTION`/`NAMESPACE`/`man/` son heredados y no se usan. Nada de `devtools`, `roxygen2`, `R CMD check`.
- `R/` contiene scripts modulares por tema; se cargan con `source("R/cargar_funciones.R")`.
- `ciecl` (CRAN) es dependencia **externa**; no vive en este repo.
- Dependencias fijadas con `renv` (`renv.lock`); verificar antes de proponer paquetes nuevos.
- **Proyecto:** tesis Magíster Salud Pública (U. de Chile). Análisis epidemiológico de Pueblos Originarios (PO) con egresos hospitalarios 2010–2022: concordancia entre fuentes de pertenencia (CCC de Lin), perfiles diagnósticos CIE-10 PO vs Población General, disparidades por región/sexo/edad/previsión.
- Repo remoto: <https://github.com/Rodotasso/GITTESIS>.

## 2. Reglas críticas del proyecto (no negociables)

1. **Reparaciones prohibidas:** jamás reparar bases de datos (`.RData`, `.csv`) ni hacer modificaciones estructurales sin autorización explícita. Protocolo: diagnosticar → informar con evidencia → proponer → **esperar aprobación** → respaldo (BACKUP) → ejecutar.
2. **Git:** sin stage/commit/push/PR sin orden explícita. Verificar `.gitignore` antes de tocar `.RData` pesados.
3. **Datos sensibles:** no leer `Lock_sensible/` ni bases con RUN sin hash salvo necesidad estricta y autorización.
4. **Rutas (CRÍTICO):** prohibido `../../`. Todo `.qmd`/script usa `rprojroot`:

   ```r
   if (!exists("project_root")) {
     project_root <- rprojroot::find_root(rprojroot::has_file("BBDD_homologados.RData"))
   }
   source(file.path(project_root, "R/cargar_funciones.R"))
   load(file.path(project_root, "BBDD_homologados.RData"))
   ```

   Exportaciones siempre con `file.path(project_root, ...)`.
5. **Context7 obligatorio** antes de escribir código con paquetes (dplyr, ggplot2, flextable, DescTools…). No aplica a refactoring ni lectura para entender bugs.
6. **Memoria:** al iniciar sesión de trabajo relevante, leer memorias del proyecto; al cerrar hitos, guardar progreso proactivamente.

## 3. Entorno verificado (2026-08-09)

- Rscript: `C:/Program Files/R/R-4.6.0/bin/Rscript.exe` (⚠ `CLAUDE.md` dice 4.4.3 : desactualizado; instalado es **4.6.0**). No está en PATH.
- Quarto: `1.6.40` (en PATH). Render desde la raíz:

  ```bash
  quarto render analisis/03_concordancia/Concord_nuevas_modular.qmd
  ```

- Bash en este equipo NO mapea `/c/…` (Git-Bash paths); usar PowerShell (`powershell -NoProfile -Command …`) para rutas de sistema Windows.
- **renv desincronizado:** el entorno R 4.6.0 no tiene los paquetes de `renv.lock` restaurados. Antes de renders pesados o regenerar figuras, restaurar con `renv::restore()` (con OK del usuario). Detalle: memoria `project_r460_renv_desync.md`.

## 4. Datos

- Base principal: `BBDD_homologados.RData` → objeto `datos_homologados` (20 957 004 registros × 29 columnas, gitignored).
- Columnas clave: `RUN` (hash), `DIAG1` (CIE-10), `PERTENENCIA` (EH binaria), `PERTENENCIA2` (enriquecida RSH+CONADI+EH), `PUEBLO_ORIGINARIO_BIN`, `CONADI`, `RSH`, `GLOSA_SEXO`, `EDAD_ANOS`/`GRUPO_ETARIO`/`Grupo_Edad`, `GLOSA_PREVISION`, `AÑO` (chr "2010"–"2022"), `NOMBRE_REGION` (del establecimiento, no residencia), `CODIGO_REGION`, `Grupo_CIE10`, fechas `*_FMT_DEIS` (IDate), `RSH_label`/`CONADI_label`/`EGRESO_label`, `DEPENDENCIA`/`TIPO_ESTABLECIMIENTO`/`ESTAB_HOMO`.
- Esquema completo: memoria del proyecto (`MEMORY.md` en `~/.claude/projects/D--MAGISTER-aa-TESIS-rtsppoo/memory/`).
- **Ñuble:** SÍ está reconstruida retrospectivamente en EH vía homologación de establecimientos (`ESTAB_HOMO` contra maestro DEIS abr-2022; ver `preparacion/Homologacion de establecimientos.qmd`); todo establecimiento de Ñuble lleva `CODIGO_REGION = "16"` en toda la serie 2010-2022 (515.662 egresos, 2,46% de la base). `crear_region_nuble()` (21 comunas) aplica SOLO al Censo 2017; EH no tiene comuna y no la necesita. CCC=0,09 de Ñuble ya NO se explica por ausencia de serie pre-2018: pendiente de reinterpretación (p.ej. subregistro de pertenencia en establecimientos de Ñuble).

## 5. Estructura de navegación

- `analisis/` : QMDs temáticos 00–05 (`03_concordancia/Concord_nuevas_modular.qmd` = CCC principal).
- `R/` : `graficos/`(13), `analisis/`(10), `concordancias/`(10), `perfiles/`(9), `tablas/`(6), `utilidades/`(7), `funciones/`(2).
- `preparacion/` : limpieza/homologación. `resultados_tesis/` : figuras/tablas finales.
- `DOCUMENTOS TESIS/` : manuscritos, guías (`GUIA_PAPER_TESIS.md`, `GUIA_TESIS_COMPLETA.md`, `LINEAMIENTOS_SALUD_PUBLICA_MEXICO.md`), auditorías (gitignored).
- `docs/estructura_repositorio.md` : mapa completo. `docs/estado_documentos_tesis.md` : estado vigente/enviado/respaldo de cada manuscrito. Consultar antes de explorar.
- `html/`, `output_qmd/` : renders (gitignored el primero).

## 6. Estándares de código y prosa

- **Código:** tidyverse style, ASCII limpio en identificadores/strings ejecutables; funciones modulares DRY; validar inputs; `requireNamespace()` para deps opcionales; conexiones con `on.exit()`.
- **Prosa:** español técnico con tildes y eñes completas (UTF-8) en docs, labels y markdown.
- **Gráficos:** ggplot2 + `guardar_multiformato()`/`guardar_figura_revista()` (600 dpi). **Tablas:** flextable + `guardar_tabla_png()`.
- **Citas:** Vancouver `[@clave]`, inmediatamente después del concepto (no al final del párrafo); verificar clave en `referencias_tesis.bib` con `vancouver-superscript.csl`. Lineamientos revista: *Salud Pública de México* (SPM).
- **Preferencias del autor (feedback confirmado):**
  - Sin guiones largos (em-dash) en prosa visible; usar comas, paréntesis o dos puntos.
  - Evitar la palabra "brecha": usar "Diferencia de Puntos Porcentuales (DPP)" (término canónico), "disparidades" o "diferencias".
  - Objetivos del protocolo/tesis intocables salvo autorización explícita e individual.
  - Antes de cada `git commit` y cada `git push`: mostrar contenido y esperar OK, sin encadenar de corrido.
- **Autoría:** sin menciones de IA en commits/código/docs.
- **Cita del repo:** Zenodo DOI `10.5281/zenodo.20518201` (v1.0.0, MIT); usar para citar el repositorio en manuscritos.

## 7. Bug conocido

`calcular_ccc_detallado()` calcula un CCC global e **ignora `columnas_categoria`**. Para tablas resumen por nivel de desagregación usar siempre `calcular_ccc_desagregacion()`.

## 8. Skills y agentes (harness omp)

Invocar antes de actuar cuando aplique (equivalencias a las skills "superpowers" de `CLAUDE.md`):

- `brainstorming` : antes de tareas complejas de análisis.
- `writing-plans` / `executing-plans` : planificar / implementar planes.
- `systematic-debugging` : errores en R/Quarto (verificar primero rutas `project_root`).
- `verification-before-completion` : antes de declarar término.
- `test-driven-development` : funciones nuevas.
- `dispatching-parallel-agents` : análisis paralelos independientes.
- `academic-write` / `academic-fix` : revisión/corrección de secciones contra SPM (soportan modo TESIS).
- `scholar-evaluation`, `statistical-analysis`, `peer-review`, `scientific-writing` : según dominio.

Agente de auditoría académica: revisión multi-capa (formal, científico, STROBE, IMRaD, editorial) : usar agentes especializados del roster (`Academic Writer Spanish`, `R Code Reviewer`/`r-code-reviewer`, `R Manual Consultant`) según la tarea.

## 9. Eficiencia

- Respuestas concisas, sin preámbulos. Ediciones quirúrgicas (`edit` sobre `write` en archivos grandes). Búsquedas paralelas. No releer archivos ya vistos. Delegar exploración masiva a subagentes (`scout`).
- Gestión de memoria RAM: `rm()` + `gc()` en R tras objetos grandes; verificar headroom de pagefile antes de cargar los `.RData` de ~850–940 MB (regla global `pagefile-memoria.md`).
