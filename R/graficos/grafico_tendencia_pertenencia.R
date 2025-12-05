# ==============================================================================
# FUNCION: grafico_tendencia_pertenencia
# ==============================================================================
# 
# DESCRIPCION:
#   Genera un gráfico de línea que muestra la evolución temporal del porcentaje
#   de personas pertenecientes a pueblos originarios (solo categoría "pertenece")
#
# PARAMETROS:
#   @param data          Data frame con datos de egresos hospitalarios
#   @param var_nombre    Nombre de la variable a analizar (ej: "RSH", "CONADI")
#   @param var_etiqueta  Etiqueta descriptiva para títulos del gráfico
#
# RETORNA:
#   Objeto ggplot con gráfico de línea (sin puntos)
#   NULL si la variable no existe
#
# DEPENDENCIAS:
#   - dplyr (filter, group_by, summarise, mutate, ungroup)
#   - ggplot2 (ggplot, geom_line, labs, theme_minimal, theme)
#
# ARCHIVO ORIGEN:
#   - grafico_pertenencia.qmd
#
# EJEMPLO:
#   grafico <- grafico_tendencia_pertenencia(datos_ordenados, "RSH", "RSH")
#   print(grafico)
#
# ==============================================================================

grafico_tendencia_pertenencia <- function(data, var_nombre, var_etiqueta) {
  # Verificar que la variable existe
  if(!(var_nombre %in% names(data))) {
    message("La variable ", var_nombre, " no existe en los datos.")
    return(NULL)
  }
  
  # Calcular porcentaje de pertenencia por año
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
    filter(etiqueta != "No reportado") %>%  # Excluir valores no reportados
    filter(etiqueta == "Pertenece a Pueblos Originarios")  # Solo pertenencia
  
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
    "Nota: El gráfico muestra la evolución del porcentaje de pertenencia a pueblos originarios por año.\n",
    "Los valores no reportados (", no_reportados, " registros, ", 
    porcentaje_no_reportados, "% del total) fueron excluidos del análisis."
  )
  
  # Gráfico de tendencia - SIN PUNTOS NI ETIQUETAS
  grafico_tendencia <- ggplot(data_tendencia, aes(x = AÑO, y = porcentaje, group = 1)) +
    geom_line(color = "#003366", linewidth = 1.8) +  # Azul oscuro, línea más gruesa
    labs(
      title = paste("Evolución anual de", var_etiqueta),
      subtitle = "Tendencia del porcentaje de personas pertenecientes a pueblos originarios",
      x = "Año",
      y = "Porcentaje (%)",
      caption = nota_explicativa
    ) +
    theme_minimal() +
    theme(
      panel.grid.major.x = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
      axis.title = element_text(size = 10, face = "bold"),
      plot.title = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 10),
      plot.caption = element_text(hjust = 0, size = 8)
    )
  
  return(grafico_tendencia)
}
