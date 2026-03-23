#' Comparar perfiles epidemiológicos entre PO y PG
#'
#' @description
#' Compara tasas y proporciones de diagnósticos entre Pueblos Originarios
#' y Población General. Calcula RR crudo, diferencias de tasas y dirección.
#'
#' @param datos Datos con columnas DIAG1, DIAG_COMPLETO y col_pertenencia
#' @param poblacion_po Población de Pueblos Originarios (Censo 2017)
#' @param poblacion_pg Población General (Censo 2017)
#' @param total_egresos_po Total de egresos PO
#' @param total_egresos_pg Total de egresos PG
#' @param anos_estudio Número de años del período (default: 13)
#' @param min_casos_po Casos mínimos en PO para incluir (default: 100)
#' @param top_n Número de diagnósticos a retornar (default: 20)
#' @param ordenar_por Criterio de orden: "dif_tasa" o "rr" (default: "dif_tasa")
#' @param col_pertenencia Nombre de la columna de pertenencia
#'   (default: "PERTENENCIA2" = Variable Enriquecida;
#'   usar "PUEBLO_ORIGINARIO_BIN" para la declarada en EH)
#' @param verbose Mostrar mensajes de progreso (default: TRUE)
#'
#' @return Tibble con comparación completa entre PO y PG:
#'   - casos_po, casos_pg: Número de egresos
#'   - tasa_anual_po, tasa_anual_pg: Tasas por 1000 persona-años
#'   - dif_tasa_anual: Diferencia de tasas (PO - PG)
#'   - prop_po, prop_pg: Proporción por 1000 egresos propios
#'   - dif_prop: Diferencia de proporciones
#'   - rr_crudo: Razón de tasas anuales (PO/PG) sin ajuste
#'   - prom_dias_po, prom_dias_pg: Promedio días de estada (si disponible)
#'   - tasa_letalidad_po_x1000, tasa_letalidad_pg_x1000: Tasa de letalidad
#'     por causa × 1000 (si disponible)
#'   - direccion: Indicador visual de predominio
#'
#' @details
#' RR crudo (sin ajuste por edad):
#' - >=1.5: Sobre-representado en PO (up up PO)
#' - 1.0-1.5: Mayor en PO (up PO)
#' - <=0.67: Sub-representado en PO (down down PG)
#' - 0.67-1.0: Mayor en PG (down PG)
#'
#' Tasas de letalidad expresadas por 1000 (x1000), segun Bonita 2006 / OPS 2018.
#'
#' ADVERTENCIA: RR crudos pueden estar confundidos por edad y otros factores.
#'
#' @examples
#' comparacion <- comparar_perfiles_po_pg(
#'   datos = datos_preparados,
#'   poblacion_po = 2185792,
#'   poblacion_pg = 14700467,
#'   total_egresos_po = 500000,
#'   total_egresos_pg = 15000000,
#'   min_casos_po = 100,
#'   top_n = 20
#' )
#'
#' @export
comparar_perfiles_po_pg <- function(datos,
                                    poblacion_po,
                                    poblacion_pg,
                                    total_egresos_po,
                                    total_egresos_pg,
                                    anos_estudio = 13,
                                    min_casos_po = 100,
                                    top_n = 20,
                                    ordenar_por = "dif_tasa",
                                    col_pertenencia = "PERTENENCIA2",
                                    verbose = TRUE) {

  if (verbose) {
    cat("\n\u2550\u2550\u2550 COMPARANDO PERFILES PO vs PG \u2550\u2550\u2550\n")
  }

  # Validaciones
  if (!all(c("DIAG1", "DIAG_COMPLETO", col_pertenencia) %in% names(datos))) {
    stop(paste0("Datos deben contener columnas: DIAG1, DIAG_COMPLETO, ", col_pertenencia))
  }

  tiene_dias <- "DIAS_ESTADA" %in% names(datos)
  tiene_cond <- "COND_EGR" %in% names(datos)

  if (verbose) {
    if (tiene_dias) cat("  \u2022 D\u00edas de estada: disponible\n")
    if (tiene_cond) cat("  \u2022 Condici\u00f3n de egreso: disponible (letalidad x1000)\n")
  }

  # Calcular persona-años
  persona_anos_po <- poblacion_po * anos_estudio
  persona_anos_pg <- poblacion_pg * anos_estudio

  # Obtener descripciones únicas
  tabla_descripciones <- datos %>%
    dplyr::select(DIAG1, DIAG_COMPLETO) %>%
    dplyr::distinct()

  # Calcular conteos y días de estada por diagnóstico y grupo
  comparacion <- datos %>%
    dplyr::group_by(DIAG1) %>%
    dplyr::summarise(
      casos_po = sum(.data[[col_pertenencia]] == 1, na.rm = TRUE),
      casos_pg = sum(.data[[col_pertenencia]] == 0, na.rm = TRUE),
      # Días de estada por grupo (si existe)
      prom_dias_po = if (tiene_dias) {
        mean(DIAS_ESTADA[.data[[col_pertenencia]] == 1], na.rm = TRUE)
      } else NA_real_,
      prom_dias_pg = if (tiene_dias) {
        mean(DIAS_ESTADA[.data[[col_pertenencia]] == 0], na.rm = TRUE)
      } else NA_real_,
      # Fallecidos por grupo (si existe COND_EGR: 2 = fallecido)
      fallecidos_po = if (tiene_cond) {
        sum(COND_EGR == 2 & .data[[col_pertenencia]] == 1, na.rm = TRUE)
      } else NA_integer_,
      fallecidos_pg = if (tiene_cond) {
        sum(COND_EGR == 2 & .data[[col_pertenencia]] == 0, na.rm = TRUE)
      } else NA_integer_,
      .groups = "drop"
    ) %>%
    dplyr::filter(casos_po >= min_casos_po) %>%
    dplyr::left_join(tabla_descripciones, by = "DIAG1") %>%
    dplyr::mutate(
      # Tasas anuales por 1000 persona-años
      tasa_anual_po = (casos_po / persona_anos_po) * 1000,
      tasa_anual_pg = (casos_pg / persona_anos_pg) * 1000,
      dif_tasa_anual = tasa_anual_po - tasa_anual_pg,

      # Proporciones por 1000 egresos propios de cada grupo
      prop_po = (casos_po / total_egresos_po) * 1000,
      prop_pg = (casos_pg / total_egresos_pg) * 1000,
      dif_prop = prop_po - prop_pg,

      # RR crudo de tasas (PO / PG)
      rr_crudo = dplyr::case_when(
        tasa_anual_pg == 0 ~ NA_real_,
        TRUE ~ tasa_anual_po / tasa_anual_pg
      ),

      # RR de proporciones
      rr_prop = dplyr::case_when(
        prop_pg == 0 ~ NA_real_,
        TRUE ~ prop_po / prop_pg
      ),

      # Tasa de letalidad por causa × 1000 (Bonita 2006 / OPS 2018)
      tasa_letalidad_po_x1000 = if (tiene_cond) {
        ifelse(casos_po > 0, (fallecidos_po / casos_po) * 1000, NA_real_)
      } else NA_real_,
      tasa_letalidad_pg_x1000 = if (tiene_cond) {
        ifelse(casos_pg > 0, (fallecidos_pg / casos_pg) * 1000, NA_real_)
      } else NA_real_,

      # Dirección visual
      direccion = dplyr::case_when(
        is.na(rr_crudo)   ~ "?",
        rr_crudo >= 1.5   ~ "\u2191\u2191 PO",
        rr_crudo >= 1.0   ~ "\u2191 PO",
        rr_crudo <= 0.67  ~ "\u2193\u2193 PG",
        TRUE              ~ "\u2193 PG"
      )
    ) %>%
    dplyr::select(
      DIAG_COMPLETO, casos_po, casos_pg,
      tasa_anual_po, tasa_anual_pg, dif_tasa_anual,
      prop_po, prop_pg, dif_prop,
      rr_crudo, rr_prop,
      dplyr::any_of(c(
        "prom_dias_po", "prom_dias_pg",
        "fallecidos_po", "fallecidos_pg",
        "tasa_letalidad_po_x1000", "tasa_letalidad_pg_x1000"
      )),
      direccion
    )

  # Ordenar según criterio
  if (ordenar_por == "rr") {
    comparacion <- comparacion %>%
      dplyr::arrange(desc(abs(rr_crudo - 1)))
  } else {
    comparacion <- comparacion %>%
      dplyr::arrange(desc(abs(dif_tasa_anual)))
  }

  # Limitar a top_n
  comparacion <- comparacion %>%
    dplyr::slice_head(n = top_n)

  if (verbose) {
    cat(sprintf("  \u2713 %d diagn\u00f3sticos comparados (\u2265%d casos en PO)\n",
                nrow(comparacion), min_casos_po))

    n_mayor_po <- sum(comparacion$rr_crudo >= 1.5, na.rm = TRUE)
    n_mayor_pg <- sum(comparacion$rr_crudo <= 0.67, na.rm = TRUE)

    cat(sprintf("  \u2713 Sobre-representados en PO (RR\u22651.5): %d\n", n_mayor_po))
    cat(sprintf("  \u2713 Sub-representados en PO (RR\u22640.67): %d\n", n_mayor_pg))
    if (tiene_dias) {
      cat(sprintf("  \u2713 D\u00edas estada promedio PO: %.1f | PG: %.1f\n",
                  mean(comparacion$prom_dias_po, na.rm = TRUE),
                  mean(comparacion$prom_dias_pg, na.rm = TRUE)))
    }
    if (tiene_cond) {
      cat(sprintf("  \u2713 Letalidad promedio PO: %.2f x1000 | PG: %.2f x1000\n",
                  mean(comparacion$tasa_letalidad_po_x1000, na.rm = TRUE),
                  mean(comparacion$tasa_letalidad_pg_x1000, na.rm = TRUE)))
    }
    cat("\n  \u26a0 ADVERTENCIA: RR crudos sin ajuste por edad\n")
  }

  return(comparacion)
}
