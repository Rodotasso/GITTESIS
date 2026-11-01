# ==============================================================================
# SCRIPT: regenerar_tabla7_fig9_ciecl.R
# ==============================================================================
#
# DESCRIPCIÓN:
#   Regenera la Tabla 7 (PEC/PLI/PDE por capítulo CIE-10) y la Figura 9
#   (cuadrantes de severidad PEC vs PLI) con la clasificación CIE-10 corregida
#   de 22 capítulos que aplica cargar_datos_homologados() EN MEMORIA.
#
# MOTIVO:
#   Ambos artefactos se generaron con la clasificación persistida heredada
#   (clasificar_grupo(), regex con ^H0|^H1 y ^H6|^H7 incompletos y sin códigos
#   U). Esa clasificación producía una fila/punto residual "Otros" y dejaba
#   desactualizados los capítulos de ojo (H20-H59) y oído (H80-H95). Con la
#   clasificación corregida "Otros" ya no existe (salvo un único egreso con
#   DIAG1 vacío) y aparece el capítulo XXII (códigos U).
#
# PRODUCTORES DE ORIGEN (no se modifican; este script los re-ejecuta):
#   - Tabla 7: calcular_indicadores_objetivo4() + formato de tabla de
#     R/perfiles/calcular_indicadores_objetivo4.R (llamada desde
#     analisis/05_perfiles_cie10/perfiles_diagnosticos_objetivo4.qmd).
#   - Figura 9: grafico_cuadrantes_severidad() de la copia corregida
#     DOCUMENTOS TESIS/FINAL-TESIS/figuras_nuevas/scripts/graficos_objetivo4.R,
#     la misma que usa R/graficos/regenerar_figuras_600dpi.R.
#
# ENTRADA:
#   BBDD_homologados.RData vía cargar_datos_homologados() (~940 MB en disco;
#   no se escribe nada sobre el .RData). Verificar headroom de memoria antes.
#   Contraste opcional: resultados_tesis/VIGENTES/indicadores/
#   tli_ajustada_edad_capitulo_indirecto.csv (egresos y TLI cruda por capítulo).
#
# SALIDA:
#   resultados_tesis/VIGENTES/indicadores/tabla7_pec_pli_pde_capitulo.csv
#   DOCUMENTOS TESIS/FINAL-TESIS/figuras_nuevas/salida/tablas/
#     tabla_1_perfiles_diagnosticos_obj4.png          (Tabla 7, imagen)
#   DOCUMENTOS TESIS/FINAL-TESIS/figuras_nuevas/salida/600dpi/
#     figura_9_cuadrantes_severidad.png / .jpg         (600 dpi)
#   DOCUMENTOS TESIS/FINAL-TESIS/figuras_nuevas/salida/
#     figura_5_cuadrantes_severidad.jpg               (la que se embebe como Figura 9)
#   Los artefactos previos se respaldan con el sufijo .bak_pre_ciecl.
#
# USO:
#   Rscript "R/graficos/regenerar_tabla7_fig9_ciecl.R"
#
# ==============================================================================

# --- Raíz del proyecto (patrón project_root; prohibido "../../") --------------
if (!exists("project_root")) {
  project_root <- rprojroot::find_root(rprojroot::has_file("BBDD_homologados.RData"))
}

# --- Utilidades del repo ------------------------------------------------------
source(file.path(project_root, "R", "cargar_funciones.R"))

# Versión corregida de las funciones de graficado (misma que usan los drivers y
# R/graficos/regenerar_figuras_600dpi.R): sobrescribe la de R/graficos.
dir_scripts <- file.path(
  project_root, "DOCUMENTOS TESIS", "FINAL-TESIS", "figuras_nuevas", "scripts"
)
source(file.path(dir_scripts, "graficos_objetivo4.R"))

# --- Constantes ---------------------------------------------------------------
DIR_SALIDA_FIG <- file.path(
  project_root, "DOCUMENTOS TESIS", "FINAL-TESIS", "figuras_nuevas", "salida"
)
DIR_600DPI   <- file.path(DIR_SALIDA_FIG, "600dpi")
DIR_TABLAS   <- file.path(DIR_SALIDA_FIG, "tablas")
DIR_VIGENTES <- file.path(project_root, "resultados_tesis", "VIGENTES", "indicadores")

DPI <- 600L

# Etiqueta del único egreso sin capítulo asignable (DIAG1 vacío): es la fila
# residual que la Tabla 7 y la Figura 9 no deben mostrar.
etiqueta_residual <- "Otros"

# Número de capítulos con egresos en la serie 2010-2022 (el capítulo XX,
# "Causas externas de morbilidad y mortalidad", no tiene egresos porque esos
# códigos nunca son diagnóstico principal).
n_capitulos_esperados <- 21L

# ==============================================================================
# FUNCIÓN: respaldar_si_existe
# ==============================================================================
# Copia el artefacto vigente a "<nombre>.bak_pre_ciecl.<ext>" la primera vez.
# Idempotente: si el respaldo ya existe no lo sobrescribe.
respaldar_si_existe <- function(ruta) {
  if (!file.exists(ruta)) return(invisible(FALSE))
  ext  <- tools::file_ext(ruta)
  base <- tools::file_path_sans_ext(ruta)
  destino <- paste0(base, ".bak_pre_ciecl", if (nzchar(ext)) paste0(".", ext) else "")
  if (!file.exists(destino)) {
    file.copy(ruta, destino, overwrite = FALSE)
    cat("  respaldo:", basename(destino), "\n")
  }
  invisible(TRUE)
}

# ==============================================================================
# FUNCIÓN: crear_tabla7
# ==============================================================================
# Reproduce el formato de la Tabla 7 del documento vigente: encabezado de dos
# filas (bloque por indicador + población), orden descendente por la magnitud de
# la diferencia de puntos porcentuales (DPP) de la PEC y decimales con coma.
# No se reutiliza crear_tabla_maestra_perfiles() porque ese productor ordena por
# PEC indígena y agrega una fila superior con la TBE global, layout distinto al
# de la tabla publicada.
crear_tabla7 <- function(tabla_df, titulo) {
  ft <- flextable::flextable(tabla_df) %>%
    flextable::set_header_labels(
      Capitulo = "",
      PEC_PO = "Pueblos Indígenas",
      PEC_PG = "Población General",
      PLI_PO = "Pueblos Indígenas",
      PLI_PG = "Población General",
      PDE_PO = "Pueblos Indígenas",
      PDE_PG = "Población General"
    ) %>%
    flextable::add_header_row(
      top = TRUE,
      colwidths = c(1L, 2L, 2L, 2L),
      values = c(
        "Capítulo CIE-10",
        "Proporción de Egresos por Causas (%)",
        "Proporción de Letalidad Intrahospitalaria (%)",
        "Promedio Días de estada (días)"
      )
    ) %>%
    flextable::merge_v(j = 1L, part = "header") %>%
    flextable::colformat_double(
      j = 2:ncol(tabla_df), digits = 2, big.mark = ".", decimal.mark = ","
    ) %>%
    flextable::align(align = "center", part = "all") %>%
    flextable::align(j = 1L, align = "left", part = "all") %>%
    flextable::fontsize(size = 8, part = "all") %>%
    flextable::bold(part = "header") %>%
    flextable::bold(part = "body", bold = FALSE) %>%
    flextable::set_caption(titulo) %>%
    flextable::theme_booktabs() %>%
    flextable::autofit()
  ft
}

# ==============================================================================
# EJECUCIÓN
# ==============================================================================
main <- function() {
  cat("================================================================================\n")
  cat("TABLA 7 Y FIGURA 9 CON LA CLASIFICACIÓN CIE-10 CORREGIDA (22 CAPÍTULOS)\n")
  cat("================================================================================\n\n")

  # ---------------------------------------------------------------------------
  # BLOQUE 1: indicadores del Objetivo 4 con la capa de derivación corregida
  # ---------------------------------------------------------------------------
  cat("-- Bloque 1: indicadores por capítulo CIE-10 --\n")

  # cargar_datos_homologados() sobrescribe Grupo_CIE10 en memoria (no en disco)
  datos_homologados <- cargar_datos_homologados()
  data.table::setDT(datos_homologados)

  censo_lista <- obtener_poblacion_censo(verbose = FALSE)
  censo_df <- tibble::tibble(
    grupo     = c("PI", "PG"),
    poblacion = c(censo_lista$pob_po, censo_lista$pob_pg)
  )

  cols_obj4 <- c("PERTENENCIA2", "COND_EGR", "FECHA_EGRESO_FMT_DEIS",
                 "FECHA_INGRESO_FMT_DEIS", "Grupo_CIE10")
  datos_base <- datos_homologados[, cols_obj4, with = FALSE]
  rm(datos_homologados)
  gc(verbose = FALSE)

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
  rm(datos_analisis_obj4)
  gc(verbose = FALSE)

  # Capítulos distintos y fila residual: control de composición
  capitulos <- sort(unique(resultados_obj4$Capitulo))
  cat("  capítulos en la base:", length(capitulos), "\n")
  fila_residual <- resultados_obj4 %>% dplyr::filter(Capitulo == etiqueta_residual)
  if (nrow(fila_residual) > 0L) {
    cat("  fila residual '", etiqueta_residual, "': ",
        paste(sprintf("%s=%d", fila_residual$grupo, fila_residual$Ec), collapse = " | "),
        " egreso(s)\n", sep = "")
  }

  # ---------------------------------------------------------------------------
  # BLOQUE 2: Tabla 7 (21 capítulos, sin fila residual)
  # ---------------------------------------------------------------------------
  cat("-- Bloque 2: Tabla 7 --\n")

  # Se excluye la fila residual y se recalcula la PEC sobre los egresos con
  # capítulo asignado, de modo que cada columna cierre exactamente en 100,00.
  # El efecto es de 3,2e-5 pp en la PEC indígena (1 egreso de 3.117.578); la
  # PEC general no cambia (no tiene fila residual).
  sin_residual <- resultados_obj4 %>%
    dplyr::filter(Capitulo != etiqueta_residual)

  totales_publicados <- sin_residual %>%
    dplyr::group_by(grupo) %>%
    dplyr::summarise(Et_publicado = sum(Ec), .groups = "drop")

  sin_residual <- sin_residual %>%
    dplyr::left_join(totales_publicados, by = "grupo") %>%
    dplyr::mutate(PEC = (Ec / Et_publicado) * 100)

  tabla_wide <- sin_residual %>%
    dplyr::select(Capitulo, grupo, PEC, TLI, PDE) %>%
    tidyr::pivot_wider(names_from = grupo, values_from = c(PEC, TLI, PDE)) %>%
    dplyr::mutate(DPP = PEC_PI - PEC_PG) %>%
    # Orden del documento vigente: magnitud de la diferencia; Capitulo como
    # segundo criterio para un desempate determinista.
    dplyr::arrange(dplyr::desc(abs(DPP)), Capitulo)

  tabla_df <- tabla_wide %>%
    dplyr::select(Capitulo, PEC_PI, PEC_PG, TLI_PI, TLI_PG, PDE_PI, PDE_PG) %>%
    dplyr::rename(
      PEC_PO = PEC_PI, PEC_PG = PEC_PG,
      PLI_PO = TLI_PI, PLI_PG = TLI_PG,
      PDE_PO = PDE_PI, PDE_PG = PDE_PG
    )

  # --- Verificaciones de contrato --------------------------------------------
  stopifnot(
    "La tabla debe tener 21 capítulos" = nrow(tabla_df) == n_capitulos_esperados,
    "No debe quedar la fila residual"  = !etiqueta_residual %in% tabla_df$Capitulo,
    "No debe haber NA en la tabla"     = !anyNA(tabla_df),
    "Sin etiquetas duplicadas"         = !anyDuplicated(tabla_df$Capitulo)
  )

  suma_pec_po <- sum(tabla_df$PEC_PO)
  suma_pec_pg <- sum(tabla_df$PEC_PG)
  suma_red_po <- sum(round(tabla_df$PEC_PO, 2))
  suma_red_pg <- sum(round(tabla_df$PEC_PG, 2))

  # Etiquetas en title case: se descarta que algún capítulo venga en mayúsculas
  mayusculas <- tabla_df$Capitulo[!grepl("[a-záéíóúñ]", tabla_df$Capitulo)]
  stopifnot("Hay etiquetas sin minúsculas" = length(mayusculas) == 0L)

  cat(sprintf("  PEC indígena: suma exacta %.5f | suma redondeada %.2f\n",
              suma_pec_po, suma_red_po))
  cat(sprintf("  PEC general:  suma exacta %.5f | suma redondeada %.2f\n",
              suma_pec_pg, suma_red_pg))
  stopifnot(
    "PEC indígena no cierra en 100" = abs(suma_pec_po - 100) < 1e-6,
    "PEC general no cierra en 100"  = abs(suma_pec_pg - 100) < 1e-6
  )

  # --- Contraste con el CSV vigente (egresos y TLI cruda) --------------------
  ruta_tli <- file.path(DIR_VIGENTES, "tli_ajustada_edad_capitulo_indirecto.csv")
  if (file.exists(ruta_tli)) {
    tli_ref <- utils::read.csv(ruta_tli, encoding = "UTF-8", check.names = FALSE)
    tli_ref <- tli_ref[tli_ref$capitulo != etiqueta_residual, ]
    control <- sin_residual %>%
      dplyr::filter(grupo == "PI") %>%
      dplyr::transmute(capitulo = Capitulo, Ec, TLI) %>%
      dplyr::inner_join(
        tli_ref[, c("capitulo", "egresos_PO", "TLI_cruda_PO_pct")],
        by = "capitulo"
      ) %>%
      dplyr::mutate(
        d_egresos = Ec - as.numeric(egresos_PO),
        d_tli     = TLI - as.numeric(TLI_cruda_PO_pct)
      )
    cat(sprintf("  contraste CSV: %d capítulos, max|d egresos| = %d, max|d TLI| = %.2e\n",
                nrow(control), max(abs(control$d_egresos)), max(abs(control$d_tli))))
    stopifnot(
      "Egresos PO no coinciden con el CSV vigente" = all(control$d_egresos == 0),
      "TLI cruda no coincide con el CSV vigente"   = max(abs(control$d_tli)) < 1e-9
    )
  } else {
    warning("No se encontró el CSV de contraste: ", ruta_tli)
  }

  # --- Escritura -------------------------------------------------------------
  if (!dir.exists(DIR_VIGENTES)) dir.create(DIR_VIGENTES, recursive = TRUE)
  ruta_csv <- file.path(DIR_VIGENTES, "tabla7_pec_pli_pde_capitulo.csv")
  respaldar_si_existe(ruta_csv)
  utils::write.csv(tabla_df, ruta_csv, row.names = FALSE, fileEncoding = "UTF-8")
  cat("  CSV:", ruta_csv, "\n")

  tabla_ft <- crear_tabla7(
    tabla_df,
    paste0("Tabla 7. Egresos hospitalarios por capítulo CIE-10 según pertenencia ",
           "o no a pueblos indígenas. Chile, 2010-2022.")
  )
  if (!dir.exists(DIR_TABLAS)) dir.create(DIR_TABLAS, recursive = TRUE)
  ruta_png_tabla <- file.path(DIR_TABLAS, "tabla_1_perfiles_diagnosticos_obj4.png")
  respaldar_si_existe(ruta_png_tabla)
  guardar_tabla_png(
    tabla_ft, "tabla_1_perfiles_diagnosticos_obj4", dir_salida = DIR_TABLAS
  )
  cat("  PNG:", ruta_png_tabla, "\n")

  rm(resultados_obj4, tabla_wide, tabla_ft)
  gc(verbose = FALSE)

  # ---------------------------------------------------------------------------
  # BLOQUE 3: Figura 9 (cuadrantes PEC vs PLI, sin la fila residual)
  # ---------------------------------------------------------------------------
  cat("-- Bloque 3: Figura 9 --\n")

  datos_fig9 <- sin_residual
  stopifnot(
    "La figura debe tener 21 capítulos por grupo" =
      nrow(datos_fig9) == n_capitulos_esperados * 2L,
    "La figura no debe incluir el punto residual" =
      !etiqueta_residual %in% datos_fig9$Capitulo
  )

  p_fig9 <- grafico_cuadrantes_severidad(datos_fig9)

  # 600 dpi (PNG nativo + JPG derivado con magick, mismo workaround de
  # regenerar_figuras_600dpi.R: el device JPEG de ggsave escribe APP14)
  if (!dir.exists(DIR_600DPI)) dir.create(DIR_600DPI, recursive = TRUE)
  ruta_600_png <- file.path(DIR_600DPI, "figura_9_cuadrantes_severidad.png")
  ruta_600_jpg <- file.path(DIR_600DPI, "figura_9_cuadrantes_severidad.jpg")
  respaldar_si_existe(ruta_600_png)
  respaldar_si_existe(ruta_600_jpg)
  ggplot2::ggsave(ruta_600_png, p_fig9, width = 10, height = 6, dpi = DPI,
                  bg = "white")
  magick::image_write(magick::image_read(ruta_600_png), ruta_600_jpg,
                      format = "jpeg", quality = 95)
  cat("  PNG:", ruta_600_png, "\n  JPG:", ruta_600_jpg, "\n")

  # Copia embebida en el documento vigente (Figura 9) y en los HTML de VIGENTES
  ruta_fig9 <- file.path(DIR_SALIDA_FIG, "figura_5_cuadrantes_severidad.jpg")
  respaldar_si_existe(ruta_fig9)
  magick::image_write(magick::image_read(ruta_600_png), ruta_fig9,
                      format = "jpeg", quality = 95)
  cat("  JPG (embebida):", ruta_fig9, "\n")

  rm(datos_fig9, p_fig9)
  gc(verbose = FALSE)

  cat("\nListo.\n")
  invisible(TRUE)
}

main()
