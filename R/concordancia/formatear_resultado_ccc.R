# ==============================================================================
# FUNCION: formatear_resultado_ccc
# ==============================================================================
# 
# DESCRIPCION:
#   Formatea los resultados del coeficiente de correlación y concordancia de Lin (CCC)
#   en un tibble con interpretación según escala estándar
#
# PARAMETROS:
#   @param resultado_ccc          Objeto resultado de DescTools::CCC()
#   @param nombre_desagregacion   Etiqueta de la desagregación analizada
#
# RETORNA:
#   Tibble con columnas:
#   - Desagregacion: Nombre de la desagregación (ej: "Por Region", "Por Sexo")
#   - N: Número de observaciones
#   - Lin's CCC: Valor del coeficiente de concordancia de Lin
#   - IC 95% Inferior: Límite inferior del intervalo de confianza
#   - IC 95% Superior: Límite superior del intervalo de confianza
#   - Interpretacion: Categoría según escala de concordancia
#
# DEPENDENCIAS:
#   - dplyr::tibble
#   - dplyr::case_when
#
# ARCHIVO ORIGEN:
#   - Concord_nuevas.qmd
#
# NOTAS:
#   Interpretación del CCC:
#   - > 0.80: Casi perfecta
#   - 0.61-0.80: Sustancial
#   - 0.41-0.60: Moderada
#   - 0.21-0.40: Aceptable
#   - ≤ 0.20: Leve
#
# EJEMPLO:
#   # Después de calcular CCC
#   ccc_resultado <- CCC(datos_censo, datos_pert2, ci = "z-transform")
#   tabla <- formatear_resultado_ccc(ccc_resultado, "Por Region")
#   print(tabla)
#
# ==============================================================================

formatear_resultado_ccc <- function(resultado_ccc, nombre_desagregacion) {
  tibble(
    Desagregacion = nombre_desagregacion,
    N = resultado_ccc$n,
    `Lin's CCC` = round(resultado_ccc$rho.c$est, 4),
    `IC 95% Inferior` = round(resultado_ccc$rho.c$lwr.ci, 4),
    `IC 95% Superior` = round(resultado_ccc$rho.c$upr.ci, 4),
    Interpretacion = case_when(
      resultado_ccc$rho.c$est > 0.80 ~ "Casi perfecta",
      resultado_ccc$rho.c$est > 0.61 ~ "Sustancial",
      resultado_ccc$rho.c$est > 0.41 ~ "Moderada",
      resultado_ccc$rho.c$est > 0.21 ~ "Aceptable",
      TRUE ~ "Leve"
    )
  )
}
