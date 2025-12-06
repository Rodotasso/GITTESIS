#' Graficar diferencias de tasas entre PO y PG (barras divergentes)
#'
#' @description
#' Genera gráfico de barras divergente para visualizar diferencias
#' de tasas entre Pueblos Originarios y Población General. Barras
#' positivas indican mayor tasa en PO, negativas mayor tasa en PG.
#'
#' @param datos Tibble con columnas DIAG_COMPLETO y dif_tasa_anual
#' @param top_n Número de diagnósticos a mostrar (default: 15)
#' @param ordenar_por Criterio para seleccionar diagnósticos: "abs" (valor absoluto de diferencia) 
#'   o "positivo" (mayores diferencias positivas) o "negativo" (mayores diferencias negativas)
#' @param titulo Título del gráfico
#' @param subtitulo Subtítulo del gráfico
#' @param color_po Color para tasas mayores en PO (default: "#C62828" rojo)
#' @param color_pg Color para tasas mayores en PG (default: "#1565C0" azul)
#' @param mostrar_etiquetas Mostrar valores en barras (default: TRUE)
#' @param tamano_etiquetas Tamaño de etiquetas (default: 2.3)
#'
#' @return Objeto ggplot
#'
#' @examples
#' grafico <- graficar_diferencias_tasas(
#'   datos = comparacion,
#'   top_n = 15,
#'   titulo = "Diferencias de Tasas: PO vs PG",
#'   subtitulo = "Tasas anuales por 1000 personas-año"
#' )
#'
#' @export
graficar_diferencias_tasas <- function(datos,
                                       top_n = 15,
                                       ordenar_por = "abs",
                                       titulo,
                                       subtitulo = NULL,
                                       color_po = "#C62828",
                                       color_pg = "#1565C0",
                                       mostrar_etiquetas = TRUE,
                                       tamano_etiquetas = 2.3) {
  
  # Seleccionar top N según criterio
  if (ordenar_por == "abs") {
    datos_grafico <- datos %>%
      dplyr::arrange(desc(abs(dif_tasa_anual))) %>%
      dplyr::slice_head(n = top_n)
  } else if (ordenar_por == "positivo") {
    datos_grafico <- datos %>%
      dplyr::arrange(desc(dif_tasa_anual)) %>%
      dplyr::slice_head(n = top_n)
  } else if (ordenar_por == "negativo") {
    datos_grafico <- datos %>%
      dplyr::arrange(dif_tasa_anual) %>%
      dplyr::slice_head(n = top_n)
  } else {
    stop("ordenar_por debe ser 'abs', 'positivo' o 'negativo'")
  }
  
  # Crear variable de color según signo
  datos_grafico <- datos_grafico %>%
    dplyr::mutate(
      color_grupo = dplyr::if_else(dif_tasa_anual > 0, "Mayor en PO", "Mayor en PG")
    )
  
  # Crear gráfico
  grafico <- ggplot2::ggplot(
    datos_grafico,
    ggplot2::aes(
      x = reorder(DIAG_COMPLETO, dif_tasa_anual),
      y = dif_tasa_anual,
      fill = color_grupo
    )
  ) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::scale_fill_manual(
      values = c("Mayor en PO" = color_po, "Mayor en PG" = color_pg),
      name = NULL
    )
  
  # Agregar etiquetas si se solicita
  if (mostrar_etiquetas) {
    grafico <- grafico +
      ggplot2::geom_text(
        ggplot2::aes(
          label = sprintf("%.2f", dif_tasa_anual),
          hjust = dplyr::if_else(dif_tasa_anual > 0, -0.1, 1.1)
        ),
        size = tamano_etiquetas
      )
  }
  
  # Formato del gráfico
  grafico <- grafico +
    ggplot2::coord_flip() +
    ggplot2::geom_hline(yintercept = 0, linetype = "solid", color = "black", linewidth = 0.3) +
    ggplot2::scale_y_continuous(
      labels = function(x) sprintf("%.1f", x),
      expand = ggplot2::expansion(mult = c(0.15, 0.15))
    ) +
    ggplot2::labs(
      title = titulo,
      subtitle = subtitulo,
      x = NULL,
      y = "Diferencia de tasa anual (PO - PG)\npor 1000 personas-año",
      caption = "Diferencias positivas indican mayor tasa en Pueblos Originarios\nDiferencias negativas indican mayor tasa en Población General"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 7),
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10),
      plot.caption = ggplot2::element_text(hjust = 0, size = 7.5, color = "gray40"),
      legend.position = "top"
    )
  
  return(grafico)
}
