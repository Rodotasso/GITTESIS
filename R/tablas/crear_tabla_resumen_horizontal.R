# ==============================================================================
# FUNCION: crear_tabla_resumen_horizontal
# ==============================================================================
# 
# DESCRIPCION:
#   Crea tabla resumen horizontal con frecuencias y porcentajes de pertenencia
#   desagregados por año y sexo
#
# PARAMETROS:
#   @param data              data.frame con datos preparados
#   @param var_label         Nombre de columna con etiquetas de pertenencia
#   @param etiqueta_variable Etiqueta descriptiva para la variable
#
# RETORNA:
#   data.frame pivoteado con columnas: Año, Hombres Pertenecen, 
#   Hombres No Pertenecen, Hombres Sin Datos, Mujeres Pertenecen, etc.
#
# EFECTOS SECUNDARIOS:
#   Ninguno
#
# DEPENDENCIAS:
#   - dplyr (filter, group_by, summarise, mutate, select, rename)
#   - tidyr (pivot_wider)
#   - scales (percent)
#
# VARIABLES GLOBALES:
#   Ninguna
#
# ARCHIVO ORIGEN:
#   - E_descriptiva.qmd (líneas 197-260)
#
# NOTAS:
#   - Excluye sexo INTERSEX y No reportado
#   - Formato de celda: "Frecuencia (Porcentaje%)" con separador de miles
#   - Porcentajes calculados sobre total del año
#   - Accuracy 0.01 para 2 decimales en porcentajes
#
# EJEMPLO:
#   tabla_rsh <- crear_tabla_resumen_horizontal(
#     datos_preparados, 
#     "RSH_label", 
#     "RSH"
#   )
#   print(tabla_rsh)
#
# ==============================================================================

crear_tabla_resumen_horizontal <- function(data, var_label, etiqueta_variable) {
  
  # Paso 1: Filtrar datos para excluir INTERSEX y No reportado en GLOSA_SEXO
  # y calcular frecuencias y porcentajes sobre el total del año
  datos_calculados <- data %>%
    filter(!GLOSA_SEXO %in% c("INTERSEX", "No reportado")) %>%
    group_by(AÑO, GLOSA_SEXO, !!sym(var_label)) %>%
    summarise(Frecuencia = n(), .groups = "drop") %>%
    group_by(AÑO) %>%
    mutate(
      # Crear la celda con el formato "Frecuencia (Porcentaje%)"
      ValorCelda = paste0(
        # CORREGIDO: Especificamos ambos separadores para evitar warnings
        format(Frecuencia, big.mark = ".", decimal.mark = ","), 
        " (", 
        scales::percent(Frecuencia / sum(Frecuencia), accuracy = 0.01), 
        ")"
      )
    ) %>%
    ungroup()

  # Paso 2: Pivotar usando la nueva columna 'ValorCelda'
  tabla_pivoteada <- datos_calculados %>%
    select(AÑO, GLOSA_SEXO, !!sym(var_label), ValorCelda) %>%
    pivot_wider(
      names_from = c(GLOSA_SEXO, !!sym(var_label)),
      values_from = ValorCelda,
      values_fill = "0 (0.0%)"
    ) %>%
    rename(Año = AÑO) # Renombramos AÑO
  
  # Paso 3: Eliminar columnas que contengan "INTERSEX" o "No reportado" en el nombre
  # (por si acaso quedaron del pivoteo)
  tabla_pivoteada <- tabla_pivoteada %>%
    select(-contains("INTERSEX")) %>%
    select(-matches("^(INTERSEX|No reportado)_"))
  
  # Paso 4: Renombrar las columnas
  # Crear un vector de nombres nuevos
  nombres_actuales <- names(tabla_pivoteada)
  nombres_nuevos <- nombres_actuales
  
  # Reemplazar los nombres según patrones específicos
  nombres_nuevos <- gsub("HOMBRE_Pertenece", "Hombres Pertenecen", nombres_nuevos)
  nombres_nuevos <- gsub("HOMBRE_No pertenece", "Hombres No Pertenecen", nombres_nuevos)
  nombres_nuevos <- gsub("HOMBRE_No reportado", "Hombres Sin Datos", nombres_nuevos)
  nombres_nuevos <- gsub("MUJER_Pertenece", "Mujeres Pertenecen", nombres_nuevos)
  nombres_nuevos <- gsub("MUJER_No pertenece", "Mujeres No Pertenecen", nombres_nuevos)
  nombres_nuevos <- gsub("MUJER_No reportado", "Mujeres Sin Datos", nombres_nuevos)
  
  # Aplicar los nombres nuevos
  names(tabla_pivoteada) <- nombres_nuevos
  
  return(tabla_pivoteada)
}
