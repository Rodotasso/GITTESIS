# ==============================================================================
# FUNCION: analizar_variable_solo_po
# ==============================================================================
# 
# DESCRIPCION:
#   Análisis de variable filtrando SOLO población perteneciente a pueblos originarios
#   con gráfico facetado de evolución temporal
#
# PARAMETROS:
#   @param data          data.frame con datos ordenados
#   @param variable_col  Nombre de columna a analizar
#   @param titulo        Título descriptivo
#   @param limite_top    Número de valores top (default: 5)
#   @param n_columnas    Número de columnas en facet_wrap (default: 2)
#
# RETORNA:
#   Objeto ggplot con gráfico facetado
#
# EFECTOS SECUNDARIOS:
#   - Muestra mensaje en consola
#
# DEPENDENCIAS:
#   - dplyr, ggplot2, RColorBrewer
#
# VARIABLES GLOBALES:
#   Ninguna
#
# ARCHIVO ORIGEN:
#   - graf_cie_prev.qmd (líneas 572-665)
#
# NOTAS:
#   - Filtra PERTENENCIA2 == 1
#   - Excluye Intersex y años No reportado
#   - Paleta de colores: RColorBrewer Set1
#   - Colores específicos por panel (sin leyenda)
#   - Caption con nota explicativa de n total
#
# EJEMPLO:
#   grafico_prev_po <- analizar_variable_solo_po(
#     datos_ordenados, 
#     "GLOSA_PREVISION", 
#     "Previsión", 
#     limite_top = 5
#   )
#   print(grafico_prev_po)
#
# ==============================================================================

analizar_variable_solo_po <- function(data, variable_col, titulo, limite_top = 5, n_columnas = 2) {
  message(paste("--- Iniciando análisis de:", titulo, "solo para pueblos originarios ---"))
  
  # Filtrar datos excluyendo Intersex y filtrando solo pueblos originarios
  data_filtered <- data %>%
    filter(GLOSA_SEXO != "Intersex" & PERTENENCIA2 == 1)
  
  # Identificar top valores
  top_valores <- data_filtered %>%
    group_by(!!sym(variable_col)) %>%
    summarise(n = n()) %>%
    arrange(desc(n)) %>%
    head(limite_top) %>%
    pull(!!sym(variable_col))
  
  # Análisis por año
  dist_anual <- data_filtered %>%
    filter(!!sym(variable_col) %in% top_valores & AÑO != "No reportado") %>%
    group_by(AÑO, !!sym(variable_col)) %>%
    summarise(
      n_casos = n(),
      .groups = "drop"
    ) %>%
    group_by(AÑO) %>%
    mutate(
      total_año = sum(n_casos),
      porcentaje = round(n_casos/total_año * 100, 2)
    ) %>%
    ungroup()
  
  # Calcular el total de registros
  total_po <- nrow(data_filtered %>% filter(AÑO != "No reportado"))
  
  # Crear nota explicativa
  nota_explicativa <- paste0(
    "Nota: Los gráficos muestran la distribución por año dentro de la población perteneciente a pueblos originarios (n=", 
    total_po, ").\n",
    "Se muestran los ", limite_top, " ", tolower(titulo), " más frecuentes."
  )
  
  # Crear una paleta de colores personalizada
  colores_po <- RColorBrewer::brewer.pal(9, "Set1")[1:limite_top]
  
  # Crear un mapeo de colores para cada valor
  nombres_valores <- unique(dist_anual[[variable_col]])
  mapeo_colores <- setNames(colores_po[1:length(nombres_valores)], nombres_valores)
  
  # Gráfico facetado por valor del atributo con colores específicos para cada panel
  grafico_facetado <- ggplot(dist_anual, aes(x = AÑO, y = porcentaje, group = 1)) +
    geom_line(aes(color = !!sym(variable_col)), linewidth = 1.5) +
    facet_wrap(vars(!!sym(variable_col)), scales = "free_y", ncol = n_columnas) +
    scale_color_manual(values = mapeo_colores) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1, size = 7),
      strip.text = element_text(size = 9),
      plot.caption = element_text(hjust = 0, size = 8),
      legend.position = "none"  # Ocultar leyenda ya que los paneles tienen etiquetas
    ) +
    labs(
      title = paste("Evolución anual de", titulo, "en Pueblos Originarios"),
      subtitle = "Porcentajes sobre el total de población perteneciente a pueblos originarios",
      x = "Año",
      y = "Porcentaje (%)",
      caption = nota_explicativa
    )
  
  return(grafico_facetado)
}
