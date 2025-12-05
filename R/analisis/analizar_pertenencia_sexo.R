# ==============================================================================
# FUNCION: analizar_pertenencia_sexo
# ==============================================================================
# 
# DESCRIPCION:
#   Analiza la pertenencia a pueblos originarios desagregada por sexo,
#   generando gráficos anuales y promedios para hombres y mujeres
#
# PARAMETROS:
#   @param data          Data frame con datos de egresos hospitalarios
#   @param var_nombre    Nombre de la variable a analizar
#   @param var_etiqueta  Etiqueta descriptiva para títulos
#
# RETORNA:
#   Lista con elementos:
#   - anual: Gráfico de barras facetado por sexo (distribución anual)
#   - promedio: Gráfico de barras facetado por sexo (promedios)
#   - datos_anual: Data frame con datos anuales procesados
#   - datos_promedio: Data frame con promedios por sexo
#   - nota: Texto explicativo sobre valores no reportados
#
# DEPENDENCIAS:
#   - dplyr (filter, group_by, summarise, mutate, ungroup, left_join)
#   - ggplot2 (ggplot, geom_bar, geom_text, scale_fill_manual, facet_wrap)
#   - stringr (str_to_title)
#
# VARIABLES GLOBALES:
#   - colores_analisis: Vector nombrado con colores para categorías
#
# ARCHIVO ORIGEN:
#   - grafico_pertenencia.qmd
#
# NOTAS:
#   - Excluye categoría "INTERSEX" del análisis
#   - Solo considera HOMBRE y MUJER
#
# EJEMPLO:
#   resultado <- analizar_pertenencia_sexo(datos_ordenados, "RSH", "RSH")
#   print(resultado$anual)
#   print(resultado$promedio)
#
# ==============================================================================

analizar_pertenencia_sexo <- function(data, var_nombre, var_etiqueta) {
  # Verificar que la variable existe
  if(!(var_nombre %in% names(data))) {
    message("La variable ", var_nombre, " no existe en los datos.")
    return(NULL)
  }
  
  # Filtrar datos válidos
  data_filtrada <- data %>%
    filter(AÑO != "No reportado" & GLOSA_SEXO %in% c("HOMBRE", "MUJER"))
  
  # Calcular distribución por sexo y año
  data_anual_sexo <- data_filtrada %>%
    group_by(AÑO, GLOSA_SEXO, .data[[var_nombre]]) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(AÑO, GLOSA_SEXO) %>%
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
      ),
      GLOSA_SEXO = str_to_title(GLOSA_SEXO)  # Convertir a Título
    ) %>%
    filter(etiqueta != "No reportado")  # Excluir valores no reportados
  
  # Calcular promedios anuales por sexo
  data_promedio_sexo <- data_anual_sexo %>%
    group_by(GLOSA_SEXO, etiqueta) %>%
    summarise(
      porcentaje_promedio = mean(porcentaje),
      .groups = "drop"
    )
  
  # Contar valores no reportados o nulos por sexo
  no_reportados_por_sexo <- data_filtrada %>%
    filter(is.na(.data[[var_nombre]]) | !(.data[[var_nombre]] %in% c(0,1))) %>%
    group_by(GLOSA_SEXO) %>%
    summarise(
      no_reportados = n(),
      .groups = "drop"
    ) %>%
    mutate(GLOSA_SEXO = str_to_title(GLOSA_SEXO))
  
  total_por_sexo <- data_filtrada %>%
    group_by(GLOSA_SEXO) %>%
    summarise(
      total = n(),
      .groups = "drop"
    ) %>%
    mutate(GLOSA_SEXO = str_to_title(GLOSA_SEXO))
  
  info_no_reportados <- left_join(no_reportados_por_sexo, total_por_sexo, by = "GLOSA_SEXO") %>%
    mutate(porcentaje = round((no_reportados / total) * 100, 1))
  
  # Crear nota explicativa
  hombre_info <- info_no_reportados %>% filter(GLOSA_SEXO == "Hombre")
  mujer_info <- info_no_reportados %>% filter(GLOSA_SEXO == "Mujer")
  
  nota_explicativa <- paste0(
    "Nota: Los gráficos muestran la distribución entre población general y perteneciente a pueblos originarios por sexo.\n",
    "Valores no reportados excluidos: Hombres (", 
    ifelse(nrow(hombre_info)>0, paste0(hombre_info$no_reportados, " registros, ", hombre_info$porcentaje, "%"), "0 registros, 0%"),
    "), Mujeres (", 
    ifelse(nrow(mujer_info)>0, paste0(mujer_info$no_reportados, " registros, ", mujer_info$porcentaje, "%"), "0 registros, 0%"),
    ")."
  )
  
  # Gráfico por año y sexo
  grafico_anual_sexo <- ggplot(data_anual_sexo, 
                              aes(x = AÑO, y = porcentaje, fill = etiqueta)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_text(aes(label = sprintf("%.1f%%", porcentaje)), 
              position = position_dodge(width = 0.9), 
              vjust = -0.5, size = 3) +
    scale_fill_manual(values = colores_analisis) +
    labs(
      title = paste("Distribución anual según", var_etiqueta, "por sexo"),
      subtitle = "Los porcentajes suman 100% para cada año y sexo entre las categorías mostradas",
      x = "Año",
      y = "Porcentaje (%)",
      fill = "Pertenencia",
      caption = nota_explicativa
    ) +
    facet_wrap(~ GLOSA_SEXO) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      panel.grid.major.x = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.caption = element_text(hjust = 0, size = 8)
    )
  
  # Gráfico de promedios por sexo
  grafico_promedio_sexo <- ggplot(data_promedio_sexo, 
                                 aes(x = etiqueta, y = porcentaje_promedio, fill = etiqueta)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = sprintf("%.1f%%", porcentaje_promedio)), 
              vjust = -0.5, size = 4) +
    scale_fill_manual(values = colores_analisis) +
    labs(
      title = paste("Promedio anual según", var_etiqueta, "por sexo"),
      subtitle = "Los porcentajes suman 100% para cada sexo entre las dos categorías mostradas",
      x = "",
      y = "Porcentaje Promedio (%)",
      caption = nota_explicativa
    ) +
    facet_wrap(~ GLOSA_SEXO) +
    theme_minimal() +
    theme(
      legend.position = "none",
      panel.grid.major.x = element_blank(),
      plot.caption = element_text(hjust = 0, size = 8)
    )
  
  return(list(
    anual = grafico_anual_sexo,
    promedio = grafico_promedio_sexo,
    datos_anual = data_anual_sexo,
    datos_promedio = data_promedio_sexo,
    nota = nota_explicativa
  ))
}
