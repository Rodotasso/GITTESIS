# ==============================================================================
# FUNCION: crear_grafico_tendencia
# ==============================================================================
# 
# DESCRIPCION:
#   Crea gráfico de líneas con tendencia de pertenencia por año, grupo etario y sexo
#
# PARAMETROS:
#   @param data              data.frame con datos preparados
#   @param var_label         Nombre de columna con variable de pertenencia
#   @param titulo_variable   Título descriptivo para el gráfico
#
# RETORNA:
#   Objeto ggplot con gráfico de líneas facetado
#
# EFECTOS SECUNDARIOS:
#   Ninguno
#
# DEPENDENCIAS:
#   - dplyr (filter, count, group_by, mutate, ungroup)
#   - ggplot2 (todas las funciones de graficación)
#   - scales (percent_format)
#
# VARIABLES GLOBALES:
#   Ninguna
#
# ARCHIVO ORIGEN:
#   - codigo de graficos.qmd (líneas 48-150)
#
# NOTAS:
#   - Excluye GLOSA_SEXO "No reportado" y años "No reportado"
#   - Determina automáticamente valor de pertenencia (numérico 1 o texto "Pertenece")
#   - Facetado por GRUPO_ETARIO (ncol=3)
#   - Colores: HOMBRE=#F8766D (rojo), MUJER=#00BFC4 (cyan)
#   - Sin puntos en las líneas (solo líneas)
#   - Eje X con años como enteros, eje Y con porcentajes
#   - Tamaño de fuente: base 11pt
#
# EJEMPLO:
#   grafico_rsh <- crear_grafico_tendencia(
#     datos_preparados, 
#     "RSH_label", 
#     "RSH"
#   )
#   print(grafico_rsh)
#
# ==============================================================================

crear_grafico_tendencia <- function(data, var_label, titulo_variable) {
    
  # Determinar el valor de "pertenencia" (numérico o texto)
  valor_pertenencia <- if (is.numeric(data[[var_label]])) {
    1
  } else {
    "Pertenece"
  }
  
  # Preparar los datos para el gráfico de prevalencia
  datos_tendencia <- data %>%
    filter(GLOSA_SEXO %in% c("HOMBRE", "MUJER"),
           AÑO != "No reportado") %>%  # Excluir "No reportado"
    count(AÑO, GRUPO_ETARIO, GLOSA_SEXO, !!sym(var_label), name = "n") %>%
    group_by(AÑO, GRUPO_ETARIO, GLOSA_SEXO) %>%
    mutate(Porcentaje = n / sum(n)) %>%
    ungroup() %>%
    filter(!!sym(var_label) == valor_pertenencia) %>%
    # Asegurarnos de que AÑO sea numérico para el eje X
    mutate(AÑO = as.numeric(as.character(AÑO)))

  # Crear el gráfico de líneas con el AÑO en el eje X
  ggplot(datos_tendencia, aes(x = AÑO, y = Porcentaje, group = GLOSA_SEXO, color = GLOSA_SEXO)) +
    geom_line(linewidth = 1.2, alpha = 0.8) +
    # geom_point(size = 3) +    # PUNTOS ELIMINADOS
    
    # --- CAMBIO CLAVE: Facetar por GRUPO_ETARIO ---
    facet_wrap(~ GRUPO_ETARIO, ncol = 3) +
    
    scale_y_continuous(labels = scales::percent_format(accuracy = 0.01)) +
    # Aseguramos que el eje X muestre los años como números enteros
    scale_x_continuous(breaks = unique(datos_tendencia$AÑO)) +
    scale_color_manual(values = c("HOMBRE" = "#F8766D", "MUJER" = "#00BFC4")) +
    
    # Títulos y etiquetas con terminología epidemiológica
    labs(
      title = paste("Porcentaje de Personas registradas como Pertenecientes a", titulo_variable),
      subtitle = "Tendencia del % anual del total de registros por grupo de edad y sexo",
      x = "Año",
      y = "Porcentaje de Pertenencia en el tiempo",
      color = "Sexo"
    ) +
    theme_minimal(base_size = 11) +   # Tamaño de FUENTE
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
      axis.text.y = element_text(size = 8),
      axis.title = element_text(size = 10, face = "bold"),

    #Leyenda
      legend.position = "bottom",
      legend.title = element_text(size = 9, face = "bold"),
        legend.text = element_text(size = 8),

    
    #este es el de las facetas
      strip.text = element_text(face = "bold", size = 10),

    #Tamaño titulo y subtitulo
        plot.title = element_text(size = 12, face = "bold"),
        plot.subtitle = element_text(size = 10),

    #lineas de cuadricula
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank()
    )
}
