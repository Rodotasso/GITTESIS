#' Gráfico de Evolución Temporal con Disparidades en Grupos CIE-10
#'
#' Genera un gráfico de líneas mostrando la evolución temporal de la representación
#' de pueblos originarios en diferentes grupos diagnósticos CIE-10, comparado con
#' la tendencia general de la variable enriquecida.
#'
#' @param datos_evolucion Data frame con datos de evolución temporal por grupo
#' @param tendencia_pertenencia2 Data frame con tendencia anual de variable enriquecida
#' @param pct_variable_enriquecida Numeric. Porcentaje de referencia (Variable Enriquecida)
#' @param clasificacion_grupos Data frame con clasificación de grupos
#' @param colores_disparidad Named vector con colores por grupo
#' @param tamanios_linea Named vector con tamaños de línea por grupo
#' @param umbral Numeric. Umbral usado para filtrar grupos (para el título)
#' @param titulo Character. Título del gráfico (default: automático)
#' @param subtitulo Character. Subtítulo del gráfico (default: automático)
#' @param ancho Numeric. Ancho del gráfico en pulgadas (default: 15)
#' @param alto Numeric. Alto del gráfico en pulgadas (default: 11)
#'
#' @return ggplot object
#'
#' @examples
#' graf <- grafico_evolucion_disparidades(
#'   datos_evolucion_disparidades,
#'   tendencia_pertenencia2,
#'   pct_variable_enriquecida,
#'   clasificacion_grupos,
#'   colores_disparidad,
#'   tamanios_linea,
#'   umbral = 1.5
#' )
#' print(graf)
#'
#' @export
grafico_evolucion_disparidades <- function(datos_evolucion,
                                           tendencia_pertenencia2,
                                           pct_variable_enriquecida,
                                           clasificacion_grupos,
                                           colores_disparidad,
                                           tamanios_linea,
                                           umbral = 1.5,
                                           titulo = NULL,
                                           subtitulo = NULL,
                                           ancho = 15,
                                           alto = 11) {

  # Cargar librería necesaria
  require(ggplot2)
  require(dplyr)
  require(stringr)

  # Validaciones
  if (nrow(datos_evolucion) == 0) {
    stop("datos_evolucion está vacío. No hay datos para graficar.")
  }

  # Calcular límite superior del eje Y
  max_porcentaje <- max(datos_evolucion$porcentaje, na.rm = TRUE)
  limite_y <- max(40, ceiling(max_porcentaje / 5) * 5 + 5)

  # Títulos por defecto (sin subtítulo, se mueve a notas)
  if (is.null(titulo)) {
    titulo <- "Evolución temporal de la representación de personas pertenecientes a pueblos originarios por grupo diagnóstico CIE-10"
  }

  # Subtítulo vacío por defecto (información se mueve a notas al pie)
  if (is.null(subtitulo)) {
    subtitulo <- NULL
  }
  
  # Número de años y grupos
  n_anios <- length(unique(datos_evolucion$AÑO))
  n_grupos <- length(unique(datos_evolucion$Grupo_CIE10))
  
  # Crear gráfico
  grafico <- ggplot(datos_evolucion, 
                   aes(x = AÑO, y = porcentaje, 
                       color = Grupo_CIE10, 
                       group = Grupo_CIE10,
                       size = Grupo_CIE10)) +
    
    # FONDO: Franja de referencia Variable Enriquecida estática
    annotate(
      "rect",
      xmin = -Inf, xmax = Inf,
      ymin = pct_variable_enriquecida - 0.5,
      ymax = pct_variable_enriquecida + 0.5,
      fill = "#95A5A6",
      alpha = 0.15
    ) +
    
    # Línea de referencia estática (Variable Enriquecida promedio general)
    geom_hline(
      yintercept = pct_variable_enriquecida, 
      linetype = "dotted", 
      color = "#95A5A6", 
      linewidth = 0.8,
      alpha = 0.7
    ) +
    
    # LÍNEA PRINCIPAL: Tendencia temporal de PERTENENCIA2 (año a año)
    geom_line(
      data = tendencia_pertenencia2,
      aes(x = AÑO, y = pct_po, group = 1),
      color = "#2C3E50",
      linewidth = 1.8,
      linetype = "solid",
      alpha = 0.9,
      inherit.aes = FALSE
    ) +
    geom_point(
      data = tendencia_pertenencia2,
      aes(x = AÑO, y = pct_po),
      color = "#2C3E50",
      size = 3,
      alpha = 0.9,
      inherit.aes = FALSE
    ) +
    
    # Zonas de sobre/subrepresentación
    annotate(
      "rect",
      xmin = -Inf, xmax = Inf,
      ymin = mean(tendencia_pertenencia2$pct_po), ymax = Inf,
      fill = "#E74C3C", alpha = 0.06
    ) +
    annotate(
      "rect",
      xmin = -Inf, xmax = Inf,
      ymin = -Inf, ymax = mean(tendencia_pertenencia2$pct_po),
      fill = "#3498DB", alpha = 0.04
    ) +

    # Etiquetas de zonas (sin mayúsculas excesivas)
    annotate(
      "text",
      x = 2,
      y = limite_y * 0.95,
      label = "Sobrerrepresentacion",
      hjust = 0,
      size = 3.5,
      color = "#C62828",
      alpha = 0.7,
      fontface = "italic",
      lineheight = 0.9
    ) +
    annotate(
      "text",
      x = n_anios - 1,
      y = 2,
      label = "Subrepresentacion",
      hjust = 1,
      size = 3.5,
      color = "#1565C0",
      alpha = 0.7,
      fontface = "italic",
      lineheight = 0.9
    ) +

    # Anotación de línea de tendencia (referencia general)
    annotate(
      "text",
      x = n_anios / 2,
      y = max(tendencia_pertenencia2$pct_po) + 1.5,
      label = "Tendencia general\n(variable enriquecida)",
      hjust = 0.5,
      size = 3.2,
      fontface = "bold",
      color = "#2C3E50",
      lineheight = 0.9
    ) +
    
    # Líneas de evolución temporal (DATOS PRINCIPALES)
    geom_line(alpha = 0.9) +
    geom_point(size = 3, alpha = 0.9) +

    # Etiquetas finales: nombres de grupos diagnósticos (no porcentajes)
    geom_text(
      data = datos_evolucion %>% filter(AÑO == max(AÑO)),
      aes(label = str_wrap(Grupo_CIE10, width = 25), x = AÑO, y = porcentaje),
      hjust = -0.05,
      size = 2.8,
      fontface = "plain",
      show.legend = FALSE,
      lineheight = 0.85
    ) +
    
    # Escalas
    scale_color_manual(
      values = colores_disparidad,
      name = NULL,
      labels = function(x) str_wrap(x, width = 35)
    ) +
    scale_size_manual(
      values = tamanios_linea,
      guide = "none"
    ) +
    scale_y_continuous(
      labels = function(x) paste0(x, "%"),
      breaks = seq(0, limite_y, by = 5),
      limits = c(0, limite_y),
      expand = c(0.02, 0)
    ) +
    scale_x_discrete(expand = expansion(add = c(0.5, 3.5))) +
    
    # Etiquetas
    labs(
      title = titulo,
      subtitle = subtitulo,
      x = "Año",
      y = "Porcentaje de atenciones de personas\npertenecientes a pueblos originarios",
      caption = paste0(
        "Notas: Línea negra gruesa: tendencia general de la variable enriquecida (todos los egresos). ",
        "Línea gris punteada: promedio general del período (", sprintf("%.1f%%", pct_variable_enriquecida), "). ",
        "Banda gris: intervalo de ±0.5 puntos porcentuales respecto al promedio.\n",
        "Líneas de colores: porcentaje de atenciones de personas pertenecientes a pueblos originarios dentro de cada grupo diagnóstico. ",
        "Colores rojos/naranjas: sobrerrepresentación (sobre la tendencia). Colores azules/verdes: subrepresentación (bajo la tendencia).\n",
        "Se incluyen grupos con diferencia ≥", sprintf("%.1f", umbral), " puntos porcentuales respecto a la tendencia general. ",
        "Fuente: Egresos hospitalarios 2010-2022, Departamento de Estadísticas e Información de Salud. Elaboración propia."
      )
    ) +
    
    # Tema
    theme_minimal() +
    theme(
      legend.position = "bottom",
      legend.text = element_text(size = 10),
      legend.box = "vertical",
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 11),
      axis.text.y = element_text(size = 11),
      axis.title = element_text(size = 12, face = "bold"),
      plot.title = element_text(size = 14, face = "bold", margin = margin(b = 5)),
      plot.subtitle = element_text(size = 11, margin = margin(b = 15)),
      plot.caption = element_text(
        hjust = 0, 
        size = 8.5, 
        color = "gray40", 
        lineheight = 1.3,
        margin = margin(t = 10)
      ),
      plot.margin = margin(15, 20, 15, 15)
    ) +
    guides(
      color = guide_legend(
        nrow = 3,
        override.aes = list(size = 3, linewidth = 1.5)
      )
    )
  
  return(grafico)
}
