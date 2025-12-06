#' Crear región de Ñuble de forma retrospectiva
#'
#' Convierte códigos de comunas del Biobío (región 8) que fueron traspasadas
#' a Ñuble (región 16) en 2018. Permite análisis retrospectivo de datos
#' anteriores a la creación de la región 16.
#'
#' La función identifica las 21 comunas que pasaron del Biobío a Ñuble y
#' actualiza tanto el código de comuna como la región correspondiente.
#'
#' @param datos Data frame con columnas de región y comuna
#' @param col_region Nombre de la columna con código de región (puede ser character o numeric)
#' @param col_comuna Nombre de la columna con código de comuna (puede ser character o numeric)
#' @param verbose Mostrar mensajes de progreso (default: TRUE)
#' 
#' @return Data frame con dos columnas adicionales:
#' \itemize{
#'   \item region_actualizada: Código de región con Ñuble separado (1-16)
#'   \item codigo_comuna_actualizado: Código de comuna actualizado a nomenclatura 2018+
#' }
#' 
#' @details
#' Comunas convertidas de Biobío (08) a Ñuble (16):
#' - Provincia de Diguillín: Chillán, Bulnes, Chillán Viejo, El Carmen, Pemuco, Pinto, Quillón, San Ignacio, Yungay
#' - Provincia de Itata: Cobquecura, Coelemu, Ninhue, Portezuelo, Quirihue, Ránquil, Treguaco
#' - Provincia de Punilla: Coihueco, Ñiquén, San Carlos, San Fabián, San Nicolás
#' 
#' Total: 21 comunas
#' 
#' @references
#' Ley 21033 (6 de septiembre de 2017): Crea la XVI Región de Ñuble
#' 
#' @examples
#' \dontrun{
#' # Con columnas numéricas
#' datos_actualizados <- crear_region_nuble(
#'   datos_homologados, 
#'   col_region = "REGION",
#'   col_comuna = "COMUNA_RESIDENCIA"
#' )
#' 
#' # Verificar conversiones
#' verificacion <- datos_actualizados %>%
#'   filter(region_actualizada == 16) %>%
#'   count(codigo_comuna_actualizado, region_actualizada)
#' }
#' 
#' @export
crear_region_nuble <- function(datos, col_region, col_comuna, verbose = TRUE) {
  
  if (verbose) {
    cat("═══ CREANDO REGIÓN DE ÑUBLE (RETROSPECTIVA) ═══\n\n")
  }
  
  # Diccionario de conversión Biobío → Ñuble
  # Códigos de 2017 (08XXX) a códigos de 2018 (16XXX)
  conversion_biobio_a_nuble <- tibble::tribble(
    ~codigo_biobio_2017, ~codigo_nuble_2018, ~nombre_comuna,
    8401,  16101, "Chillán",
    8402,  16102, "Bulnes",
    8403,  16201, "Cobquecura",
    8404,  16202, "Coelemu",
    8405,  16302, "Coihueco",
    8406,  16103, "Chillán Viejo",
    8407,  16104, "El Carmen",
    8408,  16203, "Ninhue",
    8409,  16303, "Ñiquén",
    8410,  16105, "Pemuco",
    8411,  16106, "Pinto",
    8412,  16204, "Portezuelo",
    8413,  16107, "Quillón",
    8414,  16205, "Quirihue",
    8415,  16206, "Ránquil",
    8416,  16301, "San Carlos",
    8417,  16304, "San Fabián",
    8418,  16108, "San Ignacio",
    8419,  16305, "San Nicolás",
    8420,  16207, "Treguaco",
    8421,  16109, "Yungay"
  )
  
  # Verificar que las columnas existan
  if (!col_region %in% names(datos)) {
    stop("La columna '", col_region, "' no existe en los datos.")
  }
  if (!col_comuna %in% names(datos)) {
    stop("La columna '", col_comuna, "' no existe en los datos.")
  }
  
  # Convertir a símbolos para evaluación
  col_region_sym <- rlang::sym(col_region)
  col_comuna_sym <- rlang::sym(col_comuna)
  
  # Aplicar conversión
  datos_actualizados <- datos %>%
    dplyr::mutate(
      # Convertir a numérico si es necesario
      cod_comuna_num = as.numeric(!!col_comuna_sym),
      cod_region_num = as.numeric(!!col_region_sym),
      
      # Convertir códigos Biobío antiguos (08XXX) a Ñuble nuevos (16XXX)
      codigo_comuna_actualizado = dplyr::case_when(
        # Si es código de Biobío que pertenece a Ñuble
        cod_comuna_num %in% conversion_biobio_a_nuble$codigo_biobio_2017 &
        cod_region_num == 8 ~
          conversion_biobio_a_nuble$codigo_nuble_2018[
            match(cod_comuna_num, conversion_biobio_a_nuble$codigo_biobio_2017)
          ],
        # Sino, mantener código original
        TRUE ~ cod_comuna_num
      ),
      
      # Actualizar región: si convertimos comuna a Ñuble, cambiar región 8 → 16
      region_actualizada = dplyr::case_when(
        cod_comuna_num %in% conversion_biobio_a_nuble$codigo_biobio_2017 &
        cod_region_num == 8 ~ 16,  # Biobío → Ñuble
        TRUE ~ cod_region_num
      )
    ) %>%
    # Remover columnas temporales
    dplyr::select(-cod_comuna_num, -cod_region_num)
  
  # Verificar conversiones
  if (verbose) {
    n_convertidos <- datos_actualizados %>%
      dplyr::filter(region_actualizada == 16) %>%
      nrow()
    
    comunas_convertidas <- datos_actualizados %>%
      dplyr::filter(region_actualizada == 16) %>%
      dplyr::distinct(codigo_comuna_actualizado) %>%
      nrow()
    
    cat("✓ Conversión completada:\n")
    cat("  - Registros en región Ñuble:", format(n_convertidos, big.mark = ","), "\n")
    cat("  - Comunas únicas en Ñuble:", comunas_convertidas, "de 21 esperadas\n\n")
    
    # Mostrar distribución por región actualizada
    distribucion <- datos_actualizados %>%
      dplyr::count(region_actualizada, name = "n_registros") %>%
      dplyr::arrange(region_actualizada)
    
    cat("Distribución por región actualizada:\n")
    print(distribucion, n = Inf)
    cat("\n")
  }
  
  return(datos_actualizados)
}
