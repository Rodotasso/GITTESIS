#' Calcular perfil epidemiológico por diagnósticos
#'
#' @description
#' Calcula el top N de diagnósticos más frecuentes con tasas anuales,
#' proporciones y porcentajes acumulados. Metodología según Bonita 2006.
#'
#' @param datos Datos con columnas DIAG1, DIAG_COMPLETO, PERTENENCIA2
#' @param pertenencia Valor de PERTENENCIA2 a filtrar (1 = PO, 0 = PG)
#' @param poblacion Población de referencia (Censo 2017)
#' @param total_egresos Total de egresos del grupo
#' @param anos_estudio Número de años del período (default: 13 para 2010-2022)
#' @param top_n Número de diagnósticos a retornar (default: 20)
#' @param min_casos Casos mínimos para incluir diagnóstico (default: 1)
#' @param verbose Mostrar mensajes de progreso (default: TRUE)
#'
#' @return Tibble con ranking, diagnóstico, casos, tasas y proporciones
#'
#' @details
#' Calcula:
#' - Tasa anual promedio por 1000 persona-años
#' - Proporción por 1000 egresos del grupo
#' - Porcentaje del total y acumulado
#'
#' Persona-años = población × años de estudio
#'
#' @examples
#' perfil_po <- calcular_perfil_diagnostico(
#'   datos = datos_preparados,
#'   pertenencia = 1,
#'   poblacion = 2185792,
#'   total_egresos = 500000,
#'   top_n = 20
#' )
#'
#' @export
calcular_perfil_diagnostico <- function(datos,
                                        pertenencia,
                                        poblacion,
                                        total_egresos,
                                        anos_estudio = 13,
                                        top_n = 20,
                                        min_casos = 1,
                                        verbose = TRUE) {
  
  if (verbose) {
    grupo_label <- ifelse(pertenencia == 1, "Pueblos Originarios", "Población General")
    cat(sprintf("\n═══ CALCULANDO PERFIL: %s ═══\n", grupo_label))
  }
  
  # Validaciones
  if (!all(c("DIAG1", "DIAG_COMPLETO", "PERTENENCIA2") %in% names(datos))) {
    stop("Datos deben contener columnas: DIAG1, DIAG_COMPLETO, PERTENENCIA2")
  }
  
  # Calcular persona-años
  persona_anos <- poblacion * anos_estudio
  
  # Calcular perfil
  perfil <- datos %>%
    dplyr::filter(PERTENENCIA2 == pertenencia) %>%
    dplyr::group_by(DIAG1, DIAG_COMPLETO) %>%
    dplyr::summarise(
      n_casos = dplyr::n(),
      .groups = "drop"
    ) %>%
    dplyr::filter(n_casos >= min_casos) %>%
    dplyr::arrange(desc(n_casos)) %>%
    dplyr::slice_head(n = top_n) %>%
    dplyr::mutate(
      # Tasa anual promedio por causa específica (por 1000 persona-años)
      tasa_anual = (n_casos / persona_anos) * 1000,
      
      # Proporción de egresos por causa específica (por 1000 egresos del grupo)
      prop_x1000_egresos = (n_casos / total_egresos) * 1000,
      
      # Porcentajes del total
      pct_total = (n_casos / total_egresos) * 100,
      pct_acumulado = cumsum(pct_total),
      
      ranking = dplyr::row_number()
    ) %>%
    # Asegurar que DIAG_COMPLETO esté presente y al inicio
    dplyr::select(ranking, DIAG_COMPLETO, n_casos, tasa_anual, 
                  prop_x1000_egresos, pct_total, pct_acumulado)
  
  if (verbose) {
    cat(sprintf("  ✓ Top %d diagnósticos calculados\n", nrow(perfil)))
    cat(sprintf("  ✓ Representan %.1f%% del total de egresos\n", sum(perfil$pct_total)))
    cat(sprintf("  ✓ Tasa anual promedio: %.2f x1000 persona-años\n", 
                sum(perfil$tasa_anual)))
  }
  
  return(perfil)
}
