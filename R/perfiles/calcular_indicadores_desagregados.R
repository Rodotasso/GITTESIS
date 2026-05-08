# ==============================================================================
# FUNCIONES: Indicadores epidemiológicos desagregados
# ==============================================================================

#' Preparar denominador estratificado
#'
#' @param df_censo Data frame del censo con columnas 'total', 'pertenece' y variables de estrato.
#'
#' @return Data frame con columnas 'grupo' (PI/PG) y 'poblacion' en formato largo.
#' @export
preparar_denominador_estrato <- function(df_censo) {
  df_censo %>%
    dplyr::mutate(
      PI = pertenece,
      PG = total - pertenece
    ) %>%
    dplyr::select(-total, -pertenece, -dplyr::any_of("porcentaje_censo")) %>%
    tidyr::pivot_longer(cols = c("PI", "PG"), names_to = "grupo", values_to = "poblacion")
}

#' Calcular Indicadores Estratificados
#'
#' @param datos Data frame de egresos.
#' @param denominador_df Data frame con la población. Debe tener columnas 'grupo', 'poblacion' y las de `var_estrato`.
#' @param var_estrato Vector de caracteres con los nombres de las variables a estratificar.
#' @param col_pertenencia Columna de pertenencia (default: "PERTENENCIA2").
#'
#' @return Tibble con TBE, TLI, PEC, BPP, PDE estratificados.
#' @export
calcular_indicadores_estratificados <- function(datos, denominador_df, var_estrato, col_pertenencia = "PERTENENCIA2") {
  
  # Asignar grupo PI/PG
  datos <- datos %>%
    dplyr::mutate(grupo = ifelse(!is.na(.data[[col_pertenencia]]) & .data[[col_pertenencia]] == 1, "PI", "PG")) %>%
    dplyr::filter(grupo %in% c("PI", "PG"))
  
  # Totales por grupo y estrato (Denominador para PEC, TBE y TLI global)
  totales_estrato <- datos %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(c("grupo", var_estrato)))) %>%
    dplyr::summarise(
      Et = dplyr::n(),
      F_total = sum(COND_EGR == 2, na.rm = TRUE),
      Sum_dias = sum(DIAS_ESTADA, na.rm = TRUE),
      n_validos_dias = sum(!is.na(DIAS_ESTADA)),
      .groups = "drop"
    ) %>%
    dplyr::inner_join(denominador_df, by = c("grupo", var_estrato)) %>%
    dplyr::mutate(
      TBE = (Et / poblacion) * 10000,
      TLI_global = (F_total / Et) * 100,
      PDE_global = Sum_dias / n_validos_dias
    )
  
  # Indicadores por Capitulo y estrato
  indicadores_capitulo <- datos %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(c("grupo", var_estrato, "Capitulo")))) %>%
    dplyr::summarise(
      Ec = dplyr::n(),
      Fc = sum(COND_EGR == 2, na.rm = TRUE),
      Sum_dias_c = sum(DIAS_ESTADA, na.rm = TRUE),
      n_validos_c = sum(!is.na(DIAS_ESTADA)),
      .groups = "drop"
    ) %>%
    dplyr::inner_join(
      totales_estrato %>% dplyr::select(dplyr::all_of(c("grupo", var_estrato, "Et", "poblacion"))), 
      by = c("grupo", var_estrato)
    ) %>%
    dplyr::mutate(
      TBE = (Ec / poblacion) * 10000,
      PEC = (Ec / Et) * 100,
      TLI = (Fc / Ec) * 100,
      PDE = Sum_dias_c / n_validos_c
    )
  
  # Brechas de Puntos Porcentuales (BPP)
  brechas <- indicadores_capitulo %>%
    dplyr::select(dplyr::all_of(c(var_estrato, "Capitulo", "grupo", "PEC"))) %>%
    tidyr::pivot_wider(names_from = grupo, values_from = PEC, names_prefix = "PEC_") %>%
    dplyr::mutate(
      PEC_PI = tidyr::replace_na(PEC_PI, 0),
      PEC_PG = tidyr::replace_na(PEC_PG, 0),
      BPP = PEC_PI - PEC_PG
    ) %>%
    dplyr::select(dplyr::all_of(c(var_estrato, "Capitulo", "BPP")))
  
  # Resultado final ensamblado
  resultado <- indicadores_capitulo %>%
    dplyr::left_join(brechas, by = c(var_estrato, "Capitulo")) %>%
    dplyr::select(dplyr::all_of(c("grupo", var_estrato, "Capitulo", "Ec", "Et", "PEC", "BPP", "TLI", "PDE", "TBE"))) %>%
    dplyr::arrange(dplyr::across(dplyr::all_of(c(var_estrato, "Capitulo"))), dplyr::desc(grupo))
  
  return(resultado)
}
