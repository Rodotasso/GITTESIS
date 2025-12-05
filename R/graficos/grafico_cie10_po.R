# ==============================================================================
# FUNCION: grafico_cie10_po
# ==============================================================================
# 
# DESCRIPCION:
#   Gráfico de líneas con evolución de top 7 grupos CIE-10 en pueblos originarios
#
# PARAMETROS:
#   @param data  data.frame con datos ordenados
#
# RETORNA:
#   Objeto ggplot con gráfico de líneas
#
# DEPENDENCIAS:
#   - dplyr, ggplot2
#
# ARCHIVO ORIGEN:
#   - graf_cie_prev.qmd (líneas 350-420)
#
# NOTAS:
#   - Filtra PERTENENCIA2 == 1
#   - Muestra top 7 grupos CIE-10
#   - Sin puntos, solo líneas (linewidth 1.5)
#   - Paleta de colores específica (7 colores)
#   - Leyenda con 2 columnas
#
# EJEMPLO:
#   grafico <- grafico_cie10_po(datos_ordenados)
#   print(grafico)
#
# ==============================================================================

grafico_cie10_po <- function(data) {
  # Filtrar datos solo para pertenencia a pueblos originarios
  datos_po <- data %>%
    filter(AÑO != "No reportado" & PERTENENCIA2 == 1) %>%
    group_by(AÑO, Grupo_CIE10) %>%
    summarise(n_casos = n(), .groups = "drop") %>%
    group_by(AÑO) %>%
    mutate(
      total_año = sum(n_casos),
      porcentaje = round(n_casos/total_año * 100, 2)
    ) %>%
    ungroup()
  
  # Identificar top 7 grupos CIE-10 para incluir en el gráfico
  top_grupos <- datos_po %>%
    group_by(Grupo_CIE10) %>%
    summarise(total = sum(n_casos)) %>%
    arrange(desc(total)) %>%
    head(7) %>%
    pull(Grupo_CIE10)
  
  # Filtrar solo los top grupos
  datos_top_po <- datos_po %>%
    filter(Grupo_CIE10 %in% top_grupos)
  
  # Calcular el total de registros analizados
  total_po <- sum(datos_po$n_casos)
  
  # Contar registros no incluidos en top grupos
  registros_excluidos <- datos_po %>%
    filter(!Grupo_CIE10 %in% top_grupos) %>%
    summarise(n = sum(n_casos)) %>%
    pull(n)
  
  # Crear nota explicativa
  nota_explicativa <- paste0(
    "Nota: El gráfico muestra solo la evolución de grupos CIE-10 en personas pertenecientes a pueblos originarios (n=", total_po, ").\n",
    "Se muestran los 7 grupos más frecuentes. Otros grupos (", registros_excluidos, 
    " casos, ", round(registros_excluidos/total_po*100, 1), "% del total) están excluidos del gráfico."
  )
  
  # Generar el gráfico con colores distintos - SIN PUNTOS
  p <- ggplot(datos_top_po, aes(x = AÑO, y = porcentaje, color = Grupo_CIE10, group = Grupo_CIE10)) +
    geom_line(linewidth = 1.5) +
    labs(
      title = "Evolución de principales grupos CIE-10 en Pueblos Originarios",
      subtitle = "Porcentajes sobre el total de población perteneciente a pueblos originarios",
      x = "Año",
      y = "Porcentaje (%)",
      color = "Grupo CIE-10",
      caption = nota_explicativa
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.caption = element_text(hjust = 0, size = 8),
      legend.text = element_text(size = 8)
    ) +
    guides(color = guide_legend(ncol = 2)) +
    scale_color_manual(values = c(
  "#E41A1C", "#053e6dff", "#4DAF4A", "#984EA3", 
  "#FF7F00", "#33c5ffff", "#A65628"
))
  
  return(p)
}
