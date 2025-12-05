# ==============================================================================
# FUNCION: analizar_variable
# ==============================================================================
# 
# DESCRIPCION:
#   Análisis completo de variable con tablas anuales, promedios y gráfico de evolución
#
# PARAMETROS:
#   @param data          data.frame con datos ordenados
#   @param variable_col  Nombre de columna a analizar
#   @param titulo        Título descriptivo para la variable
#   @param limite_top    Número de valores top a incluir (default: 10)
#
# RETORNA:
#   Lista con 3 elementos:
#     - tabla_anual: flextable con distribución anual
#     - promedio_anual: flextable con promedio anual
#     - grafico: ggplot con evolución temporal de top 5
#
# EFECTOS SECUNDARIOS:
#   - Muestra mensaje en consola con título del análisis
#
# DEPENDENCIAS:
#   - dplyr (filter, group_by, summarise, mutate, arrange, select, head, pull)
#   - tidyr (pivot_wider)
#   - ggplot2 (todas las funciones de graficación)
#   - flextable (flextable, set_caption, set_header_labels, colformat_double, autofit)
#   - purrr (map)
#
# VARIABLES GLOBALES:
#   - colores_analisis: vector con colores para pertenencia (debe estar definido)
#
# ARCHIVO ORIGEN:
#   - E_descriptiva2.qmd (líneas 52-145)
#
# NOTAS:
#   - Excluye sexo "Intersex" y años "No reportado"
#   - Compara Población General vs Pertenece a Pueblos Originarios
#   - Tabla anual: columnas por año y pertenencia
#   - Gráfico: solo top 5 valores, facetado, scales free_y
#   - Requiere variable colores_analisis definida globalmente
#
# EJEMPLO:
#   colores_analisis <- c(
#     "Población General" = "#377EB8",
#     "Pertenece a Pueblos Originarios" = "#E41A1C"
#   )
#   analisis_estab <- analizar_variable(
#     datos_ordenados, 
#     "DEPENDENCIA", 
#     "Establecimientos"
#   )
#   analisis_estab$tabla_anual
#   analisis_estab$promedio_anual
#   print(analisis_estab$grafico)
#
# ==============================================================================

analizar_variable <- function(data, variable_col, titulo, limite_top = 10) {
  message(paste("--- Iniciando análisis de:", titulo, "---"))
  
  # Filtrar datos excluyendo Intersex
  data_filtered <- data %>%
    filter(GLOSA_SEXO != "Intersex")
  
  # Identificar top valores
  top_valores <- data_filtered %>%
    group_by(!!sym(variable_col)) %>%
    summarise(n = n()) %>%
    arrange(desc(n)) %>%
    head(limite_top) %>%
    pull(!!sym(variable_col))
  
  # Análisis por año y pertenencia
  dist_anual <- data_filtered %>%
    filter(!!sym(variable_col) %in% top_valores & AÑO != "No reportado") %>%
    group_by(AÑO, !!sym(variable_col), PERTENENCIA2) %>%
    summarise(
      n_casos = n(),
      .groups = "drop"
    ) %>%
    group_by(AÑO, !!sym(variable_col)) %>%
    mutate(
      total_año = sum(n_casos),
      porcentaje = round(n_casos/total_año * 100, 2),
      PERTENENCIA_CAT = if_else(PERTENENCIA2 == 1, 
                               "Pertenece a Pueblos Originarios", 
                               "Población General")
    ) %>%
    ungroup()
  
  # Tabla anual
  tabla_anual <- dist_anual %>%
    select(AÑO, !!sym(variable_col), PERTENENCIA_CAT, porcentaje) %>%
    pivot_wider(
      id_cols = c(!!sym(variable_col), AÑO),
      names_from = PERTENENCIA_CAT,
      values_from = porcentaje,
      values_fill = 0
    ) %>%
    arrange(AÑO, desc(`Población General`))
  
  # Promedio anual
  promedio_anual <- dist_anual %>%
    group_by(!!sym(variable_col), PERTENENCIA_CAT) %>%
    summarise(
      promedio = mean(porcentaje, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    pivot_wider(
      id_cols = !!sym(variable_col),
      names_from = PERTENENCIA_CAT,
      values_from = promedio
    ) %>%
    arrange(desc(`Población General`))
  
  # Gráfico de evolución temporal
  grafico <- dist_anual %>%
    filter(!!sym(variable_col) %in% head(top_valores, 5)) %>%
    ggplot(aes(x = as.factor(AÑO), 
               y = porcentaje, 
               color = PERTENENCIA_CAT,
               group = PERTENENCIA_CAT)) +
    geom_line(linewidth = 1) +
    facet_wrap(vars(!!sym(variable_col)), scales = "free_y", ncol = 2) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      strip.text = element_text(size = 8)
    ) +
    labs(
      title = paste("Evolución temporal de", titulo),
      x = "Año",
      y = "Porcentaje (%)",
      color = "Grupo Poblacional"
    ) +
    scale_color_manual(values = colores_analisis)
  
  # Crear y retornar resultados
  resultados <- list(
    tabla_anual = flextable(tabla_anual) %>%
      set_caption(paste("Distribución anual de", titulo)) %>%
      set_header_labels(
        AÑO = "Año",
        `Población General` = "Población General (%)",
        `Pertenece a Pueblos Originarios` = "Pueblos Originarios (%)"
      ) %>%
      colformat_double(
        j = c("Población General", "Pertenece a Pueblos Originarios"), 
        digits = 2
      ) %>%
      autofit(),
    
    promedio_anual = flextable(promedio_anual) %>%
      set_caption(paste("Promedio anual de", titulo)) %>%
      set_header_labels(
        `Población General` = "Población General (%)",
        `Pertenece a Pueblos Originarios` = "Pueblos Originarios (%)"
      ) %>%
      colformat_double(
        j = c("Población General", "Pertenece a Pueblos Originarios"), 
        digits = 2
      ) %>%
      autofit(),
    
    grafico = grafico
  )
  
  return(resultados)
}
