# ==============================================================================
# FUNCION: analizar_cie10_top
# ==============================================================================
# 
# DESCRIPCION:
#   Análisis de top N grupos CIE-10 por pertenencia, genera tablas anuales y promedio
#
# PARAMETROS:
#   @param data        data.frame con datos ordenados
#   @param limite_top  Número de grupos top a mostrar (default: 20)
#
# RETORNA:
#   Lista con 2 elementos:
#     - tablas_anuales: lista de flextables por año y pertenencia
#     - tablas_promedio: lista de flextables de promedio por pertenencia
#
# EFECTOS SECUNDARIOS:
#   - Muestra mensaje en consola
#
# DEPENDENCIAS:
#   - dplyr (filter, group_by, summarise, mutate, arrange, slice_head, select)
#   - purrr (map, split)
#   - flextable (flextable, set_caption, set_header_labels, colformat_double, autofit)
#
# VARIABLES GLOBALES:
#   Ninguna
#
# ARCHIVO ORIGEN:
#   - E_descriptiva2.qmd (líneas 202-300)
#
# NOTAS:
#   - Excluye años "No reportado"
#   - Sin desagregación por sexo (a diferencia de versión anterior)
#   - Tablas por año x pertenencia (cada combinación es una tabla)
#   - Porcentajes sobre total del grupo poblacional
#
# EJEMPLO:
#   resultados <- analizar_cie10_top(datos_ordenados, limite_top = 20)
#   # Ver promedio para Población General
#   print(resultados$tablas_promedio[[1]])
#   # Ver año 2020, Pueblos Originarios
#   print(resultados$tablas_anuales[["2020.Pertenece a Pueblos Originarios"]])
#
# ==============================================================================

analizar_cie10_top <- function(data, limite_top = 20) {
  message("--- Iniciando análisis de Top CIE-10 por pertenencia ---")
  
  # Filtrar datos excluyendo valores no reportados
  data_filtered <- data %>%
    filter(AÑO != "No reportado")
  
  # Crear categorías para pertenencia
  data_categorias <- data_filtered %>%
    mutate(
      PERTENENCIA_CAT = if_else(PERTENENCIA2 == 1, 
                              "Pertenece a Pueblos Originarios", 
                              "Población General")
    )
  
  # Análisis por año
  top_anual <- data_categorias %>%
    group_by(AÑO, PERTENENCIA_CAT, Grupo_CIE10) %>%
    summarise(
      n_casos = n(),
      .groups = "drop"
    ) %>%
    group_by(AÑO, PERTENENCIA_CAT) %>%
    mutate(
      total_grupo = sum(n_casos),
      porcentaje = round(n_casos/total_grupo * 100, 2)
    ) %>%
    arrange(AÑO, PERTENENCIA_CAT, desc(n_casos)) %>%
    group_by(AÑO, PERTENENCIA_CAT) %>%
    slice_head(n = limite_top) %>%
    ungroup()
  
  # Promedio por años
  top_promedio <- data_categorias %>%
    group_by(PERTENENCIA_CAT, Grupo_CIE10) %>%
    summarise(
      n_casos = n(),
      .groups = "drop"
    ) %>%
    group_by(PERTENENCIA_CAT) %>%
    mutate(
      total_grupo = sum(n_casos),
      porcentaje = round(n_casos/total_grupo * 100, 2)
    ) %>%
    arrange(PERTENENCIA_CAT, desc(n_casos)) %>%
    group_by(PERTENENCIA_CAT) %>%
    slice_head(n = limite_top) %>%
    ungroup()
  
  # Formatar tablas anuales
  tablas_anuales <- top_anual %>%
    split(interaction(.$AÑO, .$PERTENENCIA_CAT)) %>%
    map(function(df) {
      año <- unique(df$AÑO)
      pertenencia <- unique(df$PERTENENCIA_CAT)
      
      flextable(
        df %>% 
          select(Grupo_CIE10, n_casos, porcentaje) %>%
          arrange(desc(n_casos))
      ) %>%
        set_caption(paste("Top", limite_top, "Grupos CIE-10 -", 
                         "Año:", año,  
                         "- Grupo:", pertenencia)) %>%
        set_header_labels(
          Grupo_CIE10 = "Grupo CIE-10",
          n_casos = "N° Casos",
          porcentaje = "Porcentaje (%)"
        ) %>%
        colformat_double(j = "porcentaje", digits = 2) %>%
        autofit()
    })
  
  # Formatar tablas de promedio
  tablas_promedio <- top_promedio %>%
    split(.$PERTENENCIA_CAT) %>%
    map(function(df) {
      pertenencia <- unique(df$PERTENENCIA_CAT)
      
      flextable(
        df %>% 
          select(Grupo_CIE10, n_casos, porcentaje) %>%
          arrange(desc(n_casos))
      ) %>%
        set_caption(paste("Top", limite_top, "Grupos CIE-10 - Promedio General -",
                         "Grupo:", pertenencia)) %>%
        set_header_labels(
          Grupo_CIE10 = "Grupo CIE-10",
          n_casos = "N° Casos",
          porcentaje = "Porcentaje (%)"
        ) %>%
        colformat_double(j = "porcentaje", digits = 2) %>%
        autofit()
    })
  
  return(list(
    tablas_anuales = tablas_anuales,
    tablas_promedio = tablas_promedio
  ))
}