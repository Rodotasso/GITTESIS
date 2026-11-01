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

#' Anclas de rotulo de la Figura 9 (cuadrantes de severidad)
#'
#' Posicion de cada etiqueta relativa a su punto, expresada como fraccion de la
#' amplitud de cada eje, y separacion de cada punto rotulado. Los valores se
#' calibraron sobre la geometria del panel de 10 x 6 pulgadas con 600 dpi, de
#' modo que las diez etiquetas (los tres capitulos de mayor PEC y los dos de
#' mayor PLI, para PI y PG) no se superponen entre si, no salen del panel y no
#' tapan puntos. Se usan como semilla de ggrepel, que solo corrige desvíos
#' residuales; el segmento guia mantiene la identificabilidad del punto.
#'
#' @return data.frame con columnas Capitulo, grupo, fx, fy (fracciones de la
#'   amplitud de los ejes).
#' @noRd
anclas_rotulos_cuadrantes <- function() {
  data.frame(
    Capitulo = c(
      "Códigos para situaciones especiales", "Códigos para situaciones especiales",
      "Enfermedades infecciosas y parasitarias", "Enfermedades infecciosas y parasitarias",
      "Enfermedades del sistema respiratorio", "Enfermedades del sistema respiratorio",
      "Enfermedades del sistema digestivo", "Enfermedades del sistema digestivo",
      "Embarazo, parto y puerperio", "Embarazo, parto y puerperio"
    ),
    grupo = c("PG", "PI", "PG", "PI", "PG", "PI", "PG", "PI", "PG", "PI"),
    fx = c(0.0954, 0.0788, 0.1062, 0.1011, 0.0688, 0.0258, 0.1050, 0.1895, 0.1642, 0.0190),
    fy = c(-0.0206, -0.0964, -0.0350, 0.0530, 0.1117, -0.0622, 0.1954, 0.0296, 0.0608, 0.1834),
    stringsAsFactors = FALSE
  )
}

#' Gráfico de Cuadrantes (Severidad vs Frecuencia)
#' @export
grafico_cuadrantes_severidad <- function(datos_obj4) {
  library(ggplot2)
  library(dplyr)
  library(stringr)
  library(ggrepel)

  # La variable del eje y es TLI = (Fc / Ec) * 100, es decir una proporcion de
  # letalidad intrahospitalaria; en el documento se rotula PLI (Proporcion de
  # Letalidad Intrahospitalaria, ver la Tabla 7).

  # Rotulado: rotular los 42 puntos satura el panel, por lo que solo se
  # etiquetan los extremos de los cuadrantes: los 3 capitulos de mayor PEC y
  # los 2 de mayor PLI. Se rotulan ambos puntos del capitulo (PI y PG) para
  # que el par sea legible; el resto queda identificado por su posicion.
  # El nombre se abrevia con un salto de linea explicito (tabla de
  # equivalencias nombre completo -> abreviatura en el pie de figura) porque
  # los nombres oficiales completos ocupan 3-4 lineas y no caben en el panel
  # sin superponerse entre series.
  n_capitulos_pec <- 3L
  n_capitulos_pli <- 2L

  capitulos_pec <- datos_obj4 %>%
    dplyr::group_by(Capitulo) %>%
    dplyr::summarise(max_pec = max(PEC), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(max_pec)) %>%
    dplyr::slice_head(n = n_capitulos_pec) %>%
    dplyr::pull(Capitulo)

  capitulos_pli <- datos_obj4 %>%
    dplyr::group_by(Capitulo) %>%
    dplyr::summarise(max_pli = max(TLI), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(max_pli)) %>%
    dplyr::slice_head(n = n_capitulos_pli) %>%
    dplyr::pull(Capitulo)

  capitulos_etiquetados <- unique(c(capitulos_pec, capitulos_pli))

  # Equivalencias nombre completo -> abreviatura (maximo dos lineas).
  abreviaturas <- c(
    "Códigos para situaciones especiales"     = "Códigos especiales\n(XXII)",
    "Enfermedades infecciosas y parasitarias" = "Infecciosas y\nparasitarias (I)",
    "Enfermedades del sistema respiratorio"   = "Sistema respiratorio\n(X)",
    "Enfermedades del sistema digestivo"      = "Sistema digestivo\n(XI)",
    "Embarazo, parto y puerperio"             = "Embarazo, parto\ny puerperio (XV)"
  )

  datos_graf <- datos_obj4 %>%
    dplyr::mutate(
      etiqueta = dplyr::if_else(
        Capitulo %in% capitulos_etiquetados,
        dplyr::coalesce(
          unname(abreviaturas[Capitulo]),
          stringr::str_wrap(Capitulo, width = 26)
        ),
        ""
      )
    )

  # Semilla de posicionamiento: cada etiqueta se ancla en la posicion fijada en
  # anclas_rotulos_cuadrantes() (desplazamiento relativo a su punto, en
  # fracciones de la amplitud de cada eje). Asi las dos etiquetas de un mismo
  # capitulo no compiten por el mismo espacio y ggrepel solo resuelve los
  # solapamientos residuales.
  rango_x  <- diff(range(datos_graf$PEC))
  rango_y  <- diff(range(datos_graf$TLI))
  anclas   <- anclas_rotulos_cuadrantes()
  clave    <- paste(datos_graf$Capitulo, datos_graf$grupo)
  i_ancla  <- match(clave, paste(anclas$Capitulo, anclas$grupo))
  con_etiqueta <- nzchar(datos_graf$etiqueta) & !is.na(i_ancla)
  nudge_x <- ifelse(con_etiqueta, anclas$fx[i_ancla] * rango_x, 0)
  nudge_y <- ifelse(con_etiqueta, anclas$fy[i_ancla] * rango_y, 0)

  p <- ggplot(datos_graf, aes(x = PEC, y = TLI, color = grupo)) +
    geom_point(alpha = 0.7, size = 4) +
    ggrepel::geom_text_repel(
      aes(label = etiqueta),
      size = 3.6,
      show.legend = FALSE,
      position = ggrepel::position_nudge_repel(x = nudge_x, y = nudge_y),
      # Las etiquetas se mantienen sobre el eje x (y >= 0) y dentro del panel.
      ylim = c(0, NA),
      max.overlaps = Inf,
      min.segment.length = 0,
      box.padding = 0.30,
      point.padding = 0.30,
      force = 1,
      force_pull = 2,
      max.iter = 50000,
      segment.size = 0.35,
      direction = "both",
      seed = 2024
    ) +
    # Aire extra a la derecha y abajo: las etiquetas del borde derecho y las de
    # los puntos con PLI cercana a cero necesitan espacio dentro del panel.
    scale_x_continuous(expand = expansion(mult = c(0.03, 0.10))) +
    scale_y_continuous(expand = expansion(mult = c(0.04, 0.07))) +
    scale_color_manual(values = c("PI" = "#D32F2F", "PG" = "#1976D2"),
                       labels = c("PI" = "Pertenecientes a pueblos indígenas", "PG" = "Población general")) +
    # Tipografia mayor (peticion revisoras, item 49): base_size >= 12
    theme_bw(base_size = 14) +
    labs(
      title = "Severidad vs. Frecuencia de Hospitalización",
      subtitle = "Proporción de Letalidad Intrahospitalaria (PLI) vs. Proporción de Egresos por Causa (PEC)",
      x = "Proporción de Egresos por Causa (PEC %)",
      y = "Proporción de Letalidad Intrahospitalaria (PLI %)",
      color = "Población"
    ) +
    guides(color = guide_legend(nrow = 1, byrow = TRUE, override.aes = list(size = 4))) +
    theme(
      legend.position = "bottom",
      legend.title = element_text(size = 12),
      legend.text = element_text(size = 11),
      legend.box.margin = margin(t = 4, b = 4),
      plot.title = element_text(face = "bold"),
      plot.margin = margin(10, 16, 10, 10)
    )
  return(p)
}

#' Gráfico Convencional de Barras (Top PEC)
#' @export
grafico_barras_top_pec <- function(datos_obj4, grupo_obj = "PI", top_n = 10, y_max = NULL) {
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
    # Etiqueta de porcentaje mas grande (peticion revisoras, item 48)
    geom_text(aes(label = sprintf("%.1f%%", PEC)), hjust = -0.1, size = 4.5) +
    coord_flip() +
    theme_minimal(base_size = 12) +
    labs(
      title = sprintf("Top %d Causas de Hospitalización", top_n),
      subtitle = sprintf("Proporción de Egresos por Causa en %s", nombre_grupo),
      x = "",
      y = "Porcentaje (%)"
    ) +
    # y_max permite escala comun entre paneles; expansion mayor para no cortar el % (item 48)
    # mult superior 0.35: deja aire suficiente entre la etiqueta % de la barra maxima
    # y el borde derecho del panel (solicitud del autor: que no se superponga)
    scale_y_continuous(
      limits = if (!is.null(y_max)) c(0, y_max) else NULL,
      expand = expansion(mult = c(0, 0.35))
    ) +
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
#' @param text_size Tamaño del texto del eje Y (default 10).
#' @param scales Escalas de facet_wrap: "free_y" (default) libera las filas de
#'   capítulos por panel manteniendo el eje DPP común; "fixed" comparte ambos ejes.
#' @export
graficar_disparidades_facet <- function(datos_ind, var_facet, titulo,
                                        n_pos = NULL, n_neg = NULL,
                                        ncol = NULL, text_size = 10,
                                        scales = "free_y") {
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

  # Filas independientes por panel (equivalente manual de tidytext::reorder_within,
  # no instalado en este equipo): sufijo único por faceta, de modo que cada
  # capítulo es un nivel propio dentro de su panel, ordenado por BPP; las
  # etiquetas visibles remueven el sufijo. Requiere scales = "free_y" (default):
  # con coord_flip() y ggplot2 >= 3.5 libera el eje vertical desplegado
  # (capítulos) y el eje DPP (horizontal desplegado) se mantiene común.
  df_plot <- df_plot %>%
    dplyr::mutate(
      Capitulo_within = paste(Capitulo_wrap, !!rlang::sym(var_facet), sep = "___"),
      Capitulo_within = forcats::fct_reorder(Capitulo_within, BPP)
    )

  ggplot2::ggplot(df_plot, ggplot2::aes(x = Capitulo_within, y = BPP, fill = color_dif)) +
    ggplot2::geom_col() +
    ggplot2::scale_x_discrete(labels = function(x) sub("___.*$", "", x)) +
    # Escala libre por panel (scales = "free_y"): versión aprobada por el autor.
    # Con coord_flip() libera el eje de capítulos de cada panel (sin filas vacías),
    # mientras el eje DPP se mantiene común entre paneles (solo se libera y).
    ggplot2::facet_wrap(stats::as.formula(paste("~", var_facet)), scales = scales, ncol = ncol) +
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
      caption = "DPP > 0: el capítulo tiene mayor peso relativo en la población indígena.\nPI: población indígena; PG: población general.\nAnálisis por Evento Hospitalario. Chile 2010-2022. Excluye Cap. XV."
    ) +
    # Tipografia mayor (peticion revisoras, items 50 y 51)
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      strip.text      = ggplot2::element_text(face = "bold", size = 12),
      axis.text.y     = ggplot2::element_text(size = text_size)
    )
}

#' Heatmap Regional de Morbilidad Hospitalaria (TBE) en Población Indígena
#'
#' @param datos_ind Data frame con indicadores por región (output de calcular_indicadores_estratificados con var_estrato = "region").
#' @param titulo Título del gráfico. Se ignora cuando `sin_texto = TRUE`.
#' @param sin_texto Si TRUE, suprime título, bajada y nota del lienzo (el pie
#'   de figura del documento los aporta) y conserva ejes, leyenda y celdas
#'   (default: FALSE, el comportamiento vigente).
#' @param tamano_base Tamaño base (pt) del tema, que escala toda la tipografía
#'   del gráfico. Se reduce cuando la figura se inserta con un footprint menor
#'   que el lienzo de origen (default: 12, el valor vigente).
#' @export
graficar_heatmap_regional <- function(datos_ind, titulo, sin_texto = FALSE,
                                       tamano_base = 12) {
  tabla_regiones <- obtener_tabla_regiones()
  df_plot <- datos_ind %>%
    dplyr::filter(grupo == "PI") %>%
    # Capa corregida de capitulos: la categoria residual "Otros" (1 egreso
    # sin DIAG1 en toda la serie 2010-2022) no es un capitulo CIE-10 y se
    # excluye de la figura (exclusion declarada en el pie).
    dplyr::filter(Capitulo != "Otros") %>%
    dplyr::mutate(
      nombre_region = codigo_a_nombre_region(region, tipo = "corto"),
      nombre_region = factor(nombre_region, levels = tabla_regiones$nombre_corto),
      Capitulo_wrap = stringr::str_wrap(Capitulo, width = 30)
    )

  # Totalidad de capitulos (22 menos el XV, excluido por diseno "sin_op").
  # Cap. XX (Causas externas de morbilidad y mortalidad) no registra egresos
  # en la serie: se muestra como fila vacia (gris) para que la figura cubra
  # los 21 capitulos, en coherencia con la Tabla 8 del manuscrito.
  cap_xx <- "Causas externas de morbilidad y mortalidad"
  if (!cap_xx %in% df_plot$Capitulo) {
    filas_xx <- data.frame(
      nombre_region = factor(tabla_regiones$nombre_corto,
                             levels = tabla_regiones$nombre_corto),
      Capitulo_wrap = stringr::str_wrap(cap_xx, width = 30),
      TBE = NA_real_
    )
    df_plot <- dplyr::bind_rows(df_plot, filas_xx)
  }

  df_plot %>%
    ggplot2::ggplot(ggplot2::aes(x = nombre_region, y = Capitulo_wrap, fill = TBE)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::scale_fill_distiller(palette = "YlOrRd", direction = 1, name = "TBE anual x 1.000 hab.", na.value = "grey90") +
    ggplot2::labs(
      title    = if (sin_texto) NULL else titulo,
      subtitle = if (sin_texto) NULL else
        "Tasa Bruta de Egresos (TBE) anual por 1.000 hab. en Población Indígena",
      x = NULL, y = NULL,
      caption = if (sin_texto) NULL else
        "Excluye Cap. XV. Cap. XX no registra egresos en la serie (fila vacía). Se excluye la categoría residual 'Otros' (n = 1). Regiones ordenadas de Norte a Sur."
    ) +
    ggplot2::theme_minimal(base_size = tamano_base) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1,
                                          size = 0.75 * tamano_base),
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
        axis.text.x = ggplot2::element_text(size = 12),
        plot.subtitle = ggplot2::element_text(face = "bold", size = 13)
      )
  }

  # Escala comun entre paneles (peticion revisoras, item 48):
  # ambos paneles comparten el limite del eje segun el mayor PEC del top N
  y_max_panel <- datos_obj4 %>%
    dplyr::group_by(grupo) %>%
    dplyr::slice_max(PEC, n = top_n, with_ties = FALSE) %>%
    dplyr::ungroup() %>%
    dplyr::summarise(m = max(PEC, na.rm = TRUE)) %>%
    dplyr::pull(m)

  p_pi <- ajustar(grafico_barras_top_pec(datos_obj4, grupo_obj = "PI", top_n = top_n, y_max = y_max_panel),
                  "Pertenecientes a pueblos indígenas")
  p_pg <- ajustar(grafico_barras_top_pec(datos_obj4, grupo_obj = "PG", top_n = top_n, y_max = y_max_panel),
                  "Población general")

  (p_pi | p_pg) +
    patchwork::plot_annotation(
      title = sprintf("Principales %d causas de egreso hospitalario por capítulo CIE-10", top_n),
      theme = ggplot2::theme(plot.title = ggplot2::element_text(size = 15, face = "bold"))
    )
}
