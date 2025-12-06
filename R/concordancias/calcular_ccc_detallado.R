#' Calcular Lin's CCC con tabla detallada por categorías
#'
#' @description
#' Calcula Lin's CCC para cada categoría (región, grupo etario, etc.) 
#' comparando distribuciones internas de subcategorías
#'
#' @param datos_censo Datos del Censo 2017 desagregados
#' @param datos_comparacion Datos a comparar desagregados  
#' @param columnas_categoria Columna(s) de la categoría principal (ej: "region")
#' @param columnas_subcategoria Columna(s) de subcategorías para calcular CCC (ej: "sexo", "grupo_etario")
#' @param nombre_desagregacion Nombre descriptivo
#' @param col_porcentaje_comparacion Nombre de columna de porcentaje en datos_comparacion
#' @param verbose Mostrar mensajes
#'
#' @return Lista con:
#'   - ccc_valor: Tibble con CCC global (1 fila)
#'   - tabla_detalle: Tibble con CCC por cada categoría
#'
#' @export
calcular_ccc_detallado <- function(datos_censo,
                                   datos_comparacion,
                                   columnas_categoria,
                                   columnas_subcategoria = NULL,
                                   nombre_desagregacion,
                                   col_porcentaje_comparacion = "porcentaje_pert2",
                                   verbose = TRUE) {
  
  # Validaciones básicas
  if (!requireNamespace("DescTools", quietly = TRUE)) {
    stop("El paquete 'DescTools' no está instalado.")
  }
  
  if (verbose) {
    cat("\nCalculando CCC detallado:", nombre_desagregacion, "...\n")
  }
  
  # Determinar todas las columnas de agrupación
  columnas_todas <- c(columnas_categoria, columnas_subcategoria)
  
  # Unir datos
  datos_unidos <- datos_censo %>%
    dplyr::inner_join(
      datos_comparacion,
      by = columnas_todas,
      suffix = c("_censo", "_comp")
    )
  
  # Verificar datos
  if (nrow(datos_unidos) == 0) {
    warning("No hay datos para unir en ", nombre_desagregacion)
    return(list(
      ccc_valor = tibble::tibble(
        Desagregacion = nombre_desagregacion,
        N = 0,
        `Lin's CCC` = NA_real_,
        `IC 95% Inferior` = NA_real_,
        `IC 95% Superior` = NA_real_,
        Interpretacion = "Sin datos"
      ),
      tabla_detalle = tibble::tibble()
    ))
  }
  
  # Calcular CCC GLOBAL (usando todas las combinaciones)
  porcentaje_censo_global <- datos_unidos$porcentaje_censo
  col_comp_real <- names(datos_unidos)[grepl(paste0("^", col_porcentaje_comparacion), 
                                              names(datos_unidos))][1]
  porcentaje_comp_global <- datos_unidos[[col_comp_real]]
  
  resultado_ccc_global <- tryCatch({
    DescTools::CCC(
      porcentaje_censo_global,
      porcentaje_comp_global,
      ci = "z-transform",
      conf.level = 0.95
    )
  }, error = function(e) {
    warning("Error al calcular CCC global: ", e$message)
    return(NULL)
  })
  
  # Formatear valor CCC agregado
  if (!is.null(resultado_ccc_global)) {
    ccc_valor <- formatear_resultado_ccc(resultado_ccc_global, nombre_desagregacion)
    
    if (verbose) {
      cat(sprintf("  CCC Global = %.4f [%.4f, %.4f] - %s\n",
                  ccc_valor$`Lin's CCC`,
                  ccc_valor$`IC 95% Inferior`,
                  ccc_valor$`IC 95% Superior`,
                  ccc_valor$Interpretacion))
    }
  } else {
    ccc_valor <- tibble::tibble(
      Desagregacion = nombre_desagregacion,
      N = nrow(datos_unidos),
      `Lin's CCC` = NA_real_,
      `IC 95% Inferior` = NA_real_,
      `IC 95% Superior` = NA_real_,
      Interpretacion = "Error"
    )
  }
  
  # Calcular CCC por cada categoría (si hay subcategorías)
  if (!is.null(columnas_subcategoria)) {
    # Calcular CCC para cada valor de la categoría principal
    categorias_unicas <- datos_unidos %>%
      dplyr::distinct(!!!rlang::syms(columnas_categoria)) %>%
      dplyr::pull(!!rlang::sym(columnas_categoria[1]))
    
    resultados_por_categoria <- purrr::map_dfr(categorias_unicas, function(cat_valor) {
      # Filtrar datos de esta categoría
      datos_cat <- datos_unidos %>%
        dplyr::filter(!!rlang::sym(columnas_categoria[1]) == cat_valor)
      
      if (nrow(datos_cat) < 2) {
        return(tibble::tibble(
          !!columnas_categoria[1] := cat_valor,
          `Lin's CCC` = NA_real_,
          `IC 95% Inferior` = NA_real_,
          `IC 95% Superior` = NA_real_,
          Interpretacion = "Datos insuficientes"
        ))
      }
      
      # Calcular CCC para esta categoría
      resultado_ccc_cat <- tryCatch({
        DescTools::CCC(
          datos_cat$porcentaje_censo,
          datos_cat[[col_comp_real]],
          ci = "z-transform",
          conf.level = 0.95
        )
      }, error = function(e) {
        return(NULL)
      })
      
      if (is.null(resultado_ccc_cat)) {
        return(tibble::tibble(
          !!columnas_categoria[1] := cat_valor,
          `Lin's CCC` = NA_real_,
          `IC 95% Inferior` = NA_real_,
          `IC 95% Superior` = NA_real_,
          Interpretacion = "Error"
        ))
      }
      
      # Extraer valores
      ccc_val <- resultado_ccc_cat$rho.c$est
      ic_inf <- resultado_ccc_cat$rho.c$lwr.ci
      ic_sup <- resultado_ccc_cat$rho.c$upr.ci
      
      interp <- dplyr::case_when(
        ccc_val > 0.80 ~ "Casi perfecta",
        ccc_val > 0.61 ~ "Sustancial",
        ccc_val > 0.41 ~ "Moderada",
        ccc_val > 0.21 ~ "Aceptable",
        TRUE ~ "Leve"
      )
      
      tibble::tibble(
        !!columnas_categoria[1] := cat_valor,
        `Lin's CCC` = ccc_val,
        `IC 95% Inferior` = ic_inf,
        `IC 95% Superior` = ic_sup,
        Interpretacion = interp
      )
    })
    
    tabla_detalle <- resultados_por_categoria
    
  } else {
    # Sin subcategorías, mostrar solo porcentajes
    tabla_detalle <- datos_unidos %>%
      dplyr::select(
        dplyr::all_of(columnas_categoria),
        `% Censo 2017` = porcentaje_censo,
        `% Variable Enriquecida` = !!rlang::sym(col_comp_real)
      ) %>%
      dplyr::mutate(
        `Diferencia (pp)` = `% Variable Enriquecida` - `% Censo 2017`
      ) %>%
      dplyr::arrange(dplyr::across(dplyr::all_of(columnas_categoria)))
  }
  
  if (verbose) {
    cat("  Categorías analizadas:", nrow(tabla_detalle), "\n")
  }
  
  # Retornar lista con ambos elementos
  return(list(
    ccc_valor = ccc_valor,
    tabla_detalle = tabla_detalle
  ))
}
