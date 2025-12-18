# ==============================================================================
# FUNCION: guardar_como_jpg (mejorada para guardar tablas como imágenes)
# ==============================================================================
# 
# DESCRIPCION:
#   Guarda una tabla flextable como imagen PNG de alta calidad usando webshot2.
#   PNG es preferible a JPG para tablas porque mantiene mejor la nitidez del texto
#   y los bordes. La función intenta múltiples métodos si el primero falla.
#
# PARAMETROS:
#   @param tabla_ft        Objeto flextable a guardar
#   @param nombre_archivo  Nombre del archivo (sin extensión)
#   @param formato         Formato de salida: "png" (recomendado) o "jpg"
#   @param zoom            Factor de zoom para mejor calidad (default: 3)
#   @param vwidth          Ancho del viewport en píxeles (default: 1400)
#   @param vheight         Alto del viewport en píxeles (default: NULL = auto)
#
# RETORNA:
#   Invisible TRUE si tiene éxito, FALSE si falla
#
# EFECTOS SECUNDARIOS:
#   - Guarda archivo PNG/JPG en dir_salida/nombre_archivo.png/jpg
#   - Muestra mensaje de éxito o error en consola
#
# DEPENDENCIAS:
#   - flextable::save_as_html o flextable::save_as_image
#   - webshot2::webshot (método primario)
#
# VARIABLES GLOBALES:
#   - dir_salida: Directorio donde guardar el archivo
#
# NOTAS:
#   - PNG produce mejor calidad para tablas (texto más nítido)
#   - zoom=3 genera imágenes de alta resolución (300 DPI equivalente)
#   - Si webshot2 falla, intenta usar save_as_image de flextable
#
# EJEMPLO:
#   dir_salida <- "resultados_tesis/"
#   tabla <- flextable(data.frame(A=1:3, B=4:6))
#   guardar_como_jpg(tabla, "mi_tabla")  # Guarda como PNG por defecto
#   guardar_como_jpg(tabla, "mi_tabla", formato = "jpg")  # Guarda como JPG
#
# ==============================================================================

guardar_como_jpg <- function(tabla_ft, 
                             nombre_archivo, 
                             formato = "png",
                             zoom = 3,
                             vwidth = 1400,
                             vheight = NULL) {
  
  # Validar formato
  formato <- tolower(formato)
  if (!formato %in% c("png", "jpg", "jpeg")) {
    formato <- "png"
    warning("Formato no válido. Usando PNG por defecto.")
  }
  if (formato == "jpeg") formato <- "jpg"
  
  # Verificar que dir_salida existe
  if (!exists("dir_salida", envir = .GlobalEnv)) {
    dir_salida <- "resultados_tesis"
    warning("Variable 'dir_salida' no definida. Usando: ", dir_salida)
    assign("dir_salida", dir_salida, envir = .GlobalEnv)
  } else {
    dir_salida <- get("dir_salida", envir = .GlobalEnv)
  }
  
  # Crear directorio si no existe
  if (!dir.exists(dir_salida)) {
    dir.create(dir_salida, recursive = TRUE)
  }
  
  # Ruta del archivo de salida
  ruta_salida <- file.path(dir_salida, paste0(nombre_archivo, ".", formato))
  
  # MÉTODO 1: Intentar con webshot2 (más confiable)
  exito <- tryCatch({
    if (requireNamespace("webshot2", quietly = TRUE)) {
      # Crear archivo temporal HTML con estilos mejorados
      temp_html <- tempfile(fileext = ".html")
      
      # Guardar HTML con estilos para fondo blanco
      html_content <- paste0(
        '<!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
        body { 
          background-color: white; 
          margin: 20px;
          font-family: Arial, sans-serif;
        }
        </style>
        </head>
        <body>'
      )
      
      flextable::save_as_html(tabla_ft, path = temp_html)
      
      # Leer el HTML y agregar estilos
      html_lines <- readLines(temp_html, warn = FALSE)
      writeLines(c(html_content, html_lines, "</body></html>"), temp_html)
      
      # Capturar con webshot2
      webshot2::webshot(
        url = temp_html,
        file = ruta_salida,
        vwidth = vwidth,
        vheight = vheight,
        zoom = zoom,
        delay = 0.5  # Pequeño delay para que cargue bien
      )
      
      # Limpiar archivo temporal
      unlink(temp_html)
      
      cat(sprintf("  ✓ %s.%s guardado en %s (método: webshot2)\n", 
                  nombre_archivo, formato, dir_salida))
      TRUE
    } else {
      FALSE
    }
  }, error = function(e) {
    message("Método webshot2 falló: ", e$message)
    FALSE
  })
  
  # MÉTODO 2: Si webshot2 falló, intentar con save_as_image de flextable
  if (!exito) {
    exito <- tryCatch({
      if (requireNamespace("officer", quietly = TRUE) && 
          requireNamespace("magick", quietly = TRUE)) {
        
        # Usar save_as_image (requiere officer + magick)
        flextable::save_as_image(
          x = tabla_ft,
          path = ruta_salida,
          zoom = zoom,
          expand = 10
        )
        
        # Agregar fondo blanco si es PNG (eliminar transparencia)
        if (formato == "png" && requireNamespace("magick", quietly = TRUE)) {
          img <- magick::image_read(ruta_salida)
          img <- magick::image_background(img, "white")
          img <- magick::image_flatten(img)
          magick::image_write(img, ruta_salida)
        }
        
        cat(sprintf("  ✓ %s.%s guardado en %s (método: save_as_image con fondo)\n", 
                    nombre_archivo, formato, dir_salida))
        TRUE
      } else {
        FALSE
      }
    }, error = function(e) {
      message("Método save_as_image falló: ", e$message)
      FALSE
    })
  }
  
  # Si todo falló, mostrar mensaje de error con soluciones
  if (!exito) {
    cat(sprintf("  ✗ Error al guardar %s.%s\n", nombre_archivo, formato))
    cat("\nSoluciones posibles:\n")
    cat("  1. Instalar webshot2:  install.packages('webshot2')\n")
    cat("  2. Instalar magick:    install.packages('magick')\n")
    cat("  3. Usar guardar_tabla_html() en su lugar\n\n")
  }
  
  invisible(exito)
}
