# ==============================================================================
# SCRIPT: grafico_S6_retencion_pertenencia_conadi_rsh
# ==============================================================================
#
# DESCRIPCIÓN:
#   Genera la Figura S6 del Material Suplementario: retención de la pertenencia
#   a pueblos originarios (%) entre egresos enlazados a registros sociales,
#   por año de egreso (2010-2022), según fuente (CONADI vs RSH) y condición
#   de egreso (vivo vs fallecido).
#
#   Evidencia el sesgo de supervivencia del RSH: entre fallecidos enlazados,
#   CONADI retiene la pertenencia en 56-89% mientras el RSH la pierde (0-17%).
#   Entre egresados vivos ambas fuentes se mantienen estables, lo que descarta
#   un efecto temporal general y atribuye el gradiente a la condición vital.
#
#   Nota de exportación: el device JPEG de ggsave corrompe los colores en
#   este equipo (fondo magenta); la figura se guarda en PNG y se convierte
#   a JPG vía magick (mismo patrón de
#   R/graficos/fig_sesgo_supervivencia_rsh_conadi.R).
#
# ENTRADAS (ya calculadas por la auditoría; NO se recalculan desde la base):
#   - resultados_tesis/VIGENTES/auditoria_rsh_conadi/C_match_por_condicion_egreso.csv
#
# SALIDAS (resultados_tesis/sesgo_supervivencia/):
#   - fig_S6_retencion_pertenencia_conadi_rsh.png  (600 dpi)
#   - fig_S6_retencion_pertenencia_conadi_rsh.jpg  (600 dpi)
#
# USO:
#   "C:/Program Files/R/R-4.6.0/bin/Rscript.exe" R/graficos/grafico_S6_retencion_pertenencia_conadi_rsh.R
#
# DEPENDENCIAS:
#   - dplyr, readr, tidyr, ggplot2, rprojroot
#   - magick para convertir la figura PNG -> JPG (workaround device JPEG)
#
# ==============================================================================

# --- Raíz del proyecto (patrón project_root; prohibido "../../") -------------
if (!exists("project_root")) {
  project_root <- rprojroot::find_root(rprojroot::has_file("BBDD_homologados.RData"))
}

# --- Verificación de dependencias (no instalar nada; reportar y detener) -----
required_pkgs <- c("dplyr", "readr", "tidyr", "ggplot2", "magick")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0L) {
  stop("Missing required packages: ", paste(missing_pkgs, collapse = ", "),
       ". Restore the project library (renv) and retry.")
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
})

# --- Constantes ----------------------------------------------------------------
AUDIT_DIR <- file.path(project_root, "resultados_tesis", "VIGENTES", "auditoria_rsh_conadi")
OUT_DIR   <- file.path(project_root, "resultados_tesis", "sesgo_supervivencia")

# Paleta coherente con R/graficos/fig_sesgo_supervivencia_rsh_conadi.R
# (rojo/azul Material Design); aquí el contraste es por fuente
COLORS_SOURCE <- c("CONADI" = "#1565C0", "RSH" = "#C62828")

YEARS_EXPECTED <- 2010L:2022L

# Rangos de referencia publicados en la tesis (fallecidos enlazados, %)
REF_CONADI_RANGE <- c(56, 89)
REF_RSH_RANGE    <- c(0, 17)

# ==============================================================================
# FUNCION: load_retention_data
# ==============================================================================
# Lee y valida el CSV de la auditoría. Retorna un tibble largo con una fila
# por año x condición x fuente y el porcentaje de enlazados que constan como
# "Pertenece" en cada fuente. Detiene con error informativo si falta algún
# insumo o si la estructura no es la esperada.
# ==============================================================================
load_retention_data <- function(audit_dir) {
  path_match <- file.path(audit_dir, "C_match_por_condicion_egreso.csv")
  if (!file.exists(path_match)) stop("Input file not found: ", path_match)

  raw_match <- readr::read_csv(path_match, show_col_types = FALSE)

  required_cols <- c("ano", "condicion", "n_rsh_match", "n_conadi_match",
                     "pct_rsh_pertenece_entre_matcheados",
                     "pct_conadi_pertenece_entre_matcheados")
  missing_cols <- setdiff(required_cols, names(raw_match))
  if (length(missing_cols) > 0L) {
    stop("Missing columns in C_match_por_condicion_egreso.csv: ",
         paste(missing_cols, collapse = ", "))
  }

  # Excluir la fila "No reportado" (15 egresos sin año) y pasar a formato largo
  retention_long <- raw_match %>%
    filter(.data$ano != "No reportado") %>%
    mutate(ano = as.integer(.data$ano)) %>%
    select("ano", "condicion",
           RSH = "pct_rsh_pertenece_entre_matcheados",
           CONADI = "pct_conadi_pertenece_entre_matcheados") %>%
    pivot_longer(cols = c("RSH", "CONADI"), names_to = "source",
                 values_to = "pct_retention") %>%
    arrange(.data$ano, .data$condicion, .data$source)

  # Denominadores por año x condición (n de enlazados; idénticos en ambas fuentes)
  denominators <- raw_match %>%
    filter(.data$ano != "No reportado") %>%
    mutate(ano = as.integer(.data$ano)) %>%
    transmute(.data$ano, .data$condicion, n_matched = .data$n_rsh_match)

  # Validaciones de estructura
  if (!all(YEARS_EXPECTED %in% retention_long$ano) ||
      dplyr::n_distinct(retention_long$ano) != length(YEARS_EXPECTED)) {
    stop("Unexpected year coverage: expected 2010-2022.")
  }
  if (!setequal(retention_long$condicion, c("Vivo", "Fallecido")) ||
      nrow(retention_long) != 2L * 2L * length(YEARS_EXPECTED)) {
    stop("Unexpected condition values or row count after filtering.")
  }
  if (anyNA(retention_long$pct_retention)) {
    stop("Unexpected NA values in retention percentages after filtering.")
  }
  if (!all(raw_match$n_rsh_match[raw_match$ano != "No reportado"] ==
           raw_match$n_conadi_match[raw_match$ano != "No reportado"])) {
    stop("RSH and CONADI match counts differ: check the audit table.")
  }

  # Verificación contra los rangos de referencia publicados (solo fallecidos)
  deceased_ref <- retention_long %>%
    filter(.data$condicion == "Fallecido") %>%
    group_by(.data$source) %>%
    summarise(obs_min = min(.data$pct_retention),
              obs_max = max(.data$pct_retention), .groups = "drop")

  cat("Rangos observados en fallecidos enlazados:\n")
  cat(sprintf("  CONADI: %.1f-%.1f%% (referencia tesis: %d-%d%%)\n",
              deceased_ref$obs_min[deceased_ref$source == "CONADI"],
              deceased_ref$obs_max[deceased_ref$source == "CONADI"],
              REF_CONADI_RANGE[1L], REF_CONADI_RANGE[2L]))
  cat(sprintf("  RSH:    %.1f-%.1f%% (referencia tesis: %d-%d%%)\n",
              deceased_ref$obs_min[deceased_ref$source == "RSH"],
              deceased_ref$obs_max[deceased_ref$source == "RSH"],
              REF_RSH_RANGE[1L], REF_RSH_RANGE[2L]))

  list(retention_long = retention_long, denominators = denominators)
}

# ==============================================================================
# FUNCION: fmt_pct
# ==============================================================================
# Formato local: coma decimal y punto de miles (convención chilena).
# ==============================================================================
fmt_pct <- function(x, digits = 1L) {
  formatC(x, format = "f", digits = digits, decimal.mark = ",")
}

# ==============================================================================
# FUNCION: build_figure_s6
# ==============================================================================
# Figura S6: dos paneles lado a lado (condición de egreso), dos series por
# panel (fuente). Etiquetas de valor solo en los extremos de cada serie (primer
# y último año). Sin título, bajada, nota ni fuente quemados: ese texto va en el
# pie de figura del documento. Se conservan los encabezados de panel
# ("Egresados vivos" / "Egresados fallecidos") y la leyenda de la fuente, que
# son rótulos internos del gráfico, no título de documento.
# ==============================================================================
build_figure_s6 <- function(retention_long) {
  plot_data <- retention_long %>%
    mutate(
      condition_label = factor(.data$condicion,
                               levels = c("Vivo", "Fallecido"),
                               labels = c("Egresados vivos", "Egresados fallecidos")),
      source = factor(.data$source, levels = c("CONADI", "RSH"))
    )

  # Etiquetas de valor en los extremos: sobre la línea, salvo la serie superior
  # de cada panel en el primer año (se desplaza hacia arriba) y la inferior
  # (hacia abajo) para evitar solapamientos con la línea
  endpoint_labels <- plot_data %>%
    filter(.data$ano %in% c(min(.data$ano), max(.data$ano))) %>%
    mutate(
      value_label = paste0(fmt_pct(.data$pct_retention), "%"),
      nudge_y = case_when(
        .data$condicion == "Fallecido" & .data$source == "RSH" ~ 4,
        .data$condicion == "Vivo" & .data$source == "CONADI" ~ -5,
        TRUE ~ 4
      )
    )

  ggplot(plot_data, aes(x = .data$ano, y = .data$pct_retention,
                        color = .data$source, group = .data$source)) +
    geom_line(linewidth = 1.4) +
    geom_point(size = 2.2) +
    geom_text(data = endpoint_labels,
              aes(label = .data$value_label, y = .data$pct_retention + .data$nudge_y),
              size = 3.2, fontface = "bold", show.legend = FALSE) +
    facet_wrap(~ condition_label, ncol = 2) +
    scale_color_manual(values = COLORS_SOURCE) +
    # Un año de holgura a cada lado: las etiquetas de valor de los extremos se
    # centran en 2010 y 2022 y, sin holgura, el recorte del panel les corta la
    # mitad izquierda/derecha (el "8" de 89,0% se leía como "3").
    scale_x_continuous(breaks = YEARS_EXPECTED,
                       expand = ggplot2::expansion(mult = 0.01, add = 1)) +
    scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 20)) +
    labs(
      x = "Año de egreso",
      y = "Retención de pertenencia (%)",
      color = "Fuente"
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      panel.grid.major.x = element_blank(),
      strip.text = element_text(size = 11, face = "bold"),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
      axis.text.y = element_text(size = 9),
      axis.title = element_text(size = 10, face = "bold"),
      legend.title = element_text(size = 9, face = "bold"),
      legend.text = element_text(size = 9)
    )
}

# ==============================================================================
# FUNCION: guardar_jpg_via_png
# ==============================================================================
# Workaround del device JPEG de ggsave (corrompe colores en este equipo):
# guarda en PNG y convierte a JPG con magick (calidad 95), manteniendo la
# convención del proyecto (.jpg) con colores correctos. Retorna la ruta JPG.
# ==============================================================================
guardar_jpg_via_png <- function(grafico, nombre_base, ancho = 10, alto = 6,
                                dpi = 600, dir_salida) {
  ruta_png <- file.path(dir_salida, paste0(nombre_base, ".png"))
  ruta_jpg <- file.path(dir_salida, paste0(nombre_base, ".jpg"))
  ggsave(ruta_png, grafico, width = ancho, height = alto, dpi = dpi, bg = "white")
  img <- magick::image_read(ruta_png)
  magick::image_write(img, ruta_jpg, format = "jpeg", quality = 95)
  invisible(ruta_jpg)
}

# ==============================================================================
# FUNCION: main
# ==============================================================================
main <- function() {
  cat("================================================================================\n")
  cat("FIGURA S6: RETENCIÓN DE PERTENENCIA CONADI VS RSH SEGÚN CONDICIÓN DE EGRESO\n")
  cat("================================================================================\n\n")

  audit <- load_retention_data(AUDIT_DIR)
  cat("Datos de auditoría cargados y validados\n")

  if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

  fig_s6 <- build_figure_s6(audit$retention_long)
  # Footprint final de inserción (Figura 4 del cuerpo en el docx): 7,2 x 3,7 in
  guardar_jpg_via_png(fig_s6, "fig_S6_retencion_pertenencia_conadi_rsh",
                      ancho = 7.2, alto = 3.7, dpi = 600, dir_salida = OUT_DIR)
  cat("fig_S6_retencion_pertenencia_conadi_rsh.png / .jpg (600 dpi)\n")

  cat("\nArchivos generados en:", OUT_DIR, "\n")
  invisible(TRUE)
}

# Ejecutar solo cuando el script se corre directamente (no al sourcearlo)
if (sys.nframe() == 0L) {
  main()
}
