#' Crear Tamaños de Línea según Magnitud de Diferencia
#'
#' Asigna tamaños de línea a grupos CIE-10 basándose en la magnitud
#' de su diferencia respecto a la tendencia esperada.
#'
#' @param clasificacion_grupos Data frame con columnas: Grupo_CIE10, diferencia_promedio
#' @param umbral_grande Numeric. Umbral para líneas más gruesas (default: 8)
#' @param umbral_medio Numeric. Umbral para líneas medianas (default: 5)
#' @param umbral_pequeno Numeric. Umbral para líneas delgadas (default: 3)
#' @param tamanio_grande Numeric. Grosor para diferencias grandes (default: 2.2)
#' @param tamanio_medio Numeric. Grosor para diferencias medias (default: 1.8)
#' @param tamanio_normal Numeric. Grosor para diferencias normales (default: 1.5)
#' @param tamanio_pequeno Numeric. Grosor para diferencias pequeñas (default: 1.2)
#'
#' @return Named numeric vector con tamaños asignados a cada grupo
#'
#' @examples
#' tamanios <- crear_tamanios_linea(clasificacion_grupos)
#'
#' @export
crear_tamanios_linea <- function(clasificacion_grupos,
                                  umbral_grande = 8,
                                  umbral_medio = 5,
                                  umbral_pequeno = 3,
                                  tamanio_grande = 2.2,
                                  tamanio_medio = 1.8,
                                  tamanio_normal = 1.5,
                                  tamanio_pequeno = 1.2) {
  
  # Validación
  required_cols <- c("Grupo_CIE10", "diferencia_promedio")
  missing_cols <- setdiff(required_cols, names(clasificacion_grupos))
  if (length(missing_cols) > 0) {
    stop("Faltan columnas en clasificacion_grupos: ", paste(missing_cols, collapse = ", "))
  }
  
  # Asignar tamaños
  tamanios_linea <- clasificacion_grupos %>%
    mutate(
      tamanio = case_when(
        abs(diferencia_promedio) >= umbral_grande ~ tamanio_grande,
        abs(diferencia_promedio) >= umbral_medio ~ tamanio_medio,
        abs(diferencia_promedio) >= umbral_pequeno ~ tamanio_normal,
        TRUE ~ tamanio_pequeno
      )
    ) %>%
    {setNames(.$tamanio, .$Grupo_CIE10)}
  
  return(tamanios_linea)
}
