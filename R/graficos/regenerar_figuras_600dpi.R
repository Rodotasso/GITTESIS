# ==============================================================================
# SCRIPT: regenerar_figuras_600dpi.R
# ==============================================================================
#
# DESCRIPCIÓN:
#   Regenera a 600 dpi las figuras del Objetivo 4 que el documento de tesis
#   necesita reinsertar (el .docx devuelto por las revisoras perdió el 63% de
#   los bytes de imagen).
#
#   No introduce análisis nuevos: reutiliza exactamente los mismos indicadores y
#   funciones de graficado que los drivers ya existentes del proyecto:
#     - DOCUMENTOS TESIS/FINAL-TESIS/figuras_nuevas/scripts/
#         perfiles_diagnosticos_objetivo4.qmd
#         perfiles_diagnosticos_desagregados_sin_op.qmd
#     - R/graficos/grafico_evolucion_prevision_po.R
#   La única diferencia respecto de esos drivers es el device de salida:
#   PNG/JPG a 600 dpi en lugar de JPG a 300 dpi.
#
#   Las funciones de graficado se sourcean desde las copias CORREGIDAS de
#   `figuras_nuevas/scripts/` (peticiones de las revisoras), que sobrescriben
#   las versiones de `R/graficos/` en la sesión, igual que hacen los drivers.
#
#   Correcciones aplicadas (pasada de figuras pendientes, comentarios S&A):
#     - Bloque 0: la Figura 6 real del manuscrito es el gráfico de BARRAS
#       APILADAS de previsión (paleta de graf_cie_prev_modular.qmd), no el de
#       líneas de grafico_evolucion_prevision_po(); etiquetas agrandadas
#       (comentarios 109 y 110).
#     - Figura 7: el gráfico divergente NO es la Figura 7 del docx (esa es el
#       ensamblado forest plot + heatmap de R/funciones/visualizaciones_cie10.R,
#       embebido desde resultados_tesis/final_resultados/Figura_3E_forest_heatmap.jpg).
#       Se regenera como paneles LADO A LADO (A | B) en el footprint de
#       inserción 7,2 x 4,2 in, con fuentes dimensionadas a ese tamaño y panel B
#       sin etiquetas de eje y (comentarios 115 y 117; plan de figuras
#       2026-10-31, sección 5). El divergente se sigue exportando como
#       `divergente_dpp_po_vs_pg` (no es figura del docx;
#       su rol quedó pendiente de confirmación del autor).
#     - Figura 10: título embebido alineado al pie del docx (comentario 124).
#     - Figura 13: dumbbell PI vs PG por región y sexo; la FORMA distingue la
#       población y el COLOR el sexo (comentario 127). Se conserva el orden de
#       regiones norte-sur ya presente en la figura embebida.
#
#   Segunda pasada (QA visual de los PNG regenerados):
#     - Figuras 7 y S5: marcadores y barras de IC dimensionados al footprint
#       (2,4 mm y 0,5 mm, la proporción de la referencia de geometría
#       Figura_3E_forest_heatmap) y etiquetas de valor a la derecha del IC
#       (`etiquetas_al_derecho = TRUE`), porque centradas sobre el punto se
#       superponían entre filas contiguas y quedaban bajo el marcador.
#     - Figuras 2, 6, 12 y 13: sin título, bajada, nota ni fuente quemados
#       (los aporta el pie del docx) y regeneradas en su footprint de inserción
#       (7,01 x 4,49; 6,27 x 3,92; 7,31 x 4,87; 7,32 x 5,32 in) con la
#       tipografía escalada a ese tamaño.
#
# ENTRADA:
#   BBDD_homologados.RData -> objeto `datos_homologados` (~940 MB).
#   Verificar headroom de memoria antes de ejecutar.
#
# SALIDA (600 dpi, PNG + JPG):
#   DOCUMENTOS TESIS/FINAL-TESIS/figuras_nuevas/salida/600dpi/
#     figura_2_tendencia_mensual_fuentes          (.png/.jpg)
#     figura_6_evolucion_prevision_po            (.png/.jpg)  barras apiladas
#     figura_7_forest_heatmap_vertical           (.png/.jpg)  paneles A|B lado a lado
#                                                              (nombre historico: ya no es vertical)
#     divergente_dpp_po_vs_pg                    (.png/.jpg)  (no es figura del docx)
#     figura_8_top_causas_panel_po_pg            (.png/.jpg)
#     figura_9_cuadrantes_severidad              (.png/.jpg)
#     figura_10_disparidades_sexo_sin_op         (.png/.jpg)
#     figura_11_disparidades_edad_sin_op         (.png/.jpg)
#     figura_12_heatmap_regional_tbe_sin_op      (.png/.jpg)
#     figura_13_dumbbell_tbe_region_sexo         (.png/.jpg)  dumbbell (cmt 127)
#     figura_dumbbell_pec_po_vs_pg               (.png/.jpg)
#
# USO:
#   Rscript "R/graficos/regenerar_figuras_600dpi.R"
#
# ==============================================================================

# --- Raíz del proyecto (patrón project_root; prohibido "../../") --------------
if (!exists("project_root")) {
  project_root <- rprojroot::find_root(rprojroot::has_file("BBDD_homologados.RData"))
}

# --- Utilidades del repo ------------------------------------------------------
source(file.path(project_root, "R", "cargar_funciones.R"))
source(file.path(project_root, "R", "funciones", "ordenar_regiones.R"))

# Versiones corregidas (peticiones de las revisoras): sobrescriben las de R/graficos
dir_scripts <- file.path(
  project_root, "DOCUMENTOS TESIS", "FINAL-TESIS", "figuras_nuevas", "scripts"
)
source(file.path(dir_scripts, "graficos_objetivo4.R"))

# Figura 7: funciones originales + copias corregidas (fuentes agrandadas y
# heatmap con `sin_etiquetas_y`; comentarios 115, 116 y 117)
source(file.path(project_root, "R", "funciones", "visualizaciones_cie10.R"))
source(file.path(dir_scripts, "visualizaciones_cie10_fig7.R"))

# --- Constantes ---------------------------------------------------------------
OUT_DIR <- file.path(
  project_root, "DOCUMENTOS TESIS", "FINAL-TESIS", "figuras_nuevas", "salida",
  "600dpi"
)
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)

DPI <- 600L

# ==============================================================================
# FUNCIÓN: guardar_figura_600
# ==============================================================================
# Guarda PNG a 600 dpi y deriva el JPG con magick (calidad 95).
# Motivo: el device JPEG de ggsave escribe JPEG en espacio RGB con marcador
# APP14 (Adobe) y en este equipo los decodificadores que lo ignoran muestran
# colores invertidos (fondo magenta). Es el mismo workaround que ya usan los
# tres scripts de sesgo de supervivencia del repo.
guardar_figura_600 <- function(plot, nombre_base, ancho = 10, alto = 6,
                               dpi = DPI, dir_salida = OUT_DIR) {
  if (!dir.exists(dir_salida)) dir.create(dir_salida, recursive = TRUE)
  ruta_png <- file.path(dir_salida, paste0(nombre_base, ".png"))
  ruta_jpg <- file.path(dir_salida, paste0(nombre_base, ".jpg"))
  ggplot2::ggsave(ruta_png, plot, width = ancho, height = alto, dpi = dpi,
                  bg = "white")
  img <- magick::image_read(ruta_png)
  magick::image_write(img, ruta_jpg, format = "jpeg", quality = 95)
  cat("  OK ", nombre_base, ".png/.jpg (", dpi, " dpi)\n", sep = "")
  invisible(c(png = ruta_png, jpg = ruta_jpg))
}

# ==============================================================================
# EJECUCIÓN
# ==============================================================================
main <- function() {
  cat("================================================================================\n")
  cat("REGENERACIÓN DE FIGURAS A 600 DPI (OBJETIVO 4)\n")
  cat("================================================================================\n\n")

  datos_homologados <- cargar_datos_homologados()
  data.table::setDT(datos_homologados)

  # Aserciones de contrato sobre la base (baratas)
  req_cols <- c("RUN", "PERTENENCIA2", "COND_EGR", "FECHA_EGRESO_FMT_DEIS",
                "FECHA_INGRESO_FMT_DEIS", "Grupo_CIE10", "AÑO", "CODIGO_REGION",
                "GLOSA_SEXO", "EDAD_ANOS", "GLOSA_PREVISION",
                "RSH", "CONADI", "PUEBLO_ORIGINARIO_BIN")
  stopifnot("Faltan columnas en la base homologada" =
              all(req_cols %in% names(datos_homologados)))

  # ---------------------------------------------------------------------------
  # BLOQUE 0: evolución anual de la previsión en población indígena (Figura 6)
  # ---------------------------------------------------------------------------
  # Réplica del gráfico de barras apiladas que está embebido en el docx
  # (paleta específica FONASA/ISAPRE de graf_cie_prev_modular.qmd §3).
  # Versión revista: sin título ni nota embebidos, igual que la imagen
  # actualmente en el documento.
  # Denominador: las 5 categorías mostradas (verificado contra la imagen
  # embebida: 2010 FONASA A = 56,8% solo cuadra con ese denominador). Así cada
  # año suma 100%; "Otro" (231.705 egresos) y "FONASA" sin tramo (700) quedan
  # fuera del denominador, igual que en la figura revisada por las revisoras.
  # Comentarios 109 y 110: porcentajes dentro de las barras agrandados
  # (size 3.5 -> 5) y con color de texto según contraste del relleno
  # (blanco solo sobre FONASA D, que es el relleno más oscuro).
  cat("-- Bloque 0: evolución de previsión en población indígena (Figura 6) --\n")

  colores_prevision_especificos <- c(
    "FONASA A" = "#FF9999",  # Rosa salmón
    "FONASA B" = "#9ACD32",  # Verde oliva/amarillento
    "FONASA C" = "#48D1CC",  # Turquesa
    "FONASA D" = "#4169E1",  # Azul real
    "ISAPRE"   = "#DA70D6"   # Orquídea/magenta
  )

  datos_prev <- datos_homologados[, c("AÑO", "PERTENENCIA2", "GLOSA_PREVISION"),
                                  with = FALSE] %>%
    tibble::as_tibble() %>%
    dplyr::filter(AÑO != "No reportado", PERTENENCIA2 == 1,
                  GLOSA_PREVISION %in% names(colores_prevision_especificos)) %>%
    dplyr::group_by(AÑO, GLOSA_PREVISION) %>%
    dplyr::summarise(n_casos = dplyr::n(), .groups = "drop") %>%
    dplyr::group_by(AÑO) %>%
    dplyr::mutate(
      total_anio = sum(n_casos),
      porcentaje = (n_casos / total_anio) * 100
    ) %>%
    dplyr::ungroup() %>%
    # Posición vertical de las etiquetas calculada a mano (centro de cada
    # segmento), en vez de position_stack(): en ggplot2 4.x position_stack()
    # en geom_text reordena los grupos cuando hay estéticas adicionales y las
    # etiquetas quedan desplazadas respecto de sus segmentos (detectado en QA
    # visual; verificado con layer_data). Con position = "identity" la
    # correspondencia etiqueta-segmento es exacta y determinista.
    # Orden de apilado: ISAPRE abajo, luego FONASA D, C, B y A arriba
    # (geom_bar con position_stack apila el primer nivel del fill arriba).
    dplyr::arrange(AÑO, match(GLOSA_PREVISION, rev(names(colores_prevision_especificos)))) %>%
    dplyr::group_by(AÑO) %>%
    dplyr::mutate(y_etiqueta = cumsum(porcentaje) - porcentaje / 2) %>%
    dplyr::ungroup() %>%
    # Color de etiqueta por contraste: negro salvo sobre el relleno más oscuro
    dplyr::mutate(
      color_txt = ifelse(GLOSA_PREVISION == "FONASA D", "white", "black")
    )

  p_prev <- ggplot2::ggplot(
    datos_prev,
    ggplot2::aes(x = AÑO, y = porcentaje, fill = GLOSA_PREVISION)
  ) +
    ggplot2::geom_bar(stat = "identity", position = "stack", width = 0.8) +
    ggplot2::geom_text(
      ggplot2::aes(y = y_etiqueta, label = sprintf("%.1f%%", porcentaje),
                   color = color_txt),
      position = "identity",
      size = 2.6, fontface = "bold", show.legend = FALSE
    ) +
    ggplot2::scale_color_identity() +
    ggplot2::scale_fill_manual(values = colores_prevision_especificos) +
    ggplot2::scale_y_continuous(
      labels = function(x) paste0(x, "%"),
      breaks = seq(0, 100, by = 25),
      expand = c(0, 0)
    ) +
    ggplot2::labs(x = "Año", y = "Porcentaje (%)", fill = "Previsión") +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 7),
      axis.text.y = ggplot2::element_text(size = 7),
      axis.title = ggplot2::element_text(size = 8, face = "bold"),
      legend.title = ggplot2::element_text(size = 7.5, face = "bold"),
      legend.text = ggplot2::element_text(size = 7)
    )

  # Footprint de inserción en el docx (6,27 x 3,92 in). La tipografía se
  # dimensiona para ese tamaño y no para un lienzo grande que luego se reduce
  # (comentarios 109 y 110: etiquetas dentro de las barras legibles al tamaño
  # final). La imagen no lleva título, bajada, nota ni fuente quemados: los
  # aporta el pie de figura del documento.
  guardar_figura_600(p_prev, "figura_6_evolucion_prevision_po",
                     ancho = 6.27, alto = 3.92)
  rm(datos_prev, p_prev)
  gc(verbose = FALSE)

  # ---------------------------------------------------------------------------
  # BLOQUE 1: perfiles de mortalidad y carga por capítulo (driver objetivo4)
  # ---------------------------------------------------------------------------
  cat("-- Bloque 1: indicadores del Objetivo 4 --\n")

  censo_lista <- obtener_poblacion_censo(verbose = FALSE)
  censo_df <- tibble::tibble(
    grupo     = c("PI", "PG"),
    poblacion = c(censo_lista$pob_po, censo_lista$pob_pg)
  )

  cols_obj4 <- c("PERTENENCIA2", "COND_EGR", "FECHA_EGRESO_FMT_DEIS",
                 "FECHA_INGRESO_FMT_DEIS", "Grupo_CIE10")
  datos_base <- datos_homologados[, cols_obj4, with = FALSE]
  datos_base$FECHA_EGRESO_FMT_DEIS  <- as.Date(datos_base$FECHA_EGRESO_FMT_DEIS)
  datos_base$FECHA_INGRESO_FMT_DEIS <- as.Date(datos_base$FECHA_INGRESO_FMT_DEIS)

  datos_analisis_obj4 <- datos_base %>%
    tibble::as_tibble() %>%
    dplyr::mutate(
      DIAS_ESTADA = as.numeric(FECHA_EGRESO_FMT_DEIS - FECHA_INGRESO_FMT_DEIS)
    ) %>%
    dplyr::rename(Capitulo = Grupo_CIE10) %>%
    dplyr::filter(!is.na(Capitulo))
  rm(datos_base)
  gc(verbose = FALSE)

  resultados_obj4 <- calcular_indicadores_objetivo4(
    datos               = datos_analisis_obj4,
    denominadores_censo = censo_df,
    col_pertenencia     = "PERTENENCIA2",
    anos_estudio        = 13,
    verbose             = FALSE
  )

  guardar_figura_600(grafico_barras_top_pec_panel(resultados_obj4, top_n = 10),
                     "figura_8_top_causas_panel_po_pg", ancho = 14, alto = 7)
  # El gráfico divergente NO corresponde a ninguna figura del docx (su rol
  # quedó pendiente de confirmación del autor): se exporta sin prefijo
  # "figura_" para que no se confunda con la Figura 7 verdadera.
  guardar_figura_600(grafico_divergente_bpp(resultados_obj4),
                     "divergente_dpp_po_vs_pg", ancho = 10, alto = 6)
  guardar_figura_600(grafico_cuadrantes_severidad(resultados_obj4),
                     "figura_9_cuadrantes_severidad", ancho = 10, alto = 6)
  guardar_figura_600(grafico_dumbbell_pec(resultados_obj4, top_n = 15),
                     "figura_dumbbell_pec_po_vs_pg", ancho = 10, alto = 6)

  rm(datos_analisis_obj4, resultados_obj4, censo_df)
  gc(verbose = FALSE)

  # ---------------------------------------------------------------------------
  # BLOQUE 1b: Figura 7 verdadera (forest plot IC95% + heatmap temporal)
  # ---------------------------------------------------------------------------
  # La Figura 7 del docx se embebe desde
  # resultados_tesis/final_resultados/Figura_3E_forest_heatmap.jpg (pipeline del
  # artículo, may-2026), ensamblada con crear_forest_plot_cie10() y
  # crear_heatmap_temporal() sobre preparar_datos_disparidades_cie10().
  # Comentarios aplicados (versiones corregidas en
  # figuras_nuevas/scripts/visualizaciones_cie10_fig7.R):
  #   115: fuentes agrandadas en ambos paneles.
  #   116: panel layout fijado por el plan de figuras 2026-10-31 (sección 5):
  #        paneles LADO A LADO (A | B) en un footprint de 7,2 x 4,2 in, que es
  #        el tamaño final de inserción en el docx (página vertical, ancho de
  #        caja 7,32 in). La tipografía se dimensiona para ese footprint y no
  #        para un lienzo grande que luego se reduce.
  #   117: panel B sin etiquetas de eje y (repetían las del panel A).
  cat("-- Bloque 1b: Figura 7 (forest | heatmap, 7,2 x 4,2 in) --\n")

  datos_disparidades <- preparar_datos_disparidades_cie10(datos_homologados)

  # Exclusiones documentadas (diagnóstico empírico sobre la base cargada):
  # - "Otros": categoría residual de la capa de clasificación (1 egreso sin
  #   clasificar en toda la serie); no es un capítulo CIE-10 y su diferencia
  #   (+68,5 pp) es un artefacto de n = 1.
  # - "Códigos para situaciones especiales" (cap. XXII): sin serie válida
  #   antes de 2020 (2 egresos en 2013 y 6 en 2014; los 167.721 restantes son
  #   2020-2022), por lo que sus celdas pre-2020 son ruido de números pequeños
  #   y su diferencia promedio cubre solo 41 meses (vs 156 del resto de
  #   capítulos), lo que rompe la comparabilidad temporal que esta figura
  #   muestra (evolución año a año 2010-2022). Los 9 capítulos restantes
  #   reproducen exactamente los valores de la figura embebida en el docx.
  excluir_fig7 <- c("Otros", "Códigos para situaciones especiales")
  datos_disparidades$datos_cie10_resumen <- datos_disparidades$datos_cie10_resumen %>%
    dplyr::filter(!Grupo_CIE10 %in% excluir_fig7)
  datos_disparidades$datos_cie10_anual <- datos_disparidades$datos_cie10_anual %>%
    dplyr::filter(!Grupo_CIE10 %in% excluir_fig7)
  datos_disparidades$datos_cie10_mensual <- datos_disparidades$datos_cie10_mensual %>%
    dplyr::filter(!Grupo_CIE10 %in% excluir_fig7)

  # wrap_y = 40 y valores de celda/etiqueta reducidos: al compartir el ancho
  # del lienzo, las etiquetas de capítulo y los números de las celdas tienen
  # menos espacio por fila y por columna que en la versión apilada (13 años en
  # la mitad del lienzo => celda de ~0,19 in).
  # Marcadores, barras y etiquetas dimensionados al footprint (verificados
  # contra la referencia de geometría Figura_3E_forest_heatmap: el diámetro del
  # marcador y el cuerpo de la etiqueta de valor están en la misma proporción,
  # 0,92, y la etiqueta va al costado del punto). Con 9 filas en 4,2 in el paso
  # vertical es de ~3,6 mm: un marcador de 4,5 mm (el default de lienzo
  # grande) tapa su propia etiqueta y la de la fila contigua, y el IC queda
  # oculto bajo el marcador.
  p_forest  <- crear_forest_plot_cie10(datos_disparidades, version_revista = TRUE,
                                      wrap_y = 40, tamano_valor = 2.6,
                                      tamano_punto = 2.4, grosor_barra = 0.5,
                                      etiquetas_al_derecho = TRUE,
                                      espacio_etiqueta = 0.42)
  p_heatmap <- crear_heatmap_temporal(datos_disparidades, version_revista = TRUE,
                                      sin_etiquetas_y = TRUE, tamano_celda = 1.9)

  # Tipografía dimensionada para el footprint final (7,2 x 4,2 in): sin título,
  # bajada, nota ni fuente (los pone el pie del docx). Las leyendas van al pie
  # de cada panel para que no compitan por el ancho con las etiquetas de eje.
  p_forest <- p_forest +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 8.5, hjust = 1),
    axis.text.x = ggplot2::element_text(size = 7),
      axis.title.x = ggplot2::element_text(size = 8.5, face = "bold"),
      legend.text = ggplot2::element_text(size = 8),
      legend.position = "bottom",
      plot.margin = ggplot2::margin(4, 3, 2, 2)
    ) +
    ggplot2::guides(color = ggplot2::guide_legend(ncol = 1))

  p_heatmap <- p_heatmap +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(size = 8, angle = 45, hjust = 1),
      axis.title.x = ggplot2::element_text(size = 8.5, face = "bold"),
      legend.text = ggplot2::element_text(size = 8),
      legend.title = ggplot2::element_text(size = 8, face = "bold"),
      legend.title.position = "top",
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.key.width = grid::unit(1.3, "lines"),
      legend.key.height = grid::unit(0.6, "lines"),
      plot.margin = ggplot2::margin(4, 2, 2, 2)
    )

  p_fig7 <- ((p_forest | p_heatmap) +
    patchwork::plot_layout(widths = c(0.95, 1.10)) +
    patchwork::plot_annotation(tag_levels = "A")) &
    ggplot2::theme(plot.tag = ggplot2::element_text(size = 11, face = "bold"))

  guardar_figura_600(p_fig7, "figura_7_forest_heatmap_vertical",
                     ancho = 7.2, alto = 4.2)

  rm(datos_disparidades, p_forest, p_heatmap, p_fig7)
  gc(verbose = FALSE)

  # ---------------------------------------------------------------------------
  # BLOQUE 1c: Figura S5 (totalidad de capitulos CIE-10, paneles lado a lado)
  # ---------------------------------------------------------------------------
  # La Figura S5 del docx extiende la Figura 7 a la totalidad de los capitulos
  # CIE-10, pero la version embebida (pipeline del articulo, may-2026,
  # Figura_4E_forest_heatmap) conserva los paneles horizontales y la fila
  # "Otros" del clasificador antiguo. Se regenera con la misma logica de la
  # Figura 7 (comentarios 115-117 y plan de figuras 2026-10-31: paneles lado a
  # lado, fuentes dimensionadas al footprint, panel B sin etiquetas de eje y)
  # usando umbral = 0 (sin filtro por
  # magnitud de la diferencia => totalidad de capitulos presentes en la
  # base). Mismas exclusiones documentadas que la Figura 7: "Otros"
  # (residual, n = 1) y cap. XXII (serie valida solo 2020-2022). El cap. XX
  # no registra egresos y no genera fila (a diferencia de la Figura 12, aqui
  # no hay denominador territorial que justifique mostrar una fila vacia).
  cat("-- Bloque 1c: Figura S5 (totalidad de capitulos, 9,3 x 6,2 in) --\n")

  datos_s5 <- preparar_datos_disparidades_cie10(datos_homologados, umbral = 0)
  excluir_s5 <- c("Otros", "Códigos para situaciones especiales")
  datos_s5$datos_cie10_resumen <- datos_s5$datos_cie10_resumen %>%
    dplyr::filter(!Grupo_CIE10 %in% excluir_s5)
  datos_s5$datos_cie10_anual <- datos_s5$datos_cie10_anual %>%
    dplyr::filter(!Grupo_CIE10 %in% excluir_s5)
  datos_s5$datos_cie10_mensual <- datos_s5$datos_cie10_mensual %>%
    dplyr::filter(!Grupo_CIE10 %in% excluir_s5)

  p_forest_s5  <- crear_forest_plot_cie10(datos_s5, version_revista = TRUE,
                                          wrap_y = 40, tamano_valor = 2.6,
                                          tamano_punto = 2.4, grosor_barra = 0.5,
                                          etiquetas_al_derecho = TRUE,
                                          espacio_etiqueta = 0.40)
  p_heatmap_s5 <- crear_heatmap_temporal(datos_s5, version_revista = TRUE,
                                         sin_etiquetas_y = TRUE,
                                         tamano_celda = 2.7)

  # Tipografia dimensionada para el footprint final (9,3 x 6,2 in, pagina
  # landscape del docx). Con 20 capitulos las etiquetas del eje y ocupan hasta
  # 2 lineas por fila: 8 pt es el maximo que evita el solape entre filas a
  # 6,2 in de alto, y 8,5 pt el de los anios del heatmap.
  p_forest_s5 <- p_forest_s5 +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 8, hjust = 1),
      axis.text.x = ggplot2::element_text(size = 8.5),
      axis.title.x = ggplot2::element_text(size = 9, face = "bold"),
      legend.text = ggplot2::element_text(size = 8),
      legend.position = "bottom",
      plot.margin = ggplot2::margin(4, 3, 2, 2)
    ) +
    ggplot2::guides(color = ggplot2::guide_legend(ncol = 3))

  p_heatmap_s5 <- p_heatmap_s5 +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(size = 8.5, angle = 45, hjust = 1),
      axis.title.x = ggplot2::element_text(size = 9, face = "bold"),
      legend.text = ggplot2::element_text(size = 8),
      legend.title = ggplot2::element_text(size = 8, face = "bold"),
      legend.title.position = "top",
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.key.width = grid::unit(1.6, "lines"),
      legend.key.height = grid::unit(0.6, "lines"),
      plot.margin = ggplot2::margin(4, 2, 2, 2)
    )

  p_s5 <- ((p_forest_s5 | p_heatmap_s5) +
    patchwork::plot_layout(widths = c(1, 1)) +
    patchwork::plot_annotation(tag_levels = "A")) &
    ggplot2::theme(plot.tag = ggplot2::element_text(size = 11, face = "bold"))

  guardar_figura_600(p_s5, "figura_S5_forest_heatmap_vertical_todas",
                     ancho = 9.3, alto = 6.2)

  rm(datos_s5, p_forest_s5, p_heatmap_s5, p_s5)
  gc(verbose = FALSE)

  # ---------------------------------------------------------------------------
  # BLOQUE 2: perfiles desagregados sin capítulo XV (driver desagregados_sin_op)
  # ---------------------------------------------------------------------------
  cat("-- Bloque 2: indicadores estratificados sin salud materna --\n")

  censo_estratos <- extraer_datos_censo(verbose = FALSE, responders_only = TRUE)

  cols_estrato <- c("PERTENENCIA2", "COND_EGR", "FECHA_EGRESO_FMT_DEIS",
                    "FECHA_INGRESO_FMT_DEIS", "Grupo_CIE10", "AÑO",
                    "CODIGO_REGION", "GLOSA_SEXO", "EDAD_ANOS")

  datos_analisis <- datos_homologados[, cols_estrato, with = FALSE] %>%
    tibble::as_tibble() %>%
    dplyr::mutate(
      DIAS_ESTADA = as.numeric(as.Date(FECHA_EGRESO_FMT_DEIS) -
                                 as.Date(FECHA_INGRESO_FMT_DEIS)),
      Capitulo = Grupo_CIE10,
      sexo = GLOSA_SEXO,
      grupo_etario = dplyr::case_when(
        EDAD_ANOS <  5  ~ "0-4",
        EDAD_ANOS < 15  ~ "5-14",
        EDAD_ANOS < 25  ~ "15-24",
        EDAD_ANOS < 45  ~ "25-44",
        EDAD_ANOS < 65  ~ "45-64",
        EDAD_ANOS < 75  ~ "65-74",
        EDAD_ANOS >= 75 ~ "75+",
        TRUE ~ NA_character_
      ),
      region = as.numeric(CODIGO_REGION)
    ) %>%
    dplyr::filter(!stringr::str_detect(Capitulo, "Embarazo, parto y puerperio")) %>%
    dplyr::filter(!is.na(Capitulo), !is.na(sexo),
                  !is.na(grupo_etario), !is.na(region))
  gc(verbose = FALSE)

  # Figura 10: disparidades por sexo
  ind_sexo <- calcular_indicadores_estratificados(
    datos          = datos_analisis,
    denominador_df = preparar_denominador_estrato(censo_estratos$por_sexo),
    var_estrato    = "sexo"
  )
  # Comentario 124: el título embebido se alinea al pie de figura del docx
  # (antes decía "Desigualdades por Sexo (Excluyendo Salud Materna)").
  guardar_figura_600(
    graficar_disparidades_facet(
      ind_sexo, "sexo",
      "Desigualdades por sexo (sin capítulo de Embarazo, parto y puerperio)",
      n_pos = 3, n_neg = 3
    ),
    "figura_10_disparidades_sexo_sin_op", ancho = 12, alto = 7
  )

  # Figura 11: disparidades por grupo etario
  ind_edad <- calcular_indicadores_estratificados(
    datos          = datos_analisis,
    denominador_df = preparar_denominador_estrato(censo_estratos$por_grupo_etario),
    var_estrato    = "grupo_etario"
  ) %>%
    dplyr::mutate(
      grupo_etario = factor(
        grupo_etario,
        levels = c("0-4", "5-14", "15-24", "25-44", "45-64", "65-74", "75+")
      )
    )
  guardar_figura_600(
    graficar_disparidades_facet(
      ind_edad, "grupo_etario",
      "Desigualdades por Grupo Etario (Sin Salud Materna)",
      n_pos = 3, n_neg = 3, ncol = 2, text_size = 10, scales = "free_y"
    ),
    "figura_11_disparidades_edad_sin_op", ancho = 11, alto = 13
  )

  # Figura 12: heatmap regional de TBE
  ind_region <- calcular_indicadores_estratificados(
    datos          = datos_analisis,
    denominador_df = preparar_denominador_estrato(censo_estratos$por_region),
    var_estrato    = "region"
  )
  # Footprint de inserción en el docx (7,31 x 4,87 in) y sin título, bajada ni
  # nota quemados: los aporta el pie de figura del documento. `tamano_base`
  # escala la tipografía completa del gráfico para ese footprint (con el
  # default 12 el texto queda a ~5 pt al tamaño de inserción).
  guardar_figura_600(
    graficar_heatmap_regional(
      ind_region, titulo = NULL, sin_texto = TRUE, tamano_base = 7.5
    ),
    "figura_12_heatmap_regional_tbe_sin_op", ancho = 7.31, alto = 4.87
  )

  # Figura 13: TBE por región y sexo, PI vs PG (regiones ordenadas de norte a sur)
  ind_sexo_reg <- calcular_indicadores_estratificados(
    datos          = datos_analisis,
    denominador_df = preparar_denominador_estrato(censo_estratos$region_sexo),
    var_estrato    = c("sexo", "region")
  )

  tabla_regiones <- obtener_tabla_regiones()

  # Comentario 127: dumbbell en lugar de barras. La FORMA del punto distingue
  # la población (PI círculo, PG triángulo) y el COLOR se mantiene para el sexo
  # (un panel por sexo, con la paleta colores_sexo del proyecto). Se conserva
  # el orden norte-sur de regiones ya presente en la figura embebida (norte
  # arriba: niveles invertidos porque ggplot despliega el primer nivel abajo).
  datos_dumbbell_rs <- ind_sexo_reg %>%
    dplyr::filter(grupo %in% c("PI", "PG")) %>%
    dplyr::group_by(grupo, region, sexo) %>%
    dplyr::summarise(TBE_global = sum(TBE), .groups = "drop") %>%
    dplyr::mutate(
      nombre_region = codigo_a_nombre_region(region, tipo = "corto"),
      nombre_region = factor(nombre_region,
                             levels = rev(tabla_regiones$nombre_corto)),
      grupo = factor(grupo, levels = c("PI", "PG"),
                     labels = c("Población indígena", "Población general")),
      sexo = factor(sexo, levels = c("HOMBRE", "MUJER"))
    )

  datos_segmentos_rs <- datos_dumbbell_rs %>%
    dplyr::select(nombre_region, sexo, grupo, TBE_global) %>%
    tidyr::pivot_wider(names_from = grupo, values_from = TBE_global)

  p_sexo_region <- ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = datos_segmentos_rs,
      ggplot2::aes(x = `Población general`, xend = `Población indígena`,
                   y = nombre_region, yend = nombre_region),
      color = "gray60", linewidth = 0.5
    ) +
    ggplot2::geom_point(
      data = datos_dumbbell_rs,
      ggplot2::aes(x = TBE_global, y = nombre_region,
                   shape = grupo, color = sexo),
      size = 2
    ) +
    ggplot2::facet_wrap(~ sexo) +
    ggplot2::scale_shape_manual(
      values = c("Población indígena" = 16, "Población general" = 17)
    ) +
    ggplot2::scale_color_manual(
      values = c("HOMBRE" = colores_sexo[["HOMBRE"]],
                 "MUJER"  = colores_sexo[["MUJER"]])
    ) +
    # Sin título, bajada ni nota quemados: los aporta el pie de figura del
    # documento. Se conservan la leyenda de símbolos (población) y la de sexo.
    ggplot2::labs(
      x = "TBE anual por 1.000 hab.",
      y = NULL,
      shape = "Población",
      color = "Sexo"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.y = element_text(size = 7),
      axis.text.x = element_text(size = 7),
      axis.title.x = element_text(size = 8, face = "bold"),
      strip.text = element_text(face = "bold", size = 8),
      legend.position = "bottom",
      legend.title = element_text(size = 7.5, face = "bold"),
      legend.text = element_text(size = 7),
      panel.grid.minor = ggplot2::element_blank()
    )
  # Footprint de inserción en el docx (7,32 x 5,32 in).
  guardar_figura_600(p_sexo_region, "figura_13_dumbbell_tbe_region_sexo",
                     ancho = 7.32, alto = 5.32)

  rm(datos_analisis, ind_sexo, ind_edad, ind_region, ind_sexo_reg,
     datos_dumbbell_rs, datos_segmentos_rs, p_sexo_region, censo_estratos)
  gc(verbose = FALSE)

  # ---------------------------------------------------------------------------
  # BLOQUE 3: tendencia mensual de pertenencia por fuente (ex Figura 5)
  # ---------------------------------------------------------------------------
  # Réplica del pipeline de analisis/02_tendencias/grafico_pertenencia_modular.qmd
  # (un registro por paciente: el RUN más reciente). No cambia nada del cálculo;
  # solo el device de salida (600 dpi en lugar de 300 dpi).
  cat("-- Bloque 3: tendencia mensual por fuente de pertenencia --\n")

  datos_preparados <- datos_homologados %>%
    dplyr::rename(ANIO = AÑO) %>%
    dplyr::filter(!is.na(RUN)) %>%
    dplyr::arrange(RUN, dplyr::desc(ANIO)) %>%
    dplyr::distinct(RUN, .keep_all = TRUE)

  datos_mensuales <- datos_preparados %>%
    dplyr::mutate(
      FECHA_EGRESO = as.Date(FECHA_EGRESO_FMT_DEIS),
      MES = lubridate::month(FECHA_EGRESO),
      ANIO_NUM = lubridate::year(FECHA_EGRESO),
      PERIODO = as.Date(paste0(ANIO_NUM, "-", sprintf("%02d", MES), "-01"))
    ) %>%
    dplyr::filter(!is.na(FECHA_EGRESO), !is.na(ANIO_NUM),
                  ANIO_NUM >= 2010, ANIO_NUM <= 2022)

  calc_mensual <- function(data, var) {
    data %>%
      dplyr::group_by(PERIODO) %>%
      dplyr::summarise(
        pertenece  = sum(.data[[var]] == 1, na.rm = TRUE),
        total      = dplyr::n(),
        porcentaje = (pertenece / total) * 100,
        .groups    = "drop"
      )
  }

  fuentes   <- c("RSH", "CONADI", "PUEBLO_ORIGINARIO_BIN", "PERTENENCIA2")
  etiquetas <- c("RSH", "CONADI", "Egresos Hospitalarios",
                 "Variable Enriquecida")

  datos_mensuales_combined <- dplyr::bind_rows(lapply(
    seq_along(fuentes),
    function(i) {
      calc_mensual(datos_mensuales, fuentes[i]) %>%
        dplyr::mutate(Variable = etiquetas[i])
    }
  )) %>%
    dplyr::mutate(Variable = factor(Variable, levels = etiquetas))

  # Paleta de fuentes del qmd de referencia (genérica, no ligada a una entidad)
  colores_fuentes <- c(
    "RSH"                   = "#E41A1C",
    "CONADI"                = "#4DAF4A",
    "Egresos Hospitalarios" = "#377EB8",
    "Variable Enriquecida"  = "#FF7F00"
  )

  p_mensual <- ggplot2::ggplot(
    datos_mensuales_combined,
    ggplot2::aes(x = PERIODO, y = porcentaje, color = Variable, group = Variable)
  ) +
    ggplot2::geom_line(linewidth = 0.6, alpha = 0.9) +
    ggplot2::scale_color_manual(values = colores_fuentes) +
    ggplot2::scale_x_date(date_breaks = "1 year", date_labels = "%Y",
                          expand = c(0.01, 0)) +
    ggplot2::scale_y_continuous(
      labels = function(x) paste0(round(x, 1), "%"),
      breaks = seq(0, 100, by = 5)
    ) +
    # Sin título, bajada ni nota quemados: los aporta el pie de figura del
    # documento (el pie declara n, período y la nota de una fila por RUN).
    ggplot2::labs(
      x = "Período (Año-Mes)",
      y = "Porcentaje de pertenencia (%)",
      color = "Fuente de datos"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(color = "gray90", linewidth = 0.3),
      panel.grid.major.y = ggplot2::element_line(color = "gray90", linewidth = 0.3),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 7),
      axis.text.y = ggplot2::element_text(size = 7),
      axis.title = ggplot2::element_text(size = 8, face = "bold"),
      legend.title = ggplot2::element_text(size = 7.5, face = "bold"),
      legend.text = ggplot2::element_text(size = 7),
      panel.border = ggplot2::element_rect(color = "gray70", fill = NA,
                                           linewidth = 0.4)
    )

  # Footprint de inserción en el docx (7,01 x 4,49 in).
  guardar_figura_600(p_mensual, "figura_2_tendencia_mensual_fuentes",
                     ancho = 7.01, alto = 4.49)

  rm(datos_preparados, datos_mensuales, datos_mensuales_combined, p_mensual)
  gc(verbose = FALSE)

  cat("\nArchivos generados en:", OUT_DIR, "\n")
  invisible(OUT_DIR)
}

main()
