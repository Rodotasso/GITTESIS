#' Crear Paleta de Colores para Grupos con Disparidad
#'
#' Crea una paleta de colores dinámica para grupos CIE-10 basada en si
#' muestran sobre o subrepresentación. Rojos para sobrerrepresentación,
#' azules/verdes para subrepresentación.
#'
#' @param clasificacion_grupos Data frame con columnas: Grupo_CIE10, tipo_representacion, diferencia_promedio
#' @param intensidad_rojos Character vector. Colores para sobrerrepresentación (default: c("#B71C1C", "#E74C3C", "#FF6B6B"))
#' @param intensidad_frios Character vector. Colores para subrepresentación (default: c("#0D47A1", "#1976D2", "#42A5F5", "#26A69A"))
#' @param color_limite Character. Color para grupos límite (default: "#757575")
#'
#' @return Named character vector con colores asignados a cada grupo
#'
#' @examples
#' colores <- crear_paleta_disparidad(clasificacion_grupos)
#'
#' @export
crear_paleta_disparidad <- function(clasificacion_grupos,
                                     intensidad_rojos = c("#B71C1C", "#E74C3C", "#FF6B6B"),
                                     intensidad_frios = c("#0D47A1", "#1976D2", "#42A5F5", "#26A69A"),
                                     color_limite = "#757575") {
  
  # Validación
  required_cols <- c("Grupo_CIE10", "tipo_representacion", "diferencia_promedio")
  missing_cols <- setdiff(required_cols, names(clasificacion_grupos))
  if (length(missing_cols) > 0) {
    stop("Faltan columnas en clasificacion_grupos: ", paste(missing_cols, collapse = ", "))
  }
  
  # Separar grupos por tipo
  grupos_sobre <- clasificacion_grupos %>% 
    filter(tipo_representacion == "Sobrerrepresentación") %>% 
    arrange(desc(diferencia_promedio)) %>%
    pull(Grupo_CIE10)
  
  grupos_sub <- clasificacion_grupos %>% 
    filter(tipo_representacion == "Subrepresentación") %>% 
    arrange(diferencia_promedio) %>%
    pull(Grupo_CIE10)
  
  grupos_limite <- clasificacion_grupos %>% 
    filter(tipo_representacion == "Límite") %>% 
    pull(Grupo_CIE10)
  
  # Crear paleta
  colores_disparidad <- c()
  
  # Rojos para sobrerrepresentación
  if (length(grupos_sobre) > 0) {
    paleta_rojos <- colorRampPalette(intensidad_rojos)(max(3, length(grupos_sobre)))
    colores_disparidad <- c(colores_disparidad, 
                           setNames(paleta_rojos[1:length(grupos_sobre)], grupos_sobre))
  }
  
  # Azules/verdes para subrepresentación
  if (length(grupos_sub) > 0) {
    paleta_frios <- colorRampPalette(intensidad_frios)(max(4, length(grupos_sub)))
    colores_disparidad <- c(colores_disparidad, 
                           setNames(paleta_frios[1:length(grupos_sub)], grupos_sub))
  }
  
  # Gris para grupos límite
  if (length(grupos_limite) > 0) {
    colores_disparidad <- c(colores_disparidad, 
                           setNames(rep(color_limite, length(grupos_limite)), grupos_limite))
  }
  
  return(colores_disparidad)
}
