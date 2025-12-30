#' Comparar perfiles epidemiológicos entre PO y PG
#'
#' @description
#' Compara tasas y proporciones de diagnósticos entre Pueblos Originarios
#' y Población General. Calcula RR crudo, diferencias de tasas y dirección.
#'
#' @param datos Datos con columnas DIAG1, DIAG_COMPLETO, PERTENENCIA2
#' @param poblacion_po Población de Pueblos Originarios (Censo 2017)
#' @param poblacion_pg Población General (Censo 2017)
#' @param total_egresos_po Total de egresos PO
#' @param total_egresos_pg Total de egresos PG
#' @param anos_estudio Número de años del período (default: 13)
#' @param min_casos_po Casos mínimos en PO para incluir (default: 100)
#' @param top_n Número de diagnósticos a retornar (default: 20)
#' @param ordenar_por Criterio de orden: "dif_tasa" o "rr" (default: "dif_tasa")
#' @param verbose Mostrar mensajes de progreso (default: TRUE)
#'
#' @return Tibble con comparación completa entre PO y PG:
#'   - casos_po, casos_pg: Número de egresos
#'   - tasa_anual_po, tasa_anual_pg: Tasas por 1000 persona-años
#'   - dif_tasa_anual: Diferencia de tasas (PO - PG)
#'   - prop_po, prop_pg: Proporción por 1000 egresos
#'   - dif_prop: Diferencia de proporciones
#'   - rr_crudo: Razón de tasas anuales (PO/PG) sin ajuste
#'   - direccion: Indicador visual de predominio
#'
#' @details
#' RR crudo (sin ajuste por edad):
#' - ≥1.5: Sobre-representado en PO (↑↑ PO)
#' - 1.0-1.5: Mayor en PO (↑ PO)
#' - ≤0.67: Sub-representado en PO (↓↓ PG)
#' - 0.67-1.0: Mayor en PG (↓ PG)
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
                                    verbose = TRUE) {
  
  if (verbose) {
    cat("\n═══ COMPARANDO PERFILES PO vs PG ═══\n")
  }
  
  # Validaciones
  if (!all(c("DIAG1", "DIAG_COMPLETO", "PERTENENCIA2") %in% names(datos))) {
    stop("Datos deben contener columnas: DIAG1, DIAG_COMPLETO, PERTENENCIA2")
  }
  
  # Calcular persona-años
  persona_anos_po <- poblacion_po * anos_estudio
  persona_anos_pg <- poblacion_pg * anos_estudio
  
  # Obtener descripciones únicas
  tabla_descripciones <- datos %>%
    dplyr::select(DIAG1, DIAG_COMPLETO) %>%
    dplyr::distinct()
  
  # Calcular tasas y proporciones para cada diagnóstico
  comparacion <- datos %>%
    dplyr::group_by(DIAG1) %>%
    dplyr::summarise(
      casos_po = sum(PERTENENCIA2 == 1, na.rm = TRUE),
      casos_pg = sum(PERTENENCIA2 == 0, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      # Tasa anual promedio por causa (por 1000 persona-años)
      tasa_anual_po = (casos_po / persona_anos_po) * 1000,
      tasa_anual_pg = (casos_pg / persona_anos_pg) * 1000,
      dif_tasa_anual = tasa_anual_po - tasa_anual_pg,
      
      # Proporción de egresos por causa (por 1000 egresos)
      prop_po = (casos_po / total_egresos_po) * 1000,
      prop_pg = (casos_pg / total_egresos_pg) * 1000,
      dif_prop = prop_po - prop_pg,
      
      # Razón de tasas (Risk Ratio) - NO ajustada por edad
      rr_crudo = tasa_anual_po / tasa_anual_pg,
      rr_prop = prop_po / prop_pg,
      
      # Dirección del efecto
      direccion = dplyr::case_when(
        rr_crudo >= 1.5 ~ "↑↑ PO",
        rr_crudo > 1 ~ "↑ PO",
        rr_crudo <= 0.67 ~ "↓↓ PG",
        rr_crudo < 1 ~ "↓ PG",
        TRUE ~ "="
      )
    ) %>%
    dplyr::filter(casos_po >= min_casos_po) %>%
    dplyr::left_join(tabla_descripciones, by = "DIAG1") %>%
    # Asegurar que DIAG_COMPLETO esté presente y al inicio
    dplyr::select(DIAG_COMPLETO, dplyr::everything(), -DIAG1)
  
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
    cat(sprintf("  ✓ %d diagnósticos comparados (≥%d casos en PO)\n", 
                nrow(comparacion), min_casos_po))
    
    n_mayor_po <- sum(comparacion$rr_crudo >= 1.5)
    n_mayor_pg <- sum(comparacion$rr_crudo <= 0.67)
    
    cat(sprintf("  ✓ Sobre-representados en PO (RR≥1.5): %d\n", n_mayor_po))
    cat(sprintf("  ✓ Sub-representados en PO (RR≤0.67): %d\n", n_mayor_pg))
    cat("\n  ⚠ ADVERTENCIA: RR crudos sin ajuste por edad\n")
  }
  
  return(comparacion)
}
