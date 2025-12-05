# ==============================================================================
# FUNCION: grafico_comparativo_fuentes
# ==============================================================================
# 
# DESCRIPCION:
#   Genera un gráfico comparativo de la evolución temporal del porcentaje de
#   pertenencia a pueblos originarios según diferentes fuentes de datos (RSH,
#   CONADI, Egresos Hospitalarios, Variable Enriquecida)
#
# PARAMETROS:
#   @param data Data frame con datos de egresos hospitalarios que debe contener:
#               - AÑO: Año del egreso
#               - RSH: Variable binaria de pertenencia según RSH
#               - CONADI: Variable binaria de pertenencia según CONADI
#               - PUEBLO_ORIGINARIO_BIN: Variable binaria de egresos
#               - PERTENENCIA2: Variable enriquecida de pertenencia
#
# RETORNA:
#   Lista con dos elementos:
#   - grafico: Objeto ggplot con gráfico de líneas comparativo
#   - datos: Data frame con datos procesados (año, fuente, porcentaje)
#
# DEPENDENCIAS:
#   - dplyr (filter, group_by, summarise, mutate, select, bind_rows)
#   - ggplot2 (ggplot, geom_line, scale_color_manual, labs, theme_minimal, theme)
#   - tidyr (pivot_wider)
#
# ARCHIVO ORIGEN:
#   - grafico_pertenencia.qmd
#
# EJEMPLO:
#   resultado <- grafico_comparativo_fuentes(datos_ordenados)
#   print(resultado$grafico)
#   View(resultado$datos)
#
# ==============================================================================

grafico_comparativo_fuentes <- function(data) {
  # Preparar datos de RSH
  data_rsh <- data %>%
    filter(AÑO != "No reportado") %>%
    group_by(AÑO, RSH) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(AÑO) %>%
    mutate(
      total = sum(n),
      porcentaje = n / total * 100
    ) %>%
    ungroup() %>%
    filter(RSH == 1) %>%  # Solo pertenencia a pueblos originarios
    select(AÑO, porcentaje) %>%
    mutate(fuente = "RSH")
  
  # Preparar datos de CONADI
  data_conadi <- data %>%
    filter(AÑO != "No reportado") %>%
    group_by(AÑO, CONADI) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(AÑO) %>%
    mutate(
      total = sum(n),
      porcentaje = n / total * 100
    ) %>%
    ungroup() %>%
    filter(CONADI == 1) %>%  # Solo pertenencia a pueblos originarios
    select(AÑO, porcentaje) %>%
    mutate(fuente = "CONADI")
  
  # Preparar datos de Egresos Hospitalarios
  data_egresos <- data %>%
    filter(AÑO != "No reportado") %>%
    group_by(AÑO, PUEBLO_ORIGINARIO_BIN) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(AÑO) %>%
    mutate(
      total = sum(n),
      porcentaje = n / total * 100
    ) %>%
    ungroup() %>%
    filter(PUEBLO_ORIGINARIO_BIN == 1) %>%  # Solo pertenencia a pueblos originarios
    select(AÑO, porcentaje) %>%
    mutate(fuente = "Egresos Hospitalarios")
  
  # Preparar datos de Pertenencia Enriquecida
  data_pertenencia <- data %>%
    filter(AÑO != "No reportado") %>%
    group_by(AÑO, PERTENENCIA2) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(AÑO) %>%
    mutate(
      total = sum(n),
      porcentaje = n / total * 100
    ) %>%
    ungroup() %>%
    filter(PERTENENCIA2 == 1) %>%  # Solo pertenencia a pueblos originarios
    select(AÑO, porcentaje) %>%
    mutate(fuente = "Pertenencia Enriquecida")
  
  # Combinar todos los datos
  datos_combinados <- bind_rows(data_rsh, data_conadi, data_egresos, data_pertenencia)
  
  # Definir colores para cada fuente
  colores_fuentes <- c(
    "RSH" = "#E41A1C",                   # Rojo
    "CONADI" = "#4DAF4A",                # Verde
    "Egresos Hospitalarios" = "#377EB8", # Azul
    "Pertenencia Enriquecida" = "#FF7F00" # Naranja
  )
  
  # Crear nota explicativa
  nota_explicativa <- paste0(
    "Nota: El gráfico muestra la evolución del porcentaje de pertenencia a pueblos originarios según diferentes fuentes.\n",
    "Se incluyen solo los valores reportados (1=pertenece) para cada fuente, excluyendo valores no reportados."
  )
  
  # Generar gráfico comparativo
  grafico <- ggplot(datos_combinados, aes(x = AÑO, y = porcentaje, group = fuente, color = fuente)) +
    geom_line(linewidth = 1.5) +
    scale_color_manual(values = colores_fuentes) +
    labs(
      title = "Comparación de fuentes de pertenencia a pueblos originarios",
      subtitle = "Evolución temporal del porcentaje de pertenencia según diferentes registros",
      x = "Año",
      y = "Porcentaje (%)",
      color = "Fuente de datos",
      caption = nota_explicativa
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      panel.grid.major.x = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
      axis.title = element_text(size = 10, face = "bold"),
      plot.title = element_text(size = 13, face = "bold"),
      plot.subtitle = element_text(size = 10),
      plot.caption = element_text(hjust = 0, size = 8),
      legend.text = element_text(size = 9)
    )
  
  return(list(grafico = grafico, datos = datos_combinados))
}
