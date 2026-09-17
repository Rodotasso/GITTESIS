# Correcciones gráficas y de tabla Cap2 (Sandra) — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aplicar las correcciones gráficas diferidas de la revisión de Sandra al capítulo 2 (Objetivo 4): consolidar Fig 2.1+2.2, eliminar Fig 2.3 y la columna DPP de la tabla maestra, arreglar la leyenda cortada del scatter (Fig 2.5), pasar la figura de edad (2.7) a 2 columnas y añadir una figura gemela en población general para la figura de brecha por sexo (2.9).

**Architecture:** Las figuras del capítulo provienen de dos QMD (`perfiles_diagnosticos_objetivo4.qmd` y `perfiles_diagnosticos_desagregados.qmd`) que llaman funciones en `R/graficos/graficos_objetivo4.R`, `R/perfiles/calcular_indicadores_objetivo4.R` y funciones inline en el propio QMD desagregado. Se editan funciones y celdas QMD; la verificación es por regeneración + revisión visual del artefacto (no hay suite de tests unitarios para gráficos).

**Tech Stack:** R 4.6.0, ggplot2, patchwork, flextable, dplyr/tidyr, Quarto. Datos: `BBDD_homologados.RData` (~21M filas). Ruta R: `C:\Program Files\R\R-4.6.0\bin\Rscript.exe`.

**Convención de verificación:** cada tarea de código se verifica con un script R mínimo que sourcéa funciones, genera el objeto afectado con un subconjunto/datos reales y confirma estructura (columnas/clase). La inspección visual final está en la Tarea 6.

---

## Tarea 0: Restaurar entorno renv para R 4.6.0 (PREREQUISITO — requiere OK del autor)

**Contexto:** R se actualizó a 4.6.0 y la librería renv (compilada para 4.4.3) quedó incompatible; `requireNamespace('ggplot2')` devuelve FALSE. Sin esto no se puede regenerar ninguna figura. Ver memoria `project_r460_renv_desync`. **No ejecutar sin autorización explícita** (regla del proyecto: prohibidas reparaciones automáticas).

- [ ] **Step 1: Confirmar estado**

Run: `& "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" -e "renv::status()"`
Expected: reporta out-of-sync / paquetes no instalados.

- [ ] **Step 2: Restaurar (tras OK del autor)**

Run: `& "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" -e "renv::restore(prompt = FALSE)"`
Expected: reinstala desde `renv.lock`. Puede tardar (compilación). Si `renv.lock` no resuelve bajo 4.6.0, escalar al autor antes de modificar el lockfile.

- [ ] **Step 3: Verificar paquetes clave**

Run: `& "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" -e "cat(sapply(c('ggplot2','patchwork','flextable','ggrepel','dplyr','tidyr','stringr'), requireNamespace, quietly=TRUE))"`
Expected: `TRUE TRUE TRUE TRUE TRUE TRUE TRUE`

No hay commit en esta tarea (cambios solo en `renv/library`, ya gitignored).

---

## Tarea 1: Tabla maestra — eliminar columna DPP, reordenar y estandarizar estilo

**Files:**
- Modify: `R/perfiles/calcular_indicadores_objetivo4.R`

Responde comentarios id=3 ("¿por qué brechas solo para PEC?") e id=2 (estilo único de tablas). Decisión del autor: quitar la diferencia de proporciones de la tabla.

- [ ] **Step 1: Eliminar el cálculo de BPP en `calcular_indicadores_objetivo4()`**

En el bloque "3. Calcular Brecha de Puntos Porcentuales (BPP)", eliminar todo el bloque `brechas <- ...` y el `left_join(brechas, ...)` del ensamblado. El `select` final pasa de:

```r
  resultado <- indicadores_capitulo %>%
    dplyr::left_join(brechas, by = "Capitulo") %>%
    dplyr::select(grupo, Capitulo, Ec, Et, PEC, BPP, TLI, PDE, TBE) %>%
    dplyr::arrange(Capitulo, desc(grupo))
```

a:

```r
  resultado <- indicadores_capitulo %>%
    dplyr::select(grupo, Capitulo, Ec, Et, PEC, TLI, PDE, TBE) %>%
    dplyr::arrange(Capitulo, desc(grupo))
```

Y en el bloque `if (verbose)`, cambiar la línea que menciona BPP:

```r
    cat("  ✓ Indicadores TBE, TLI, PEC y PDE generados.\n")
```

- [ ] **Step 2: Quitar BPP de `crear_tabla_maestra_perfiles()`**

Reemplazar el armado de `tabla_df`:

```r
  tabla_df <- datos_resultado %>%
    dplyr::select(Capitulo, grupo, TBE, PEC, TLI, PDE) %>%
    tidyr::pivot_wider(
      names_from = grupo,
      values_from = c(TBE, PEC, TLI, PDE)
    ) %>%
    dplyr::select(
      Capitulo,
      TBE_PI, TBE_PG,
      PEC_PI, PEC_PG,
      TLI_PI, TLI_PG,
      PDE_PI, PDE_PG
    ) %>%
    dplyr::arrange(dplyr::desc(PEC_PI)) # Ordenar por peso relativo en pueblos indígenas
```

- [ ] **Step 3: Quitar header BPP, colores/negrita BPP y estandarizar estilo**

Reemplazar la construcción de `ft`:

```r
  ft <- flextable::flextable(tabla_df) %>%
    flextable::set_header_labels(
      Capitulo = "Capítulo CIE-10",
      TBE_PI = "Tasa Bruta de Egreso\nPueblos Indígenas (x10.000)",
      TBE_PG = "Tasa Bruta de Egreso\nPoblación General (x10.000)",
      PEC_PI = "Proporción de Egresos por Causa\nPueblos Indígenas (%)",
      PEC_PG = "Proporción de Egresos por Causa\nPoblación General (%)",
      TLI_PI = "Tasa de Letalidad Intrahospitalaria\nPueblos Indígenas (%)",
      TLI_PG = "Tasa de Letalidad Intrahospitalaria\nPoblación General (%)",
      PDE_PI = "Estada\nPueblos Indígenas (días)",
      PDE_PG = "Estada\nPoblación General (días)"
    ) %>%
    flextable::colformat_double(j = 2:9, digits = 2) %>%
    flextable::align(align = "center", part = "all") %>%
    flextable::align(j = 1, align = "left", part = "all") %>%
    flextable::fontsize(size = tamano_fuente, part = "all") %>%
    flextable::bold(part = "header") %>%
    flextable::bold(part = "body", bold = FALSE) %>%
    flextable::set_caption(titulo) %>%
    flextable::theme_booktabs() %>%
    flextable::autofit()
```

(Estilo: `theme_booktabs` = solo líneas horizontales; negrita solo en encabezado.)

- [ ] **Step 4: Verificar estructura de la tabla**

Run:
```powershell
& "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" -e "source('R/cargar_funciones.R'); d <- data.frame(grupo=rep(c('PI','PG'),3), Capitulo=rep(c('A','B','C'),each=2), Ec=1:6, Et=rep(100,6), PEC=c(10,8,20,25,5,3), TLI=c(1,2,1,1,3,2), PDE=c(4,5,4,4,6,5), TBE=c(50,40,60,55,30,20)); ft <- crear_tabla_maestra_perfiles(d, 'Tabla 1. Prueba'); cat('cols:', paste(ft\$col_keys, collapse=', '), '\n')"
```
Expected: `cols: Capitulo, TBE_PI, TBE_PG, PEC_PI, PEC_PG, TLI_PI, TLI_PG, PDE_PI, PDE_PG` (sin `BPP`).

- [ ] **Step 5: Commit**

```bash
git add "R/perfiles/calcular_indicadores_objetivo4.R"
git commit -m "feat: quitar columna DPP de tabla maestra y estandarizar estilo (obj4)"
```

---

## Tarea 2: Consolidar Fig 2.1 + 2.2 en una figura de 2 paneles y eliminar Fig 2.3

**Files:**
- Modify: `R/graficos/graficos_objetivo4.R`
- Modify: `analisis/05_perfiles_cie10/perfiles_diagnosticos_objetivo4.qmd`

Responde id=4 (juntar 2.1 y 2.2, agrandar etiquetas) y la eliminación de Fig 2.3 (id=5/id=6 + decisión DPP).

- [ ] **Step 1: Añadir función de panel en `graficos_objetivo4.R`**

Agregar al final del archivo:

```r
#' Panel consolidado de Top Causas (PI + PG en 2 paneles)
#' @export
grafico_barras_top_pec_panel <- function(datos_obj4, top_n = 10) {
  library(ggplot2)
  library(patchwork)

  ajustar <- function(p, subtitulo) {
    p +
      ggplot2::labs(title = NULL, subtitle = subtitulo) +
      ggplot2::theme(
        axis.text.y = ggplot2::element_text(size = 12),
        axis.text.x = ggplot2::element_text(size = 11),
        plot.subtitle = ggplot2::element_text(face = "bold", size = 12)
      )
  }

  p_pi <- ajustar(grafico_barras_top_pec(datos_obj4, grupo_obj = "PI", top_n = top_n),
                  "Pertenecientes a pueblos indígenas")
  p_pg <- ajustar(grafico_barras_top_pec(datos_obj4, grupo_obj = "PG", top_n = top_n),
                  "Población general")

  (p_pi | p_pg) +
    patchwork::plot_annotation(
      title = sprintf("Principales %d causas de egreso hospitalario por capítulo CIE-10", top_n),
      tag_levels = "A",
      theme = ggplot2::theme(plot.title = ggplot2::element_text(size = 15, face = "bold"))
    )
}
```

- [ ] **Step 2: Reemplazar las dos celdas de barras en el QMD por una sola**

En `perfiles_diagnosticos_objetivo4.qmd`, reemplazar las secciones "### Top 10 Causas - Pertenecientes a Pueblos Indígenas" y "### Top 10 Causas - Población General" (prosa + ambas celdas `barras-pi` y `barras-pg`) por:

````markdown
### Top 10 Causas de Hospitalización (Pueblos Indígenas y Población General)
La **Figura 2.1** consolida en dos paneles la estructura de morbilidad hospitalaria: el panel A corresponde a la población indígena (donde "Embarazo, parto y puerperio" concentra el mayor peso relativo) y el panel B a la población general (donde digestivo, respiratorio y circulatorio tienen un peso más parejo en el tope de la lista).

```{r barras-panel}
#| fig-cap: "Figura 2.1. Principales causas de egreso hospitalario por capítulo CIE-10, según pertenencia a pueblos indígenas (panel A) y población general (panel B). Chile, 2010-2022."
#| fig-width: 14
#| fig-height: 7
p_barras_panel <- grafico_barras_top_pec_panel(resultados_obj4, top_n = 10)
guardar_multiformato(p_barras_panel, "figura_2_1_top_causas_panel", ancho = 14, alto = 7, dir_salida = "resultados_tesis/figuras")
p_barras_panel
```
````

- [ ] **Step 3: Eliminar la sección de la Figura 2.3 (divergente DPP) en el QMD**

Eliminar por completo la sección "### Gráfico Divergente de Brechas (BPP)" (su prosa y la celda `grafico-divergente` que llama a `grafico_divergente_bpp`). Mantener intactas las secciones Dumbbell y Scatterplot que siguen.

- [ ] **Step 4: Verificar que la función de panel construye sin error**

Run:
```powershell
& "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" -e "source('R/cargar_funciones.R'); d <- data.frame(grupo=rep(c('PI','PG'),each=12), Capitulo=paste0('Cap',1:12), PEC=c(22,13,9,8,7,6,5,4,3,2,1,0.5, 17,14,10,9,8,7,6,5,4,3,2,1)); p <- grafico_barras_top_pec_panel(d, top_n=10); cat('clase:', paste(class(p), collapse=','), '\n')"
```
Expected: imprime una clase que incluye `patchwork` / `gg` sin error.

- [ ] **Step 5: Commit**

```bash
git add "R/graficos/graficos_objetivo4.R" "analisis/05_perfiles_cie10/perfiles_diagnosticos_objetivo4.qmd"
git commit -m "feat: consolidar Fig 2.1+2.2 en panel y eliminar Fig 2.3 divergente"
```

---

## Tarea 3: Arreglar leyenda cortada del scatter (Fig 2.5)

**Files:**
- Modify: `R/graficos/graficos_objetivo4.R`

El autor reporta que parte de la leyenda del gráfico de dispersión (PEC vs TLI) se corta. Causa probable: las dos etiquetas largas en la leyenda inferior sin control de filas/márgenes.

- [ ] **Step 1: Ajustar leyenda en `grafico_cuadrantes_severidad()`**

Reemplazar el bloque final `labs(...) + theme(...)` por:

```r
    labs(
      title = "Severidad vs. Frecuencia de Hospitalización",
      subtitle = "Tasa de Letalidad Intrahospitalaria vs. Proporción de Egresos por Causa",
      x = "Proporción de Egresos por Causa (PEC %)",
      y = "Tasa de Letalidad Intrahospitalaria (TLI %)",
      color = "Población"
    ) +
    guides(color = guide_legend(nrow = 1, byrow = TRUE, override.aes = list(size = 4))) +
    theme(
      legend.position = "bottom",
      legend.title = element_text(size = 11),
      legend.text = element_text(size = 10),
      legend.box.margin = margin(t = 4, b = 4),
      plot.title = element_text(face = "bold"),
      plot.margin = margin(10, 16, 10, 10)
    )
```

- [ ] **Step 2: Verificar que construye sin error**

Run:
```powershell
& "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" -e "source('R/cargar_funciones.R'); d <- data.frame(grupo=rep(c('PI','PG'),5), Capitulo=paste0('Cap',1:10), PEC=runif(10,1,20), TLI=runif(10,0,8)); p <- grafico_cuadrantes_severidad(d); ggplot2::ggsave(tempfile(fileext='.png'), p, width=10, height=6); cat('ok\n')"
```
Expected: `ok` (guarda sin error). La verificación visual del recorte se hace en Tarea 6.

- [ ] **Step 3: Commit**

```bash
git add "R/graficos/graficos_objetivo4.R"
git commit -m "fix: evitar recorte de leyenda en scatter PEC vs TLI (Fig 2.5)"
```

---

## Tarea 4: Figura de disparidades por edad (2.7) a panel de 2 columnas

**Files:**
- Modify: `analisis/05_perfiles_cie10/perfiles_diagnosticos_desagregados.qmd` (función inline `graficar_disparidades_facet`, ~línea 68, y la celda de edad, ~línea 226)

Responde id=9 (pasar a 2 columnas; etiquetas muy pequeñas; página completa).

- [ ] **Step 1: Parametrizar `ncol` y tamaño de etiquetas en `graficar_disparidades_facet`**

Cambiar la firma y el `facet_wrap`/`theme`. Firma:

```r
graficar_disparidades_facet <- function(datos_ind, var_facet, titulo, ncol = NULL, text_size = 9) {
```

`facet_wrap`:

```r
    facet_wrap(as.formula(paste("~", var_facet)), scales = "free_y", ncol = ncol) +
```

`theme` final:

```r
    theme_minimal() +
    theme(
      legend.position = "bottom",
      strip.text = element_text(face = "bold", size = 11),
      axis.text.y = element_text(size = text_size)
    )
```

(La llamada de sexo, línea ~203, no pasa `ncol` y conserva el comportamiento actual.)

- [ ] **Step 2: Actualizar la celda de edad para usar 2 columnas y exportar a página completa**

En la celda `{r edad}` (la que llama `graficar_disparidades_facet(ind_edad, "grupo_etario", ...)`), reemplazar la llamada por:

```r
#| fig-width: 11
#| fig-height: 13
p_edad <- graficar_disparidades_facet(
  ind_edad, "grupo_etario",
  "Brechas Diagnósticas por Grupo Etario",
  ncol = 2, text_size = 10
)
guardar_multiformato(p_edad, "figura_2_7_disparidades_edad", ancho = 11, alto = 13,
                     dir_salida = "resultados_tesis/figuras")
p_edad
```

- [ ] **Step 3: Verificar construcción con ncol=2**

Run:
```powershell
& "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" -e "library(ggplot2); library(dplyr); library(stringr); colores_pertenencia <- c(PO='#D32F2F', PG='#1976D2'); graficar_disparidades_facet <- function(datos_ind, var_facet, titulo, ncol=NULL, text_size=9){ df_plot <- datos_ind %>% group_by(.data[[var_facet]]) %>% arrange(desc(abs(BPP))) %>% slice_head(n=10) %>% ungroup() %>% mutate(color_brecha=ifelse(BPP>0,'Sobre','Sub'), Capitulo_wrap=str_wrap(Capitulo,35)); ggplot(df_plot, aes(reorder(Capitulo_wrap,BPP), BPP, fill=color_brecha)) + geom_col() + facet_wrap(as.formula(paste('~',var_facet)), scales='free_y', ncol=ncol) + coord_flip() }; d <- data.frame(grupo_etario=rep(c('0-4','5-14','15-24','25-44'),each=5), Capitulo=paste0('C',1:20), BPP=rnorm(20)); p <- graficar_disparidades_facet(d,'grupo_etario','t',ncol=2); cat('facet ncol ok\n')"
```
Expected: `facet ncol ok` (verifica que el patrón `ncol` no rompe; la versión real vive en el QMD).

- [ ] **Step 4: Commit**

```bash
git add "analisis/05_perfiles_cie10/perfiles_diagnosticos_desagregados.qmd"
git commit -m "feat: figura de disparidades por edad (2.7) en panel de 2 columnas"
```

---

## Tarea 5: Figura de brecha por sexo (2.9) — añadir equivalente en población general

**Files:**
- Modify: `analisis/05_perfiles_cie10/perfiles_diagnosticos_desagregados.qmd` (sección 6, celda `{r sexo-region}`, ~línea 332)

Responde id=10: añadir equivalente en población general para comparar el patrón mujer-hombre entre poblaciones.

- [ ] **Step 1: Reemplazar el ggplot de la celda `sexo-region`**

Cambiar el `filter(grupo == "PI")` por ambos grupos y facetar por población:

```r
g_sexo_region <- ind_sexo_reg %>%
  dplyr::filter(grupo %in% c("PI", "PG")) %>%
  dplyr::group_by(grupo, region, sexo) %>%
  dplyr::summarise(TBE_global = sum(TBE), .groups = "drop") %>%
  dplyr::mutate(
    nombre_region = codigo_a_nombre_region(region, tipo = "corto"),
    nombre_region = factor(nombre_region, levels = tabla_regiones$nombre_corto),
    grupo = factor(grupo, levels = c("PI", "PG"),
                   labels = c("Población indígena", "Población general"))
  ) %>%
  ggplot(aes(x = nombre_region, y = TBE_global, fill = sexo)) +
  geom_col(position = "dodge") +
  facet_wrap(~ grupo, ncol = 1, scales = "free_y") +
  scale_fill_manual(values = c("HOMBRE" = colores_sexo[["HOMBRE"]], "MUJER" = colores_sexo[["MUJER"]])) +
  labs(
    title = "Carga Total de Egresos (TBE) por Región y Sexo: Población Indígena vs Población General",
    subtitle = "Tasas Brutas por 10.000 habitantes; permite comparar el patrón por sexo entre poblaciones",
    x = NULL,
    y = "TBE x 10k hab.",
    fill = "Sexo",
    caption = "Regiones ordenadas de Norte a Sur."
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(face = "bold", size = 12),
    legend.position = "bottom"
  )

guardar_multiformato(g_sexo_region, "figura_2_9_tbe_region_sexo_PI_PG", ancho = 12, alto = 11,
                     dir_salida = "resultados_tesis/figuras")
g_sexo_region
```

Añadir al chunk las opciones `#| fig-width: 12` y `#| fig-height: 11`.

- [ ] **Step 2: Actualizar la prosa de la sección 6**

Ajustar el texto introductorio de la sección 6 para mencionar la comparación PI vs PG (en vez de solo PI), p. ej.: "Se comparó la carga total de egresos por región y sexo entre población indígena y población general, para evaluar si el patrón de diferencias por sexo se mantiene entre ambas poblaciones."

- [ ] **Step 3: Verificar patrón de faceta por grupo**

Run:
```powershell
& "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" -e "library(ggplot2); library(dplyr); colores_sexo <- c(HOMBRE='#1f77b4', MUJER='#e377c2'); d <- expand.grid(grupo=c('PI','PG'), region=1:3, sexo=c('HOMBRE','MUJER')); d\$TBE <- runif(nrow(d),20,200); p <- d %>% group_by(grupo,region,sexo) %>% summarise(TBE_global=sum(TBE),.groups='drop') %>% mutate(grupo=factor(grupo,c('PI','PG'),c('Indígena','General'))) %>% ggplot(aes(factor(region),TBE_global,fill=sexo)) + geom_col(position='dodge') + facet_wrap(~grupo, ncol=1, scales='free_y') + scale_fill_manual(values=colores_sexo); ggplot2::ggsave(tempfile(fileext='.png'),p,width=8,height=8); cat('facet PI/PG ok\n')"
```
Expected: `facet PI/PG ok`

- [ ] **Step 4: Commit**

```bash
git add "analisis/05_perfiles_cie10/perfiles_diagnosticos_desagregados.qmd"
git commit -m "feat: figura TBE region x sexo con equivalente en poblacion general (Fig 2.9)"
```

---

## Tarea 6: Regeneración real y verificación visual

**Files:** ninguno (ejecución/inspección). Requiere Tarea 0 completada.

- [ ] **Step 1: Renderizar el QMD del objetivo 4**

Run:
```powershell
cd "D:\MAGISTER\aa TESIS\rtsppoo"; quarto render "analisis/05_perfiles_cie10/perfiles_diagnosticos_objetivo4.qmd"
```
Expected: render sin error; genera HTML y figuras en `resultados_tesis/figuras`.

- [ ] **Step 2: Renderizar el QMD desagregado**

Run:
```powershell
cd "D:\MAGISTER\aa TESIS\rtsppoo"; quarto render "analisis/05_perfiles_cie10/perfiles_diagnosticos_desagregados.qmd"
```
Expected: render sin error.

- [ ] **Step 3: Inspección visual de los artefactos**

Abrir y revisar en `resultados_tesis/figuras`:
- `figura_2_1_top_causas_panel.jpg` → 2 paneles (A/B), título único, etiquetas de causas legibles.
- `figura_2_5_cuadrantes_severidad.jpg` (scatter) → leyenda completa, sin recorte.
- `figura_2_7_disparidades_edad.jpg` → 2 columnas, etiquetas legibles, página completa.
- `figura_2_9_tbe_region_sexo_PI_PG.jpg` → dos paneles PI y PG comparables.

En `resultados_tesis/tablas`:
- `tabla_1_perfiles_diagnosticos_obj4.png` → sin columna DPP/BPP, solo líneas horizontales, negrita solo encabezado, ordenada por PEC de pueblos indígenas.

Confirmar también que la Figura 2.3 (divergente) ya no se genera.

- [ ] **Step 4: Commit de figuras/tablas regeneradas (si el repo las trackea)**

Verificar con `git status` qué artefactos cambiaron y, con OK del autor, commitear:
```bash
git add resultados_tesis/figuras resultados_tesis/tablas
git commit -m "chore: regenerar figuras y tabla del cap2 tras correcciones de Sandra"
```

(Nota: `resultados_tesis/` puede estar parcialmente gitignored; revisar antes de commitear.)

---

## Notas de cierre

- No se modifican objetivos del protocolo.
- No hay commits/push sin OK explícito del autor (regla del proyecto).
- Las ediciones de texto del .docx (id=0, id=1, id=7, id=11) están fuera de alcance (ya hechas o manuales en Word).
- `grafico_divergente_bpp()` queda sin uso; se conserva su definición para no romper otros QMD que pudieran referenciarla.
