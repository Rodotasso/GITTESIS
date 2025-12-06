#' Guardar tabla flextable como imagen JPG
#'
#' Convierte una tabla flextable a imagen JPG usando webshot2.
#' Útil para incluir tablas en presentaciones o documentos que requieren
#' formato de imagen.
#'
#' @param tabla_ft Objeto flextable a exportar
#' @param nombre_archivo Nombre del archivo sin extensión (se agregará .jpg)
#' @param dir_salida Directorio donde guardar la imagen. Por defecto "resultados_tesis/"
#' @param vwidth Ancho del viewport en pixeles (por defecto 1200)
#' @param vheight Alto del viewport en pixeles (por defecto 800)
#' 
#' @return NULL (invisible). La función guarda el archivo y muestra mensaje de confirmación.
#' 
#' @details
#' La función:
#' 1. Crea un archivo HTML temporal con la tabla
#' 2. Usa webshot2 para capturar la tabla como imagen
#' 3. Limpia archivos temporales
#' 4. Maneja errores con try-catch
#' 
#' Requiere paquetes: flextable, officer, webshot2
#' 
#' @examples
#' \dontrun{
#' library(flextable)
#' 
#' # Crear tabla
#' tabla <- data.frame(A = 1:5, B = 6:10) %>%
#'   flextable() %>%
#'   theme_vanilla()
#' 
#' # Guardar como JPG
#' guardar_tabla_jpg(tabla, "mi_tabla", dir_salida = "resultados/")
#' }
#' 
#' @export
guardar_tabla_jpg <- function(tabla_ft, 
                               nombre_archivo, 
                               dir_salida = "resultados_tesis/",
                               vwidth = 1200,
                               vheight = 800) {
  
  # Verificar que el paquete webshot2 está disponible
  if (!requireNamespace("webshot2", quietly = TRUE)) {
    stop("El paquete 'webshot2' no está instalado.\n",
         "Instalar con: install.packages('webshot2')")
  }
  
  # Verificar que el paquete officer está disponible (para save_as_html)
  if (!requireNamespace("officer", quietly = TRUE)) {
    stop("El paquete 'officer' no está instalado.\n",
         "Instalar con: install.packages('officer')")
  }
  
  # Crear directorio si no existe
  if (!dir.exists(dir_salida)) {
    dir.create(dir_salida, recursive = TRUE)
  }
  
  # Ejecutar con manejo de errores
  tryCatch({
    # Crear archivo temporal HTML
    temp_html <- tempfile(fileext = ".html")
    flextable::save_as_html(tabla_ft, path = temp_html)
    
    # Convertir a JPG
    ruta_jpg <- file.path(dir_salida, paste0(nombre_archivo, ".jpg"))
    webshot2::webshot(temp_html, ruta_jpg, vwidth = vwidth, vheight = vheight)
    
    # Limpiar archivo temporal
    unlink(temp_html)
    
    cat(sprintf("✓ Guardado: %s\n", ruta_jpg))
    
    return(invisible(ruta_jpg))
    
  }, error = function(e) {
    cat(sprintf("✗ Error al guardar %s.jpg: %s\n", nombre_archivo, e$message))
    return(invisible(NULL))
  })
}
