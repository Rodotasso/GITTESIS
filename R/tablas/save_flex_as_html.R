# ==============================================================================
# FUNCION: save_flex_as_html
# ==============================================================================
# 
# DESCRIPCION:
#   Guarda un objeto flextable como archivo HTML con mensaje de confirmación
#
# PARAMETROS:
#   @param ft        Objeto flextable a guardar
#   @param filename  Nombre del archivo HTML (se guardará en resultados_tesis/)
#
# RETORNA:
#   Invisible NULL (muestra mensaje en consola)
#
# EFECTOS SECUNDARIOS:
#   - Guarda archivo HTML en resultados_tesis/filename
#   - Muestra mensaje de éxito o error en consola
#
# DEPENDENCIAS:
#   - flextable::save_as_html
#   - base::file.path, base::message
#
# VARIABLES GLOBALES:
#   Ninguna
#
# ARCHIVO ORIGEN:
#   - E_descriptiva2.qmd (líneas 510-520)
#
# NOTAS:
#   - Directorio fijo: "resultados_tesis"
#   - Retorna invisible NULL si ft es NULL
#   - Muestra mensaje descriptivo al usuario
#
# EJEMPLO:
#   tabla <- flextable(data.frame(A=1:3, B=4:6))
#   save_flex_as_html(tabla, "mi_tabla.html")
#   # Guarda: resultados_tesis/mi_tabla.html
#
# ==============================================================================

save_flex_as_html <- function(ft, filename) {
  if(is.null(ft)) {
    message("La tabla es NULL, no se puede guardar: ", filename)
    return(invisible(NULL))
  }
  
  html_file <- file.path("resultados_tesis", filename)
  flextable::save_as_html(ft, path = html_file)
  message("Tabla guardada como: ", html_file)
}
