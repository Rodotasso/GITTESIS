# ==============================================================================
# FUNCIONES: Indicadores epidemiológicos del protocolo (Tabla 4)
# ==============================================================================
#
# Calcula los 5 indicadores del protocolo de tesis:
# 1. Tasa de egresos (x1000 persona-años)
# 2. Proporción de egresos por causa (x1000 egresos)
# 3. Proporción de letalidad intrahospitalaria (x1000)
# 4. Tasa de letalidad por causa (x1000)
# 5. Días de estada (promedio y mediana)
#
# Metodología: OPS 2018, Bonita 2006
# ==============================================================================


#' Calcular indicadores globales PO vs PG
#'
#' @param datos Data frame con PERTENENCIA2, COND_EGR, DIAS_ESTADA
#' @param col_pertenencia Columna de pertenencia (default: "PERTENENCIA2")
#' @param poblacion_po Población PO del Censo 2017
#' @param poblacion_pg Población PG del Censo 2017
#' @param anos_estudio Número de años del período (default: 13)
#' @param verbose Mostrar mensajes (default: TRUE)
#'
#' @return Tibble con indicadores por grupo (PO/PG)
#' @export
calcular_indicadores_globales <- function(datos,
                                          poblacion_po,
                                          poblacion_pg,
                                          col_pertenencia = "PERTENENCIA2",
                                          anos_estudio = 13,
                                          verbose = TRUE) {

  if (verbose) cat("\n═══ INDICADORES GLOBALES (Protocolo Tabla 4) ═══\n")

  tiene_dias <- "DIAS_ESTADA" %in% names(datos)
  tiene_cond <- "COND_EGR" %in% names(datos)

  # Calcular por grupo
  resumen <- datos %>%
    dplyr::mutate(
      grupo = ifelse(.data[[col_pertenencia]] == 1, "PO", "PG")
    ) %>%
    dplyr::group_by(grupo) %>%
    dplyr::summarise(
      n_egresos = dplyr::n(),
      n_fallecidos = if (tiene_cond) sum(COND_EGR == 2, na.rm = TRUE) else NA_integer_,
      prom_dias_estada = if (tiene_dias) mean(DIAS_ESTADA, na.rm = TRUE) else NA_real_,
      med_dias_estada = if (tiene_dias) stats::median(DIAS_ESTADA, na.rm = TRUE) else NA_real_,
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      poblacion = ifelse(grupo == "PO", poblacion_po, poblacion_pg),
      persona_anos = poblacion * anos_estudio,
      tasa_egresos_x1000 = (n_egresos / persona_anos) * 1000,
      prop_letalidad_x1000 = ifelse(!is.na(n_fallecidos),
                                    (n_fallecidos / n_egresos) * 1000,
                                    NA_real_)
    ) %>%
    dplyr::select(grupo, n_egresos, poblacion, persona_anos,
                  tasa_egresos_x1000, n_fallecidos, prop_letalidad_x1000,
                  prom_dias_estada, med_dias_estada)

  if (verbose) {
    for (i in seq_len(nrow(resumen))) {
      g <- resumen$grupo[i]
      cat(sprintf("\n  %s:\n", g))
      cat(sprintf("    Egresos: %s\n", format(resumen$n_egresos[i], big.mark = ",")))
      cat(sprintf("    Tasa egresos: %.2f x1000 persona-años\n", resumen$tasa_egresos_x1000[i]))
      if (!is.na(resumen$prop_letalidad_x1000[i])) {
        cat(sprintf("    Letalidad: %.2f x1000\n", resumen$prop_letalidad_x1000[i]))
      }
      if (!is.na(resumen$prom_dias_estada[i])) {
        cat(sprintf("    Días estada: %.1f (prom) / %.0f (med)\n",
                    resumen$prom_dias_estada[i], resumen$med_dias_estada[i]))
      }
    }
  }

  return(resumen)
}


#' Calcular indicadores desagregados por variable
#'
#' @param datos Data frame con columnas necesarias
#' @param var_desglose Nombre de la variable de desagregación en datos EH
#' @param denominadores_censo Tibble del censo con columnas: categoría, total, pertenece
#' @param col_join_censo Nombre de la columna en denominadores_censo para hacer join
#' @param col_pertenencia Columna de pertenencia (default: "PERTENENCIA2")
#' @param anos_estudio Número de años (default: 13)
#' @param calcular_tasas Si FALSE, solo proporciones y razones (para región)
#' @param verbose Mostrar mensajes (default: TRUE)
#'
#' @return Tibble con indicadores por categoría y grupo
#' @export
calcular_indicadores_desagregados <- function(datos,
                                              var_desglose,
                                              denominadores_censo,
                                              col_join_censo,
                                              col_pertenencia = "PERTENENCIA2",
                                              anos_estudio = 13,
                                              calcular_tasas = TRUE,
                                              verbose = TRUE) {

  if (verbose) {
    cat(sprintf("\n═══ INDICADORES POR %s ═══\n", toupper(var_desglose)))
    if (!calcular_tasas) cat("  (Solo proporciones y razones, sin tasas)\n")
  }

  tiene_dias <- "DIAS_ESTADA" %in% names(datos)
  tiene_cond <- "COND_EGR" %in% names(datos)

  # Calcular conteos por categoría y grupo
  conteos <- datos %>%
    dplyr::mutate(
      grupo = ifelse(.data[[col_pertenencia]] == 1, "PO", "PG")
    ) %>%
    dplyr::group_by(categoria = .data[[var_desglose]], grupo) %>%
    dplyr::summarise(
      n_egresos = dplyr::n(),
      n_fallecidos = if (tiene_cond) sum(COND_EGR == 2, na.rm = TRUE) else NA_integer_,
      prom_dias = if (tiene_dias) mean(DIAS_ESTADA, na.rm = TRUE) else NA_real_,
      med_dias = if (tiene_dias) stats::median(DIAS_ESTADA, na.rm = TRUE) else NA_real_,
      .groups = "drop"
    )

  # Totales por grupo (para proporciones)
  totales_grupo <- datos %>%
    dplyr::mutate(grupo = ifelse(.data[[col_pertenencia]] == 1, "PO", "PG")) %>%
    dplyr::count(grupo, name = "total_grupo")

  conteos <- conteos %>%
    dplyr::left_join(totales_grupo, by = "grupo") %>%
    dplyr::mutate(
      prop_egresos_x1000 = (n_egresos / total_grupo) * 1000,
      prop_letalidad_x1000 = ifelse(!is.na(n_fallecidos) & n_egresos > 0,
                                    (n_fallecidos / n_egresos) * 1000,
                                    NA_real_)
    )

  # Agregar denominadores censales si calcular_tasas
  if (calcular_tasas) {
    # Preparar denominadores: necesita columnas pob_po y pob_pg por categoría
    denom <- denominadores_censo %>%
      dplyr::transmute(
        categoria = as.character(.data[[col_join_censo]]),
        pob_po = as.numeric(pertenece),
        pob_pg = as.numeric(total - pertenece)
      )

    conteos <- conteos %>%
      dplyr::mutate(categoria = as.character(categoria)) %>%
      dplyr::left_join(denom, by = "categoria") %>%
      dplyr::mutate(
        poblacion = ifelse(grupo == "PO", pob_po, pob_pg),
        persona_anos = poblacion * anos_estudio,
        tasa_x1000 = ifelse(!is.na(poblacion) & poblacion > 0,
                            (n_egresos / persona_anos) * 1000,
                            NA_real_)
      ) %>%
      dplyr::select(-pob_po, -pob_pg)
  } else {
    conteos <- conteos %>%
      dplyr::mutate(
        categoria = as.character(categoria),
        poblacion = NA_real_,
        persona_anos = NA_real_,
        tasa_x1000 = NA_real_
      )
  }

  # Calcular razón PO/PG para proporciones
  razon <- conteos %>%
    dplyr::select(categoria, grupo, prop_egresos_x1000) %>%
    tidyr::pivot_wider(
      names_from = grupo,
      values_from = prop_egresos_x1000,
      names_prefix = "prop_"
    ) %>%
    dplyr::mutate(
      razon_po_pg = ifelse(!is.na(prop_PG) & prop_PG > 0, prop_PO / prop_PG, NA_real_)
    ) %>%
    dplyr::select(categoria, razon_po_pg)

  resultado <- conteos %>%
    dplyr::left_join(razon, by = "categoria") %>%
    dplyr::select(categoria, grupo, n_egresos, total_grupo,
                  prop_egresos_x1000, poblacion, persona_anos, tasa_x1000,
                  n_fallecidos, prop_letalidad_x1000,
                  prom_dias, med_dias, razon_po_pg) %>%
    dplyr::arrange(categoria, desc(grupo))

  if (verbose) {
    n_cat <- length(unique(resultado$categoria))
    cat(sprintf("  %d categorías procesadas\n", n_cat))
  }

  return(resultado)
}


#' Crear tabla flextable de indicadores
#'
#' @param datos_indicadores Resultado de calcular_indicadores_globales o _desagregados
#' @param titulo Título de la tabla
#' @param incluir_tasas Incluir columna de tasas (default: TRUE)
#' @param tamano_fuente Tamaño de fuente (default: 8)
#' @param formato Formato: "global" para indicadores globales, "desagregado" para desagregados
#'
#' @return Objeto flextable
#' @export
crear_tabla_indicadores <- function(datos_indicadores,
                                    titulo,
                                    incluir_tasas = TRUE,
                                    tamano_fuente = 8,
                                    formato = c("global", "desagregado")) {

  formato <- match.arg(formato)

  if (formato == "global") {
    # Tabla global: una fila por grupo
    tabla_df <- datos_indicadores %>%
      dplyr::mutate(
        n_egresos_fmt = format(n_egresos, big.mark = ","),
        poblacion_fmt = format(poblacion, big.mark = ","),
        persona_anos_fmt = format(persona_anos, big.mark = ",")
      ) %>%
      dplyr::select(
        Grupo = grupo,
        Egresos = n_egresos_fmt,
        Poblacion = poblacion_fmt,
        Persona_anos = persona_anos_fmt,
        Tasa_egresos = tasa_egresos_x1000,
        Fallecidos = n_fallecidos,
        Letalidad = prop_letalidad_x1000,
        Dias_prom = prom_dias_estada,
        Dias_med = med_dias_estada
      )

    ft <- flextable::flextable(tabla_df) %>%
      flextable::set_header_labels(
        Grupo = "Grupo",
        Egresos = "N° Egresos",
        Poblacion = "Población",
        Persona_anos = "Persona-años",
        Tasa_egresos = "Tasa egresos\n(x1000 p-a)",
        Fallecidos = "Fallecidos",
        Letalidad = "Letalidad\n(x1000)",
        Dias_prom = "Días estada\n(prom)",
        Dias_med = "Días estada\n(med)"
      ) %>%
      flextable::colformat_double(
        j = c("Tasa_egresos", "Letalidad", "Dias_prom", "Dias_med"),
        digits = 2
      ) %>%
      flextable::colformat_num(j = "Fallecidos", big.mark = ",")

  } else {
    # Tabla desagregada: pivotar PO y PG lado a lado
    po_data <- datos_indicadores %>%
      dplyr::filter(grupo == "PO") %>%
      dplyr::select(categoria, n_po = n_egresos,
                    dplyr::any_of(c(tasa_po = "tasa_x1000")),
                    prop_po = prop_egresos_x1000,
                    let_po = prop_letalidad_x1000,
                    dias_po = prom_dias,
                    razon_po_pg)

    pg_data <- datos_indicadores %>%
      dplyr::filter(grupo == "PG") %>%
      dplyr::select(categoria, n_pg = n_egresos,
                    dplyr::any_of(c(tasa_pg = "tasa_x1000")),
                    prop_pg = prop_egresos_x1000,
                    let_pg = prop_letalidad_x1000,
                    dias_pg = prom_dias)

    tabla_df <- dplyr::left_join(po_data, pg_data, by = "categoria")

    # Seleccionar columnas según si incluir tasas
    if (incluir_tasas && "tasa_po" %in% names(tabla_df)) {
      ft <- flextable::flextable(tabla_df) %>%
        flextable::set_header_labels(
          categoria = "Categoría",
          n_po = "N° Egresos\nPO",
          n_pg = "N° Egresos\nPG",
          tasa_po = "Tasa PO\n(x1000 p-a)",
          tasa_pg = "Tasa PG\n(x1000 p-a)",
          prop_po = "Prop. PO\n(x1000)",
          prop_pg = "Prop. PG\n(x1000)",
          let_po = "Letalidad PO\n(x1000)",
          let_pg = "Letalidad PG\n(x1000)",
          dias_po = "Días PO\n(prom)",
          dias_pg = "Días PG\n(prom)",
          razon_po_pg = "Razón\nPO/PG"
        ) %>%
        flextable::colformat_double(
          j = c("tasa_po", "tasa_pg", "prop_po", "prop_pg",
                "let_po", "let_pg", "dias_po", "dias_pg", "razon_po_pg"),
          digits = 2
        )
    } else {
      # Sin tasas (ej: región)
      tabla_df <- tabla_df %>%
        dplyr::select(-dplyr::any_of(c("tasa_po", "tasa_pg")))

      ft <- flextable::flextable(tabla_df) %>%
        flextable::set_header_labels(
          categoria = "Categoría",
          n_po = "N° Egresos\nPO",
          n_pg = "N° Egresos\nPG",
          prop_po = "Prop. PO\n(x1000)",
          prop_pg = "Prop. PG\n(x1000)",
          let_po = "Letalidad PO\n(x1000)",
          let_pg = "Letalidad PG\n(x1000)",
          dias_po = "Días PO\n(prom)",
          dias_pg = "Días PG\n(prom)",
          razon_po_pg = "Razón\nPO/PG"
        ) %>%
        flextable::colformat_double(
          j = c("prop_po", "prop_pg", "let_po", "let_pg",
                "dias_po", "dias_pg", "razon_po_pg"),
          digits = 2
        )
    }

    ft <- ft %>%
      flextable::colformat_num(j = c("n_po", "n_pg"), big.mark = ",")

    # Colores condicionales: rojo si razón > 1, azul si < 1
    if ("razon_po_pg" %in% names(tabla_df)) {
      ft <- ft %>%
        flextable::bg(i = ~ razon_po_pg > 1.1, bg = "#FFEBEE", part = "body") %>%
        flextable::bg(i = ~ razon_po_pg < 0.9, bg = "#E3F2FD", part = "body")
    }
  }

  # Formato común
  ft <- ft %>%
    flextable::align(align = "center", part = "all") %>%
    flextable::bold(part = "header") %>%
    flextable::fontsize(size = tamano_fuente, part = "all") %>%
    flextable::set_caption(titulo) %>%
    flextable::theme_booktabs() %>%
    flextable::autofit()

  return(ft)
}
