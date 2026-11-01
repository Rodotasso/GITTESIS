# ==============================================================================
# SCRIPT: fig_figura3_pertenencia_fallecidos_rsh_conadi
# ==============================================================================
#
# DESCRIPCIÓN:
#   Genera la figura de Resultados que reemplaza a la actual Figura 3 del
#   manuscrito. La versión anterior mostraba solo la curva del RSH; esta agrega
#   la curva de CONADI en el mismo panel, que es lo que pide la revisora
#   (comentario 100): la comparación entre ambas fuentes permite sostener que el
#   sesgo de supervivencia afecta solo al RSH, porque el RSH elimina del registro
#   a las personas fallecidas, mientras que CONADI conserva el registro histórico.
#
#   Universo: egresos fallecidos con enlace no nulo, Chile 2010-2022.
#   Indicador: porcentaje de esos egresos que consta como "Pertenece" a pueblos
#   originarios en cada fuente, sobre el total de enlazados de cada año.
#
#   Criterios de legibilidad (comentarios 98 y 99 de la revisora): tipografías
#   grandes, años sin rotar, etiquetas de valor en los extremos de cada serie y
#   exportación a 600 dpi, de modo que la figura no requiera zoom ni se pixele
#   al insertarla en el documento. La figura no lleva título, subtítulo ni pie
#   dentro de la imagen: el comentario 98 pide explicitamente sacar el pie de la
#   figura y dejarlo solo en el texto, y el subtítulo era ilegible. Toda esa
#   prosa va en el pie de figura del documento.
#
# ENTRADAS (ya calculadas por la auditoría; NO se recalculan desde la base):
#   - resultados_tesis/VIGENTES/auditoria_rsh_conadi/C_match_por_condicion_egreso.csv
#
# SALIDAS (resultados_tesis/sesgo_supervivencia/):
#   - fig_figura3_pertenencia_fallecidos_rsh_conadi.png  (600 dpi)
#   - fig_figura3_pertenencia_fallecidos_rsh_conadi.jpg  (600 dpi)
#
# USO:
#   "C:/Program Files/R/R-4.6.0/bin/Rscript.exe" R/graficos/fig_figura3_pertenencia_fallecidos_rsh_conadi.R
#
# DEPENDENCIAS:
#   - dplyr, readr, tidyr, ggplot2, rprojroot
#   - magick para convertir la figura PNG -> JPG (workaround del device JPEG,
#     que corrompe los colores en este equipo; mismo patrón que
#     R/graficos/grafico_S6_retencion_pertenencia_conadi_rsh.R)
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

# Paleta coherente con las figuras de sesgo de supervivencia y con la Figura S6
# (azul/rojo Material Design); aquí el contraste es por fuente
COLORS_SOURCE <- c("CONADI" = "#1565C0", "RSH" = "#C62828")

YEARS_EXPECTED <- 2010L:2022L

# Rangos de referencia de la tesis (fallecidos enlazados, %)
REF_CONADI_RANGE <- c(56, 89)
REF_RSH_RANGE    <- c(0, 17)

# ==============================================================================
# FUNCION: load_deceased_membership
# ==============================================================================
# Lee el CSV de la auditoría y devuelve un tibble largo con una fila por
# año x fuente para los egresos fallecidos. Detiene con error informativo si
# falta el insumo o si la estructura no es la esperada.
# ==============================================================================
load_deceased_membership <- function(audit_dir) {
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

  # Excluir la fila "No reportado" (egresos sin año) y quedarse con fallecidos
  deceased <- raw_match %>%
    filter(.data$ano != "No reportado", .data$condicion == "Fallecido") %>%
    mutate(ano = as.integer(.data$ano))

  # Validaciones de estructura
  if (!setequal(deceased$ano, YEARS_EXPECTED) || dplyr::n_distinct(deceased$ano) != length(YEARS_EXPECTED)) {
    stop("Unexpected year coverage: expected 2010-2022 for deceased discharges.")
  }
  if (anyNA(deceased$n_rsh_match) || anyNA(deceased$pct_rsh_pertenece_entre_matcheados) ||
      anyNA(deceased$pct_conadi_pertenece_entre_matcheados)) {
    stop("Unexpected NA values in the audit table for deceased discharges.")
  }
  # Las dos fuentes comparten el mismo universo de egresos enlazados
  if (!all(deceased$n_rsh_match == deceased$n_conadi_match)) {
    stop("RSH and CONADI match counts differ: check the audit table.")
  }

  membership_long <- deceased %>%
    select("ano", "n_matched" = "n_rsh_match",
           RSH = "pct_rsh_pertenece_entre_matcheados",
           CONADI = "pct_conadi_pertenece_entre_matcheados") %>%
    pivot_longer(cols = c("CONADI", "RSH"), names_to = "source",
                 values_to = "pct_membership") %>%
    mutate(source = factor(.data$source, levels = c("CONADI", "RSH"))) %>%
    arrange(.data$ano, .data$source)

  if (nrow(membership_long) != 2L * length(YEARS_EXPECTED)) {
    stop("Unexpected row count after reshaping to long format.")
  }

  # Verificación contra los rangos de referencia publicados en la tesis
  observed <- membership_long %>%
    group_by(.data$source) %>%
    summarise(obs_min = min(.data$pct_membership),
              obs_max = max(.data$pct_membership), .groups = "drop")

  cat("Rangos observados en fallecidos enlazados:\n")
  cat(sprintf("  CONADI: %.1f-%.1f%% (referencia tesis: %d-%d%%)\n",
              observed$obs_min[observed$source == "CONADI"],
              observed$obs_max[observed$source == "CONADI"],
              REF_CONADI_RANGE[1L], REF_CONADI_RANGE[2L]))
  cat(sprintf("  RSH:    %.1f-%.1f%% (referencia tesis: %d-%d%%)\n",
              observed$obs_min[observed$source == "RSH"],
              observed$obs_max[observed$source == "RSH"],
              REF_RSH_RANGE[1L], REF_RSH_RANGE[2L]))

  list(membership_long = membership_long, observed = observed)
}

# ==============================================================================
# FUNCION: fmt_pct / fmt_int
# ==============================================================================
# Formato local: coma decimal y punto de miles (convención chilena).
# ==============================================================================
fmt_pct <- function(x, digits = 1L) {
  formatC(x, format = "f", digits = digits, decimal.mark = ",")
}
fmt_int <- function(x) {
  format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

# ==============================================================================
# FUNCION: build_figure
# ==============================================================================
# Un panel, dos series (CONADI y RSH), egresos fallecidos enlazados por año.
# ==============================================================================
build_figure <- function(membership_long) {
  # Etiquetas de valor solo en los extremos de cada serie (primer y último año)
  endpoint_labels <- membership_long %>%
    filter(.data$ano %in% range(.data$ano)) %>%
    mutate(
      value_label = paste0(fmt_pct(.data$pct_membership), "%"),
      # Las dos etiquetas van por encima de su punto, dentro del área de trazado
      nudge_y = 6
    )

  # Sin título, subtítulo ni pie: la revisora pidió (comentario 98) que el pie
  # salga de la imagen y quede solo en el texto, y el subtítulo era ilegible.
  # El título, la nota y la fuente van en el pie de figura del documento.
  ggplot(membership_long, aes(x = .data$ano, y = .data$pct_membership,
                              color = .data$source, group = .data$source)) +
    geom_line(linewidth = 1.4) +
    geom_point(size = 2.6) +
    geom_text(data = endpoint_labels,
              aes(label = .data$value_label, y = .data$pct_membership + .data$nudge_y),
              size = 4.1, fontface = "bold", show.legend = FALSE) +
    scale_color_manual(values = COLORS_SOURCE) +
    scale_x_continuous(breaks = YEARS_EXPECTED) +
    scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 20)) +
    labs(
      x = "Año de egreso",
      y = "Pertenece a pueblos originarios (%)",
      color = "Fuente"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      legend.position = "bottom",
      legend.title = element_text(size = 13, face = "bold"),
      legend.text = element_text(size = 13),
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text.x = element_text(size = 13),
      axis.text.y = element_text(size = 13),
      axis.title = element_text(size = 13, face = "bold"),
      plot.margin = margin(10, 16, 8, 12)
    )
}

# ==============================================================================
# FUNCION: guardar_jpg_via_png
# ==============================================================================
# Workaround del device JPEG de ggsave (corrompe colores en este equipo):
# se exporta PNG y se convierte a JPG con magick.
# ==============================================================================
guardar_jpg_via_png <- function(grafico, nombre_base, ancho = 10, alto = 6.5,
                                dpi = 600, dir_salida) {
  ruta_png <- file.path(dir_salida, paste0(nombre_base, ".png"))
  ruta_jpg <- file.path(dir_salida, paste0(nombre_base, ".jpg"))
  ggsave(ruta_png, grafico, width = ancho, height = alto, dpi = dpi, bg = "white")
  magick::image_write(magick::image_read(ruta_png), ruta_jpg, format = "jpg",
                      quality = 95)
  invisible(c(png = ruta_png, jpg = ruta_jpg))
}

# ==============================================================================
# EJECUCIÓN
# ==============================================================================
main <- function() {
  if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

  data <- load_deceased_membership(AUDIT_DIR)
  fig <- build_figure(data$membership_long)

  rutas <- guardar_jpg_via_png(fig, "fig_figura3_pertenencia_fallecidos_rsh_conadi",
                               ancho = 9, alto = 6, dpi = 600,
                               dir_salida = OUT_DIR)

  cat("\nFiguras guardadas:\n")
  cat("  ", rutas[["png"]], "\n")
  cat("  ", rutas[["jpg"]], "\n")
  invisible(data)
}

main()
