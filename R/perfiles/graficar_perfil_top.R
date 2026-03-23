#' Graficar top N diagnósticos (barras horizontales)
#'
#' @description
#' Genera gráfico de barras horizontal para visualizar el top N
#' de diagnósticos más frecuentes.
#'
#' @param datos Tibble con columnas DIAG_COMPLETO y n_casos
#' @param titulo Título del gráfico
#' @param subtitulo Subtítulo del gráfico
#' @param color_barras Color de las barras (default: colores_pertenencia[["PO"]])
#' @param mostrar_etiquetas Mostrar valores en barras (default: TRUE)
#' @param tamano_etiquetas Tamaño de etiquetas (default: 2.5)
#' @param caption Pie de gráfico (default: NULL, se calcula automático)
#'
#' @return Objeto ggplot
#'
#' @examples
#' grafico <- graficar_perfil_top(
#'   datos = perfil_po,
#'   titulo = "Top 20 Diagnósticos - Pueblos Originarios",
#'   subtitulo = "Egresos hospitalarios 2010-2022"
#' )
#'
#' @export
graficar_perfil_top <- function(datos,
                                titulo,
                                subtitulo = NULL,
                                color_barras = colores_pertenencia[["PO"]],
                                mostrar_etiquetas = TRUE,
                                tamano_etiquetas = 2.5,
                                caption = NULL) {
  
  # Caption automático si no se especifica
  if (is.null(caption)) {
    total_casos <- sum(datos$n_casos)
    pct_total <- sum(datos$pct_total, na.rm = TRUE)
    
    caption <- paste0(
      "n total = ", format(total_casos, big.mark = ","), " egresos"
    )
    
    if (!is.na(pct_total)) {
      caption <- paste0(caption, " | ",
                       sprintf("%.1f%%", pct_total), " del total de egresos")
    }
  }
  
  # Crear gráfico
  grafico <- ggplot2::ggplot(
    datos, 
    ggplot2::aes(x = reorder(DIAG_COMPLETO, n_casos), y = n_casos)
  ) +
    ggplot2::geom_col(fill = color_barras, width = 0.7)
  
  # Agregar etiquetas si se solicita
  if (mostrar_etiquetas) {
    grafico <- grafico +
      ggplot2::geom_text(
        ggplot2::aes(label = format(n_casos, big.mark = ",")), 
        hjust = -0.1, 
        size = tamano_etiquetas
      )
  }
  
  # Formato del gráfico
  grafico <- grafico +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(
      labels = scales::comma,
      expand = ggplot2::expansion(mult = c(0, 0.15))
    ) +
    ggplot2::labs(
      title = titulo,
      subtitle = subtitulo,
      x = NULL,
      y = "Número de egresos",
      caption = caption
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 7.5),
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10),
      plot.caption = ggplot2::element_text(hjust = 0, size = 8, color = "gray40")
    )
  
  return(grafico)
}
