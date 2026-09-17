# ==============================================================================
# SCRIPT: fig_distribucion_enlace_rsh_conadi
# ==============================================================================
#
# DESCRIPCIÓN:
#   Genera el material suplementario sobre la DISTRIBUCIÓN del enlace
#   RSH/CONADI (complementa las figuras de sesgo de supervivencia):
#
#   1. Tabla S2 (CSV tidy + PNG flextable): tasa de enlace por categoría en
#      tres bloques (sexo, grupo etario, región de residencia).
#   2. Figura S3 (JPG 600 dpi): barras horizontales del % de enlace por
#      categoría en tres paneles (patchwork).
#
#   RSH y CONADI comparten exactamente el mismo conjunto de enlaces (enlace
#   único, verificado en la auditoría): se reporta una sola columna/serie.
#
#   Nota de exportación: el device JPEG de ggsave corrompe los colores en
#   este equipo (fondo magenta); la figura se guarda en PNG y se convierte
#   a JPG vía magick (mismo patrón de
#   temp_read/audit_rsh_conadi/sesgo_supervivencia_figuras.R).
#
# ENTRADA (ya calculada por la auditoría; NO se recalcula desde la base):
#   - temp_read/audit_rsh_conadi/F_nas_resumen.csv
#
# SALIDAS (resultados_tesis/sesgo_supervivencia/):
#   - tabla_distribucion_enlace.csv
#   - tabla_distribucion_enlace.png
#   - fig_distribucion_enlace.jpg (600 dpi)
#
# USO:
#   "C:/Program Files/R/R-4.6.0/bin/Rscript.exe" R/graficos/fig_distribucion_enlace_rsh_conadi.R
#
# DEPENDENCIAS:
#   - dplyr, readr, ggplot2, flextable, patchwork, rprojroot
#   - magick para convertir la figura PNG -> JPG (workaround device JPEG)
#   - officer + magick (o webshot2) para exportar la tabla a PNG
#   - R/tablas/guardar_tabla_png.R
#
# ==============================================================================

# --- Raíz del proyecto (patrón project_root; prohibido "../../") -------------
if (!exists("project_root")) {
  project_root <- rprojroot::find_root(rprojroot::has_file("BBDD_homologados.RData"))
}

# --- Verificación de dependencias (no instalar nada; reportar y detener) -----
required_pkgs <- c("dplyr", "readr", "ggplot2", "flextable", "patchwork", "magick")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0L) {
  stop("Missing required packages: ", paste(missing_pkgs, collapse = ", "),
       ". Restore the project library (renv) and retry.")
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(flextable)
  library(patchwork)
})

# --- Utilidades del repo (carga mínima: solo lo que este script usa) ----------
source(file.path(project_root, "R", "tablas", "guardar_tabla_png.R"))

# --- Constantes ----------------------------------------------------------------
AUDIT_DIR <- file.path(project_root, "temp_read", "audit_rsh_conadi")
OUT_DIR   <- file.path(project_root, "resultados_tesis", "sesgo_supervivencia")

# Azul de la paleta del repo (R/utilidades/paleta_colores.R)
COLOR_LINK <- "#1565C0"

TOTAL_EGRESOS <- 20957004L  # total de la base auditada (INFORME.md)

AGE_ORDER <- c("0-4", "5-14", "15-24", "25-44", "45-64", "65-74", "75+")

REGION_NAMES <- c(
  "1" = "Tarapacá",            "2" = "Antofagasta",   "3" = "Atacama",
  "4" = "Coquimbo",            "5" = "Valparaíso",    "6" = "O'Higgins",
  "7" = "Maule",               "8" = "Biobío",        "9" = "La Araucanía",
  "10" = "Los Lagos",          "11" = "Aysén",        "12" = "Magallanes",
  "13" = "Metropolitana",      "14" = "Los Ríos",     "15" = "Arica y Parinacota",
  "16" = "Ñuble"
)

SEX_LABELS <- c(
  "HOMBRE" = "Hombre",
  "MUJER" = "Mujer",
  "INTERSEX (INDETERMINADO)" = "Intersex (indeterminado)"
)

# Cifras canónicas del informe de auditoría (sección F) para validación cruzada
CANONICAL <- tibble::tribble(
  ~dimension,      ~categoria, ~expected,
  "GLOSA_SEXO",    "MUJER",     8.9,
  "GLOSA_SEXO",    "HOMBRE",    7.3,
  "GRUPO_ETARIO",  "15-24",    12.8,
  "GRUPO_ETARIO",  "75+",       3.3,
  "CODIGO_REGION", "9",        28.5,
  "CODIGO_REGION", "11",       27.6,
  "CODIGO_REGION", "13",        4.6,
  "CODIGO_REGION", "7",         2.3,
  "CODIGO_REGION", "16",        2.0
)

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
# FUNCION: load_link_distribution
# ==============================================================================
# Lee y valida F_nas_resumen.csv. Retorna lista con:
#   - body:     tibble del cuerpo (sin "No reportado"/"NA"), con etiquetas de
#               display y orden interno por bloque
#   - excluded: tibble con las filas excluidas del cuerpo (para la nota al pie)
# Validaciones: enlace único RSH==CONADI, cobertura de categorías esperada,
# suma por dimensión == total de la base, cifras canónicas del informe.
# ==============================================================================
load_link_distribution <- function(audit_dir) {
  path <- file.path(audit_dir, "F_nas_resumen.csv")
  if (!file.exists(path)) stop("Input file not found: ", path)

  # na = "" preserva la categoría literal "NA" de CODIGO_REGION
  raw <- readr::read_csv(path, show_col_types = FALSE, na = "")

  required_cols <- c("dimension", "categoria", "n_total", "n_rsh_match",
                     "pct_rsh_match", "n_conadi_match", "pct_conadi_match")
  missing_cols <- setdiff(required_cols, names(raw))
  if (length(missing_cols) > 0L) {
    stop("Missing columns in F_nas_resumen.csv: ", paste(missing_cols, collapse = ", "))
  }
  if (anyNA(raw)) stop("Unexpected NA values in F_nas_resumen.csv.")

  # 1) Enlace unico: RSH y CONADI deben ser identicos fila a fila
  if (!all(raw$n_rsh_match == raw$n_conadi_match) ||
      !all(raw$pct_rsh_match == raw$pct_conadi_match)) {
    stop("RSH and CONADI columns differ: single-linkage assumption violated.")
  }

  # 2) Dimensiones y categorias esperadas (contrato cerrado de la auditoria)
  expected_cats <- list(
    GLOSA_SEXO    = c("HOMBRE", "MUJER", "INTERSEX (INDETERMINADO)", "No reportado"),
    GRUPO_ETARIO  = AGE_ORDER,
    CODIGO_REGION = c(as.character(1:16), "NA")
  )
  if (!setequal(unique(raw$dimension), names(expected_cats))) {
    stop("Unexpected dimensions in F_nas_resumen.csv.")
  }
  for (d in names(expected_cats)) {
    observed <- raw$categoria[raw$dimension == d]
    if (!setequal(observed, expected_cats[[d]])) {
      stop("Unexpected categories in dimension ", d, ": ",
           paste(setdiff(observed, expected_cats[[d]]), collapse = ", "))
    }
  }

  # 3) Cada dimension debe cubrir el total de la base
  sums_by_dim <- tapply(raw$n_total, raw$dimension, sum)
  if (!all(sums_by_dim == TOTAL_EGRESOS)) {
    stop("Dimension totals do not add up to the full base (20,957,004 discharges).")
  }

  # 4) Cifras canonicas del informe (redondeo a 1 decimal)
  check <- raw %>%
    semi_join(CANONICAL, by = c("dimension", "categoria")) %>%
    left_join(CANONICAL, by = c("dimension", "categoria")) %>%
    mutate(ok = round(.data$pct_rsh_match, 1) == .data$expected)
  if (nrow(check) != nrow(CANONICAL) || !all(check$ok)) {
    stop("Canonical cross-check failed against INFORME.md section F figures.")
  }

  # Separar excluidos del cuerpo (se reportan solo en la nota al pie)
  excluded <- raw %>% filter(.data$categoria %in% c("No reportado", "NA"))
  body <- raw %>% filter(!.data$categoria %in% c("No reportado", "NA"))

  # Etiquetas de display y orden interno por bloque
  body <- body %>%
    mutate(
      dimension_label = dplyr::recode(.data$dimension,
                                      GLOSA_SEXO = "Sexo",
                                      GRUPO_ETARIO = "Grupo etario",
                                      CODIGO_REGION = "Región de residencia"),
      category_label = dplyr::case_when(
        .data$dimension == "GLOSA_SEXO" ~ unname(SEX_LABELS[.data$categoria]),
        .data$dimension == "GRUPO_ETARIO" ~ paste0(.data$categoria, " años"),
        .data$dimension == "CODIGO_REGION" ~ paste(.data$categoria, unname(REGION_NAMES[.data$categoria]))
      ),
      # clave de orden determinista dentro de cada bloque (match sobre strings:
      # evita la coercion a entero que ensucia con warnings a las otras ramas)
      order_key = dplyr::case_when(
        .data$dimension == "GLOSA_SEXO" ~ match(.data$categoria, names(SEX_LABELS)),
        .data$dimension == "GRUPO_ETARIO" ~ match(.data$categoria, AGE_ORDER),
        .data$dimension == "CODIGO_REGION" ~ match(.data$categoria, as.character(1:16))
      ),
      block_key = match(.data$dimension, c("GLOSA_SEXO", "GRUPO_ETARIO", "CODIGO_REGION"))
    ) %>%
    arrange(.data$block_key, .data$order_key)

  list(body = body, excluded = excluded)
}

# ==============================================================================
# FUNCION: build_footnote
# ==============================================================================
# Nota al pie con las exclusiones (n y % reales, no hardcodeados) y la
# advertencia sobre Nuble.
#   - compact = FALSE: parrafo unico para el pie de la tabla (hace wrap solo).
#   - compact = TRUE:  lineas cortas con saltos explicitos para el caption de
#     la figura (plot.caption no hace wrap y se corta al ancho del grafico).
# ==============================================================================
build_footnote <- function(excluded, compact = FALSE) {
  ex_sex <- excluded %>% filter(.data$dimension == "GLOSA_SEXO")
  ex_reg <- excluded %>% filter(.data$dimension == "CODIGO_REGION")
  if (compact) {
    paste0(
      "Nota: se excluyen ", fmt_int(ex_sex$n_total), " egresos sin sexo reportado (",
      fmt_pct(ex_sex$pct_rsh_match), "% con enlace) y ", fmt_int(ex_reg$n_total),
      " sin región reportada (", fmt_pct(ex_reg$pct_rsh_match), "%).\n",
      "Ñuble (16) existe como región desde noviembre de 2018; los egresos previos de ese territorio van en Biobío (8). ",
      "RSH y CONADI son un único enlace."
    )
  } else {
    paste0(
      "Nota: Ñuble (16) existe como región desde noviembre de 2018; los egresos previos de ese territorio se contabilizan en Biobío (8). ",
      "Se excluyen del cuerpo ", fmt_int(ex_sex$n_total), " egresos sin sexo reportado (",
      fmt_pct(ex_sex$pct_rsh_match), "% con enlace) y ", fmt_int(ex_reg$n_total),
      " sin región reportada (", fmt_pct(ex_reg$pct_rsh_match), "% con enlace). ",
      "RSH y CONADI comparten el mismo conjunto de enlaces (enlace único); se reporta una sola columna."
    )
  }
}

# ==============================================================================
# FUNCION: build_distribution_table
# ==============================================================================
# Tabla S2: tres bloques con filas de encabezado de bloque insertadas.
# Retorna lista con table_long (CSV) y table_ft (flextable para PNG).
# ==============================================================================
build_distribution_table <- function(body, footnote) {
  table_long <- body %>%
    transmute(
      dimension = .data$dimension,
      category = .data$categoria,
      category_label = .data$category_label,
      n_total = .data$n_total,
      n_rsh_match = .data$n_rsh_match,
      pct_rsh_match = .data$pct_rsh_match
    )

  # Construir display con filas de encabezado de bloque (indices registrados).
  # El split se hace sobre body (table_long no incluye dimension_label).
  blocks <- split(body, body$dimension_label)[c("Sexo", "Grupo etario", "Región de residencia")]
  display_rows <- list()
  block_header_idx <- integer(0)
  row_cursor <- 0L
  for (block_name in names(blocks)) {
    row_cursor <- row_cursor + 1L
    block_header_idx <- c(block_header_idx, row_cursor)
    display_rows[[block_name]] <- bind_rows(
      tibble::tibble(Categoría = block_name, `N egresos` = "", `N enlazados` = "", `% enlace` = ""),
      blocks[[block_name]] %>%
        transmute(
          Categoría = .data$category_label,
          `N egresos` = fmt_int(.data$n_total),
          `N enlazados` = fmt_int(.data$n_rsh_match),
          `% enlace` = fmt_pct(.data$pct_rsh_match)
        )
    )
    row_cursor <- row_cursor + nrow(blocks[[block_name]])
  }
  display_df <- bind_rows(display_rows)

  table_ft <- flextable(display_df) %>%
    add_header_lines(values = paste0(
      "Tabla S2. Distribución del enlace RSH/CONADI según sexo, grupo etario y región de residencia. ",
      "Egresos hospitalarios, Chile 2010-2022."
    )) %>%
    merge_at(i = 1L, j = seq_len(ncol(display_df)), part = "header") %>%
    add_footer_lines(values = footnote) %>%
    merge_at(i = 1L, j = seq_len(ncol(display_df)), part = "footer") %>%
    theme_booktabs() %>%
    bold(part = "header") %>%
    bold(i = block_header_idx, part = "body") %>%
    bg(i = block_header_idx, bg = "#F5F5F5", part = "body") %>%
    align(j = 2:4, align = "center", part = "all") %>%
    align(i = 1L, align = "left", part = "header") %>%
    fontsize(size = 9, part = "all") %>%
    fontsize(i = 1L, size = 10, part = "header") %>%
    fontsize(size = 8, part = "footer") %>%
    autofit()

  list(table_long = table_long, table_ft = table_ft)
}

# ==============================================================================
# FUNCION: build_distribution_figure
# ==============================================================================
# Figura S3: barras horizontales del % de enlace, tres paneles (patchwork).
# ==============================================================================
build_bar_panel <- function(df, panel_title, show_x_label = FALSE) {
  # factor con niveles invertidos: la primera categoria del bloque queda arriba
  plot_data <- df %>%
    mutate(category_fct = factor(.data$category_label, levels = rev(.data$category_label)))

  ggplot(plot_data, aes(x = .data$pct_rsh_match, y = .data$category_fct)) +
    geom_col(fill = COLOR_LINK, width = 0.72) +
    geom_text(aes(label = paste0(fmt_pct(.data$pct_rsh_match), "%")),
              hjust = -0.12, size = 3, color = "grey20") +
    scale_x_continuous(expand = expansion(mult = c(0, 0.16))) +
    labs(
      title = panel_title,
      x = if (show_x_label) "Egresos con enlace (%)" else NULL,
      y = NULL
    ) +
    theme_minimal() +
    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text = element_text(size = 8.5),
      axis.title.x = element_text(size = 9, face = "bold"),
      plot.title = element_text(size = 10.5, face = "bold")
    )
}

build_distribution_figure <- function(body, footnote_fig) {
  blocks <- split(body, body$dimension_label)[c("Sexo", "Grupo etario", "Región de residencia")]

  p_sex    <- build_bar_panel(blocks[["Sexo"]], "A. Sexo")
  p_age    <- build_bar_panel(blocks[["Grupo etario"]], "B. Grupo etario")
  p_region <- build_bar_panel(blocks[["Región de residencia"]], "C. Región de residencia",
                              show_x_label = TRUE)

  caption <- paste0(
    footnote_fig, "\n",
    "Fuente: base de egresos hospitalarios DEIS, Chile 2010-2022; enlace a registros sociales vigentes al año de corte (2022/2023)."
  )

  p_sex / p_age / p_region +
    plot_layout(heights = c(3, 7, 16)) +
    plot_annotation(
      title = "Distribución del enlace a registros sociales (RSH/CONADI) según características del egreso",
      subtitle = "Porcentaje de egresos con enlace no nulo por categoría. Egresos hospitalarios, Chile 2010-2022.",
      caption = caption,
      theme = theme(
        plot.title = element_text(size = 13, face = "bold"),
        plot.subtitle = element_text(size = 10),
        plot.caption = element_text(hjust = 0, size = 8)
      )
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
  cat("DISTRIBUCIÓN DEL ENLACE RSH/CONADI — TABLA S2 Y FIGURA S3\n")
  cat("================================================================================\n\n")

  data <- load_link_distribution(AUDIT_DIR)
  cat("✓ Datos de auditoría cargados y validados\n")
  cat("  - Enlace único RSH == CONADI verificado en las 28 filas\n")
  cat("  - Sumas por dimensión = 20.957.004 egresos (total de la base)\n")
  cat("  - Cifras canónicas del informe (sección F) cuadran al redondeo de 1 decimal\n")

  if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

  footnote <- build_footnote(data$excluded)

  # Tabla S2: CSV tidy + PNG flextable
  tables <- build_distribution_table(data$body, footnote)
  readr::write_csv(tables$table_long,
                   file.path(OUT_DIR, "tabla_distribucion_enlace.csv"))
  cat("✓ tabla_distribucion_enlace.csv\n")

  guardar_tabla_png(tables$table_ft, "tabla_distribucion_enlace",
                    zoom = 3, dir_salida = OUT_DIR)

  # Figura S3: tres paneles con patchwork (nota compacta: el caption no hace wrap)
  # Workaround device JPEG (corrompe colores en este equipo: fondo magenta):
  # ggsave a PNG y conversión a JPG vía magick (patrón de
  # temp_read/audit_rsh_conadi/sesgo_supervivencia_figuras.R)
  fig <- build_distribution_figure(data$body, build_footnote(data$excluded, compact = TRUE))
  guardar_jpg_via_png(fig, "fig_distribucion_enlace",
                      ancho = 10, alto = 11, dpi = 600, dir_salida = OUT_DIR)
  cat("✓ fig_distribucion_enlace.jpg (600 dpi)\n")

  cat("\nArchivos generados en:", OUT_DIR, "\n")
  invisible(TRUE)
}

# Ejecutar solo cuando el script se corre directamente (no al sourcearlo)
if (sys.nframe() == 0L) {
  main()
}
