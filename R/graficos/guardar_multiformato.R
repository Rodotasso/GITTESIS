# ==============================================================================
# FUNCION: guardar_multiformato
# ==============================================================================
# 
# DESCRIPCION:
#   Guarda un gráfico ggplot en formato JPG con fondo blanco
#
# PARAMETROS:
#   @param grafico     Objeto ggplot a guardar
#   @param nombre_base Nombre base del archivo (sin extensión)
#   @param ancho       Ancho del gráfico en pulgadas (default: 10)
#   @param alto        Alto del gráfico en pulgadas (default: 6)
#   @param dpi         Resolución en puntos por pulgada (default: 300)
#
# RETORNA:
#   Invisible NULL (guarda archivo en disco)
#
# DEPENDENCIAS:
#   - ggplot2::ggsave
#
# ARCHIVO ORIGEN:
#   - grafico_pertenencia.qmd
#
# EJEMPLO:
#   p <- ggplot(data, aes(x, y)) + geom_point()
#   guardar_multiformato(p, "mi_grafico", ancho=12, alto=8)
#
# ==============================================================================

guardar_multiformato <- function(grafico, nombre_base, ancho = 10, alto = 6, dpi = 300,
                                 dir_salida = "resultados_tesis") {
  ruta <- file.path(dir_salida, paste0(nombre_base, ".jpg"))
  dir_ruta <- dirname(ruta)
  if (!dir.exists(dir_ruta)) dir.create(dir_ruta, recursive = TRUE)
  ggsave(ruta, grafico, width = ancho, height = alto, dpi = dpi, bg = "white")
}
