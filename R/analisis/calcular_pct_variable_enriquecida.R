#' Calcular Porcentaje Variable Enriquecida (sin duplicados RUN)
#'
#' Calcula el porcentaje de personas pertenecientes a pueblos originarios
#' en la Variable Enriquecida (PERTENENCIA2) eliminando duplicados por RUN.
#' Se queda con el registro más reciente por persona.
#'
#' @param datos Data frame con los datos de egresos hospitalarios
#' @param verbose Logical. Si TRUE, imprime información del cálculo (default: TRUE)
#'
#' @return Numeric. Porcentaje de PO en la Variable Enriquecida
#'
#' @details
#' La función elimina duplicados por RUN quedándose con el registro del año
#' más reciente. Esto proporciona una estimación más precisa de la
#' representación poblacional sin inflar por múltiples hospitalizaciones.
#'
#' @examples
#' pct_ve <- calcular_pct_variable_enriquecida(datos_homologados)
#' cat("Variable Enriquecida:", sprintf("%.2f%%", pct_ve), "\n")
#'
#' @export
calcular_pct_variable_enriquecida <- function(datos, verbose = TRUE) {
  
  # Validaciones
  if (!is.data.frame(datos)) {
    stop("El argumento 'datos' debe ser un data frame")
  }
  
  required_cols <- c("AÑO", "RUN", "PERTENENCIA2")
  missing_cols <- setdiff(required_cols, names(datos))
  if (length(missing_cols) > 0) {
    stop("Faltan las siguientes columnas en los datos: ", paste(missing_cols, collapse = ", "))
  }
  
  # Eliminar duplicados por RUN (quedarse con el año más reciente)
  datos_unicos_run <- datos %>%
    filter(AÑO != "No reportado", !is.na(RUN)) %>%
    arrange(RUN, desc(AÑO)) %>%
    distinct(RUN, .keep_all = TRUE)
  
  # Calcular porcentaje
  resultado <- datos_unicos_run %>%
    summarise(
      total = n(),
      po = sum(PERTENENCIA2 == 1, na.rm = TRUE),
      pct = (po / total) * 100
    )
  
  if (verbose) {
    cat("═══ CÁLCULO VARIABLE ENRIQUECIDA (sin duplicados RUN) ═══\n")
    cat("  - Total personas únicas:", format(resultado$total, big.mark = ","), "\n")
    cat("  - Personas PO:", format(resultado$po, big.mark = ","), "\n")
    cat("  - Porcentaje:", sprintf("%.2f%%", resultado$pct), "\n\n")
  }
  
  return(resultado$pct)
}
