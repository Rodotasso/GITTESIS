#' Calcular Cohen's Kappa con DescTools
#'
#' Calcula la concordancia usando Cohen's Kappa con intervalos de confianza
#' mediante DescTools::CohenKappa(). Los intervalos se calculan usando el
#' error estándar asintótico (Fleiss et al., 2003).
#'
#' @param datos Data frame con las variables a comparar
#' @param col_verdad Nombre de la columna con la variable de referencia
#' @param col_estimado Nombre de la columna con la variable a evaluar
#' @param nombre_fuente Nombre descriptivo de la fuente de datos
#' 
#' @return Tibble con resultados: valor Kappa, IC 95%, e interpretación
#' 
#' @references
#' Fleiss, J. L., Levin, B., & Paik, M. C. (2003). Statistical methods for 
#' rates and proportions (3rd ed.). John Wiley & Sons.
#' 
#' @examples
#' \dontrun{
#' datos_prep <- datos_homologados %>%
#'   select(PERTENENCIA2, RSH, CONADI) %>%
#'   mutate(
#'     RSH = ifelse(is.na(RSH), 0, RSH),
#'     CONADI = ifelse(is.na(CONADI), 0, CONADI)
#'   )
#' 
#' kappa_rsh <- calcular_concordancia_desctools(datos_prep, "PERTENENCIA2", "RSH", "RSH")
#' }
#' 
#' @export
calcular_concordancia_desctools <- function(datos, col_verdad, col_estimado, nombre_fuente) {
  
  # Verificar que las columnas existen
  if (!col_verdad %in% names(datos)) {
    stop("La columna '", col_verdad, "' no existe en los datos")
  }
  if (!col_estimado %in% names(datos)) {
    stop("La columna '", col_estimado, "' no existe en los datos")
  }
  
  # Verificar que no hay NAs
  if (any(is.na(datos[[col_verdad]])) || any(is.na(datos[[col_estimado]]))) {
    warning("Hay valores NA en las columnas. Se filtrarán automáticamente.")
    datos <- datos %>% 
      filter(!is.na(.data[[col_verdad]]), !is.na(.data[[col_estimado]]))
  }
  
  # DescTools::CohenKappa requiere una tabla de contingencia o dos vectores
  resultado_kappa <- DescTools::CohenKappa(
    x = datos[[col_verdad]], 
    y = datos[[col_estimado]],
    conf.level = 0.95
  )
  
  valor_kappa <- resultado_kappa["kappa"]
  ic_inferior <- resultado_kappa["lwr.ci"]
  ic_superior <- resultado_kappa["upr.ci"]
  
  # Crear tibble con resultados
  tibble::tibble(
    `Fuente de Datos` = nombre_fuente,
    `Concordancia con Variable Enriquecida` = "Cohen's Kappa",
    `Valor Kappa` = round(valor_kappa, 4),
    `IC 95% Inf` = round(ic_inferior, 4),
    `IC 95% Sup` = round(ic_superior, 4),
    `Interpretación (Landis & Koch)` = dplyr::case_when(
      valor_kappa < 0.00 ~ "Pobre",
      valor_kappa < 0.20 ~ "Leve",
      valor_kappa < 0.40 ~ "Aceptable",
      valor_kappa < 0.60 ~ "Moderada",
      valor_kappa < 0.80 ~ "Sustancial",
      TRUE ~ "Casi Perfecta"
    )
  )
}
