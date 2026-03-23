# ==============================================================================
# FUNCION: guardar_tabla_html
# ==============================================================================
# 
# DESCRIPCION:
#   Guarda un objeto flextable como HTML con manejo de errores mediante tryCatch
#
# PARAMETROS:
#   @param tabla           Objeto flextable a guardar
#   @param nombre_archivo  Nombre del archivo HTML (se guardará en resultados_tesis/)
#
# RETORNA:
#   TRUE si guardado exitoso, NULL si error o tabla NULL
#
# EFECTOS SECUNDARIOS:
#   - Guarda archivo HTML en resultados_tesis/nombre_archivo
#   - Muestra mensajes de éxito o error en consola
#
# DEPENDENCIAS:
#   - flextable::save_as_html
#   - base::file.path, base::message, base::tryCatch
#
# VARIABLES GLOBALES:
#   Ninguna
#
# ARCHIVO ORIGEN:
#   - E_descriptiva2.qmd (líneas 527-540)
#
# NOTAS:
#   - Versión mejorada con manejo robusto de errores
#   - Directorio fijo: "resultados_tesis"
#   - Retorna TRUE/NULL para validación posterior
#   - Captura y muestra errores específicos
#
# EJEMPLO:
#   tabla <- flextable(data.frame(A=1:3, B=4:6))
#   if(guardar_tabla_html(tabla, "resultado.html")) {
#     cat("Guardado exitoso\n")
#   }
#
# ==============================================================================

guardar_tabla_html <- function(tabla, nombre_archivo, dir_salida = "resultados_tesis") {
  if(is.null(tabla)) {
    message("La tabla es NULL, no se puede guardar: ", nombre_archivo)
    return(invisible(NULL))
  }

  ruta_completa <- file.path(dir_salida, nombre_archivo)
  dir_ruta <- dirname(ruta_completa)
  if (!dir.exists(dir_ruta)) dir.create(dir_ruta, recursive = TRUE)

  tryCatch({
    flextable::save_as_html(tabla, path = ruta_completa)
    message("Tabla guardada como: ", ruta_completa)
    return(TRUE)
  }, error = function(e) {
    message("Error al guardar tabla '", nombre_archivo, "': ", e$message)
    return(NULL)
  })
}
