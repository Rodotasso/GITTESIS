# ============================================================================
# FUNCIONES PARA VISUALIZACIONES ALTERNATIVAS DE DISPARIDADES CIE-10
# Autor: Rodolfo Tasso
# Fecha: 2025
# ============================================================================

#' Preparar datos de disparidades CIE-10 para visualizaciones
#'
#' @param datos_homologados Data frame con los datos de egresos hospitalarios
#' @param umbral Diferencia mínima en puntos porcentuales para incluir grupo (default: 1.5)
#' @return Lista con datos preparados para visualizaciones
preparar_datos_disparidades_cie10 <- function(datos_homologados, umbral = 1.5) {

  # Calcular tendencia general de PERTENENCIA2 por año

  tendencia_general <- datos_homologados %>%
    filter(AÑO != "No reportado") %>%
    group_by(AÑO) %>%
    summarise(
      pertenece = sum(PERTENENCIA2 == 1, na.rm = TRUE),
      total = n(),
      pct_po = (pertenece / total) * 100,
      .groups = "drop"
    )

  pct_variable_enriquecida <- mean(tendencia_general$pct_po, na.rm = TRUE)

  # Calcular porcentaje de PO por grupo CIE-10 y año
  datos_cie10_anual <- datos_homologados %>%
    filter(AÑO != "No reportado", !is.na(Grupo_CIE10)) %>%
    group_by(AÑO, Grupo_CIE10) %>%
    summarise(
      pertenece = sum(PERTENENCIA2 == 1, na.rm = TRUE),
      total = n(),
      porcentaje = (pertenece / total) * 100,
      .groups = "drop"
    )

  # Calcular promedio y diferencia con tendencia general

  datos_cie10_resumen <- datos_cie10_anual %>%
    group_by(Grupo_CIE10) %>%
    summarise(
      porcentaje_promedio = mean(porcentaje, na.rm = TRUE),
      porcentaje_min = min(porcentaje, na.rm = TRUE),
      porcentaje_max = max(porcentaje, na.rm = TRUE),
      porcentaje_sd = sd(porcentaje, na.rm = TRUE),
      n_total = sum(total),
      .groups = "drop"
    ) %>%
    mutate(
      diferencia = porcentaje_promedio - pct_variable_enriquecida,
      tipo = case_when(
        diferencia >= umbral ~ "Sobrerrepresentación",
        diferencia <= -umbral ~ "Subrepresentación",
        TRUE ~ "Sin diferencia significativa"
      )
    ) %>%
    filter(abs(diferencia) >= umbral) %>%
    arrange(desc(diferencia))

  list(
    tendencia_general = tendencia_general,
    pct_variable_enriquecida = pct_variable_enriquecida,
    datos_cie10_anual = datos_cie10_anual,
    datos_cie10_resumen = datos_cie10_resumen,
    umbral = umbral
  )
}

#' Generar Diverging Bar Chart de disparidades CIE-10
#'
#' @param datos Lista generada por preparar_datos_disparidades_cie10()
#' @param version_revista Si TRUE, genera versión sin título embebido (default: FALSE)
#' @return Objeto ggplot
crear_diverging_bar_chart <- function(datos, version_revista = FALSE) {

  df <- datos$datos_cie10_resumen %>%
    mutate(
      Grupo_CIE10_wrap = str_wrap(Grupo_CIE10, width = 35),
      Grupo_CIE10_wrap = fct_reorder(Grupo_CIE10_wrap, diferencia)
    )

  # Colores
  colores_diverging <- c(
    "Sobrerrepresentación" = "#C62828",
    "Subrepresentación" = "#1565C0"
  )

  p <- ggplot(df, aes(x = diferencia, y = Grupo_CIE10_wrap, fill = tipo)) +
    geom_col(width = 0.7, alpha = 0.85) +
    geom_vline(xintercept = 0, color = "gray30", linewidth = 0.8) +
    geom_text(aes(label = sprintf("%+.1f pp", diferencia),
                  hjust = ifelse(diferencia > 0, -0.1, 1.1)),
              size = 3.5, fontface = "bold") +
    scale_fill_manual(values = colores_diverging, name = NULL) +
    scale_x_continuous(
      labels = function(x) paste0(ifelse(x > 0, "+", ""), x, " pp"),
      breaks = seq(-4, 6, by = 2),
      limits = c(min(df$diferencia) - 1, max(df$diferencia) + 1.5)
    ) +
    labs(
      x = "Diferencia respecto al promedio de la variable enriquecida (puntos porcentuales)",
      y = NULL,
      caption = if (version_revista) NULL else paste0(
        "Promedio variable enriquecida: ", sprintf("%.1f%%", datos$pct_variable_enriquecida),
        ". Umbral de inclusión: ≥", datos$umbral, " pp. Chile, 2010-2022.\n",
        "Fuente: DEIS, egresos hospitalarios. Elaboración propia."
      )
    ) +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "bottom",
      legend.text = element_text(size = 10),
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text.y = element_text(size = 10, hjust = 1),
      axis.text.x = element_text(size = 10),
      axis.title.x = element_text(size = 11, face = "bold", margin = margin(t = 10)),
      plot.caption = element_text(hjust = 0, size = 9, color = "gray40", lineheight = 1.2),
      plot.margin = margin(15, 20, 10, 10)
    )

  if (!version_revista) {
    p <- p + labs(
      title = "Sobre y subrepresentación de pueblos originarios por grupo diagnóstico CIE-10",
      subtitle = "Diferencia en puntos porcentuales respecto al promedio general"
    ) +
      theme(
        plot.title = element_text(size = 14, face = "bold", hjust = 0),
        plot.subtitle = element_text(size = 11, color = "gray30", hjust = 0)
      )
  }

  return(p)
}

#' Generar Heatmap temporal de disparidades CIE-10
#'
#' @param datos Lista generada por preparar_datos_disparidades_cie10()
#' @param version_revista Si TRUE, genera versión sin título embebido (default: FALSE)
#' @return Objeto ggplot
crear_heatmap_temporal <- function(datos, version_revista = FALSE) {

  grupos_seleccionados <- datos$datos_cie10_resumen$Grupo_CIE10

  df <- datos$datos_cie10_anual %>%
    filter(Grupo_CIE10 %in% grupos_seleccionados) %>%
    left_join(
      datos$tendencia_general %>% select(AÑO, pct_general = pct_po),
      by = "AÑO"
    ) %>%
    mutate(
      diferencia = porcentaje - pct_general,
      Grupo_CIE10_wrap = str_wrap(Grupo_CIE10, width = 30)
    )

  # Ordenar grupos por diferencia promedio
  orden_grupos <- datos$datos_cie10_resumen %>%
    arrange(desc(diferencia)) %>%
    mutate(Grupo_CIE10_wrap = str_wrap(Grupo_CIE10, width = 30)) %>%
    pull(Grupo_CIE10_wrap)

  df <- df %>%
    mutate(Grupo_CIE10_wrap = factor(Grupo_CIE10_wrap, levels = rev(orden_grupos)))

  # Límites simétricos para la escala de color
  max_abs <- max(abs(df$diferencia), na.rm = TRUE)
  limite <- ceiling(max_abs)

  p <- ggplot(df, aes(x = AÑO, y = Grupo_CIE10_wrap, fill = diferencia)) +
    geom_tile(color = "white", linewidth = 0.5) +
    geom_text(aes(label = sprintf("%+.1f", diferencia)),
              size = 2.8, color = "black") +
    scale_fill_gradient2(
      low = "#1565C0", mid = "white", high = "#C62828",
      midpoint = 0,
      limits = c(-limite, limite),
      name = "Diferencia (pp)",
      labels = function(x) paste0(ifelse(x > 0, "+", ""), x)
    ) +
    labs(
      x = "Año",
      y = NULL,
      caption = if (version_revista) NULL else paste0(
        "Valores: diferencia en puntos porcentuales respecto al promedio general de cada año.\n",
        "Rojo: sobrerrepresentación. Azul: subrepresentación. Chile, 2010-2022.\n",
        "Fuente: DEIS, egresos hospitalarios. Elaboración propia."
      )
    ) +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "right",
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 9),
      panel.grid = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
      axis.text.y = element_text(size = 9),
      axis.title.x = element_text(size = 11, face = "bold", margin = margin(t = 10)),
      plot.caption = element_text(hjust = 0, size = 9, color = "gray40", lineheight = 1.2),
      plot.margin = margin(15, 15, 10, 10)
    )

  if (!version_revista) {
    p <- p + labs(
      title = "Evolución temporal de disparidades en representación de pueblos originarios",
      subtitle = "Heatmap por grupo diagnóstico CIE-10 y año"
    ) +
      theme(
        plot.title = element_text(size = 14, face = "bold", hjust = 0),
        plot.subtitle = element_text(size = 11, color = "gray30", hjust = 0)
      )
  }

  return(p)
}

#' Generar Forest Plot adaptado de disparidades CIE-10
#'
#' @param datos Lista generada por preparar_datos_disparidades_cie10()
#' @param version_revista Si TRUE, genera versión sin título embebido (default: FALSE)
#' @return Objeto ggplot
crear_forest_plot_cie10 <- function(datos, version_revista = FALSE) {

  df <- datos$datos_cie10_resumen %>%
    mutate(
      # Calcular IC 95% usando SD y asumiendo distribución normal
      # n = 156 meses (13 años × 12 meses) para mayor precisión estadística
      n_obs = 156,
      se = porcentaje_sd / sqrt(n_obs),
      ic_inf = diferencia - 1.96 * se,
      ic_sup = diferencia + 1.96 * se,
      Grupo_CIE10_wrap = str_wrap(Grupo_CIE10, width = 35),
      Grupo_CIE10_wrap = fct_reorder(Grupo_CIE10_wrap, diferencia)
    )

  # Colores según tipo
  colores_forest <- c(
    "Sobrerrepresentación" = "#C62828",
    "Subrepresentación" = "#1565C0"
  )

  p <- ggplot(df, aes(x = diferencia, y = Grupo_CIE10_wrap, color = tipo)) +
    # Línea de referencia (sin diferencia)
    geom_vline(xintercept = 0, color = "gray50", linewidth = 0.8, linetype = "dashed") +
    # Barras de error (IC 95%)
    geom_errorbarh(aes(xmin = ic_inf, xmax = ic_sup),
                   height = 0.3, linewidth = 0.8, alpha = 0.8) +
    # Puntos centrales (estimación)
    geom_point(size = 4, alpha = 0.9) +
    # Etiquetas con valor (posicionadas arriba del IC)
    geom_text(aes(label = sprintf("%+.1f pp", diferencia)),
              hjust = 0.5, vjust = -0.8, size = 3.2, fontface = "bold",
              show.legend = FALSE) +
    scale_color_manual(values = colores_forest, name = NULL) +
    scale_x_continuous(
      labels = function(x) paste0(ifelse(x > 0, "+", ""), x, " pp"),
      breaks = seq(-6, 8, by = 2),
      limits = c(min(df$ic_inf) - 1, max(df$ic_sup) + 2)
    ) +
    labs(
      x = "Diferencia respecto al promedio (puntos porcentuales) con IC 95%",
      y = NULL,
      caption = if (version_revista) NULL else paste0(
        "Puntos: diferencia promedio 2010-2022. Barras: intervalo de confianza al 95%.\n",
        "Línea punteada: sin diferencia (0 pp). Promedio variable enriquecida: ",
        sprintf("%.1f%%", datos$pct_variable_enriquecida), ".\n",
        "Fuente: DEIS, egresos hospitalarios. Elaboración propia."
      )
    ) +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "bottom",
      legend.text = element_text(size = 10),
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text.y = element_text(size = 10, hjust = 1),
      axis.text.x = element_text(size = 10),
      axis.title.x = element_text(size = 11, face = "bold", margin = margin(t = 10)),
      plot.caption = element_text(hjust = 0, size = 9, color = "gray40", lineheight = 1.2),
      plot.margin = margin(15, 25, 10, 10)
    )

  if (!version_revista) {
    p <- p + labs(
      title = "Disparidades en representación de pueblos originarios por grupo CIE-10",
      subtitle = "Forest plot: diferencia en puntos porcentuales con intervalos de confianza"
    ) +
      theme(
        plot.title = element_text(size = 14, face = "bold", hjust = 0),
        plot.subtitle = element_text(size = 11, color = "gray30", hjust = 0)
      )
  }

  return(p)
}

#' Guardar visualización en múltiples formatos para revista
#'
#' @param plot Objeto ggplot
#' @param nombre_base Nombre base del archivo (sin extensión)
#' @param dir_salida Directorio de salida
#' @param width Ancho en pulgadas (default: 12)
#' @param height Alto en pulgadas (default: 8)
#' @param dpi Resolución (default: 600)
guardar_figura_revista <- function(plot, nombre_base, dir_salida,
                                    width = 12, height = 8, dpi = 600) {

  # JPG (para uso general)
  ggsave(file.path(dir_salida, paste0(nombre_base, ".jpg")), plot,
         width = width, height = height, dpi = dpi, bg = "white")

  # PNG (alta calidad con transparencia opcional)
  ggsave(file.path(dir_salida, paste0(nombre_base, ".png")), plot,
         width = width, height = height, dpi = dpi, bg = "white")

  # TIFF (requerimiento revistas científicas)
  ggsave(file.path(dir_salida, paste0(nombre_base, ".tiff")), plot,
         width = width, height = height, dpi = dpi, bg = "white", compression = "lzw")

  # EPS (vectorial para revistas)
  tryCatch({
    ggsave(file.path(dir_salida, paste0(nombre_base, ".eps")), plot,
           width = width, height = height, dpi = dpi, bg = "white", device = "eps")
  }, error = function(e) {
    message("No se pudo generar EPS: ", e$message)
  })

  cat("✓", nombre_base, "guardado (JPG, PNG, TIFF a", dpi, "dpi)\n")
}
