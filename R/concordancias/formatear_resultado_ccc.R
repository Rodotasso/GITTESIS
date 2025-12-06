#' Formatear resultados de Lin's CCC calculado con DescTools
#'
#' Formatea los resultados del coeficiente de concordancia de Lin (CCC) 
#' calculado con DescTools::CCC() en un tibble con interpretación.
#'
#' Los intervalos de confianza se calculan mediante transformación Z de Fisher
#' (Lin, 1989, 2000).
#'
#' @param resultado_ccc Resultado de DescTools::CCC()
#' @param nombre_desagregacion Nombre descriptivo de la desagregación analizada
#' 
#' @return Tibble con columnas:
#' \itemize{
#'   \item Desagregacion: Nombre de la desagregación
#'   \item N: Número de observaciones
#'   \item Lin's CCC: Valor del coeficiente
#'   \item IC 95% Inferior: Límite inferior del intervalo de confianza
#'   \item IC 95% Superior: Límite superior del intervalo de confianza
#'   \item Interpretacion: Clasificación según Landis & Koch (1977)
#' }
#' 
#' @references
#' Lin, L. I. (1989). A concordance correlation coefficient to evaluate 
#' reproducibility. Biometrics, 45(1), 255-268.
#' 
#' Lin, L. I. (2000). A note on the concordance correlation coefficient. 
#' Biometrics, 56(1), 324-325.
#' 
#' Landis, J. R., & Koch, G. G. (1977). The measurement of observer agreement 
#' for categorical data. Biometrics, 33(1), 159-174.
#' 
#' @examples
#' \dontrun{
#' library(DescTools)
#' 
#' # Calcular CCC
#' resultado <- CCC(porcentajes_censo, porcentajes_pert2, 
#'                  ci = "z-transform", conf.level = 0.95)
#' 
#' # Formatear resultado
#' tabla <- formatear_resultado_ccc(resultado, "Por Región")
#' }
#' 
#' @export
formatear_resultado_ccc <- function(resultado_ccc, nombre_desagregacion) {
  
  # Extraer valores directamente (asumiendo estructura de DescTools::CCC)
  valor_ccc <- resultado_ccc$rho.c$est
  ic_inferior <- resultado_ccc$rho.c$lwr.ci
  ic_superior <- resultado_ccc$rho.c$upr.ci
  n_obs <- resultado_ccc$n
  
  # Crear tibble con resultados
  tibble::tibble(
    Desagregacion = nombre_desagregacion,
    N = n_obs,
    `Lin's CCC` = round(valor_ccc, 4),
    `IC 95% Inferior` = round(ic_inferior, 4),
    `IC 95% Superior` = round(ic_superior, 4),
    Interpretacion = dplyr::case_when(
      valor_ccc > 0.80 ~ "Casi perfecta",
      valor_ccc > 0.61 ~ "Sustancial",
      valor_ccc > 0.41 ~ "Moderada",
      valor_ccc > 0.21 ~ "Aceptable",
      TRUE ~ "Leve"
    )
  )
}
