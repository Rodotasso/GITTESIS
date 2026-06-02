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
    dplyr::select(Capitulo, BPP) %>%
    dplyr::distinct() %>%
    dplyr::filter(abs(BPP) > umbral_bpp) %>%
    dplyr::mutate(
      Direccion = ifelse(BPP > 0, "Sobrerrepresentación en Pueblos Indígenas", "Subrepresentación en Pueblos Indígenas (Exceso Población General)"),
      Capitulo_corto = stringr::str_wrap(Capitulo, width = 45)
    )
  
  p <- ggplot(datos_graf, aes(x = reorder(Capitulo_corto, BPP), y = BPP, fill = Direccion)) +
    geom_col(color = "black", width = 0.7) +
    coord_flip() +
    scale_fill_manual(values = c("Sobrerrepresentación en Pueblos Indígenas" = "#D32F2F", "Subrepresentación en Pueblos Indígenas (Exceso Población General)" = "#1976D2")) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
    theme_minimal(base_size = 12) +
    labs(
      title = "Brecha Estructural en Causa de Hospitalización",
      subtitle = "Diferencia de Puntos Porcentuales (Peso Relativo Pueblos Indígenas - Peso Relativo Población General)",
      x = "Capítulo CIE-10",
      y = "Brecha (pp)",
      fill = ""
    ) +
    theme(
      legend.position = "bottom",
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
    theme(
      legend.position = "bottom",
      plot.title = element_text(face = "bold")
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
