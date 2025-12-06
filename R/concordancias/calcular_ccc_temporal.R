#' Calcular Lin's CCC temporal (año a año)
#'
#' @description
#' Calcula Lin's CCC entre Censo 2017 y Variable Enriquecida para cada año,
#' analizando la evolución temporal de la concordancia. También calcula
#' estadísticas de tendencia y correlación temporal.
#'
#' @param datos_censo Lista con datos del Censo por región (datos_censo$por_region)
#' @param datos_egresos Datos de egresos con columna AÑO, CODIGO_REGION, y PERTENENCIA2
#' @param col_anio Nombre de la columna de año (default: "AÑO")
#' @param col_region Nombre de la columna de región (default: "CODIGO_REGION")
#' @param col_pertenencia Nombre de la columna de pertenencia (default: "PERTENENCIA2")
#' @param verbose Mostrar mensajes de progreso (default: TRUE)
#'
#' @return Lista con:
#'   - datos_anuales: Tibble con CCC y estadísticas por año
#'   - correlacion: Resultado del test de correlación temporal del CCC
#'   - modelo: Modelo de regresión lineal (CCC ~ año)
#'   - resumen: Tibble con estadísticas del período
#'
#' @examples
#' resultado_temporal <- calcular_ccc_temporal(
#'   datos_censo = datos_censo,
#'   datos_egresos = datos_sin_duplicados
#' )
#'
#' @export
calcular_ccc_temporal <- function(datos_censo,
                                   datos_egresos,
                                   col_anio = "AÑO",
                                   col_region = "CODIGO_REGION",
                                   col_pertenencia = "PERTENENCIA2",
                                   verbose = TRUE) {
  
  if (verbose) {
    cat("\n═══ ANÁLISIS DE CCC TEMPORAL (AÑO A AÑO) ═══\n\n")
  }
  
  # Validaciones
  if (!requireNamespace("DescTools", quietly = TRUE)) {
    stop("El paquete 'DescTools' no está instalado.")
  }
  
  if (!col_anio %in% names(datos_egresos)) {
    stop("Columna '", col_anio, "' no existe en datos_egresos")
  }
  
  if (!col_pertenencia %in% names(datos_egresos)) {
    stop("Columna '", col_pertenencia, "' no existe en datos_egresos")
  }
  
  if (!col_region %in% names(datos_egresos)) {
    stop("Columna '", col_region, "' no existe en datos_egresos")
  }
  
  # Obtener porcentajes del Censo por región (referencia fija)
  censo_ref <- datos_censo$por_region %>%
    dplyr::select(region, porcentaje_censo)
  
  # Obtener años únicos
  anios_disponibles <- datos_egresos %>%
    dplyr::filter(!is.na(!!rlang::sym(col_anio)),
                  !!rlang::sym(col_anio) != "No reportado") %>%
    dplyr::pull(!!rlang::sym(col_anio)) %>%
    unique() %>%
    sort()
  
  if (verbose) {
    cat("Calculando CCC para", length(anios_disponibles), "años...\n")
    cat("Años:", paste(anios_disponibles, collapse = ", "), "\n\n")
  }
  
  # Calcular CCC para cada año
  resultados_por_anio <- purrr::map_dfr(anios_disponibles, function(anio_actual) {
    
    if (verbose) {
      cat(sprintf("  Año %s... ", anio_actual))
    }
    
    # Filtrar datos del año y calcular porcentaje por región
    datos_anio <- datos_egresos %>%
      dplyr::filter(!!rlang::sym(col_anio) == anio_actual,
                    !is.na(!!rlang::sym(col_region))) %>%
      dplyr::mutate(
        pertenece_bin = ifelse(!!rlang::sym(col_pertenencia) == 1, 1, 0),
        region = as.numeric(!!rlang::sym(col_region))
      ) %>%
      dplyr::group_by(region) %>%
      dplyr::summarise(
        n_egresos = dplyr::n(),
        n_pertenece = sum(pertenece_bin, na.rm = TRUE),
        porcentaje_pert2 = (n_pertenece / n_egresos) * 100,
        .groups = "drop"
      )
    
    # Unir con Censo
    datos_unidos <- censo_ref %>%
      dplyr::inner_join(datos_anio, by = "region")
    
    # Verificar que hay suficientes datos
    if (nrow(datos_unidos) < 3) {
      if (verbose) cat("Datos insuficientes\n")
      return(tibble::tibble(
        anio = anio_actual,
        n_regiones = nrow(datos_unidos),
        ccc = NA_real_,
        ic_inferior = NA_real_,
        ic_superior = NA_real_,
        interpretacion = "Datos insuficientes"
      ))
    }
    
    # Calcular CCC
    resultado_ccc <- tryCatch({
      DescTools::CCC(
        datos_unidos$porcentaje_censo,
        datos_unidos$porcentaje_pert2,
        ci = "z-transform",
        conf.level = 0.95
      )
    }, error = function(e) {
      if (verbose) cat("Error:", e$message, "\n")
      return(NULL)
    })
    
    if (is.null(resultado_ccc)) {
      return(tibble::tibble(
        anio = anio_actual,
        n_regiones = nrow(datos_unidos),
        ccc = NA_real_,
        ic_inferior = NA_real_,
        ic_superior = NA_real_,
        interpretacion = "Error en cálculo"
      ))
    }
    
    # Extraer valores
    ccc_valor <- resultado_ccc$rho.c$est
    ic_inf <- resultado_ccc$rho.c$lwr.ci
    ic_sup <- resultado_ccc$rho.c$upr.ci
    
    # Interpretación según Landis & Koch
    interpretacion <- dplyr::case_when(
      ccc_valor < 0 ~ "Pobre",
      ccc_valor < 0.20 ~ "Leve",
      ccc_valor < 0.40 ~ "Aceptable",
      ccc_valor < 0.60 ~ "Moderada",
      ccc_valor < 0.80 ~ "Sustancial",
      TRUE ~ "Casi perfecta"
    )
    
    if (verbose) {
      cat(sprintf("CCC = %.4f [%.4f - %.4f] (%s)\n", 
                  ccc_valor, ic_inf, ic_sup, interpretacion))
    }
    
    tibble::tibble(
      anio = anio_actual,
      n_regiones = nrow(datos_unidos),
      ccc = ccc_valor,
      ic_inferior = ic_inf,
      ic_superior = ic_sup,
      interpretacion = interpretacion
    )
  })
  
  # Agregar variación anual del CCC
  datos_anuales <- resultados_por_anio %>%
    dplyr::arrange(anio) %>%
    dplyr::mutate(
      variacion_ccc = ccc - dplyr::lag(ccc)
    )
  
  # Test de correlación temporal del CCC
  datos_validos <- datos_anuales %>% dplyr::filter(!is.na(ccc))
  
  if (nrow(datos_validos) >= 3) {
    test_correlacion <- stats::cor.test(
      as.numeric(datos_validos$anio),
      datos_validos$ccc,
      method = "pearson"
    )
    
    # Modelo de regresión lineal
    modelo_lineal <- stats::lm(
      ccc ~ as.numeric(anio),
      data = datos_validos
    )
    
    # Resumen estadístico del período
    resumen_periodo <- tibble::tibble(
      ccc_promedio = mean(datos_validos$ccc, na.rm = TRUE),
      ccc_sd = stats::sd(datos_validos$ccc, na.rm = TRUE),
      ccc_minimo = min(datos_validos$ccc, na.rm = TRUE),
      ccc_maximo = max(datos_validos$ccc, na.rm = TRUE),
      ccc_rango = ccc_maximo - ccc_minimo,
      cambio_anual_ccc = stats::coef(modelo_lineal)[2],
      cambio_total_ccc = cambio_anual_ccc * (max(as.numeric(datos_validos$anio)) - min(as.numeric(datos_validos$anio))),
      correlacion_temporal = test_correlacion$estimate,
      p_valor = test_correlacion$p.value,
      tendencia_significativa = p_valor < 0.05
    )
    
    if (verbose) {
      cat("\n═══ RESUMEN ESTADÍSTICO DEL CCC TEMPORAL ═══\n")
      cat(sprintf("  - CCC promedio: %.4f\n", resumen_periodo$ccc_promedio))
      cat(sprintf("  - Desviación estándar: %.4f\n", resumen_periodo$ccc_sd))
      cat(sprintf("  - Rango: %.4f - %.4f\n", resumen_periodo$ccc_minimo, resumen_periodo$ccc_maximo))
      cat(sprintf("  - Cambio anual CCC: %+.4f/año\n", resumen_periodo$cambio_anual_ccc))
      cat(sprintf("  - Cambio total período: %+.4f\n", resumen_periodo$cambio_total_ccc))
      cat(sprintf("  - Correlación temporal: r = %.4f (p = %.4f)\n",
                  resumen_periodo$correlacion_temporal,
                  resumen_periodo$p_valor))
      cat(sprintf("  - Tendencia: %s\n",
                  ifelse(resumen_periodo$tendencia_significativa,
                         "Significativa (p<0.05)",
                         "No significativa (p≥0.05)")))
    }
  } else {
    test_correlacion <- NULL
    modelo_lineal <- NULL
    resumen_periodo <- tibble::tibble(
      ccc_promedio = NA_real_,
      ccc_sd = NA_real_,
      ccc_minimo = NA_real_,
      ccc_maximo = NA_real_,
      ccc_rango = NA_real_,
      cambio_anual_ccc = NA_real_,
      cambio_total_ccc = NA_real_,
      correlacion_temporal = NA_real_,
      p_valor = NA_real_,
      tendencia_significativa = FALSE
    )
    
    if (verbose) {
      cat("\nDatos insuficientes para análisis de tendencia temporal\n")
    }
  }
  
  # Retornar resultados
  return(list(
    datos_anuales = datos_anuales,
    correlacion = test_correlacion,
    modelo = modelo_lineal,
    resumen = resumen_periodo
  ))
}
