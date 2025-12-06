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
                               tamano_fuente = 8) {
  
  tipo <- match.arg(tipo)
  
  if (tipo == "perfil") {
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
        pct_acumulado = "% Acum."
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
      flextable::width(j = "DIAG_COMPLETO", width = 3.2) %>%
      flextable::width(j = c("tasa_anual", "prop_x1000_egresos"), width = 0.9) %>%
      flextable::width(j = c("pct_total", "pct_acumulado"), width = 0.7) %>%
      flextable::set_caption(titulo) %>%
      flextable::theme_booktabs()
    
    # Resaltar si se especifica umbral
    if (!is.null(resaltar_umbral) && !is.null(col_umbral)) {
      tabla <- tabla %>%
        flextable::bg(
          i = ~ get(col_umbral) > resaltar_umbral, 
          bg = color_resaltado, 
          part = "body"
        )
    }
    
  } else if (tipo == "comparacion") {
    # Tabla de comparación PO vs PG
    tabla <- datos %>%
      flextable::flextable() %>%
      flextable::set_header_labels(
        DIAG_COMPLETO = "Diagnóstico",
        casos_po = "Egresos\nPO",
        casos_pg = "Egresos\nPG",
        tasa_anual_po = "Tasa PO\n(x1000 p-a)",
        tasa_anual_pg = "Tasa PG\n(x1000 p-a)",
        dif_tasa_anual = "Diferencia\n(PO - PG)",
        rr_crudo = "RR crudo\n(PO/PG)",
        direccion = "Dir."
      ) %>%
      flextable::colformat_num(j = c("casos_po", "casos_pg"), big.mark = ",") %>%
      flextable::colformat_double(
        j = c("tasa_anual_po", "tasa_anual_pg", "dif_tasa_anual", "rr_crudo"), 
        digits = 2
      ) %>%
      flextable::align(align = "center", part = "all") %>%
      flextable::align(j = "DIAG_COMPLETO", align = "left", part = "body") %>%
      flextable::bold(part = "header") %>%
      flextable::fontsize(size = tamano_fuente - 0.5, part = "all") %>%
      flextable::width(j = "DIAG_COMPLETO", width = 2.8) %>%
      flextable::width(j = c("casos_po", "casos_pg"), width = 0.7) %>%
      flextable::width(j = "direccion", width = 0.5) %>%
      flextable::set_caption(titulo) %>%
      flextable::theme_booktabs()
    
    # Colores según RR
    tabla <- tabla %>%
      flextable::bg(i = ~ rr_crudo >= 1.5, bg = "#FFE6E6", part = "body") %>%
      flextable::bg(i = ~ rr_crudo <= 0.67, bg = "#E6F5FF", part = "body") %>%
      flextable::bg(i = ~ dif_tasa_anual > 0, j = "direccion", 
                   bg = "#FFE6E6", part = "body") %>%
      flextable::bg(i = ~ dif_tasa_anual < 0, j = "direccion", 
                   bg = "#E6F5FF", part = "body")
  }
  
  # Autofit final
  tabla <- flextable::autofit(tabla)
  
  return(tabla)
}
