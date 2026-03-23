#' Crear tabla formateada de perfil epidemiológico
#'
#' @description
#' Genera tabla flextable con formato estandarizado para perfiles
#' epidemiológicos o comparaciones PO vs PG.
#'
#' @param datos Tibble con datos del perfil o comparación
#' @param tipo Tipo de tabla: "perfil" o "comparacion"
#' @param titulo Título de la tabla
#' @param resaltar_umbral Valor umbral para resaltar filas (default: NULL)
#' @param col_umbral Columna para evaluar umbral (default: NULL)
#' @param color_resaltado Color de fondo para resaltar (default: "#E8F4F8")
#' @param tamano_fuente Tamaño de fuente (default: 8)
#' @param incluir_rr Logical. En tipo "comparacion", incluir columnas de RR crudo
#'   y direccion (default: TRUE para retrocompatibilidad)
#'
#' @return Objeto flextable formateado
#'
#' @details
#' Tipo "perfil":
#' - Columnas: ranking, diagnóstico, casos, tasa, proporción, porcentajes
#' - Resalta filas con % > umbral
#'
#' Tipo "comparacion":
#' - Columnas: diagnóstico, casos PO/PG, tasas PO/PG, diferencia, RR, dirección
#' - Resalta según RR (rojo ≥1.5, azul ≤0.67)
#' - Si incluir_rr = FALSE: excluye RR/direccion, colorea por dif_tasa_anual
#'
#' @examples
#' tabla <- crear_tabla_perfil(
#'   datos = perfil_po,
#'   tipo = "perfil",
#'   titulo = "Top 20 Diagnósticos - Pueblos Originarios"
#' )
#'
#' @export
crear_tabla_perfil <- function(datos,
                               tipo = c("perfil", "comparacion"),
                               titulo,
                               resaltar_umbral = NULL,
                               col_umbral = NULL,
                               color_resaltado = "#E8F4F8",
                               tamano_fuente = 8,
                               incluir_rr = TRUE) {
  
  tipo <- match.arg(tipo)
  
  if (tipo == "perfil") {
    # Columnas opcionales presentes en los datos
    tiene_dias <- "promedio_dias_estada" %in% names(datos)
    tiene_letalidad <- "tasa_letalidad_x1000" %in% names(datos)
    
    # Tabla de perfil (top diagnósticos)
    tabla <- datos %>%
      flextable::flextable() %>%
      flextable::set_header_labels(
        ranking = "#",
        DIAG_COMPLETO = "Diagnóstico",
        n_casos = "N° Egresos",
        tasa_anual = "Tasa Anual\n(x1000 p-a)",
        prop_x1000_egresos = "Proporción\n(x1000 egresos)",
        pct_total = "% Total",
        pct_acumulado = "% Acum.",
        promedio_dias_estada = "Días Estada\n(prom)",
        mediana_dias_estada = "Días Estada\n(med)",
        n_fallecidos = "N° Fallec.",
        tasa_letalidad_x1000 = "Letalidad\n(x1000)"
      ) %>%
      flextable::colformat_num(j = "n_casos", big.mark = ",") %>%
      flextable::colformat_double(
        j = c("tasa_anual", "prop_x1000_egresos", "pct_total", "pct_acumulado"), 
        digits = 2
      ) %>%
      flextable::align(align = "center", part = "all") %>%
      flextable::align(j = "DIAG_COMPLETO", align = "left", part = "body") %>%
      flextable::bold(part = "header") %>%
      flextable::fontsize(size = tamano_fuente, part = "all") %>%
      flextable::width(j = "DIAG_COMPLETO", width = 3.0) %>%
      flextable::width(j = c("tasa_anual", "prop_x1000_egresos"), width = 0.9) %>%
      flextable::width(j = c("pct_total", "pct_acumulado"), width = 0.7) %>%
      flextable::set_caption(titulo) %>%
      flextable::theme_booktabs()
    
    # Formatear columnas opcionales si existen
    if (tiene_dias) {
      tabla <- tabla %>%
        flextable::colformat_double(
          j = c("promedio_dias_estada", "mediana_dias_estada"), digits = 1
        ) %>%
        flextable::width(j = c("promedio_dias_estada", "mediana_dias_estada"), width = 0.8)
    }
    if (tiene_letalidad) {
      tabla <- tabla %>%
        flextable::colformat_double(j = "tasa_letalidad_x1000", digits = 2) %>%
        flextable::width(j = "tasa_letalidad_x1000", width = 0.8) %>%
        flextable::colformat_num(j = "n_fallecidos", big.mark = ",") %>%
        flextable::width(j = "n_fallecidos", width = 0.7)
    }
    
    # Resaltar si se especifica umbral
    if (!is.null(resaltar_umbral) && !is.null(col_umbral)) {
      # Crear expresión con valor del umbral
      expr_filtro <- paste0(col_umbral, " > ", resaltar_umbral)
      tabla <- tabla %>%
        flextable::bg(
          i = as.formula(paste("~", expr_filtro)),
          bg = color_resaltado, 
          part = "body"
        )
    }
    
  } else if (tipo == "comparacion") {
    tiene_dias <- all(c("prom_dias_po", "prom_dias_pg") %in% names(datos))
    tiene_letalidad <- all(c("tasa_letalidad_po_x1000", "tasa_letalidad_pg_x1000") %in% names(datos))

    # Excluir columnas de RR si incluir_rr = FALSE
    if (!incluir_rr) {
      cols_excluir <- intersect(c("rr_crudo", "rr_prop", "direccion"), names(datos))
      datos <- datos %>% dplyr::select(-dplyr::any_of(cols_excluir))
    }

    # Headers base
    headers <- list(
      DIAG_COMPLETO = "Diagn\u00f3stico",
      casos_po = "Egresos\nPO",
      casos_pg = "Egresos\nPG",
      tasa_anual_po = "Tasa PO\n(x1000 p-a)",
      tasa_anual_pg = "Tasa PG\n(x1000 p-a)",
      dif_tasa_anual = "Diferencia\n(PO - PG)",
      prom_dias_po = "D\u00edas Est.\nPO",
      prom_dias_pg = "D\u00edas Est.\nPG",
      tasa_letalidad_po_x1000 = "Letalidad\nPO (x1000)",
      tasa_letalidad_pg_x1000 = "Letalidad\nPG (x1000)"
    )
    if (incluir_rr) {
      headers$rr_crudo <- "RR crudo\n(PO/PG)"
      headers$direccion <- "Dir."
    }

    # Columnas numericas para formato
    cols_double <- c("tasa_anual_po", "tasa_anual_pg", "dif_tasa_anual")
    if (incluir_rr) cols_double <- c(cols_double, "rr_crudo")

    # Filtrar headers a columnas presentes en datos
    headers <- headers[names(headers) %in% names(datos)]

    # Tabla de comparacion PO vs PG
    tabla <- flextable::flextable(datos)
    tabla <- do.call(flextable::set_header_labels, c(list(x = tabla), headers))
    tabla <- tabla %>%
      flextable::colformat_num(j = c("casos_po", "casos_pg"), big.mark = ",") %>%
      flextable::colformat_double(
        j = intersect(cols_double, names(datos)),
        digits = 2
      ) %>%
      flextable::align(align = "center", part = "all") %>%
      flextable::align(j = "DIAG_COMPLETO", align = "left", part = "body") %>%
      flextable::bold(part = "header") %>%
      flextable::fontsize(size = tamano_fuente - 0.5, part = "all") %>%
      flextable::width(j = "DIAG_COMPLETO", width = 2.8) %>%
      flextable::width(j = c("casos_po", "casos_pg"), width = 0.7) %>%
      flextable::set_caption(titulo) %>%
      flextable::theme_booktabs()

    if (incluir_rr && "direccion" %in% names(datos)) {
      tabla <- tabla %>%
        flextable::width(j = "direccion", width = 0.5)
    }

    # Formatear columnas opcionales si existen
    if (tiene_dias) {
      tabla <- tabla %>%
        flextable::colformat_double(j = c("prom_dias_po", "prom_dias_pg"), digits = 1) %>%
        flextable::width(j = c("prom_dias_po", "prom_dias_pg"), width = 0.7)
    }
    if (tiene_letalidad) {
      tabla <- tabla %>%
        flextable::colformat_double(
          j = c("tasa_letalidad_po_x1000", "tasa_letalidad_pg_x1000"), digits = 2
        ) %>%
        flextable::width(j = c("tasa_letalidad_po_x1000", "tasa_letalidad_pg_x1000"), width = 0.8)
    }

    # Colores condicionales
    if (incluir_rr && "rr_crudo" %in% names(datos)) {
      tabla <- tabla %>%
        flextable::bg(i = ~ rr_crudo >= 1.5, bg = "#FFEBEE", part = "body") %>%
        flextable::bg(i = ~ rr_crudo <= 0.67, bg = "#E3F2FD", part = "body") %>%
        flextable::bg(i = ~ dif_tasa_anual > 0, j = "direccion",
                     bg = "#FFEBEE", part = "body") %>%
        flextable::bg(i = ~ dif_tasa_anual < 0, j = "direccion",
                     bg = "#E3F2FD", part = "body")
    } else {
      # Sin RR: colorear filas segun dif_tasa_anual
      tabla <- tabla %>%
        flextable::bg(i = ~ dif_tasa_anual > 0, bg = "#FFEBEE", part = "body") %>%
        flextable::bg(i = ~ dif_tasa_anual < 0, bg = "#E3F2FD", part = "body")
    }
  }
  
  # Autofit final
  tabla <- flextable::autofit(tabla)
  
  return(tabla)
}
