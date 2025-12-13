# ==============================================================================
# FUNCION: guardar_como_jpg
# ==============================================================================
# 
# DESCRIPCION:
#   Guarda una tabla flextable como imagen JPG usando conversión temporal a HTML
#   y captura con webshot2
#
# PARAMETROS:
#   @param tabla_ft        Objeto flextable a guardar
#   @param nombre_archivo  Nombre del archivo (sin extensión .jpg)
#
# RETORNA:
#   Invisible NULL (guarda archivo y muestra mensaje)
#
# EFECTOS SECUNDARIOS:
#   - Crea archivo temporal HTML
#   - Guarda archivo JPG en dir_salida/nombre_archivo.jpg
#   - Limpia archivo temporal
#   - Muestra mensaje de éxito o error en consola
#
# DEPENDENCIAS:
#   - flextable::save_as_html
#   - webshot2::webshot
#   - base::tempfile, base::unlink, base::tryCatch
#
# VARIABLES GLOBALES:
#   - dir_salida: Directorio donde guardar el archivo JPG
#
# ARCHIVO ORIGEN:
#   - Concord_nuevas.qmd
#
# NOTAS:
#   - Usa manejo de errores con tryCatch
#   - Dimensiones fijas: vwidth=1200, vheight=800
#   - Requiere webshot2 instalado y chromote disponible
#
# EJEMPLO:
#   dir_salida <- "resultados_tesis/resultados_concordancia"
#   tabla <- flextable(data.frame(A=1:3, B=4:6))
#   guardar_como_jpg(tabla, "mi_tabla")
#   # Guarda: resultados_tesis/resultados_concordancia/mi_tabla.jpg
#
# ==============================================================================

guardar_como_jpg <- function(tabla_ft, nombre_archivo) {
  tryCatch({
    # Verificar que dir_salida existe
    if (!exists("dir_salida")) {
      stop("La variable 'dir_salida' no está definida. Defínela antes de usar esta función.")
    }
    
    # Crear directorio si no existe
    if (!dir.exists(dir_salida)) {
      dir.create(dir_salida, recursive = TRUE)
    }
    
    # Crear archivo temporal HTML
    temp_html <- tempfile(fileext = ".html")
    flextable::save_as_html(tabla_ft, path = temp_html)
    
    # Convertir a JPG
    ruta_jpg <- file.path(dir_salida, paste0(nombre_archivo, ".jpg"))
    webshot2::webshot(temp_html, ruta_jpg, vwidth = 1200, vheight = 800)
    
    # Limpiar archivo temporal
    unlink(temp_html)
    
    cat(sprintf("  ✓ %s.jpg guardado en %s\n", nombre_archivo, dir_salida))
  }, error = function(e) {
    cat(sprintf("  ✗ Error al guardar %s.jpg: %s\n", nombre_archivo, e$message))
  })
}
