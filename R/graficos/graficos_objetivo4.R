# ==============================================================================
# FUNCIONES DE GRÁFICOS: Perfiles Diagnósticos (Objetivo 4)
# ==============================================================================

#' Gráfico Divergente de Brechas (BPP)
#' @param datos_obj4 Resultados de calcular_indicadores_objetivo4
#' @param umbral_bpp Brecha mínima absoluta para mostrar (default 0.1)
#' @export
grafico_divergente_bpp <- function(datos_obj4, umbral_bpp = 0.1) {
  library(ggplot2)
  library(dplyr)
  library(stringr)
  
  datos_graf <- datos_obj4 %>%
    dplyr::select(grupo, Capitulo, PEC) %>%
    dplyr::distinct() %>%
    tidyr::pivot_wider(names_from = grupo, values_from = PEC) %>%
    dplyr::mutate(
      BPP = PI - PG,
      Direccion = ifelse(BPP > 0, "Sobrerrepresentación en Pueblos Indígenas", "Subrepresentación en Pueblos Indígenas"),
      Capitulo_corto = stringr::str_wrap(Capitulo, width = 45)
    ) %>%
    dplyr::filter(abs(BPP) > umbral_bpp)
  
  p <- ggplot(datos_graf, aes(x = reorder(Capitulo_corto, BPP), y = BPP, fill = Direccion)) +
    geom_col(color = "black", width = 0.7) +
    coord_flip() +
    scale_fill_manual(values = c("Sobrerrepresentación en Pueblos Indígenas" = "#D32F2F", "Subrepresentación en Pueblos Indígenas" = "#1976D2")) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
    theme_minimal(base_size = 12) +
    labs(
      title = "Disparidades en el Perfil Diagnóstico por Causa de Hospitalización",
      subtitle = "Diferencia de Puntos Porcentuales entre Pueblos Indígenas y Población General",
      x = "Capítulo CIE-10",
      y = "DPP (puntos porcentuales)",
      fill = ""
    ) +
    theme(
      legend.position = "bottom",
      legend.justification = "left",
      plot.title = element_text(face = "bold")
    )
  return(p)
}

#' Gráfico Dumbbell para Proporciones (PEC)
#' @export
grafico_dumbbell_pec <- function(datos_obj4, top_n = 15) {
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(stringr)
  
  # Seleccionar top capítulos basados en PEC de PI
  top_caps <- datos_obj4 %>%
    dplyr::filter(grupo == "PI") %>%
    dplyr::arrange(desc(PEC)) %>%
    dplyr::slice_head(n = top_n) %>%
    dplyr::pull(Capitulo)
  
  datos_filtrados <- datos_obj4 %>%
    dplyr::filter(Capitulo %in% top_caps)
  
  datos_dumbbell <- datos_filtrados %>%
    dplyr::select(Capitulo, grupo, PEC) %>%
    tidyr::pivot_wider(names_from = grupo, values_from = PEC) %>%
    dplyr::mutate(Capitulo_corto = stringr::str_wrap(Capitulo, width = 40)) %>%
    dplyr::arrange(PI)
  
  datos_dumbbell$Capitulo_corto <- factor(datos_dumbbell$Capitulo_corto, levels = datos_dumbbell$Capitulo_corto)
  
  datos_puntos <- datos_filtrados %>%
    dplyr::select(Capitulo, grupo, PEC) %>%
    dplyr::mutate(Capitulo_corto = stringr::str_wrap(Capitulo, width = 40)) %>%
    dplyr::mutate(Capitulo_corto = factor(Capitulo_corto, levels = levels(datos_dumbbell$Capitulo_corto)))
  
  p <- ggplot() +
    geom_segment(data = datos_dumbbell, 
                 aes(x = PG, xend = PI, y = Capitulo_corto, yend = Capitulo_corto), 
                 color = "gray70", linewidth = 1.5) +
    geom_point(data = datos_puntos, 
               aes(x = PEC, y = Capitulo_corto, color = grupo), 
               size = 4) +
    scale_color_manual(values = c("PI" = "#D32F2F", "PG" = "#1976D2"),
                       labels = c("PI" = "Pertenecientes a pueblos indígenas", "PG" = "Población general")) +
    theme_minimal(base_size = 12) +
    labs(
      title = "Comparación del Perfil de Morbilidad Hospitalaria",
      subtitle = sprintf("Proporción de Egresos por Causa (PEC %%) - Top %d Causas en Pueblos Indígenas", top_n),
      x = "Porcentaje sobre el total de egresos del grupo (%)",
      y = "",
      color = "Población"
    ) +
    theme(
      legend.position = "top",
      panel.grid.minor.y = element_blank(),
      plot.title = element_text(face = "bold")
    )
  return(p)
}

#' Gráfico de Cuadrantes (Severidad vs Frecuencia)
#' @export
grafico_cuadrantes_severidad <- function(datos_obj4) {
  library(ggplot2)
  library(dplyr)
  library(stringr)
  library(ggrepel)

  p <- ggplot(datos_obj4, aes(x = PEC, y = TLI, color = grupo)) +
    geom_point(alpha = 0.7, size = 4) +
    ggrepel::geom_text_repel(
      aes(label = ifelse(PEC > 5 | TLI > 5, stringr::str_sub(Capitulo, 1, 30), "")),
      size = 3,
      show.legend = FALSE,
      max.overlaps = 20
    ) +
    scale_color_manual(values = c("PI" = "#D32F2F", "PG" = "#1976D2"),
                       labels = c("PI" = "Pertenecientes a pueblos indígenas", "PG" = "Población general")) +
    theme_bw(base_size = 12) +
    labs(
      title = "Severidad vs. Frecuencia de Hospitalización",
      subtitle = "Tasa de Letalidad Intrahospitalaria vs. Proporción de Egresos por Causa",
      x = "Proporción de Egresos por Causa (PEC %)",
      y = "Tasa de Letalidad Intrahospitalaria (TLI %)",
      color = "Población"
    ) +
    guides(color = guide_legend(nrow = 1, byrow = TRUE, override.aes = list(size = 4))) +
    theme(
      legend.position = "bottom",
      legend.title = element_text(size = 11),
      legend.text = element_text(size = 10),
      legend.box.margin = margin(t = 4, b = 4),
      plot.title = element_text(face = "bold"),
      plot.margin = margin(10, 16, 10, 10)
    )
  return(p)
}

#' Gráfico Convencional de Barras (Top PEC)
#' @export
grafico_barras_top_pec <- function(datos_obj4, grupo_obj = "PI", top_n = 10) {
  library(ggplot2)
  library(dplyr)
  library(stringr)
  
  color_fill <- ifelse(grupo_obj == "PI", "#D32F2F", "#1976D2")
  nombre_grupo <- ifelse(grupo_obj == "PI", "Pertenecientes a pueblos indígenas", "Población general")
  
  datos_graf <- datos_obj4 %>%
    dplyr::filter(grupo == grupo_obj) %>%
    dplyr::arrange(desc(PEC)) %>%
    dplyr::slice_head(n = top_n) %>%
    dplyr::mutate(Capitulo_corto = stringr::str_wrap(Capitulo, width = 45))
  
  p <- ggplot(datos_graf, aes(x = reorder(Capitulo_corto, PEC), y = PEC)) +
    geom_col(fill = color_fill, color = "black", width = 0.7) +
    geom_text(aes(label = sprintf("%.1f%%", PEC)), hjust = -0.1, size = 3.5) +
    coord_flip() +
    theme_minimal(base_size = 12) +
    labs(
      title = sprintf("Top %d Causas de Hospitalización", top_n),
      subtitle = sprintf("Proporción de Egresos por Causa en %s", nombre_grupo),
      x = "",
      y = "Porcentaje (%)"
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    theme(plot.title = element_text(face = "bold"))

  return(p)
}

# ==============================================================================
# FUNCIONES DE VISUALIZACIÓN PARA ANÁLISIS DESAGREGADO (perfiles_diagnosticos_desagregados)
# ==============================================================================

#' Gráfico de Disparidades Facetado por Estrato (DPP PI vs PG)
#'
#' @param datos_ind Data frame con indicadores estratificados (output de calcular_indicadores_estratificados).
#' @param var_facet Nombre de la variable de facetado (string).
#' @param titulo Título del gráfico.
#' @param n_pos Número de capítulos con mayor sobrerrepresentación por faceta. NULL = top 10 por magnitud.
#' @param n_neg Número de capítulos con mayor subrepresentación por faceta. NULL = top 10 por magnitud.
#' @param ncol Número de columnas para facet_wrap (NULL = automático).
#' @param text_size Tamaño del texto del eje Y (default 9).
#' @export
graficar_disparidades_facet <- function(datos_ind, var_facet, titulo,
                                        n_pos = NULL, n_neg = NULL,
                                        ncol = NULL, text_size = 9) {
  datos_unicos <- datos_ind %>%
    dplyr::distinct(!!rlang::sym(var_facet), Capitulo, BPP, .keep_all = TRUE)

  if (!is.null(n_pos) || !is.null(n_neg)) {
    if (is.null(n_pos)) n_pos <- 3
    if (is.null(n_neg)) n_neg <- 3
    df_plot <- datos_unicos %>%
      dplyr::group_by(!!rlang::sym(var_facet)) %>%
      dplyr::group_modify(~ {
        pos <- .x %>% dplyr::filter(BPP > 0) %>% dplyr::arrange(dplyr::desc(BPP)) %>% dplyr::slice_head(n = n_pos)
        neg <- .x %>% dplyr::filter(BPP < 0) %>% dplyr::arrange(BPP) %>% dplyr::slice_head(n = n_neg)
        dplyr::bind_rows(pos, neg)
      }) %>%
      dplyr::ungroup()
  } else {
    df_plot <- datos_unicos %>%
      dplyr::group_by(!!rlang::sym(var_facet)) %>%
      dplyr::arrange(dplyr::desc(abs(BPP))) %>%
      dplyr::slice_head(n = 10) %>%
      dplyr::ungroup()
  }

  df_plot <- df_plot %>%
    dplyr::mutate(
      color_dif     = ifelse(BPP > 0, "Sobre-representación PI", "Sub-representación PI"),
      Capitulo_wrap = stringr::str_wrap(Capitulo, width = 35)
    )

  ggplot2::ggplot(df_plot, ggplot2::aes(x = reorder(Capitulo_wrap, BPP), y = BPP, fill = color_dif)) +
    ggplot2::geom_col() +
    ggplot2::facet_wrap(stats::as.formula(paste("~", var_facet)), scales = "free_y", ncol = ncol) +
    ggplot2::coord_flip() +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed") +
    ggplot2::scale_fill_manual(values = c(
      "Sobre-representación PI" = colores_pertenencia[["PO"]],
      "Sub-representación PI"   = colores_pertenencia[["PG"]]
    )) +
    ggplot2::labs(
      title    = titulo,
      subtitle = "Diferencia de Puntos Porcentuales (DPP) en el peso relativo de cada capítulo entre PI y PG",
      x = NULL, y = "Diferencia (puntos porcentuales)",
      fill    = "Interpretación",
      caption = "DPP > 0: el capítulo tiene mayor peso relativo en la población indígena.\nAnálisis por Evento Hospitalario. Chile 2010-2022. Excluye Cap. XV."
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "bottom",
      strip.text      = ggplot2::element_text(face = "bold", size = 11),
      axis.text.y     = ggplot2::element_text(size = text_size)
    )
}

#' Heatmap Regional de Carga de Enfermedad (TBE) en Población Indígena
#'
#' @param datos_ind Data frame con indicadores por región (output de calcular_indicadores_estratificados con var_estrato = "region").
#' @param titulo Título del gráfico.
#' @export
graficar_heatmap_regional <- function(datos_ind, titulo) {
  tabla_regiones <- obtener_tabla_regiones()
  df_plot <- datos_ind %>%
    dplyr::filter(grupo == "PI") %>%
    dplyr::mutate(
      nombre_region = codigo_a_nombre_region(region, tipo = "corto"),
      nombre_region = factor(nombre_region, levels = tabla_regiones$nombre_corto),
      Capitulo_wrap = stringr::str_wrap(Capitulo, width = 30)
    )
  top_caps <- df_plot %>%
    dplyr::group_by(Capitulo_wrap) %>%
    dplyr::summarise(m = mean(TBE, na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(m)) %>%
    head(18) %>%
    dplyr::pull(Capitulo_wrap)

  df_plot %>%
    dplyr::filter(Capitulo_wrap %in% top_caps) %>%
    ggplot2::ggplot(ggplot2::aes(x = nombre_region, y = Capitulo_wrap, fill = TBE)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::scale_fill_distiller(palette = "YlOrRd", direction = 1, name = "TBE x 10k", na.value = "grey90") +
    ggplot2::labs(
      title    = titulo,
      subtitle = "Tasa Bruta de Egresos (TBE) por 10.000 hab. en Población Indígena",
      x = NULL, y = NULL,
      caption = "Excluye Cap. XV. Regiones ordenadas de Norte a Sur. La TBE mide la carga regional."
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 9),
      panel.grid  = ggplot2::element_blank(),
      plot.title  = ggplot2::element_text(face = "bold")
    )
}

#' Gráfico de Disparidades PI vs PG para un Sexo Específico
#'
#' @param ind_df Data frame con indicadores por sexo (output de calcular_indicadores_estratificados con var_estrato = "sexo").
#' @param filtro_sexo Valor a filtrar: "HOMBRE" o "MUJER".
#' @param titulo Título del gráfico.
#' @param top_n Número de capítulos a mostrar por magnitud de BPP (default 15).
#' @export
graficar_bpp_por_sexo <- function(ind_df, filtro_sexo, titulo, top_n = 15) {
  df_plot <- ind_df %>%
    dplyr::filter(sexo == filtro_sexo) %>%
    dplyr::distinct(Capitulo, BPP) %>%
    dplyr::mutate(
      color_dif     = ifelse(BPP > 0, "Sobre-representación PI", "Sub-representación PI"),
      Capitulo_wrap = stringr::str_wrap(Capitulo, width = 35)
    ) %>%
    dplyr::slice_max(abs(BPP), n = top_n)

  ggplot2::ggplot(df_plot, ggplot2::aes(x = reorder(Capitulo_wrap, BPP), y = BPP, fill = color_dif)) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed") +
    ggplot2::scale_fill_manual(values = c(
      "Sobre-representación PI" = colores_pertenencia[["PO"]],
      "Sub-representación PI"   = colores_pertenencia[["PG"]]
    )) +
    ggplot2::labs(
      title    = titulo,
      subtitle = "DPP = % PI − % PG en el peso relativo de cada capítulo CIE-10",
      x = NULL, y = "DPP (puntos porcentuales)",
      fill    = "Interpretación",
      caption = "Análisis por Evento Hospitalario. Chile 2010-2022. Excluye Cap. XV."
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "bottom",
      axis.text.y     = ggplot2::element_text(size = 9)
    )
}

#' Panel consolidado de Top Causas (PI + PG en 2 paneles)
#' @export
grafico_barras_top_pec_panel <- function(datos_obj4, top_n = 10) {
  library(ggplot2)
  library(patchwork)

  ajustar <- function(p, subtitulo) {
    p +
      ggplot2::labs(title = NULL, subtitle = subtitulo) +
      ggplot2::theme(
        axis.text.y = ggplot2::element_text(size = 12),
        axis.text.x = ggplot2::element_text(size = 11),
        plot.subtitle = ggplot2::element_text(face = "bold", size = 12)
      )
  }

  p_pi <- ajustar(grafico_barras_top_pec(datos_obj4, grupo_obj = "PI", top_n = top_n),
                  "Pertenecientes a pueblos indígenas")
  p_pg <- ajustar(grafico_barras_top_pec(datos_obj4, grupo_obj = "PG", top_n = top_n),
                  "Población general")

  (p_pi | p_pg) +
    patchwork::plot_annotation(
      title = sprintf("Principales %d causas de egreso hospitalario por capítulo CIE-10", top_n),
      tag_levels = "A",
      theme = ggplot2::theme(plot.title = ggplot2::element_text(size = 15, face = "bold"))
    )
}
