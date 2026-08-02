# ==============================================================================
# FUNCIÓN: Tabla flextable para indicadores estratificados (perfiles desagregados)
# ==============================================================================

#' Tabla flextable estándar para indicadores estratificados
#'
#' Genera una tabla flextable a partir del output de calcular_indicadores_estratificados.
#' Renombra la columna BPP como "DPP" en la cabecera visible.
#'
#' @param df Data frame con indicadores (output de calcular_indicadores_estratificados).
#' @param var_estrato Nombre(s) de la(s) columna(s) de estrato (string o vector).
#' @param titulo Título visible de la tabla (opcional).
#' @return Objeto flextable listo para renderizar.
#' @export
tabla_indicadores_desagregados <- function(df, var_estrato, titulo = NULL) {
  cols_orden <- intersect(
    c(var_estrato, "grupo", "Capitulo", "n", "TBE", "prop", "BPP",
      "prop_PI", "prop_PG", "n_PI", "n_PG", "TBE_PI", "TBE_PG"),
    names(df)
  )
  df_ord <- df %>% dplyr::select(dplyr::all_of(cols_orden))
  ft <- flextable::flextable(df_ord) %>%
    flextable::colformat_double(digits = 2) %>%
    flextable::autofit() %>%
    flextable::theme_booktabs()
  if ("BPP" %in% names(df_ord)) ft <- flextable::set_header_labels(ft, BPP = "DPP")
  if (!is.null(titulo)) ft <- flextable::set_caption(ft, caption = titulo)
  ft
}
