#' Generar Resumen de Disparidades por Grupo CIE-10
#'
#' Calcula estadísticas resumidas de las disparidades observadas en cada
#' grupo diagnóstico comparado con el valor de referencia (Variable Enriquecida).
#'
#' @param datos_evolucion Data frame con evolución temporal por grupo
#' @param pct_variable_enriquecida Numeric. Porcentaje de referencia
#' @param verbose Logical. Si TRUE, imprime resumen formateado (default: TRUE)
#'
#' @return Data frame con resumen de disparidades por grupo
#'
#' @examples
#' resumen <- generar_resumen_disparidades(
#'   datos_evolucion_disparidades,
#'   pct_variable_enriquecida = 13.6
#' )
#'
#' @export
generar_resumen_disparidades <- function(datos_evolucion, 
                                         pct_variable_enriquecida,
                                         verbose = TRUE) {
  
  # Validación
  required_cols <- c("Grupo_CIE10", "tipo_representacion", "porcentaje")
  missing_cols <- setdiff(required_cols, names(datos_evolucion))
  if (length(missing_cols) > 0) {
    stop("Faltan columnas en datos_evolucion: ", paste(missing_cols, collapse = ", "))
  }
  
  # Calcular resumen
  resumen <- datos_evolucion %>%
    group_by(Grupo_CIE10, tipo_representacion) %>%
    summarise(
      pct_promedio = mean(porcentaje, na.rm = TRUE),
      pct_min = min(porcentaje, na.rm = TRUE),
      pct_max = max(porcentaje, na.rm = TRUE),
      diferencia_vs_enriquecida = pct_promedio - pct_variable_enriquecida,
      n_observaciones = n(),
      .groups = "drop"
    ) %>%
    arrange(desc(abs(diferencia_vs_enriquecida)))
  
  # Output verbose
  if (verbose) {
    cat("\n═══ RESUMEN DE DISPARIDADES ═══\n")
    cat(sprintf("Referencia Variable Enriquecida: %.2f%%\n\n", pct_variable_enriquecida))
    
    for (i in 1:nrow(resumen)) {
      cat(sprintf(
        "%s (%s):\n  - Promedio: %.1f%% | Rango: [%.1f%%, %.1f%%]\n  - Diferencia vs Variable Enriquecida: %+.1f pp\n  - N observaciones: %d\n\n",
        resumen$Grupo_CIE10[i],
        resumen$tipo_representacion[i],
        resumen$pct_promedio[i],
        resumen$pct_min[i],
        resumen$pct_max[i],
        resumen$diferencia_vs_enriquecida[i],
        resumen$n_observaciones[i]
      ))
    }
  }
  
  return(resumen)
}
