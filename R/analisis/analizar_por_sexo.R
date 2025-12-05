# ==============================================================================
# FUNCION: analizar_por_sexo
# ==============================================================================
# 
# DESCRIPCION:
#   Análisis de variable desagregado por sexo con tablas anuales y promedio
#
# PARAMETROS:
#   @param data          data.frame con datos ordenados
#   @param variable_col  Nombre de columna a analizar
#   @param titulo        Título descriptivo
#   @param limite_top    Número de valores top (default: 20)
#
# RETORNA:
#   Lista con 2 elementos (hombre y mujer), cada uno con:
#     - tabla_anual: flextable con distribución anual
#     - promedio_anual: flextable con promedio anual
#
# EFECTOS SECUNDARIOS:
#   - Muestra mensaje en consola
#
# DEPENDENCIAS:
#   - dplyr, tidyr, flextable, stringr
#
# VARIABLES GLOBALES:
#   Ninguna
#
# ARCHIVO ORIGEN:
#   - E_descriptiva2.qmd (líneas 331-450)
#
# NOTAS:
#   - Excluye Intersex y años No reportado
#   - Abreviaciones: PO (Pueblos Originarios), PG (Población General)
#   - Retorna lista con keys: "hombre" y "mujer"
#
# EJEMPLO:
#   resultados_cie10_sexo <- analizar_por_sexo(
#     datos_ordenados, 
#     "Grupo_CIE10", 
#     "Grupos CIE-10"
#   )
#   resultados_cie10_sexo$hombre$tabla_anual
#   resultados_cie10_sexo$mujer$promedio_anual
#
# ==============================================================================

analizar_por_sexo <- function(data, variable_col, titulo, limite_top = 20) {
  message(paste("--- Iniciando análisis de:", titulo, "por sexo ---"))
  
  # Filtrar datos excluyendo Intersex
  data_filtered <- data %>%
    filter(GLOSA_SEXO != "Intersex" & AÑO != "No reportado")
  
  # Para cada sexo
  resultados_sexo <- list()
  for(sexo in c("HOMBRE", "MUJER")) {
    
    # Filtrar por sexo
    data_sexo <- data_filtered %>%
      filter(GLOSA_SEXO == sexo)
    
    # Identificar top valores para este sexo
    top_valores <- data_sexo %>%
      group_by(!!sym(variable_col)) %>%
      summarise(n = n()) %>%
      arrange(desc(n)) %>%
      head(limite_top) %>%
      pull(!!sym(variable_col))
    
    # Análisis por año y pertenencia
    dist_anual <- data_sexo %>%
      filter(!!sym(variable_col) %in% top_valores) %>%
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
                                 "PO", # Abreviación
                                 "PG") # Abreviación
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
      arrange(AÑO)
    
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
        values_from = promedio,
        values_fill = 0
      )
    
    # Verificar nombres reales de columnas
    col_names_tabla <- names(tabla_anual)
    col_names_promedio <- names(promedio_anual)
    
    # Etiqueta para mostrar en las tablas (primera letra mayúscula)
    etiqueta_sexo <- str_to_title(sexo)
    
    # Crear flextables de manera segura
    ft_tabla_anual <- flextable(tabla_anual) %>%
      set_caption(paste("Distribución anual de", titulo, "-", etiqueta_sexo)) %>%
      set_header_labels(
        AÑO = "Año",
        PG = "Población General (%)",
        PO = "Pueblos Originarios (%)"
      )
    
    # Formato condicional para números según columnas existentes
    if ("PG" %in% col_names_tabla) ft_tabla_anual <- colformat_double(ft_tabla_anual, j = "PG", digits = 2)
    if ("PO" %in% col_names_tabla) ft_tabla_anual <- colformat_double(ft_tabla_anual, j = "PO", digits = 2)
    ft_tabla_anual <- autofit(ft_tabla_anual)
    
    ft_promedio_anual <- flextable(promedio_anual) %>%
      set_caption(paste("Promedio anual de", titulo, "-", etiqueta_sexo)) %>%
      set_header_labels(
        PG = "Población General (%)",
        PO = "Pueblos Originarios (%)"
      )
    
    # Formato condicional para números según columnas existentes
    if ("PG" %in% col_names_promedio) ft_promedio_anual <- colformat_double(ft_promedio_anual, j = "PG", digits = 2)
    if ("PO" %in% col_names_promedio) ft_promedio_anual <- colformat_double(ft_promedio_anual, j = "PO", digits = 2)
    ft_promedio_anual <- autofit(ft_promedio_anual)
    
    # Guardar resultados para este sexo (usando el sexo en minúsculas como clave)
    resultados_sexo[[tolower(sexo)]] <- list(
      tabla_anual = ft_tabla_anual,
      promedio_anual = ft_promedio_anual
    )
  }
  
  return(resultados_sexo)
}
