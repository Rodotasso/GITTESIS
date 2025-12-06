#' Calcular Lin's CCC para cualquier desagregación
#'
#' @description
#' Función genérica que calcula Lin's CCC entre dos fuentes de datos
#' para cualquier nivel de desagregación (región, sexo, edad, etc.)
#'
#' @param datos_censo Datos del Censo 2017 (tibble con columnas de agrupación + porcentaje_censo)
#' @param datos_comparacion Datos a comparar (tibble con columnas de agrupación + porcentaje a comparar)
#' @param columnas_join Vector con nombres de columnas para el join (ej: c("region", "sexo"))
#' @param nombre_desagregacion Nombre descriptivo de la desagregación (ej: "Por Región")
#' @param col_porcentaje_comparacion Nombre de la columna de porcentaje en datos_comparacion (default: "porcentaje_pert2")
#' @param verbose Mostrar mensajes de progreso (default: TRUE)
#'
#' @return Tibble con una fila conteniendo:
#'   - Desagregacion: Nombre de la desagregación
#'   - N: Número de pares comparados
#'   - Lin's CCC: Coeficiente de concordancia
#'   - IC 95% Inferior: Límite inferior del IC
#'   - IC 95% Superior: Límite superior del IC
#'   - Interpretacion: Interpretación según Landis & Koch
#'
#' @examples
#' # CCC por región
#' resultado <- calcular_ccc_desagregacion(
#'   datos_censo$por_region,
#'   datos_pert2$por_region,
#'   columnas_join = "region",
#'   nombre_desagregacion = "Por Región"
#' )
#'
#' # CCC por región x sexo
#' resultado <- calcular_ccc_desagregacion(
#'   datos_censo$region_sexo,
#'   datos_pert2$region_sexo,
#'   columnas_join = c("region", "sexo"),
#'   nombre_desagregacion = "Región × Sexo"
#' )
#'
#' @export
calcular_ccc_desagregacion <- function(datos_censo,
                                       datos_comparacion,
                                       columnas_join,
                                       nombre_desagregacion,
                                       col_porcentaje_comparacion = "porcentaje_pert2",
                                       verbose = TRUE) {
  
  # Validaciones
  if (!requireNamespace("DescTools", quietly = TRUE)) {
    stop("El paquete 'DescTools' no está instalado.\n",
         "Instalar con: install.packages('DescTools')")
  }
  
  if (!all(columnas_join %in% names(datos_censo))) {
    stop("Las columnas de join no existen en datos_censo: ",
         paste(setdiff(columnas_join, names(datos_censo)), collapse = ", "))
  }
  
  if (!all(columnas_join %in% names(datos_comparacion))) {
    stop("Las columnas de join no existen en datos_comparacion: ",
         paste(setdiff(columnas_join, names(datos_comparacion)), collapse = ", "))
  }
  
  if (!"porcentaje_censo" %in% names(datos_censo)) {
    stop("datos_censo debe tener columna 'porcentaje_censo'")
  }
  
  if (!col_porcentaje_comparacion %in% names(datos_comparacion)) {
    stop("datos_comparacion debe tener columna '", col_porcentaje_comparacion, "'")
  }
  
  if (verbose) {
    cat("Calculando CCC:", nombre_desagregacion, "...\n")
  }
  
  # Unir datos
  datos_unidos <- datos_censo %>%
    dplyr::inner_join(
      datos_comparacion,
      by = columnas_join,
      suffix = c("_censo", "_comp")
    )
  
  # Verificar que hay datos
  if (nrow(datos_unidos) == 0) {
    warning("No hay datos para unir en ", nombre_desagregacion)
    return(tibble::tibble(
      Desagregacion = nombre_desagregacion,
      N = 0,
      `Lin's CCC` = NA_real_,
      `IC 95% Inferior` = NA_real_,
      `IC 95% Superior` = NA_real_,
      Interpretacion = "Sin datos"
    ))
  }
  
  # Extraer vectores de porcentajes
  porcentaje_censo <- datos_unidos$porcentaje_censo
  
  # Buscar columna de porcentaje de comparación (puede tener sufijo _comp)
  col_comp_real <- names(datos_unidos)[grepl(paste0("^", col_porcentaje_comparacion), 
                                              names(datos_unidos))][1]
  porcentaje_comp <- datos_unidos[[col_comp_real]]
  
  # Calcular CCC
  resultado_ccc <- tryCatch({
    DescTools::CCC(
      porcentaje_censo,
      porcentaje_comp,
      ci = "z-transform",
      conf.level = 0.95
    )
  }, error = function(e) {
    warning("Error al calcular CCC para ", nombre_desagregacion, ": ", e$message)
    return(NULL)
  })
  
  # Verificar resultado
  if (is.null(resultado_ccc)) {
    return(tibble::tibble(
      Desagregacion = nombre_desagregacion,
      N = nrow(datos_unidos),
      `Lin's CCC` = NA_real_,
      `IC 95% Inferior` = NA_real_,
      `IC 95% Superior` = NA_real_,
      Interpretacion = "Error en cálculo"
    ))
  }
  
  # Formatear resultado usando función existente
  resultado_formateado <- formatear_resultado_ccc(resultado_ccc, nombre_desagregacion)
  
  if (verbose) {
    cat(sprintf("  ✓ CCC = %.4f [%.4f, %.4f] - %s\n",
                resultado_formateado$`Lin's CCC`,
                resultado_formateado$`IC 95% Inferior`,
                resultado_formateado$`IC 95% Superior`,
                resultado_formateado$Interpretacion))
  }
  
  return(resultado_formateado)
}
