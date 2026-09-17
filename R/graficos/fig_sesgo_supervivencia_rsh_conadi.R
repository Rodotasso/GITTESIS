# ==============================================================================
# SCRIPT: fig_sesgo_supervivencia_rsh_conadi
# ==============================================================================
#
# DESCRIPCIÓN:
#   Genera las figuras y la tabla que evidencian el sesgo de supervivencia del
#   enlace RSH/CONADI (fotografía de registros sociales 2022/2023 aplicada
#   retrospectivamente a egresos hospitalarios 2010-2022):
#
#   1. Figura principal: tasa de enlace (%) por año según condición de egreso
#      (vivo vs fallecido). Contraste: vivos planos ~8,4%, fallecidos con
#      gradiente creciente hacia el corte (0,7% en 2010 -> 3,8% en 2021).
#   2. Figura secundaria: entre fallecidos enlazados, porcentaje que consta
#      como "Pertenece" según RSH por año (segundo gradiente del sesgo).
#   3. Tabla resumen año x condición (CSV tidy + PNG flextable).
#
#   Nota de exportación: el device JPEG de ggsave corrompe los colores en
#   este equipo (fondo magenta); las figuras se guardan en PNG y se
#   convierten a JPG vía magick (mismo patrón de
#   temp_read/audit_rsh_conadi/sesgo_supervivencia_figuras.R).
#
# ENTRADAS (ya calculadas por la auditoría; NO se recalculan desde la base):
#   - temp_read/audit_rsh_conadi/C_match_por_condicion_egreso.csv
#   - temp_read/audit_rsh_conadi/A_cobertura_match.csv  (validación cruzada)
#
# SALIDAS (resultados_tesis/sesgo_supervivencia/):
#   - fig_tasa_enlace_por_condicion_egreso.jpg   (600 dpi)
#   - fig_pertenencia_rsh_fallecidos_enlazados.jpg (600 dpi)
#   - tabla_enlace_por_condicion_egreso.csv
#   - tabla_enlace_por_condicion_egreso.png
#
# USO:
#   "C:/Program Files/R/R-4.6.0/bin/Rscript.exe" R/graficos/fig_sesgo_supervivencia_rsh_conadi.R
#
# DEPENDENCIAS:
#   - dplyr, readr, tidyr, ggplot2, flextable, rprojroot
#   - magick para convertir las figuras PNG -> JPG (workaround device JPEG)
#   - officer + magick (o webshot2) para exportar la tabla a PNG
#   - R/tablas/guardar_tabla_png.R (se cargan solo las utilidades que el
#     script usa para mantenerlo liviano y autocontenido)
#
# ==============================================================================

# --- Raíz del proyecto (patrón project_root; prohibido "../../") -------------
if (!exists("project_root")) {
  project_root <- rprojroot::find_root(rprojroot::has_file("BBDD_homologados.RData"))
}

# --- Verificación de dependencias (no instalar nada; reportar y detener) -----
required_pkgs <- c("dplyr", "readr", "tidyr", "ggplot2", "flextable", "magick")
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
  library(flextable)
})

# --- Utilidades del repo (carga mínima: solo lo que este script usa) ----------
source(file.path(project_root, "R", "tablas", "guardar_tabla_png.R"))

# --- Constantes ----------------------------------------------------------------
AUDIT_DIR <- file.path(project_root, "temp_read", "audit_rsh_conadi")
OUT_DIR   <- file.path(project_root, "resultados_tesis", "sesgo_supervivencia")

# Paleta coherente con R/utilidades/paleta_colores.R (rojo/azul Material Design)
COLORS_CONDITION <- c("Vivo" = "#1565C0", "Fallecido" = "#C62828")

YEARS_EXPECTED <- 2010L:2022L

# ==============================================================================
# FUNCION: load_match_data
# ==============================================================================
# Lee y valida los CSV de la auditoría. Retorna lista con:
#   - match_long: tibble año x condición (alive/deceased) con tasas de enlace
#   - coverage:   tibble de cobertura global por año (validación cruzada)
# Detiene con error informativo si falta algún insumo o si la suma por
# condición no cuadra con la cobertura global reportada.
# ==============================================================================
load_match_data <- function(audit_dir) {
  path_match     <- file.path(audit_dir, "C_match_por_condicion_egreso.csv")
  path_coverage  <- file.path(audit_dir, "A_cobertura_match.csv")

  for (p in c(path_match, path_coverage)) {
    if (!file.exists(p)) stop("Input file not found: ", p)
  }

  raw_match <- readr::read_csv(path_match, show_col_types = FALSE)
  raw_coverage <- readr::read_csv(path_coverage, show_col_types = FALSE)

  required_cols <- c("ano", "condicion", "n_total", "n_rsh_match",
                     "pct_rsh_match", "pct_rsh_pertenece_entre_matcheados")
  missing_cols <- setdiff(required_cols, names(raw_match))
  if (length(missing_cols) > 0L) {
    stop("Missing columns in C_match_por_condicion_egreso.csv: ",
         paste(missing_cols, collapse = ", "))
  }

  # Excluir la fila "No reportado" (15 egresos sin año) y tipar el año
  match_long <- raw_match %>%
    filter(.data$ano != "No reportado") %>%
    mutate(
      ano = as.integer(.data$ano),
      condition = dplyr::recode(.data$condicion, Vivo = "alive", Fallecido = "deceased")
    ) %>%
    select("ano", "condition", "n_total", "n_rsh_match", "pct_rsh_match",
           pct_rsh_membership = "pct_rsh_pertenece_entre_matcheados") %>%
    arrange(.data$ano, .data$condition)

  # Validaciones de estructura
  if (!all(YEARS_EXPECTED %in% match_long$ano) || dplyr::n_distinct(match_long$ano) != length(YEARS_EXPECTED)) {
    stop("Unexpected year coverage: expected 2010-2022 for both conditions.")
  }
  if (!setequal(match_long$condition, c("alive", "deceased")) || nrow(match_long) != 2L * length(YEARS_EXPECTED)) {
    stop("Unexpected condition values or row count after filtering.")
  }
  numeric_cols <- c("n_total", "n_rsh_match", "pct_rsh_match", "pct_rsh_membership")
  if (anyNA(match_long[numeric_cols])) {
    stop("Unexpected NA values in audit table after filtering.")
  }

  # Validación cruzada: la suma por condición debe cuadrar con la cobertura global
  coverage <- raw_coverage %>%
    filter(.data$ano != "No reportado") %>%
    mutate(ano = as.integer(.data$ano)) %>%
    select("ano", n_total_global = "n_total", n_match_global = "n_rsh_match")

  cross_check <- match_long %>%
    group_by(.data$ano) %>%
    summarise(n_total_sum = sum(.data$n_total),
              n_match_sum = sum(.data$n_rsh_match), .groups = "drop") %>%
    left_join(coverage, by = "ano")

  if (!all(cross_check$n_total_sum == cross_check$n_total_global) ||
      !all(cross_check$n_match_sum == cross_check$n_match_global)) {
    stop("Cross-check failed: condition-level sums do not match global coverage table.")
  }

  list(match_long = match_long, coverage = coverage)
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
  # decimal.mark distinto de big.mark para evitar el aviso de prettyNum;
  # al ser enteros, decimal.mark nunca se materializa en la salida
  format(x, big.mark = ".", decimal.mark = ",", scientific = FALSE, trim = TRUE)
}

# ==============================================================================
# FUNCION: build_main_figure
# ==============================================================================
# Figura principal: tasa de enlace (%) por ano segun condicion de egreso.
# ==============================================================================
build_main_figure <- function(match_long) {
  plot_data <- match_long %>%
    mutate(condition_label = factor(.data$condition,
                                    levels = c("alive", "deceased"),
                                    labels = c("Vivo", "Fallecido")))

  # Etiquetas de valor solo en los extremos de cada serie (primer y ultimo ano)
  endpoint_labels <- plot_data %>%
    filter(.data$ano %in% c(min(.data$ano), max(.data$ano))) %>%
    mutate(
      value_label = paste0(fmt_pct(.data$pct_rsh_match), "%"),
      nudge_y = if_else(.data$condition == "alive", 0.45, 0.4)
    )

  nota <- paste0(
    "Nota: porcentaje de egresos con enlace no nulo a RSH/CONADI sobre el total de egresos de cada condición y año. ",
    "Se excluyen 15 egresos sin año de egreso reportado.\n",
    "Fuente: base de egresos hospitalarios DEIS, Chile 2010-2022; enlace a registros sociales vigentes al año de corte (2022/2023) ",
    "proyectado retrospectivamente."
  )

  ggplot(plot_data, aes(x = .data$ano, y = .data$pct_rsh_match,
                        color = .data$condition_label, group = .data$condition_label)) +
    geom_line(linewidth = 1.4) +
    geom_point(size = 2.2) +
    geom_text(data = endpoint_labels,
              aes(label = .data$value_label, y = .data$pct_rsh_match + .data$nudge_y),
              size = 3.2, fontface = "bold", show.legend = FALSE) +
    scale_color_manual(values = COLORS_CONDITION) +
    scale_x_continuous(breaks = YEARS_EXPECTED) +
    scale_y_continuous(limits = c(0, 10), breaks = seq(0, 10, by = 2)) +
    labs(
      title = "Proporción de enlace a registros sociales (RSH/CONADI) según condición de egreso",
      subtitle = paste0(
        "Egresos hospitalarios, Chile 2010-2022. En egresados vivos la proporción es estable (~8,4%); en fallecidos crece\n",
        "de forma monótona hacia el año de corte (0,7% en 2010 a 3,8% en 2021): evidencia de sesgo de supervivencia."
      ),
      x = "Año de egreso",
      y = "Egresos con enlace (%)",
      color = "Condición de egreso",
      caption = nota
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      panel.grid.major.x = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
      axis.title = element_text(size = 10, face = "bold"),
      plot.title = element_text(size = 13, face = "bold"),
      plot.subtitle = element_text(size = 10),
      plot.caption = element_text(hjust = 0, size = 8),
      legend.text = element_text(size = 9)
    )
}

# ==============================================================================
# FUNCION: build_secondary_figure
# ==============================================================================
# Figura secundaria: entre fallecidos enlazados, % que consta como "Pertenece"
# segun RSH por ano de egreso (segundo gradiente del sesgo).
# ==============================================================================
build_secondary_figure <- function(match_long) {
  plot_data <- match_long %>%
    filter(.data$condition == "deceased")

  endpoint_labels <- plot_data %>%
    filter(.data$ano %in% c(min(.data$ano), max(.data$ano))) %>%
    mutate(value_label = paste0(fmt_pct(.data$pct_rsh_membership), "%"),
           nudge_y = 0.9)

  n_range <- range(plot_data$n_rsh_match)

  nota <- paste0(
    "Nota: el denominador corresponde a los egresos fallecidos con enlace RSH no nulo (n entre ",
    fmt_int(n_range[1L]), " en 2010 y ", fmt_int(n_range[2L]), " en 2021).\n",
    "Fuente: base de egresos hospitalarios DEIS, Chile 2010-2022; condición registral RSH al año de corte (2022/2023)."
  )

  ggplot(plot_data, aes(x = .data$ano, y = .data$pct_rsh_membership)) +
    geom_line(linewidth = 1.4, color = COLORS_CONDITION[["Fallecido"]]) +
    geom_point(size = 2.2, color = COLORS_CONDITION[["Fallecido"]]) +
    geom_text(data = endpoint_labels,
              aes(label = .data$value_label, y = .data$pct_rsh_membership + .data$nudge_y),
              size = 3.2, fontface = "bold", color = COLORS_CONDITION[["Fallecido"]]) +
    scale_x_continuous(breaks = YEARS_EXPECTED) +
    scale_y_continuous(limits = c(0, 19), breaks = seq(0, 18, by = 3)) +
    labs(
      title = "Pertenencia a pueblos originarios según RSH entre egresos fallecidos enlazados",
      subtitle = paste0(
        "Porcentaje de fallecidos con enlace que constan como \"Pertenece\" en el RSH, por año de egreso. Chile 2010-2022.\n",
        "La pertenencia retrocede de 17,1% (2010) a menos de 1,3% desde 2016: segundo gradiente del sesgo de supervivencia."
      ),
      x = "Año de egreso",
      y = "Pertenece según RSH (%)",
      caption = nota
    ) +
    theme_minimal() +
    theme(
      panel.grid.major.x = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
      axis.title = element_text(size = 10, face = "bold"),
      plot.title = element_text(size = 13, face = "bold"),
      plot.subtitle = element_text(size = 10),
      plot.caption = element_text(hjust = 0, size = 8)
    )
}

# ==============================================================================
# FUNCION: build_summary_table
# ==============================================================================
# Tabla resumen ano x condicion. Retorna lista con:
#   - table_long:  tibble tidy (para CSV)
#   - table_ft:    flextable en formato ancho con spanners (para PNG)
# ==============================================================================
build_summary_table <- function(match_long) {
  table_long <- match_long %>%
    select("ano", "condition", "n_total", "n_rsh_match", "pct_rsh_match")

  # Formato ancho con razon de tasas (veces que el match de vivos supera al de fallecidos)
  table_wide <- table_long %>%
    pivot_wider(names_from = "condition",
                values_from = c("n_total", "n_rsh_match", "pct_rsh_match")) %>%
    mutate(match_rate_ratio = .data$pct_rsh_match_alive / .data$pct_rsh_match_deceased) %>%
    arrange(.data$ano)

  table_display <- table_wide %>%
    transmute(
      year = as.character(.data$ano),
      alive_n = fmt_int(.data$n_total_alive),
      alive_match = fmt_int(.data$n_rsh_match_alive),
      alive_pct = fmt_pct(.data$pct_rsh_match_alive),
      deceased_n = fmt_int(.data$n_total_deceased),
      deceased_match = fmt_int(.data$n_rsh_match_deceased),
      deceased_pct = fmt_pct(.data$pct_rsh_match_deceased),
      ratio = fmt_pct(.data$match_rate_ratio)
    )

  table_ft <- flextable(table_display) %>%
    set_header_labels(values = c(
      year = "Año",
      alive_n = "N egresos", alive_match = "N enlazados", alive_pct = "% enlace",
      deceased_n = "N egresos", deceased_match = "N enlazados", deceased_pct = "% enlace",
      ratio = "Razón V/F"
    )) %>%
    add_header_row(values = c("", "Egresados vivos", "Egresados fallecidos", ""),
                   colwidths = c(1L, 3L, 3L, 1L)) %>%
    add_header_lines(values = "Proporción de enlace RSH/CONADI según condición de egreso por año. Egresos hospitalarios, Chile 2010-2022.") %>%
    merge_at(i = 1L, j = seq_len(ncol(table_display)), part = "header") %>%
    theme_booktabs() %>%
    bold(part = "header") %>%
    align(j = 2:8, align = "center", part = "all") %>%
    fontsize(size = 9, part = "all") %>%
    fontsize(i = 1L, size = 10, part = "header") %>%
    autofit()

  list(table_long = table_long, table_ft = table_ft)
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
  cat("SESGO DE SUPERVIVENCIA DEL ENLACE RSH/CONADI — FIGURAS Y TABLA\n")
  cat("================================================================================\n\n")

  audit <- load_match_data(AUDIT_DIR)
  cat("✓ Datos de auditoría cargados y validados (cruce con cobertura global OK)\n")

  if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

  # Figura principal
  # Workaround device JPEG (corrompe colores en este equipo: fondo magenta):
  # ggsave a PNG y conversión a JPG vía magick (patrón de
  # temp_read/audit_rsh_conadi/sesgo_supervivencia_figuras.R)
  fig_main <- build_main_figure(audit$match_long)
  guardar_jpg_via_png(fig_main, "fig_tasa_enlace_por_condicion_egreso",
                      ancho = 10, alto = 6, dpi = 600, dir_salida = OUT_DIR)
  cat("✓ fig_tasa_enlace_por_condicion_egreso.jpg (600 dpi)\n")

  # Figura secundaria
  fig_secondary <- build_secondary_figure(audit$match_long)
  guardar_jpg_via_png(fig_secondary, "fig_pertenencia_rsh_fallecidos_enlazados",
                      ancho = 10, alto = 6, dpi = 600, dir_salida = OUT_DIR)
  cat("✓ fig_pertenencia_rsh_fallecidos_enlazados.jpg (600 dpi)\n")

  # Tabla resumen: CSV tidy + PNG flextable
  tables <- build_summary_table(audit$match_long)
  readr::write_csv(tables$table_long,
                   file.path(OUT_DIR, "tabla_enlace_por_condicion_egreso.csv"))
  cat("✓ tabla_enlace_por_condicion_egreso.csv\n")

  guardar_tabla_png(tables$table_ft, "tabla_enlace_por_condicion_egreso",
                    zoom = 3, dir_salida = OUT_DIR)

  cat("\nArchivos generados en:", OUT_DIR, "\n")
  invisible(TRUE)
}

# Ejecutar solo cuando el script se corre directamente (no al sourcearlo)
if (sys.nframe() == 0L) {
  main()
}
