# ==============================================================================
# SCRIPT: regenerar_figuras_pendientes_20261101.R
# ==============================================================================
#
# DESCRIPCIÓN:
#   Regeneración dirigida (plan de figuras 2026-10-31, Fase 2) de las figuras
#   pendientes. No reemplaza a regenerar_figuras_600dpi.R: solo rehace las
#   imágenes que requieren intervención, reutilizando sus mismos bloques de
#   código y funciones corregidas.
#
#   Parte A (defecto de solapamiento):
#     - Figura 7 (4320x2520 px, 7,2 x 4,2 in) y Figura S5 (5580x3720 px,
#       9,3 x 6,2 in): etiquetas de valor del forest ancladas en
#       max(valor, ic_sup) + 0,10 * amplitud (visualizaciones_cie10_fig7.R),
#       de modo que el remate del IC ya no queda sobre la cifra.
#
#   Parte B (suplementarias con texto quemado, mismo lienzo a 600 dpi):
#     - figura_S1_distribucion_enlace (6000x6600 px, 10 x 11 in): build_
#       distribution_figure() ya sin título/bajada/nota/fuente (editado en su
#       script generador R/graficos/fig_distribucion_enlace_rsh_conadi.R).
#     - figura_dumbbell_pec_po_vs_pg (6000x3600 px, 10 x 6 in): se retira el
#       título/subtítulo quemado de grafico_dumbbell_pec() en el llamado.
#     - fig_prevision_PO.jpg / fig_prevision_PG.jpg (6000x3300 px, 10 x 5,5 in):
#       réplica de analisis/04_sociodemografico/caracterizacion_prevision_po_pg.qmd
#       desde el CSV liviano, sin título ni fuente quemados.
#
# ENTRADA:
#   BBDD_homologados.RData (objeto `datos_homologados`, ~940 MB; blocks pesados)
#   resultados_tesis/VIGENTES/auditoria_rsh_conadi/F_nas_resumen.csv (S1)
#   temp_read/fase2_caracterizacion/caracterizacion_pertenencia2.csv (previsión)
#
# SALIDA:
#   DOCUMENTOS TESIS/FINAL-TESIS/figuras_nuevas/salida/600dpi/
#     figura_7_forest_heatmap_vertical.png/.jpg
#     figura_S5_forest_heatmap_vertical_todas.png/.jpg
#     figura_S1_distribucion_enlace.png/.jpg
#     figura_dumbbell_pec_po_vs_pg.png/.jpg
#   resultados_tesis/comentarios_tania/
#     fig_prevision_PO.png/.jpg
#     fig_prevision_PG.png/.jpg
#
# USO:
#   "C:/Program Files/R/R-4.6.0/bin/Rscript.exe" R/graficos/regenerar_figuras_pendientes_20261101.R
# ==============================================================================

# --- Raíz del proyecto (patrón project_root; prohibido "../../") -------------
if (!exists("project_root")) {
  project_root <- rprojroot::find_root(rprojroot::has_file("BBDD_homologados.RData"))
}

# --- Utilidades del repo ------------------------------------------------------
source(file.path(project_root, "R", "cargar_funciones.R"))
source(file.path(project_root, "R", "funciones", "ordenar_regiones.R"))

# Versiones corregidas (peticiones de las revisoras)
dir_scripts <- file.path(
  project_root, "DOCUMENTOS TESIS", "FINAL-TESIS", "figuras_nuevas", "scripts"
)
source(file.path(dir_scripts, "graficos_objetivo4.R"))

# Figura 7 / S5: originales + copias corregidas
source(file.path(project_root, "R", "funciones", "visualizaciones_cie10.R"))
source(file.path(dir_scripts, "visualizaciones_cie10_fig7.R"))

# Figura S1: funciones del generador (main() queda protegido por
# sys.nframe() y no se ejecuta al sourcearlo)
source(file.path(project_root, "R", "graficos",
                 "fig_distribucion_enlace_rsh_conadi.R"))

# --- Constantes ---------------------------------------------------------------
# Ojo: el script de S1 define OUT_DIR propio; se redefinen AQUÍ los directorios
# de salida de esta pasada para no interferir.
OUT_DIR <- file.path(
  project_root, "DOCUMENTOS TESIS", "FINAL-TESIS", "figuras_nuevas", "salida",
  "600dpi"
)
DIR_TANIA <- file.path(project_root, "resultados_tesis", "comentarios_tania")
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)
if (!dir.exists(DIR_TANIA)) dir.create(DIR_TANIA, recursive = TRUE)

DPI <- 600L

# ==============================================================================
# FUNCIÓN: guardar_figura_600 (mismo patrón que regenerar_figuras_600dpi.R)
# ==============================================================================
# PNG a 600 dpi + JPG derivado con magick (quality 95): el device JPEG de
# ggsave escribe un marcador APP14 que algunos decodificadores de este equipo
# muestran con colores invertidos.
guardar_figura_600 <- function(plot, nombre_base, ancho = 10, alto = 6,
                               dpi = DPI, dir_salida = OUT_DIR) {
  if (!dir.exists(dir_salida)) dir.create(dir_salida, recursive = TRUE)
  ruta_png <- file.path(dir_salida, paste0(nombre_base, ".png"))
  ruta_jpg <- file.path(dir_salida, paste0(nombre_base, ".jpg"))
  ggplot2::ggsave(ruta_png, plot, width = ancho, height = alto, dpi = dpi,
                  bg = "white")
  img <- magick::image_read(ruta_png)
  magick::image_write(img, ruta_jpg, format = "jpeg", quality = 95)
  cat("  OK ", nombre_base, ".png/.jpg (", dpi, " dpi)\n", sep = "")
  invisible(c(png = ruta_png, jpg = ruta_jpg))
}

# ==============================================================================
# BLOQUE 0 (liviano): Figura S1 — distribución del enlace
# ==============================================================================
# Datos desde la auditoría RSH/CONADI (F_nas_resumen.csv), igual que el
# generador original; el lienzo ya no lleva título, bajada, nota ni fuente.
cat("-- Bloque 0: Figura S1 distribución del enlace (10 x 11 in) --\n")

data_s1 <- load_link_distribution(AUDIT_DIR)
fig_s1 <- build_distribution_figure(
  data_s1$body,
  build_footnote(data_s1$excluded, compact = TRUE)
)
guardar_figura_600(fig_s1, "figura_S1_distribucion_enlace",
                   ancho = 10, alto = 11)
rm(data_s1, fig_s1)
gc(verbose = FALSE)

# ==============================================================================
# BLOQUE 1 (liviano): previsión PO y PG (comentario #79)
# ==============================================================================
# Réplica de analisis/04_sociodemografico/caracterizacion_prevision_po_pg.qmd
# desde el CSV liviano, con el mismo orden de barras y la misma paleta, pero
# sin título ni fuente quemados (los aporta el pie del docx).
cat("-- Bloque 1: previsión PO y PG (10 x 5,5 in, 600 dpi) --\n")

caracterizacion <- readr::read_csv(
  file.path(project_root, "temp_read", "fase2_caracterizacion",
            "caracterizacion_pertenencia2.csv"),
  show_col_types = FALSE
)

stopifnot(
  "Faltan columnas en caracterizacion_pertenencia2.csv" =
    all(c("variable", "categoria", "pertenencia", "N", "pct_columna") %in%
          names(caracterizacion)),
  "La variable GLOSA_PREVISION no está en el insumo" =
    "GLOSA_PREVISION" %in% caracterizacion$variable,
  "Faltan grupos PO/No PO en el insumo" =
    all(c("PO", "No PO") %in% caracterizacion$pertenencia)
)

prevision <- caracterizacion %>%
  dplyr::filter(variable == "GLOSA_PREVISION",
                pertenencia %in% c("PO", "No PO")) %>%
  dplyr::transmute(
    categoria,
    pertenencia,
    N,
    pct = pct_columna
  ) %>%
  dplyr::mutate(
    # Etiqueta explícita para los registros FONASA sin tramo A-D
    categoria_label = ifelse(categoria == "FONASA", "FONASA (sin tramo)",
                             categoria),
    # Clave de ordenamiento: FONASA sin tramo anclada al final del ranking
    pct_ord = ifelse(categoria == "FONASA", -Inf, pct)
  )

armar_figura_prevision <- function(df_grupo, fill_color) {
  datos <- df_grupo %>%
    dplyr::mutate(categoria_label = forcats::fct_reorder(categoria_label,
                                                         pct_ord))
  ggplot2::ggplot(datos, ggplot2::aes(x = pct, y = categoria_label)) +
    ggplot2::geom_col(width = 0.65, fill = fill_color) +
    ggplot2::geom_text(
      ggplot2::aes(label = sprintf("%.1f%%", pct)),
      hjust = -0.15, size = 3.5
    ) +
    ggplot2::scale_x_continuous(
      limits = c(0, max(datos$pct) * 1.15),
      expand = ggplot2::expansion(mult = c(0, 0))
    ) +
    # Sin título ni fuente quemados: los aporta el pie del docx. Se conservan
    # eje con rótulo y etiquetas de valor.
    ggplot2::labs(
      x = "Porcentaje de egresos del grupo (%)",
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.title.x = ggplot2::element_text(face = "bold"),
      plot.margin = ggplot2::margin(15, 25, 10, 10)
    )
}

p_po <- armar_figura_prevision(
  dplyr::filter(prevision, pertenencia == "PO"), "#2e86c1"
)
p_pg <- armar_figura_prevision(
  dplyr::filter(prevision, pertenencia == "No PO"), "#7f8c8d"
)

guardar_figura_600(p_po, "fig_prevision_PO", ancho = 10, alto = 5.5,
                   dir_salida = DIR_TANIA)
guardar_figura_600(p_pg, "fig_prevision_PG", ancho = 10, alto = 5.5,
                   dir_salida = DIR_TANIA)

rm(caracterizacion, prevision, p_po, p_pg, armar_figura_prevision)
gc(verbose = FALSE)

# ==============================================================================
# BLOQUE 2 (pesado): dumbbell PEC, Figura 7 y Figura S5
# ==============================================================================
cat("-- Bloque 2: carga de BBDD_homologados.RData --\n")

datos_homologados <- cargar_datos_homologados()
data.table::setDT(datos_homologados)

req_cols <- c("RUN", "PERTENENCIA2", "COND_EGR", "FECHA_EGRESO_FMT_DEIS",
              "FECHA_INGRESO_FMT_DEIS", "Grupo_CIE10", "AÑO", "CODIGO_REGION",
              "GLOSA_SEXO", "EDAD_ANOS", "GLOSA_PREVISION",
              "RSH", "CONADI", "PUEBLO_ORIGINARIO_BIN")
stopifnot("Faltan columnas en la base homologada" =
            all(req_cols %in% names(datos_homologados)))

# ---------------------------------------------------------------------------
# Bloque 2a: dumbbell de proporciones por capítulo (ex Figura S6)
# ---------------------------------------------------------------------------
# Mismos indicadores que regenerar_figuras_600dpi.R (Bloque 1). Se conservan
# ejes, leyenda y etiquetas; solo se retira el título/subtítulo quemados que
# grafico_dumbbell_pec() incorpora en su versión vigente.
cat("-- Bloque 2a: dumbbell PEC PI vs PG (10 x 6 in) --\n")

censo_lista <- obtener_poblacion_censo(verbose = FALSE)
censo_df <- tibble::tibble(
  grupo     = c("PI", "PG"),
  poblacion = c(censo_lista$pob_po, censo_lista$pob_pg)
)

cols_obj4 <- c("PERTENENCIA2", "COND_EGR", "FECHA_EGRESO_FMT_DEIS",
               "FECHA_INGRESO_FMT_DEIS", "Grupo_CIE10")
datos_base <- datos_homologados[, cols_obj4, with = FALSE]
datos_base$FECHA_EGRESO_FMT_DEIS  <- as.Date(datos_base$FECHA_EGRESO_FMT_DEIS)
datos_base$FECHA_INGRESO_FMT_DEIS <- as.Date(datos_base$FECHA_INGRESO_FMT_DEIS)

datos_analisis_obj4 <- datos_base %>%
  tibble::as_tibble() %>%
  dplyr::mutate(
    DIAS_ESTADA = as.numeric(FECHA_EGRESO_FMT_DEIS - FECHA_INGRESO_FMT_DEIS)
  ) %>%
  dplyr::rename(Capitulo = Grupo_CIE10) %>%
  dplyr::filter(!is.na(Capitulo))
rm(datos_base)
gc(verbose = FALSE)

resultados_obj4 <- calcular_indicadores_objetivo4(
  datos               = datos_analisis_obj4,
  denominadores_censo = censo_df,
  col_pertenencia     = "PERTENENCIA2",
  anos_estudio        = 13,
  verbose             = FALSE
)

p_dumbbell <- grafico_dumbbell_pec(resultados_obj4, top_n = 15) +
  ggplot2::labs(title = NULL, subtitle = NULL)

guardar_figura_600(p_dumbbell, "figura_dumbbell_pec_po_vs_pg",
                   ancho = 10, alto = 6)

rm(datos_analisis_obj4, resultados_obj4, censo_df, p_dumbbell)
gc(verbose = FALSE)

# ---------------------------------------------------------------------------
# Bloque 2b: Figura 7 verdadera (forest | heatmap, 7,2 x 4,2 in)
# ---------------------------------------------------------------------------
# Misma lógica y exclusiones documentadas que
# regenerar_figuras_600dpi.R (Bloque 1b). La única diferencia es el anclaje de
# las etiquetas de valor corregido en visualizaciones_cie10_fig7.R.
cat("-- Bloque 2b: Figura 7 (forest | heatmap, 7,2 x 4,2 in) --\n")

datos_disparidades <- preparar_datos_disparidades_cie10(datos_homologados)

excluir_fig7 <- c("Otros", "Códigos para situaciones especiales")
datos_disparidades$datos_cie10_resumen <- datos_disparidades$datos_cie10_resumen %>%
  dplyr::filter(!Grupo_CIE10 %in% excluir_fig7)
datos_disparidades$datos_cie10_anual <- datos_disparidades$datos_cie10_anual %>%
  dplyr::filter(!Grupo_CIE10 %in% excluir_fig7)
datos_disparidades$datos_cie10_mensual <- datos_disparidades$datos_cie10_mensual %>%
  dplyr::filter(!Grupo_CIE10 %in% excluir_fig7)

p_forest  <- crear_forest_plot_cie10(datos_disparidades, version_revista = TRUE,
                                     wrap_y = 40, tamano_valor = 2.6,
                                     tamano_punto = 2.4, grosor_barra = 0.5,
                                     etiquetas_al_derecho = TRUE,
                                     espacio_etiqueta = 0.42)
p_heatmap <- crear_heatmap_temporal(datos_disparidades, version_revista = TRUE,
                                    sin_etiquetas_y = TRUE, tamano_celda = 1.9)

p_forest <- p_forest +
  ggplot2::theme(
    axis.text.y = ggplot2::element_text(size = 8.5, hjust = 1),
    axis.text.x = ggplot2::element_text(size = 7),
    axis.title.x = ggplot2::element_text(size = 8.5, face = "bold"),
    legend.text = ggplot2::element_text(size = 8),
    legend.position = "bottom",
    plot.margin = ggplot2::margin(4, 3, 2, 2)
  ) +
  ggplot2::guides(color = ggplot2::guide_legend(ncol = 1))

p_heatmap <- p_heatmap +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(size = 8, angle = 45, hjust = 1),
    axis.title.x = ggplot2::element_text(size = 8.5, face = "bold"),
    legend.text = ggplot2::element_text(size = 8),
    legend.title = ggplot2::element_text(size = 8, face = "bold"),
    legend.title.position = "top",
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.key.width = grid::unit(1.3, "lines"),
    legend.key.height = grid::unit(0.6, "lines"),
    plot.margin = ggplot2::margin(4, 2, 2, 2)
  )

p_fig7 <- ((p_forest | p_heatmap) +
  patchwork::plot_layout(widths = c(0.95, 1.10)) +
  patchwork::plot_annotation(tag_levels = "A")) &
  ggplot2::theme(plot.tag = ggplot2::element_text(size = 11, face = "bold"))

guardar_figura_600(p_fig7, "figura_7_forest_heatmap_vertical",
                   ancho = 7.2, alto = 4.2)

rm(datos_disparidades, p_forest, p_heatmap, p_fig7)
gc(verbose = FALSE)

# ---------------------------------------------------------------------------
# Bloque 2c: Figura S5 (totalidad de capítulos, 9,3 x 6,2 in)
# ---------------------------------------------------------------------------
# Misma lógica y exclusiones que regenerar_figuras_600dpi.R (Bloque 1c).
cat("-- Bloque 2c: Figura S5 (totalidad de capítulos, 9,3 x 6,2 in) --\n")

datos_s5 <- preparar_datos_disparidades_cie10(datos_homologados, umbral = 0)
excluir_s5 <- c("Otros", "Códigos para situaciones especiales")
datos_s5$datos_cie10_resumen <- datos_s5$datos_cie10_resumen %>%
  dplyr::filter(!Grupo_CIE10 %in% excluir_s5)
datos_s5$datos_cie10_anual <- datos_s5$datos_cie10_anual %>%
  dplyr::filter(!Grupo_CIE10 %in% excluir_s5)
datos_s5$datos_cie10_mensual <- datos_s5$datos_cie10_mensual %>%
  dplyr::filter(!Grupo_CIE10 %in% excluir_s5)

p_forest_s5  <- crear_forest_plot_cie10(datos_s5, version_revista = TRUE,
                                        wrap_y = 40, tamano_valor = 2.6,
                                        tamano_punto = 2.4, grosor_barra = 0.5,
                                        etiquetas_al_derecho = TRUE,
                                        espacio_etiqueta = 0.40)
p_heatmap_s5 <- crear_heatmap_temporal(datos_s5, version_revista = TRUE,
                                       sin_etiquetas_y = TRUE,
                                       tamano_celda = 2.7)

p_forest_s5 <- p_forest_s5 +
  ggplot2::theme(
    axis.text.y = ggplot2::element_text(size = 8, hjust = 1),
    axis.text.x = ggplot2::element_text(size = 8.5),
    axis.title.x = ggplot2::element_text(size = 9, face = "bold"),
    legend.text = ggplot2::element_text(size = 8),
    legend.position = "bottom",
    plot.margin = ggplot2::margin(4, 3, 2, 2)
  ) +
  ggplot2::guides(color = ggplot2::guide_legend(ncol = 3))

p_heatmap_s5 <- p_heatmap_s5 +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(size = 8.5, angle = 45, hjust = 1),
    axis.title.x = ggplot2::element_text(size = 9, face = "bold"),
    legend.text = ggplot2::element_text(size = 8),
    legend.title = ggplot2::element_text(size = 8, face = "bold"),
    legend.title.position = "top",
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.key.width = grid::unit(1.6, "lines"),
    legend.key.height = grid::unit(0.6, "lines"),
    plot.margin = ggplot2::margin(4, 2, 2, 2)
  )

p_s5 <- ((p_forest_s5 | p_heatmap_s5) +
  patchwork::plot_layout(widths = c(1, 1)) +
  patchwork::plot_annotation(tag_levels = "A")) &
  ggplot2::theme(plot.tag = ggplot2::element_text(size = 11, face = "bold"))

guardar_figura_600(p_s5, "figura_S5_forest_heatmap_vertical_todas",
                   ancho = 9.3, alto = 6.2)

rm(datos_s5, p_forest_s5, p_heatmap_s5, p_s5, datos_homologados, censo_lista)
gc(verbose = FALSE)

cat("\nArchivos generados en:", OUT_DIR, "y", DIR_TANIA, "\n")
