#' Calcular perfil epidemiológico por diagnósticos
#'
#' @description
#' Calcula el top N de diagnósticos más frecuentes con tasas anuales,
#' proporciones, porcentajes acumulados, promedio de días de estada
#' y proporción de letalidad. Metodología según Bonita 2006.
#'
#' @param datos Datos con columnas DIAG1, DIAG_COMPLETO y col_pertenencia.
#'   Opcionalmente DIAS_ESTADA (numérico) y COND_EGR (1=vivo, 2=fallecido).
#' @param pertenencia Valor de col_pertenencia a filtrar (1 = PO, 0 = PG)
#' @param col_pertenencia Nombre de la columna de pertenencia
#'   (default: "PERTENENCIA2" = Variable Enriquecida;
#'   usar "PUEBLO_ORIGINARIO_BIN" para la declarada en EH)
#' @param poblacion Población de referencia (Censo 2017)
#' @param total_egresos Total de egresos del grupo
#' @param anos_estudio Número de años del período (default: 13 para 2010-2022)
#' @param top_n Número de diagnósticos a retornar (default: 20)
#' @param min_casos Casos mínimos para incluir diagnóstico (default: 1)
#' @param verbose Mostrar mensajes de progreso (default: TRUE)
#'
#' @return Tibble con ranking, diagnóstico, casos, tasas, proporciones,
 #'   promedio_dias_estada, mediana_dias_estada y tasa_letalidad_x1000
#'
#' @details
#' Calcula:
#' - Tasa anual promedio por 1000 persona-años
#' - Proporción por 1000 egresos del grupo
#' - Porcentaje del total y acumulado
#' - Promedio y mediana de días de estada (si DIAS_ESTADA existe)
 #' - Tasa de letalidad intrahospitalaria: fallecidos/egresos × 1000 (si COND_EGR existe)
 #' - Proporción de letalidad global: total_fallecidos/total_egresos × 1000 (atributo del resultado)
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
                                        col_pertenencia = "PERTENENCIA2",
                                        verbose = TRUE) {
  
  if (verbose) {
    grupo_label <- ifelse(pertenencia == 1, "Pueblos Originarios", "Población General")
    cat(sprintf("\n\u2550\u2550\u2550 CALCULANDO PERFIL: %s \u2550\u2550\u2550\n", grupo_label))
  }
  
  # Validaciones
  if (!all(c("DIAG1", "DIAG_COMPLETO", col_pertenencia) %in% names(datos))) {
    stop(sprintf("Datos deben contener columnas: DIAG1, DIAG_COMPLETO, %s", col_pertenencia))
  }
  
  tiene_dias <- "DIAS_ESTADA" %in% names(datos)
  tiene_cond <- "COND_EGR" %in% names(datos)
  
  if (verbose) {
    if (tiene_dias) cat("  \u2022 D\u00edas de estada: disponible\n")
    if (tiene_cond) cat("  \u2022 Condici\u00f3n de egreso: disponible (letalidad)\n")
  }
  
  # Calcular persona-años
  persona_anos <- poblacion * anos_estudio
  
  # Extraer vector de pertenencia dinámicamente
  vec_pert <- datos[[col_pertenencia]]
  
  # Calcular perfil
  perfil <- datos %>%
    dplyr::filter(.data[[col_pertenencia]] == pertenencia) %>%
    dplyr::group_by(DIAG1, DIAG_COMPLETO) %>%
    dplyr::summarise(
      n_casos = dplyr::n(),
      # Días de estada (si existe)
      promedio_dias_estada = if (tiene_dias) mean(DIAS_ESTADA, na.rm = TRUE) else NA_real_,
      mediana_dias_estada = if (tiene_dias) stats::median(DIAS_ESTADA, na.rm = TRUE) else NA_real_,
      # Letalidad (si existe COND_EGR: 2 = fallecido)
      n_fallecidos = if (tiene_cond) sum(COND_EGR == 2, na.rm = TRUE) else NA_integer_,
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
      
      # Tasa de letalidad por causa (por 1000 egresos por esa causa)
      tasa_letalidad_x1000 = ifelse(!is.na(n_fallecidos), (n_fallecidos / n_casos) * 1000, NA_real_),
      
      ranking = dplyr::row_number()
    ) %>%
    # Asegurar que DIAG_COMPLETO esté presente y al inicio
    dplyr::select(ranking, DIAG_COMPLETO, n_casos, tasa_anual, 
                  prop_x1000_egresos, pct_total, pct_acumulado,
                  promedio_dias_estada, mediana_dias_estada,
                  n_fallecidos, tasa_letalidad_x1000)
  
  if (verbose) {
    cat(sprintf("  \u2713 Top %d diagn\u00f3sticos calculados\n", nrow(perfil)))
    cat(sprintf("  \u2713 Representan %.1f%% del total de egresos\n", sum(perfil$pct_total)))
    cat(sprintf("  \u2713 Tasa anual promedio: %.2f x1000 persona-a\u00f1os\n", 
                sum(perfil$tasa_anual)))
    if (tiene_dias) {
      cat(sprintf("  \u2713 Promedio d\u00edas estada (global top %d): %.1f d\u00edas\n",
                  top_n, mean(perfil$promedio_dias_estada, na.rm = TRUE)))
    }
    if (tiene_cond) {
      let_global_x1000 <- sum(perfil$n_fallecidos, na.rm = TRUE) / total_egresos * 1000
      cat(sprintf("  \u2713 Proporci\u00f3n letalidad global: %.2f x1000 egresos\n", let_global_x1000))
    }
  }
  
  # Agregar atributo: proporción de letalidad intrahospitalaria global
  # (total fallecidos grupo / total egresos grupo × 1000) — Protocolo Tabla 4
  if (tiene_cond) {
    n_fallecidos_grupo <- datos %>%
      dplyr::filter(.data[[col_pertenencia]] == pertenencia) %>%
      dplyr::summarise(n = sum(COND_EGR == 2, na.rm = TRUE)) %>%
      dplyr::pull(n)
    attr(perfil, "prop_letalidad_global_x1000") <- (n_fallecidos_grupo / total_egresos) * 1000
    attr(perfil, "n_fallecidos_global")          <- n_fallecidos_grupo
  }
  
  return(perfil)
}
