#' Crear tabla flextable formateada para resultados de CCC
#'
#' @description
#' Genera una tabla flextable con formato estandarizado, colores según
#' interpretación de CCC y estilos predefinidos
#'
#' @param datos Tibble con resultados de CCC (debe incluir columna `Lin's CCC` e `Interpretacion`)
#' @param titulo Título de la tabla
#' @param subtitulo Subtítulo o nota al pie (opcional)
#' @param aplicar_colores Aplicar colores a la columna Lin's CCC según valor (default: TRUE)
#' @param col_ccc Nombre de la columna con valores de CCC (default: "Lin's CCC")
#' @param umbral_azul Umbral para color azul - casi perfecta (default: 0.6)
#' @param umbral_naranja Umbral para color naranja - moderada (default: 0.4)
#'
#' @return Objeto flextable formateado
#'
#' @examples
#' tabla <- crear_tabla_ccc(
#'   resultados_ccc,
#'   titulo = "Concordancia por desagregaciones",
#'   subtitulo = "CCC calculado con transformación Z (IC 95%)"
#' )
#'
#' @export
crear_tabla_ccc <- function(datos,
                            titulo,
                            subtitulo = NULL,
                            aplicar_colores = TRUE,
                            col_ccc = "Lin's CCC",
                            umbral_azul = 0.6,
                            umbral_naranja = 0.4) {
  
  if (!requireNamespace("flextable", quietly = TRUE)) {
    stop("El paquete 'flextable' no está instalado.\n",
         "Instalar con: install.packages('flextable')")
  }
  
  # Validaciones
  if (!col_ccc %in% names(datos)) {
    stop("La columna '", col_ccc, "' no existe en los datos")
  }
  
  # Crear flextable base
  tabla <- datos %>%
    flextable::flextable() %>%
    flextable::set_caption(caption = titulo) %>%
    flextable::theme_booktabs() %>%
    flextable::autofit()
  
  # Aplicar negritas a columna CCC
  if (col_ccc %in% names(datos)) {
    tabla <- tabla %>%
      flextable::bold(j = col_ccc, bold = TRUE)
  }
  
  # Aplicar colores según valor de CCC
  if (aplicar_colores && col_ccc %in% names(datos)) {
    for (i in 1:nrow(datos)) {
      valor <- datos[[col_ccc]][i]
      
      # Determinar color según umbrales
      if (!is.na(valor)) {
        color <- dplyr::case_when(
          valor >= umbral_azul ~ "#0072B2",      # Azul: Sustancial/Casi perfecta
          valor >= umbral_naranja ~ "#E69F00",   # Naranja: Moderada
          TRUE ~ "#D55E00"                       # Rojo: Aceptable/Leve
        )
        
        tabla <- tabla %>%
          flextable::color(i = i, j = col_ccc, color = color)
      }
    }
  }
  
  # Agregar subtítulo/nota al pie si se especifica
  if (!is.null(subtitulo)) {
    tabla <- tabla %>%
      flextable::add_footer_lines(subtitulo)
  }
  
  return(tabla)
}


#' Crear tabla temporal con colores para variación anual
#'
#' @description
#' Genera tabla flextable para análisis temporal con colores en la
#' columna de variación según aumento/disminución
#'
#' @param datos_anuales Tibble con datos por año (salida de calcular_ccc_temporal)
#' @param titulo Título de la tabla
#' @param col_variacion Nombre columna de variación (default: "variacion_anual_pp")
#' @param umbral_verde Umbral positivo para color verde (default: 0.5)
#' @param umbral_rojo Umbral negativo para color rojo (default: -0.5)
#'
#' @return Objeto flextable formateado
#'
#' @export
crear_tabla_temporal <- function(datos_anuales,
                                  titulo = "Evolución temporal del % de pertenencia",
                                  col_variacion = "variacion_anual_pp",
                                  umbral_verde = 0.5,
                                  umbral_rojo = -0.5) {
  
  if (!requireNamespace("flextable", quietly = TRUE)) {
    stop("El paquete 'flextable' no está instalado.")
  }
  
  # Preparar datos para tabla
  tabla_datos <- datos_anuales %>%
    dplyr::mutate(
      Año = anio,
      `N Egresos` = format(n_egresos, big.mark = ","),
      `% Pertenencia` = sprintf("%.2f", porcentaje_enriquecida),
      `Variación (pp)` = ifelse(
        is.na(!!rlang::sym(col_variacion)),
        "-",
        sprintf("%+.2f", !!rlang::sym(col_variacion))
      )
    ) %>%
    dplyr::select(Año, `N Egresos`, `% Pertenencia`, `Variación (pp)`)
  
  # Crear flextable
  tabla <- tabla_datos %>%
    flextable::flextable() %>%
    flextable::set_caption(caption = titulo) %>%
    flextable::theme_booktabs() %>%
    flextable::bold(j = "% Pertenencia", bold = TRUE) %>%
    flextable::autofit()
  
  # Aplicar colores a variación anual
  for (i in 2:nrow(tabla_datos)) {  # Empezar en 2 (primer año no tiene variación)
    var_texto <- tabla_datos$`Variación (pp)`[i]
    
    if (var_texto != "-") {
      var_num <- as.numeric(gsub("[^-0-9.]", "", var_texto))
      
      color <- dplyr::case_when(
        var_num > umbral_verde ~ "#009E73",    # Verde: aumento
        var_num < umbral_rojo ~ "#D55E00",     # Rojo: disminución
        TRUE ~ "#666666"                        # Gris: estable
      )
      
      tabla <- tabla %>%
        flextable::color(i = i, j = "Variación (pp)", color = color)
    }
  }
  
  # Agregar notas al pie
  tabla <- tabla %>%
    flextable::add_footer_lines(c(
      "Variación anual: diferencia en puntos porcentuales respecto al año anterior",
      paste0("Verde: aumento >", umbral_verde, " pp | ",
             "Rojo: disminución <", umbral_rojo, " pp | ",
             "Gris: cambio estable")
    ))
  
  return(tabla)
}
