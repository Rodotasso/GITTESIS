# ==============================================================================
# FUNCIONES DE ANALISIS DE PERTENENCIA
# ==============================================================================
#
# Este archivo contiene las funciones principales para analizar la pertenencia
# a pueblos originarios según diferentes fuentes de datos
#
# CONTENIDO:
#   - analizar_pertenencia: Análisis general con gráficos anuales y promedios
#   - analizar_pertenencia_sexo: Análisis desagregado por sexo
#
# DEPENDENCIAS:
#   - dplyr (filter, group_by, summarise, mutate, ungroup)
#   - ggplot2 (ggplot, geom_bar, geom_text, scale_fill_manual, labs, theme_minimal)
#   - ggpubr (ggarrange, annotate_figure, text_grob)
#
# ARCHIVOS ORIGEN:
#   - grafico_pertenencia.qmd
#
# ==============================================================================

# Variable global de colores para análisis (debe existir en el entorno)
# colores_analisis <- c(
#   "Pertenece a Pueblos Originarios" = "#E69F00",
#   "Población General" = "#0072B2"
# )

#' Analiza la pertenencia a pueblos originarios para una variable específica
#'
#' @param data Data frame con datos de egresos hospitalarios
#' @param var_nombre Nombre de la variable a analizar (RSH, CONADI, PUEBLO_ORIGINARIO_BIN, PERTENENCIA2)
#' @param var_etiqueta Etiqueta descriptiva de la variable para los gráficos
#'
#' @return Lista con elementos:
#'   - anual: Gráfico de barras de distribución anual
#'   - promedio: Gráfico de barras de promedios
#'   - datos_anual: Data frame con datos anuales procesados
#'   - datos_promedio: Data frame con promedios calculados
#'   - nota: Texto con nota explicativa sobre valores no reportados
#'
#' @examples
#' resultado <- analizar_pertenencia(datos_ordenados, "RSH", "Registro Social de Hogares")
#' print(resultado$anual)
#' print(resultado$promedio)
#'
analizar_pertenencia <- function(data, var_nombre, var_etiqueta) {
  # Verificar que la variable existe
  if(!(var_nombre %in% names(data))) {
    message("La variable ", var_nombre, " no existe en los datos.")
    return(NULL)
  }
  
  # Calcular distribución anual
  data_anual <- data %>%
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
  
  # Calcular promedios anuales
  data_promedio <- data_anual %>%
    group_by(etiqueta) %>%
    summarise(
      porcentaje_promedio = mean(porcentaje),
      .groups = "drop"
    )
  
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
    "Nota: Los gráficos muestran la distribución entre población general y perteneciente a pueblos originarios.\n",
    "Los valores no reportados (", no_reportados, " registros, ", 
    porcentaje_no_reportados, "% del total) fueron excluidos del análisis."
  )
  
  # Gráfico por año
  grafico_anual <- ggplot(data_anual, aes(x = AÑO, y = porcentaje, fill = etiqueta)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_text(aes(label = sprintf("%.1f%%", porcentaje)), 
              position = position_dodge(width = 0.9), 
              vjust = -0.5, size = 3.5) +
    scale_fill_manual(values = colores_analisis) +
    labs(
      title = paste("Distribución anual según", var_etiqueta),
      subtitle = "Los porcentajes suman 100% para cada año entre las categorías mostradas",
      x = "Año",
      y = "Porcentaje (%)",
      fill = "Pertenencia",
      caption = nota_explicativa
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      panel.grid.major.x = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.caption = element_text(hjust = 0, size = 8)
    )
  
  # Gráfico de promedios
  grafico_promedio <- ggplot(data_promedio, aes(x = etiqueta, y = porcentaje_promedio, fill = etiqueta)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = sprintf("%.1f%%", porcentaje_promedio)), 
              vjust = -0.5, size = 4) +
    scale_fill_manual(values = colores_analisis) +
    labs(
      title = paste("Promedio anual según", var_etiqueta),
      subtitle = "Los porcentajes suman 100% entre las dos categorías mostradas",
      x = "",
      y = "Porcentaje Promedio (%)",
      caption = nota_explicativa
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      panel.grid.major.x = element_blank(),
      plot.caption = element_text(hjust = 0, size = 8)
    )
  
  return(list(
    anual = grafico_anual,
    promedio = grafico_promedio,
    datos_anual = data_anual,
    datos_promedio = data_promedio,
    nota = nota_explicativa
  ))
}
