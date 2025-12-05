# ==============================================================================
# FUNCION: calcular_concordancia_desctools
# ==============================================================================
# 
# DESCRIPCION:
#   Calcula el coeficiente de Cohen's Kappa con intervalos de confianza al 95%
#   usando el paquete DescTools. Evalúa la concordancia entre dos variables binarias.
#
# PARAMETROS:
#   @param datos          Data frame con las variables a comparar
#   @param col_verdad     Nombre de la columna con variable de referencia (gold standard)
#   @param col_estimado   Nombre de la columna con variable a evaluar
#   @param nombre_fuente  Etiqueta descriptiva de la fuente evaluada
#
# RETORNA:
#   Tibble con columnas:
#   - Fuente de Datos: Nombre de la fuente
#   - Concordancia con Variable Enriquecida: Tipo de medida (siempre "Cohen's Kappa")
#   - Valor Kappa: Coeficiente kappa calculado
#   - IC 95% Inf: Límite inferior del intervalo de confianza
#   - IC 95% Sup: Límite superior del intervalo de confianza
#   - Interpretación (Landis & Koch): Categoría según escala estándar
#
# DEPENDENCIAS:
#   - DescTools::CohenKappa
#   - dplyr::tibble
#   - dplyr::case_when
#
# ARCHIVO ORIGEN:
#   - Concord_nuevas.qmd
#
# NOTAS:
#   Interpretación según Landis & Koch (1977):
#   - < 0.00: Pobre
#   - 0.00-0.20: Leve
#   - 0.20-0.40: Aceptable
#   - 0.40-0.60: Moderada
#   - 0.60-0.80: Sustancial
#   - > 0.80: Casi Perfecta
#
# EJEMPLO:
#   resultado <- calcular_concordancia_desctools(
#     datos = datos_kappa,
#     col_verdad = "PERTENENCIA2",
#     col_estimado = "RSH",
#     nombre_fuente = "RSH"
#   )
#   print(resultado)
#
# ==============================================================================

calcular_concordancia_desctools <- function(datos, col_verdad, col_estimado, nombre_fuente) {
  # DescTools::CohenKappa requiere una tabla de contingencia o dos vectores
  resultado_kappa <- CohenKappa(
    x = datos[[col_verdad]], 
    y = datos[[col_estimado]],
    conf.level = 0.95
  )
  
  valor_kappa <- resultado_kappa["kappa"]
  ic_inferior <- resultado_kappa["lwr.ci"]
  ic_superior <- resultado_kappa["upr.ci"]
  
  tibble(
    `Fuente de Datos` = nombre_fuente,
    `Concordancia con Variable Enriquecida` = "Cohen's Kappa",
    `Valor Kappa` = round(valor_kappa, 4),
    `IC 95% Inf` = round(ic_inferior, 4),
    `IC 95% Sup` = round(ic_superior, 4),
    `Interpretación (Landis & Koch)` = case_when(
      valor_kappa < 0.00 ~ "Pobre",
      valor_kappa < 0.20 ~ "Leve",
      valor_kappa < 0.40 ~ "Aceptable",
      valor_kappa < 0.60 ~ "Moderada",
      valor_kappa < 0.80 ~ "Sustancial",
      TRUE ~ "Casi Perfecta"
    )
  )
}
