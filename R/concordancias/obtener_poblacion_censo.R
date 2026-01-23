#' Obtener población total del Censo 2017 por pertenencia
#'
#' Extrae datos agregados del Censo 2017 para calcular población total
#' de personas que pertenecen o no a pueblos originarios.
#' 
#' Esta es una versión simplificada de extraer_datos_censo() enfocada
#' en obtener solo los totales nacionales para cálculo de tasas.
#'
#' @param conexion Conexión a la base de datos del censo. Si NULL, se crea una nueva.
#' @param verbose Lógico. Si TRUE, muestra mensajes de progreso.
#' 
#' @return Lista con 3 elementos:
#' \itemize{
#'   \item pob_po: Población que pertenece a pueblos originarios
#'   \item pob_pg: Población que NO pertenece (población general)
#'   \item pob_total: Población total
#' }
#' 
#' @examples
#' \dontrun{
#' # Obtener población para denominadores
#' poblacion <- obtener_poblacion_censo(verbose = TRUE)
#' 
#' # Usar en cálculo de tasas
#' tasa_po <- (casos_po / poblacion$pob_po) * 1000
#' }
#' 
#' @export
obtener_poblacion_censo <- function(conexion = NULL, verbose = TRUE) {
  
  # Verificar que el paquete censo2017 esté disponible
  if (!requireNamespace("censo2017", quietly = TRUE)) {
    stop("El paquete 'censo2017' no está instalado.\n",
         "Instalar con: renv::install('pachamaltese/censo2017')")
  }
  
  # Verificar si hay conexión activa, si no, crear una
  crear_conexion <- is.null(conexion)
  if(crear_conexion) {
    con_censo <- censo2017::censo_conectar()
    # Garantizar cierre de conexión al salir (incluso si hay error)
    on.exit(censo2017::censo_desconectar(), add = TRUE)
  } else {
    con_censo <- conexion
  }
  
  if(verbose) cat("═══ EXTRAYENDO POBLACIÓN DEL CENSO 2017 ═══\n\n")
  
  # Query para obtener totales por pertenencia
  query_poblacion <- "
  SELECT 
    p16 as pertenencia,
    COUNT(*) as total
  FROM personas
  WHERE p16 IS NOT NULL
  GROUP BY p16
  "
  
  if(verbose) cat("Consultando base de datos del censo...\n")
  
  # Ejecutar query
  resultado <- dplyr::tbl(con_censo, dbplyr::sql(query_poblacion)) %>% 
    dplyr::collect()
  
  # Calcular totales
  pob_po <- resultado %>%
    dplyr::filter(pertenencia == 1) %>%
    dplyr::pull(total) %>%
    sum()
  
  pob_pg <- resultado %>%
    dplyr::filter(pertenencia == 2) %>%
    dplyr::pull(total) %>%
    sum()
  
  pob_total <- pob_po + pob_pg
  
  # Nota: La conexión se cierra automáticamente via on.exit() si fue creada
  
  if(verbose) {
    cat("\n✓ Población extraída:\n")
    cat("  • Pueblos Originarios:", format(pob_po, big.mark = ","), "habitantes\n")
    cat("  • Población General:", format(pob_pg, big.mark = ","), "habitantes\n")
    cat("  • Total Nacional:", format(pob_total, big.mark = ","), "habitantes\n")
    cat("  • % Pertenencia:", round((pob_po/pob_total)*100, 2), "%\n\n")
  }
  
  # Retornar lista con valores
  return(list(
    pob_po = pob_po,
    pob_pg = pob_pg,
    pob_total = pob_total
  ))
}
