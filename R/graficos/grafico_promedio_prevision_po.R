# ==============================================================================
# FUNCION: grafico_promedio_prevision_po
# ==============================================================================
# 
# DESCRIPCION:
#   Gráfico de barras horizontales con promedio anual de top 10 previsiones en pueblos originarios
#
# PARAMETROS:
#   @param data  data.frame con datos ordenados
#
# RETORNA:
#   Objeto ggplot con gráfico de barras horizontales
#
# DEPENDENCIAS:
#   - dplyr, ggplot2
#
# ARCHIVO ORIGEN:
#   - graf_cie_prev.qmd (líneas 494-570)
#
# NOTAS:
#   - Filtra PERTENENCIA2 == 1
#   - Muestra top 10 previsiones
#   - Barras horizontales ordenadas por valor
#   - Etiquetas de porcentaje en las barras
#   - Caption con nota explicativa
#
# EJEMPLO:
#   grafico <- grafico_promedio_prevision_po(datos_ordenados)
#   print(grafico)
#
# ==============================================================================

grafico_promedio_prevision_po <- function(data) {
  # Filtrar datos solo para pertenencia a pueblos originarios
  datos_po <- data %>%
    filter(AÑO != "No reportado" & PERTENENCIA2 == 1) %>%
    group_by(AÑO, GLOSA_PREVISION) %>%
    summarise(n_casos = n(), .groups = "drop") %>%
    group_by(AÑO) %>%
    mutate(
      total_año = sum(n_casos),
      porcentaje = round(n_casos/total_año * 100, 2)
    ) %>%
    ungroup()
  
  # Calcular promedios por previsión
  promedios_po <- datos_po %>%
    group_by(GLOSA_PREVISION) %>%
    summarise(
      porcentaje_promedio = mean(porcentaje),
      total_casos = sum(n_casos),
      .groups = "drop"
    ) %>%
    arrange(desc(porcentaje_promedio))
  
  # Identificar top previsiones para incluir en el gráfico
  top_previsiones <- promedios_po %>%
    head(10) %>%
    pull(GLOSA_PREVISION)
  
  # Filtrar solo las top previsiones
  datos_top_po <- promedios_po %>%
    filter(GLOSA_PREVISION %in% top_previsiones)
  
  # Calcular el total de registros analizados
  total_po <- sum(datos_po$n_casos)
  
  # Contar registros no incluidos en top previsiones
  registros_excluidos <- promedios_po %>%
    filter(!GLOSA_PREVISION %in% top_previsiones) %>%
    summarise(total = sum(total_casos)) %>%
    pull(total)
  
  # Crear nota explicativa
  nota_explicativa <- paste0(
    "Nota: El gráfico muestra el promedio anual de las principales previsiones en personas pertenecientes a pueblos originarios (n=", total_po, ").\n",
    "Se muestran las 10 previsiones más frecuentes. Otras previsiones (", registros_excluidos, 
    " casos, ", round(registros_excluidos/total_po*100, 1), "% del total) están excluidas del gráfico."
  )
  
  # Generar el gráfico de barras del promedio
  p <- ggplot(datos_top_po, aes(x = reorder(GLOSA_PREVISION, porcentaje_promedio), y = porcentaje_promedio, fill = GLOSA_PREVISION)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = sprintf("%.1f%%", porcentaje_promedio)), 
              hjust = -0.1, size = 3.5) +
    coord_flip() +
    labs(
      title = "Promedio anual de previsión en Pueblos Originarios",
      subtitle = "Distribución promedio durante el período de estudio",
      x = "",
      y = "Porcentaje promedio (%)",
      caption = nota_explicativa
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      panel.grid.major.y = element_blank(),
      plot.caption = element_text(hjust = 0, size = 8)
    )
  
  return(p)
}
