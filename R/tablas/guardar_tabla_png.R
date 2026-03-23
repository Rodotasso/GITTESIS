# ==============================================================================
# FUNCION: guardar_tabla_png
# ==============================================================================
# 
# DESCRIPCION:
#   Guarda una tabla flextable como imagen PNG de alta calidad con fondo blanco.
#   Esta es la función RECOMENDADA para guardar tablas como imágenes porque:
#   - PNG mantiene mejor la nitidez del texto que JPG
#   - Soporta transparencia y bordes más nítidos
#   - Mejor para texto y elementos gráficos precisos
#
# PARAMETROS:
#   @param tabla_ft        Objeto flextable a guardar
#   @param nombre_archivo  Nombre del archivo (sin extensión .png)
#   @param zoom            Factor de zoom para calidad (2-4 recomendado, default: 3)
#   @param expand          Margen alrededor de la tabla en píxeles (default: 20)
#   @param fondo           Color de fondo (default: "white")
#   @param dir_salida      Directorio de salida (default: "resultados_tesis")
#
# RETORNA:
#   Invisible TRUE si tiene éxito, FALSE si falla
#
# EFECTOS SECUNDARIOS:
#   - Guarda archivo PNG en dir_salida/nombre_archivo.png
#   - Muestra mensaje de éxito o error en consola
#
# DEPENDENCIAS:
#   - flextable::save_as_image (método preferido)
#   - webshot2::webshot (método alternativo)
#   - officer, magick (para save_as_image)
#
# CALIDAD DE IMAGEN:
#   - zoom=2: Calidad media (~150 DPI)
#   - zoom=3: Alta calidad (~300 DPI) - RECOMENDADO
#   - zoom=4: Muy alta calidad (~400 DPI) - para impresión
#
# EJEMPLO:
#   dir_salida <- "resultados_tesis/"
#   tabla <- flextable(data.frame(A=1:3, B=4:6))
#   
#   # Guardar con calidad estándar
#   guardar_tabla_png(tabla, "mi_tabla")
#   
#   # Guardar con máxima calidad para impresión
#   guardar_tabla_png(tabla, "mi_tabla_impresion", zoom = 4)
#   
#   # Guardar con fondo personalizado
#   guardar_tabla_png(tabla, "mi_tabla_gris", fondo = "#f5f5f5")
#
# ==============================================================================

guardar_tabla_png <- function(tabla_ft, 
                              nombre_archivo, 
                              zoom = 3,
                              expand = 20,
                              fondo = "white",
                              dir_salida = "resultados_tesis") {
  
  # Ruta del archivo de salida
  ruta_salida <- file.path(dir_salida, paste0(nombre_archivo, ".png"))

  # Crear directorio completo (incluye subdirectorios en nombre_archivo)
  dir_ruta <- dirname(ruta_salida)
  if (!dir.exists(dir_ruta)) {
    dir.create(dir_ruta, recursive = TRUE)
  }
  
  # MÉTODO 1: save_as_image (MEJOR CALIDAD - Recomendado)
  exito <- tryCatch({
    if (requireNamespace("officer", quietly = TRUE) && 
        requireNamespace("magick", quietly = TRUE)) {
      
      flextable::save_as_image(
        x = tabla_ft,
        path = ruta_salida,
        zoom = zoom,
        expand = expand,
        webshot = "webshot2"  # Usar webshot2 si está disponible
      )
      
      # SIEMPRE agregar fondo (PNG por defecto es transparente)
      if (requireNamespace("magick", quietly = TRUE)) {
        img <- magick::image_read(ruta_salida)
        img <- magick::image_background(img, fondo)
        img <- magick::image_flatten(img)  # Aplanar para eliminar transparencia
        magick::image_write(img, ruta_salida)
      }
      
      cat(sprintf("  ✓ %s.png guardado en %s (zoom=%dx, fondo=%s, método: save_as_image)\n", 
                  nombre_archivo, dir_salida, zoom, fondo))
      TRUE
    } else {
      FALSE
    }
  }, error = function(e) {
    message("save_as_image falló: ", e$message)
    FALSE
  })
  
  # MÉTODO 2: webshot2 (Alternativo si save_as_image falla)
  if (!exito) {
    exito <- tryCatch({
      if (requireNamespace("webshot2", quietly = TRUE)) {
        
        # Crear HTML temporal con estilos de fondo
        temp_html <- tempfile(fileext = ".html")
        
        html_inicio <- sprintf('
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
body { 
  background-color: %s; 
  margin: %dpx;
  padding: 0;
  font-family: Arial, Helvetica, sans-serif;
}
table {
  background-color: white;
}
</style>
</head>
<body>', fondo, expand)
        
        # Guardar tabla como HTML
        flextable::save_as_html(tabla_ft, path = temp_html)
        
        # Leer y modificar HTML
        html_lines <- readLines(temp_html, warn = FALSE)
        writeLines(c(html_inicio, html_lines, "</body></html>"), temp_html)
        
        # Capturar con webshot2
        webshot2::webshot(
          url = temp_html,
          file = ruta_salida,
          vwidth = 1400,
          vheight = NULL,  # Auto-altura
          zoom = zoom,
          delay = 0.5
        )
        
        # Limpiar
        unlink(temp_html)
        
        cat(sprintf("  ✓ %s.png guardado en %s (zoom=%dx, método: webshot2)\n", 
                    nombre_archivo, dir_salida, zoom))
        TRUE
      } else {
        FALSE
      }
    }, error = function(e) {
      message("webshot2 falló: ", e$message)
      FALSE
    })
  }
  
  # Si todo falló
  if (!exito) {
    cat(sprintf("  ✗ ERROR: No se pudo guardar %s.png\n", nombre_archivo))
    cat("\n📦 Paquetes necesarios:\n")
    cat("  install.packages(c('officer', 'magick', 'webshot2'))\n\n")
    cat("💡 Alternativa: Usar guardar_tabla_html() y capturar manualmente\n\n")
  }
  
  invisible(exito)
}
