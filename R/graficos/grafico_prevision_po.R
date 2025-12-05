# ==============================================================================
# FUNCION: grafico_prevision_po
# ==============================================================================
# 
# DESCRIPCION:
#   Gráfico de barras apiladas con distribución de previsiones para pueblos originarios
#
# PARAMETROS:
#   @param data  data.frame con datos ordenados
#
# RETORNA:
#   Objeto ggplot con gráfico de barras apiladas
#
# DEPENDENCIAS:
#   - dplyr, ggplot2
#
# ARCHIVO ORIGEN:
#   - graf_cie_prev.qmd (líneas 202-270)
#
# NOTAS:
#   - Filtra PERTENENCIA2 == 1
#   - Muestra top 5 previsiones
#   - Barras 100% apiladas con porcentajes
#   - Caption con nota explicativa
#
# EJEMPLO:
#   grafico <- grafico_prevision_po(datos_ordenados)
#   print(grafico)
#
# ==============================================================================

grafico_prevision_po <- function(data) {
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
  
  # Identificar top 5 previsiones para incluir en el gráfico
  top_previsiones <- datos_po %>%
    group_by(GLOSA_PREVISION) %>%
    summarise(total = sum(n_casos)) %>%
    arrange(desc(total)) %>%
    head(5) %>%
    pull(GLOSA_PREVISION)
  
  # Filtrar solo las top previsiones
  datos_top_po <- datos_po %>%
    filter(GLOSA_PREVISION %in% top_previsiones)
  
  # Calcular el total de registros analizados
  total_po <- sum(datos_po$n_casos)
  
  # Contar registros no incluidos en top previsiones
  registros_excluidos <- datos_po %>%
    filter(!GLOSA_PREVISION %in% top_previsiones) %>%
    summarise(n = sum(n_casos)) %>%
    pull(n)
  
  # Crear nota explicativa
  nota_explicativa <- paste0(
    "Nota: El gráfico muestra solo la distribución entre personas pertenecientes a pueblos originarios (n=", total_po, ").\n",
    "Se muestran las 5 previsiones más frecuentes. Otras previsiones (", registros_excluidos, 
    " casos, ", round(registros_excluidos/total_po*100, 1), "% del total) están excluidas del gráfico.\n",
    "Los porcentajes suman 100% de la población perteneciente a pueblos originarios para cada año."
  )
  
  # Generar el gráfico
  p <- ggplot(datos_top_po, aes(x = AÑO, y = porcentaje, fill = GLOSA_PREVISION)) +
    geom_bar(stat = "identity", position = "stack") +
    geom_text(aes(label = sprintf("%.1f%%", porcentaje)), 
              position = position_stack(vjust = 0.5),
              size = 3, color = "white") +
    labs(
      title = "Distribución de previsión por año - Pueblos Originarios",
      subtitle = "Porcentajes sobre el total de población perteneciente a pueblos originarios",
      x = "Año",
      y = "Porcentaje (%)",
      fill = "Previsión",
      caption = nota_explicativa
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.caption = element_text(hjust = 0, size = 8)
    )
  
  return(p)
}
