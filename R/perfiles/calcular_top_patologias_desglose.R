# ==============================================================================
# FUNCIONES PARA TOP PATOLOGIAS CON DESGLOSES
# ==============================================================================
# Descripcion: Identifica top N patologias y genera tablas de desglose
#              por pertenencia, sexo, grupo etario y region
# ==============================================================================

#' Calcular top N patologias globales con datos filtrados
#'
#' @param datos Data frame con columnas DIAG1, DIAG_COMPLETO, PERTENENCIA2
#' @param top_n Numero de patologias top a retornar (default: 20)
#' @param col_pertenencia Columna de pertenencia (default: "PERTENENCIA2")
#' @param verbose Mostrar mensajes de progreso (default: TRUE)
#'
#' @return Lista con: top_global (tibble con ranking) y datos_top (datos filtrados a top N)
calcular_top_patologias_desglose <- function(datos,
                                              top_n = 20,
                                              col_pertenencia = "PERTENENCIA2",
                                              verbose = TRUE) {

  # Validaciones
  cols_requeridas <- c("DIAG1", "DIAG_COMPLETO", col_pertenencia)
  faltantes <- setdiff(cols_requeridas, names(datos))
  if (length(faltantes) > 0) {
    stop("Columnas faltantes: ", paste(faltantes, collapse = ", "))
  }

  if (verbose) cat("\n=== CALCULANDO TOP", top_n, "PATOLOGIAS ===\n\n")

  # Ranking global por frecuencia total (PO + PG combinados)
  top_global <- datos %>%
    dplyr::filter(!is.na(DIAG1), nchar(DIAG1) > 0) %>%
    dplyr::count(DIAG1, DIAG_COMPLETO, name = "n_total", sort = TRUE) %>%
    dplyr::slice_head(n = top_n) %>%
    dplyr::mutate(
      ranking = dplyr::row_number(),
      pct_total = (n_total / sum(datos[[col_pertenencia]] %in% c(0, 1))) * 100
    ) %>%
    dplyr::select(ranking, DIAG1, DIAG_COMPLETO, n_total, pct_total)

  # Filtrar datos originales a solo los top N diagnosticos
  datos_top <- datos %>%
    dplyr::filter(DIAG1 %in% top_global$DIAG1)

  if (verbose) {
    cat("  Total registros analizados:", format(nrow(datos), big.mark = ","), "\n")
    cat("  Registros en top", top_n, ":", format(nrow(datos_top), big.mark = ","),
        sprintf("(%.1f%%)\n", nrow(datos_top) / nrow(datos) * 100))
    cat("  Diagnostico mas frecuente:", top_global$DIAG_COMPLETO[1], "\n")
    cat("    n =", format(top_global$n_total[1], big.mark = ","), "\n\n")
  }

  return(list(
    top_global = top_global,
    datos_top = datos_top
  ))
}


#' Crear tabla flextable de desglose por variable
#'
#' @param datos_top Data frame filtrado a top N diagnosticos
#' @param top_global Tibble con ranking global (de calcular_top_patologias_desglose)
#' @param var_desglose Nombre de la variable para desagregar (ej: "GLOSA_SEXO")
#' @param titulo Titulo de la tabla
#' @param top_categorias Si != NULL, solo muestra las N categorias mas frecuentes
#' @param tamano_fuente Tamano de fuente (default: 8)
#' @param etiquetas_var Lista nombrada para renombrar categorias (default: NULL)
#'
#' @return Objeto flextable formateado
crear_tabla_desglose <- function(datos_top,
                                  top_global,
                                  var_desglose,
                                  titulo,
                                  top_categorias = NULL,
                                  tamano_fuente = 8,
                                  etiquetas_var = NULL) {

  if (!(var_desglose %in% names(datos_top))) {
    stop("La variable '", var_desglose, "' no existe en los datos")
  }

  # Determinar categorias a mostrar
  if (!is.null(top_categorias)) {
    cats_frecuentes <- datos_top %>%
      dplyr::count(.data[[var_desglose]], sort = TRUE) %>%
      dplyr::slice_head(n = top_categorias) %>%
      dplyr::pull(.data[[var_desglose]])

    datos_top <- datos_top %>%
      dplyr::filter(.data[[var_desglose]] %in% cats_frecuentes)
  }

  # Calcular n y % por diagnostico x categoria
  conteos <- datos_top %>%
    dplyr::filter(!is.na(.data[[var_desglose]])) %>%
    dplyr::count(DIAG1, .data[[var_desglose]], name = "n") %>%
    dplyr::group_by(DIAG1) %>%
    dplyr::mutate(pct = n / sum(n) * 100) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      etiqueta = paste0(format(n, big.mark = ","), " (", sprintf("%.1f%%", pct), ")")
    )

  # Pivotear a formato ancho
  tabla_ancha <- conteos %>%
    dplyr::select(DIAG1, !!var_desglose := .data[[var_desglose]], etiqueta) %>%
    tidyr::pivot_wider(
      names_from = dplyr::all_of(var_desglose),
      values_from = etiqueta,
      values_fill = "0 (0.0%)"
    )

  # Unir con ranking global
  tabla_final <- top_global %>%
    dplyr::select(ranking, DIAG1, DIAG_COMPLETO, n_total) %>%
    dplyr::left_join(tabla_ancha, by = "DIAG1") %>%
    dplyr::select(-DIAG1)

  # Aplicar etiquetas personalizadas a nombres de columnas
  if (!is.null(etiquetas_var)) {
    nombres_actuales <- names(tabla_final)
    for (i in seq_along(nombres_actuales)) {
      if (nombres_actuales[i] %in% names(etiquetas_var)) {
        nombres_actuales[i] <- etiquetas_var[[nombres_actuales[i]]]
      }
    }
    names(tabla_final) <- nombres_actuales
  }

  # Crear flextable

  ft <- tabla_final %>%
    flextable::flextable() %>%
    flextable::set_header_labels(
      ranking = "#",
      DIAG_COMPLETO = "Diagn\u00f3stico",
      n_total = "N Total"
    ) %>%
    flextable::colformat_num(j = "n_total", big.mark = ",") %>%
    flextable::align(align = "center", part = "all") %>%
    flextable::align(j = "DIAG_COMPLETO", align = "left", part = "body") %>%
    flextable::bold(part = "header") %>%
    flextable::fontsize(size = tamano_fuente, part = "all") %>%
    flextable::width(j = "DIAG_COMPLETO", width = 2.5) %>%
    flextable::set_caption(titulo) %>%
    flextable::theme_booktabs() %>%
    flextable::autofit()

  return(ft)
}
