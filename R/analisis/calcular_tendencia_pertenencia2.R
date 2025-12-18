#' Calcular Tendencia Temporal de PERTENENCIA2
#'
#' Calcula el porcentaje de personas pertenecientes a pueblos originarios
#' (PERTENENCIA2) por año en todos los egresos hospitalarios.
#'
#' @param datos Data frame con los datos de egresos hospitalarios
#' @param incluir_no_reportado Logical. Si TRUE, incluye años "No reportado" (default: FALSE)
#'
#' @return Data frame con columnas: AÑO, total, po, pct_po
#'
#' @examples
#' tendencia <- calcular_tendencia_pertenencia2(datos_homologados)
#' print(tendencia)
#'
#' @export
calcular_tendencia_pertenencia2 <- function(datos, incluir_no_reportado = FALSE) {
  
  # Validaciones
  if (!is.data.frame(datos)) {
    stop("El argumento 'datos' debe ser un data frame")
  }
  
  required_cols <- c("AÑO", "PERTENENCIA2")
  missing_cols <- setdiff(required_cols, names(datos))
  if (length(missing_cols) > 0) {
    stop("Faltan las siguientes columnas en los datos: ", paste(missing_cols, collapse = ", "))
  }
  
  # Filtrar datos
  datos_filtrados <- datos
  if (!incluir_no_reportado) {
    datos_filtrados <- datos_filtrados %>%
      filter(AÑO != "No reportado")
  }
  
  # Calcular tendencia
  tendencia <- datos_filtrados %>%
    group_by(AÑO) %>%
    summarise(
      total = n(),
      po = sum(PERTENENCIA2 == 1, na.rm = TRUE),
      pct_po = (po / total) * 100,
      .groups = "drop"
    )
  
  return(tendencia)
}
