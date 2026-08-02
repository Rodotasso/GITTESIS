# ==============================================================================
# FUNCIONES: Indicadores epidemiológicos actualizados (Objetivo 4)
# ==============================================================================
# 
# Implementa los 4 indicadores técnicos definidos en la propuesta final:
# 1. Tasa Bruta de Egreso (TBE) - Utilización poblacional
# 2. Tasa de Letalidad Intrahospitalaria (TLI) - Severidad/Efectividad
# 3. Proporción de Egresos por Causa (PEC) - Peso relativo CIE-10
# 4. Promedio Días de Estada (PDE) - Intensidad de uso
#
# Unidad de análisis: Evento Hospitalario (Egreso)
# Metodología: OMS 2025, OPS 2018
# ==============================================================================

#' Calcular Indicadores Técnicos del Objetivo 4
#'
#' @param datos Data frame con PERTENENCIA2, COND_EGR, DIAS_ESTADA, Capitulo (CIE-10)
#' @param denominadores_censo Tibble con columnas: grupo ("PI", "PG"), poblacion
#' @param col_pertenencia Columna de pertenencia (default: "PERTENENCIA2" = Variable Enriquecida)
#' @param anos_estudio Número de años del período (default: 13 para 2010-2022)
#' @param verbose Mostrar mensajes (default: TRUE)
#'
#' @return Tibble con TBE, TLI, PEC y PDE por grupo y capítulo
#' @export
calcular_indicadores_objetivo4 <- function(datos,
                                           denominadores_censo,
                                           col_pertenencia = "PERTENENCIA2",
                                           anos_estudio = 13,
                                           verbose = TRUE) {

  if (verbose) cat("\n═══ CALCULANDO INDICADORES TÉCNICOS (OBJETIVO 4) ═══\n")
  if (verbose) cat("Unidad de análisis: Evento (Egreso)\n")

  # 1. Preparar Totales por Grupo (PI/PG) para Denominadores
  totales_grupo <- datos %>%
    dplyr::mutate(grupo = ifelse(!is.na(.data[[col_pertenencia]]) & .data[[col_pertenencia]] == 1, "PI", "PG")) %>%
    dplyr::group_by(grupo) %>%
    dplyr::summarise(
      Et = dplyr::n(), # Total egresos del grupo
      F_total = sum(COND_EGR == 2, na.rm = TRUE), # Total fallecidos del grupo
      Sum_dias = sum(DIAS_ESTADA, na.rm = TRUE),
      n_validos_dias = sum(!is.na(DIAS_ESTADA)),
      .groups = "drop"
    ) %>%
    dplyr::left_join(denominadores_censo, by = "grupo") %>%
    dplyr::mutate(
      TBE = (Et / poblacion) * 1000,
      TLI_global = (F_total / Et) * 100,
      PDE_global = Sum_dias / n_validos_dias
    )

  # 2. Calcular Indicadores por Capítulo CIE-10
  indicadores_capitulo <- datos %>%
    dplyr::mutate(grupo = ifelse(!is.na(.data[[col_pertenencia]]) & .data[[col_pertenencia]] == 1, "PI", "PG")) %>%
    dplyr::group_by(grupo, Capitulo) %>%
    dplyr::summarise(
      Ec = dplyr::n(), # Egresos por causa
      Fc = sum(COND_EGR == 2, na.rm = TRUE), # Fallecidos por causa
      Sum_dias_c = sum(DIAS_ESTADA, na.rm = TRUE),
      n_validos_c = sum(!is.na(DIAS_ESTADA)),
      .groups = "drop"
    ) %>%
    dplyr::left_join(totales_grupo %>% dplyr::select(grupo, Et, TBE), by = "grupo") %>%
    dplyr::mutate(
      PEC = (Ec / Et) * 100,
      TLI = (Fc / Ec) * 100,
      PDE = Sum_dias_c / n_validos_c
    )

  # 3. Ensamblar Resultado Final
  resultado <- indicadores_capitulo %>%
    dplyr::select(grupo, Capitulo, Ec, Et, PEC, TLI, PDE, TBE) %>%
    dplyr::arrange(Capitulo, desc(grupo))

  if (verbose) {
    cat(sprintf("  \u2713 %d capítulos CIE-10 procesados\n", length(unique(resultado$Capitulo))))
    cat("  \u2713 Indicadores TBE, TLI, PEC y PDE generados.\n")
  }

  return(resultado)
}

#' Crear Tabla Maestra de Perfiles (Objetivo 4)
#'
#' @param datos_resultado Resultado de calcular_indicadores_objetivo4
#' @param titulo Título de la tabla
#' @param tamano_fuente Tamaño de fuente (default: 8)
#'
#' @return Objeto flextable con formato académico
#' @export
crear_tabla_maestra_perfiles <- function(datos_resultado, titulo, tamano_fuente = 8) {
  
  # Preparar tabla horizontal (PI vs PG)
  tabla_wide <- datos_resultado %>%
    dplyr::select(Capitulo, grupo, TBE, PEC, TLI, PDE) %>%
    tidyr::pivot_wider(
      names_from = grupo,
      values_from = c(TBE, PEC, TLI, PDE)
    ) %>%
    dplyr::arrange(dplyr::desc(PEC_PI)) # Ordenar por peso relativo en pueblos indigenas

  # La TBE se define como Et/poblacion (ver calcular_indicadores_objetivo4): es una
  # tasa GLOBAL por grupo, identica en todos los capitulos. Por eso no se muestra como
  # columna por capitulo (se repetiria en cada fila), sino una sola vez en una fila
  # superior que abarca toda la tabla; abajo quedan las columnas por capitulo (PEC, TLI, PDE).
  tbe_pi <- tabla_wide$TBE_PI[1]
  tbe_pg <- tabla_wide$TBE_PG[1]
  glosa_tbe <- sprintf(
    "Tasa Bruta de Egreso global (x10.000)  |  Pueblos Indígenas: %s  ·  Población General: %s",
    formatC(tbe_pi, format = "f", digits = 2, big.mark = ".", decimal.mark = ","),
    formatC(tbe_pg, format = "f", digits = 2, big.mark = ".", decimal.mark = ",")
  )

  # Tabla por capitulo con las columnas restantes (sin la TBE global)
  tabla_df <- tabla_wide %>%
    dplyr::select(
      Capitulo,
      PEC_PI, PEC_PG,
      TLI_PI, TLI_PG,
      PDE_PI, PDE_PG
    )

  ft <- flextable::flextable(tabla_df) %>%
    flextable::set_header_labels(
      Capitulo = "Capítulo CIE-10",
      PEC_PI = "Proporción de Egresos por Causa\nPueblos Indígenas (%)",
      PEC_PG = "Proporción de Egresos por Causa\nPoblación General (%)",
      TLI_PI = "Tasa de Letalidad Intrahospitalaria\nPueblos Indígenas (%)",
      TLI_PG = "Tasa de Letalidad Intrahospitalaria\nPoblación General (%)",
      PDE_PI = "Estada\nPueblos Indígenas (días)",
      PDE_PG = "Estada\nPoblación General (días)"
    ) %>%
    # Fila superior con la TBE global (una sola vez, abarcando toda la tabla)
    flextable::add_header_row(
      top = TRUE,
      colwidths = ncol(tabla_df),
      values = glosa_tbe
    ) %>%
    flextable::colformat_double(
      j = 2:ncol(tabla_df), digits = 2,
      big.mark = ".", decimal.mark = ","
    ) %>%
    flextable::align(align = "center", part = "all") %>%
    flextable::align(j = 1, align = "left", part = "all") %>%
    flextable::align(i = 1, align = "left", part = "header") %>%
    flextable::fontsize(size = tamano_fuente, part = "all") %>%
    flextable::bold(part = "header") %>%
    flextable::bold(part = "body", bold = FALSE) %>%
    flextable::set_caption(titulo) %>%
    flextable::theme_booktabs() %>%
    flextable::autofit()

  return(ft)
}
