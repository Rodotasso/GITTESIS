# ==============================================================================
# FUNCION: grafico_tendencia_completa
# ==============================================================================
# 
# DESCRIPCION:
#   Genera un gráfico de líneas que muestra la evolución temporal del porcentaje
#   de pertenencia y no pertenencia a pueblos originarios (ambas categorías)
#
# PARAMETROS:
#   @param data          Data frame con datos de egresos hospitalarios
#   @param var_nombre    Nombre de la variable a analizar
#   @param var_etiqueta  Etiqueta descriptiva para títulos del gráfico
#
# RETORNA:
#   Objeto ggplot con dos líneas (pertenece y población general)
#   NULL si la variable no existe
#
# DEPENDENCIAS:
#   - dplyr (filter, group_by, summarise, mutate, ungroup)
#   - ggplot2 (ggplot, geom_line, scale_color_manual, labs, theme_minimal)
#
# VARIABLES GLOBALES:
#   - colores_analisis: Vector nombrado con colores para las categorías
#
# ARCHIVO ORIGEN:
#   - grafico_pertenencia.qmd
#
# EJEMPLO:
#   grafico <- grafico_tendencia_completa(datos_ordenados, "RSH", "RSH")
#   print(grafico)
#
# ==============================================================================

grafico_tendencia_completa <- function(data, var_nombre, var_etiqueta) {
  # Verificar que la variable existe
  if(!(var_nombre %in% names(data))) {
    message("La variable ", var_nombre, " no existe en los datos.")
    return(NULL)
  }
  
  # Calcular porcentaje de pertenencia por año (incluyendo ambas categorías)
  data_tendencia <- data %>%
    filter(AÑO != "No reportado") %>%
    group_by(AÑO, .data[[var_nombre]]) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(AÑO) %>%
    mutate(
      total = sum(n),
      porcentaje = n / total * 100
    ) %>%
    ungroup() %>%
    mutate(
      etiqueta = case_when(
        .data[[var_nombre]] == 1 ~ "Pertenece a Pueblos Originarios",
        .data[[var_nombre]] == 0 ~ "Población General",
        TRUE ~ "No reportado"
      )
    ) %>%
    filter(etiqueta != "No reportado")  # Excluir valores no reportados
  
  # Contar valores no reportados o nulos
  no_reportados <- data %>%
    filter(AÑO != "No reportado") %>%
    filter(is.na(.data[[var_nombre]]) | !(.data[[var_nombre]] %in% c(0,1))) %>%
    nrow()
  
  total_registros <- data %>%
    filter(AÑO != "No reportado") %>%
    nrow()
  
  porcentaje_no_reportados <- round((no_reportados / total_registros) * 100, 1)
  
  # Crear nota explicativa
  nota_explicativa <- paste0(
    "Nota: El gráfico muestra la evolución del porcentaje de pertenencia a pueblos originarios y población general por año.\n",
    "Los valores no reportados (", no_reportados, " registros, ", 
    porcentaje_no_reportados, "% del total) fueron excluidos del análisis.\n",
    "La suma de ambas líneas completa el 100% de los datos reportados para cada año."
  )
  
  # Gráfico de tendencia para ambas categorías
  grafico_tendencia <- ggplot(data_tendencia, aes(x = AÑO, y = porcentaje, group = etiqueta, color = etiqueta)) +
    geom_line(linewidth = 1.8) +  # Líneas más gruesas
    scale_color_manual(values = colores_analisis) +
    labs(
      title = paste("Evolución anual completa de", var_etiqueta),
      subtitle = "Tendencias del porcentaje de pertenencia a pueblos originarios y población general",
      x = "Año",
      y = "Porcentaje (%)",
      color = "Categoría",
      caption = nota_explicativa
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      panel.grid.major.x = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
      axis.title = element_text(size = 10, face = "bold"),
      plot.title = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 10),
      plot.caption = element_text(hjust = 0, size = 8)
    )
  
  return(grafico_tendencia)
}
