#' Unificar multiples atenciones por RUN
#'
#' @description
#' Colapsa hospitalizaciones de un mismo paciente (RUN) en un unico registro.
#' Dos modos: "global" (un registro por RUN en todo el periodo) o "anual"
#' (un registro por RUN por ano).
#'
#' @param datos Data frame con columnas RUN, DIAG1, PERTENENCIA2, COND_EGR,
#'   FECHA_INGRESO_FMT_DEIS, FECHA_EGRESO_FMT_DEIS y opcionalmente DIAS_ESTADA.
#' @param modo "global" (default): un registro por RUN en todo el periodo.
#'   "anual": un registro por RUN por ano (columna AÑO).
#' @param col_pertenencia Columna de pertenencia (default: "PERTENENCIA2")
#' @param col_ano Columna de ano (default: "AÑO"). Solo usada si modo = "anual".
#' @param verbose Mostrar mensajes de progreso (default: TRUE)
#'
#' @return Data frame con un registro por RUN (o RUN+ano) y columnas agregadas:
#'   n_atenciones, dias_estada_total, fallecio, COND_EGR (compatibilidad),
#'   DIAS_ESTADA (de primera atencion). Demograficos y diagnostico de primera atencion.
#'
#' @details
#' Criterios de unificacion:
#' - Diagnostico (DIAG1, DIAG_COMPLETO): primera atencion por fecha de ingreso
#' - Demograficos (sexo, edad, region, prevision, pertenencia): primera atencion
#' - Letalidad: si CUALQUIER atencion tiene COND_EGR == 2, se marca como fallecido
#' - Dias de estada: se suman todas las atenciones; DIAS_ESTADA mantiene el de la primera
#' - En modo "anual", la agrupacion es por RUN + ano
#'
#' @export
unificar_por_run <- function(datos,
                              modo = c("global", "anual"),
                              col_pertenencia = "PERTENENCIA2",
                              col_ano = "\u00c1\u00d1O",
                              verbose = TRUE) {

  modo <- match.arg(modo)

  if (verbose) {
    etiqueta <- ifelse(modo == "global", "RUN (periodo completo)", "RUN + A\u00f1o")
    cat(sprintf("\n=== UNIFICANDO ATENCIONES POR %s ===\n\n", etiqueta))
  }

  # Validaciones
  cols_requeridas <- c("RUN", "DIAG1", col_pertenencia, "COND_EGR",
                       "FECHA_INGRESO_FMT_DEIS", "FECHA_EGRESO_FMT_DEIS")
  if (modo == "anual") cols_requeridas <- c(cols_requeridas, col_ano)
  faltantes <- setdiff(cols_requeridas, names(datos))
  if (length(faltantes) > 0) {
    stop("Columnas faltantes: ", paste(faltantes, collapse = ", "))
  }

  n_registros <- nrow(datos)

  # Columnas opcionales
  tiene_dias <- "DIAS_ESTADA" %in% names(datos)
  tiene_diag_completo <- "DIAG_COMPLETO" %in% names(datos)

  # Columnas demograficas a conservar de la primera atencion
  cols_demo <- c("GLOSA_SEXO", "GRUPO_ETARIO", "CODIGO_REGION",
                 "NOMBRE_REGION", "GLOSA_PREVISION")
  cols_demo <- intersect(cols_demo, names(datos))

  # Asegurar fechas como Date
  datos <- datos %>%
    dplyr::mutate(
      FECHA_INGRESO_FMT_DEIS = as.Date(FECHA_INGRESO_FMT_DEIS),
      FECHA_EGRESO_FMT_DEIS  = as.Date(FECHA_EGRESO_FMT_DEIS)
    ) %>%
    dplyr::arrange(RUN, FECHA_INGRESO_FMT_DEIS)

  # --- Definir variable de agrupacion ---
  if (modo == "anual") {
    datos <- datos %>% dplyr::mutate(.grupo_key = .data[[col_ano]])
    group_vars <- c("RUN", ".grupo_key")
  } else {
    group_vars <- "RUN"
  }

  # --- Primera atencion por grupo (demograficos + diagnostico) ---
  cols_primera <- c("RUN", "DIAG1", col_pertenencia, cols_demo)
  if (tiene_diag_completo) cols_primera <- c(cols_primera, "DIAG_COMPLETO")
  if (modo == "anual") cols_primera <- c(cols_primera, ".grupo_key")
  if (tiene_dias) cols_primera <- c(cols_primera, "DIAS_ESTADA")

  primera <- datos %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::slice_head(n = 1) %>%
    dplyr::ungroup() %>%
    dplyr::select(dplyr::all_of(cols_primera))

  # --- Agregados por grupo ---
  agregados <- datos %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) %>%
    dplyr::summarise(
      n_atenciones = dplyr::n(),
      dias_estada_total = if (tiene_dias) sum(DIAS_ESTADA, na.rm = TRUE) else NA_real_,
      fallecio = as.integer(any(COND_EGR == 2, na.rm = TRUE)),
      primera_fecha = min(FECHA_INGRESO_FMT_DEIS, na.rm = TRUE),
      ultima_fecha = max(FECHA_EGRESO_FMT_DEIS, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      COND_EGR = ifelse(fallecio == 1L, 2L, 1L)
    )

  # --- Unir ---
  resultado <- primera %>%
    dplyr::left_join(agregados, by = group_vars)

  # Renombrar .grupo_key a AÑO en modo anual

  if (modo == "anual" && ".grupo_key" %in% names(resultado)) {
    resultado <- resultado %>%
      dplyr::rename(!!col_ano := .grupo_key)
  }

  n_resultado <- nrow(resultado)

  if (verbose) {
    if (modo == "global") {
      n_runs <- length(unique(datos$RUN))
      cat("  Registros originales: ", format(n_registros, big.mark = ","), "\n")
      cat("  Personas unicas:      ", format(n_resultado, big.mark = ","), "\n")
      cat("  Reduccion:            ", sprintf("%.1f%%", (1 - n_resultado / n_registros) * 100), "\n")
      cat("  Atenciones/persona:   ", round(n_registros / n_resultado, 2), "\n")
    } else {
      cat("  Registros originales:  ", format(n_registros, big.mark = ","), "\n")
      cat("  Personas-ano unicas:   ", format(n_resultado, big.mark = ","), "\n")
      cat("  Reduccion:             ", sprintf("%.1f%%", (1 - n_resultado / n_registros) * 100), "\n")
      cat("  Atenciones/persona-ano:", round(n_registros / n_resultado, 2), "\n")
    }

    # Distribucion de atenciones
    cat("\n  Distribucion de atenciones:\n")
    dist <- resultado %>%
      dplyr::mutate(
        grupo_atenciones = dplyr::case_when(
          n_atenciones == 1 ~ "1",
          n_atenciones <= 3 ~ "2-3",
          n_atenciones <= 10 ~ "4-10",
          TRUE ~ "11+"
        )
      ) %>%
      dplyr::count(grupo_atenciones, sort = TRUE)
    for (i in seq_len(nrow(dist))) {
      cat(sprintf("    %s atenciones: %s (%.1f%%)\n",
                  dist$grupo_atenciones[i],
                  format(dist$n[i], big.mark = ","),
                  dist$n[i] / n_resultado * 100))
    }

    # Resumen PO vs PG
    cat("\n  Por grupo:\n")
    resumen <- resultado %>%
      dplyr::mutate(grupo = ifelse(.data[[col_pertenencia]] == 1, "PO", "PG")) %>%
      dplyr::group_by(grupo) %>%
      dplyr::summarise(
        n = dplyr::n(),
        prom_atenciones = mean(n_atenciones),
        n_fallecidos = sum(fallecio),
        .groups = "drop"
      )
    for (i in seq_len(nrow(resumen))) {
      cat(sprintf("    %s: %s | %.2f atenc/persona | %s fallecidos\n",
                  resumen$grupo[i],
                  format(resumen$n[i], big.mark = ","),
                  resumen$prom_atenciones[i],
                  format(resumen$n_fallecidos[i], big.mark = ",")))
    }
  }

  return(resultado)
}
