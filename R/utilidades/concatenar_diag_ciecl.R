# ==============================================================================
# FUNCION: concatenar_diag_ciecl
# ==============================================================================
# 
# DESCRIPCION:
#   Concatena códigos diagnósticos CIE-10 con sus descripciones en español
#   usando el paquete ciecl (39,873 códigos oficiales MINSAL/DEIS v2018)
#   Ejemplo: "J189" -> "J189 - Neumonía, no especificada"
#
# PARAMETROS:
#   @param data          Data frame con columna de códigos diagnóstico
#   @param col_diag      Nombre de la columna con códigos diagnóstico (default: "DIAG1")
#   @param col_destino   Nombre de la nueva columna con código + descripción (default: "DIAG_COMPLETO")
#   @param normalizar    Normalizar códigos antes de buscar (default: FALSE)
#   @param verbose       Mostrar mensajes de progreso (default: TRUE)
#
# RETORNA:
#   Data frame con nueva columna concatenada
#
# DEPENDENCIAS:
#   - ciecl (cie_lookup)
#   - dplyr (mutate, left_join, select)
#   - stringr (str_detect)
#
# VENTAJAS sobre concatenar_diag_cie10():
#   - Base de datos más completa (39,873 vs ~8,000 códigos)
#   - Sin dependencia de archivos externos (Lock_sensible/)
#   - Normalización automática de formatos (E110, E11.0, e11.0)
#   - Búsqueda vectorizada optimizada con SQLite
#   - Incluye códigos capitulares (E11, J44, I10)
#   - Actualizada con versión oficial MINSAL/DEIS 2018
#
# EJEMPLO:
#   datos_con_desc <- concatenar_diag_ciecl(datos_homologados)
#   # DIAG1: "J189"
#   # DIAG_COMPLETO: "J189 - Neumonía, no especificada"
#
# ==============================================================================

concatenar_diag_ciecl <- function(data, 
                                   col_diag = "DIAG1", 
                                   col_destino = "DIAG_COMPLETO",
                                   normalizar = TRUE,
                                   verbose = TRUE) {
  
  # Verificar que ciecl está disponible
  if (!requireNamespace("ciecl", quietly = TRUE)) {
    stop("El paquete 'ciecl' es necesario. Instalar con: remotes::install_github('Rodotasso/ciecl')")
  }
  
  # Verificar que exista la columna
  if (!(col_diag %in% names(data))) {
    stop(paste("La columna", col_diag, "no existe en los datos"))
  }
  
  if (verbose) {
    cat("\u2550\u2550\u2550 CONCATENANDO DIAGNOSTICOS CON ciecl \u2550\u2550\u2550\n\n")
  }
  
  # Extraer códigos únicos
  codigos_unicos <- unique(data[[col_diag]][!is.na(data[[col_diag]])])
  
  if (verbose) {
    cat("Codigos unicos a buscar:", format(length(codigos_unicos), big.mark = ","), "\n")
    cat("  \u2022 Base de datos: MINSAL/DEIS v2018 (39,873 codigos)\n")
    cat("  \u2022 Incluye: Codigos capitulares (J44, I10, E11, etc.)\n")
    cat("  \u2022 Modo: Vectorizado con SQLite\n")
    if (normalizar) {
      cat("  \u2022 Normalizacion: ACTIVA (acepta E110, E11.0, e11.0)\n")
    }
    cat("\n")
  }
  
  # Realizar búsqueda con cie_lookup()
  inicio <- Sys.time()
  
  if (verbose) {
    cat("Ejecutando cie_lookup()...\n")
  }
  
  suppressMessages({
    descripciones_cie <- ciecl::cie_lookup(
      codigo = codigos_unicos, 
      normalizar = normalizar,
      descripcion_completa = TRUE
    )
  })
  
  tiempo <- as.numeric(difftime(Sys.time(), inicio, units = "secs"))
  
  if (verbose) {
    cat("\u2713 Busqueda completada:", nrow(descripciones_cie), "codigos encontrados\n\n")
  }
  
  # Crear tabla de mapeo: codigo_original -> codigo_normalizado -> descripcion
  # Para hacer match correcto cuando los códigos originales no tienen punto
  if (normalizar && nrow(descripciones_cie) > 0) {
    # Crear función para quitar punto de un código
    quitar_punto <- function(x) gsub("\\.", "", x)
    
    # Crear tabla de lookup con código sin punto para hacer match
    tabla_lookup <- descripciones_cie %>%
      dplyr::mutate(codigo_sin_punto = quitar_punto(codigo)) %>%
      dplyr::select(codigo_sin_punto, descripcion_concatenada = descripcion_completa)
    
    # Quitar punto de los códigos originales para hacer match
    data_resultado <- data %>%
      dplyr::mutate(.codigo_temp = gsub("\\.", "", .data[[col_diag]])) %>%
      left_join(tabla_lookup, by = c(".codigo_temp" = "codigo_sin_punto")) %>%
      mutate(
        !!col_destino := ifelse(
          !is.na(descripcion_concatenada),
          descripcion_concatenada,
          as.character(.data[[col_diag]])
        )
      ) %>%
      dplyr::select(-descripcion_concatenada, -.codigo_temp)
  } else {
    # Sin normalización: join directo
    data_resultado <- data %>%
      left_join(
        descripciones_cie %>% 
          dplyr::select(codigo, descripcion_concatenada = descripcion_completa),
        by = setNames("codigo", col_diag)
      ) %>%
      mutate(
        !!col_destino := ifelse(
          !is.na(descripcion_concatenada),
          descripcion_concatenada,
          as.character(.data[[col_diag]])
        )
      ) %>%
      dplyr::select(-descripcion_concatenada)
  }
  
  # Reportar estadísticas
  total_codigos <- sum(!is.na(data[[col_diag]]))
  con_descripcion <- sum(
    !is.na(data_resultado[[col_destino]]) & 
    stringr::str_detect(data_resultado[[col_destino]], " - ")
  )
  pct_exito <- (con_descripcion / total_codigos) * 100
  
  if (verbose) {
    cat("\u2550\u2550\u2550 RESULTADO DE BUSQUEDA CIE-10 \u2550\u2550\u2550\n")
    cat("  \u2022 Codigos unicos procesados:", format(length(codigos_unicos), big.mark = ","), "\n")
    cat("  \u2022 Egresos con descripcion:", format(con_descripcion, big.mark = ","), "\n")
    cat("  \u2022 Tasa de exito:", sprintf("%.1f%%", pct_exito), "\n")
    cat("  \u2022 Tiempo total:", sprintf("%.2f", tiempo), "segundos\n")
    cat("  \u2022 Rendimiento:", sprintf("%.0f", length(codigos_unicos)/tiempo), "codigos/seg\n")
    cat("  \u2022 Metodo: cie_lookup() vectorizado (paquete ciecl)\n\n")
  }
  
  return(data_resultado)
}


# ==============================================================================
# FUNCION: obtener_descripciones_ciecl
# ==============================================================================
# 
# DESCRIPCION:
#   Obtiene tabla de descripciones CIE-10 para un vector de códigos
#   usando el paquete ciecl. Útil para pre-cargar descripciones.
#
# PARAMETROS:
#   @param codigos       Vector de códigos CIE-10
#   @param normalizar    Normalizar códigos antes de buscar (default: FALSE)
#   @param verbose       Mostrar mensajes de progreso (default: TRUE)
#
# RETORNA:
#   Data frame con columnas: codigo, descripcion, descripcion_completa
#
# EJEMPLO:
#   codigos_unicos <- unique(datos$DIAG1)
#   tabla_desc <- obtener_descripciones_ciecl(codigos_unicos)
#
# ==============================================================================

obtener_descripciones_ciecl <- function(codigos, 
                                         normalizar = FALSE,
                                         verbose = TRUE) {
  
  # Verificar que ciecl está disponible
  if (!requireNamespace("ciecl", quietly = TRUE)) {
    stop("El paquete 'ciecl' es necesario. Instalar con: remotes::install_github('Rodotasso/ciecl')")
  }
  
  # Eliminar NAs
  codigos_limpio <- codigos[!is.na(codigos)]
  
  if (verbose) {
    cat("Obteniendo descripciones para", length(codigos_limpio), "codigos...\n")
  }
  
  # Realizar búsqueda
  suppressMessages({
    resultado <- ciecl::cie_lookup(
      codigo = codigos_limpio, 
      normalizar = normalizar,
      descripcion_completa = TRUE
    )
  })
  
  if (verbose) {
    cat("\u2713", nrow(resultado), "codigos encontrados\n")
  }
  
  return(resultado)
}


# ==============================================================================
# FUNCION: validar_codigos_ciecl
# ==============================================================================
# 
# DESCRIPCION:
#   Valida un vector de códigos CIE-10 usando el paquete ciecl
#   Identifica códigos válidos, inválidos y problemáticos
#
# PARAMETROS:
#   @param codigos       Vector de códigos CIE-10 a validar
#   @param verbose       Mostrar resumen de validación (default: TRUE)
#
# RETORNA:
#   Data frame con columnas: codigo, valido (TRUE/FALSE)
#
# EJEMPLO:
#   codigos <- c("E11.0", "INVALIDO", "J44", "Z00")
#   validacion <- validar_codigos_ciecl(codigos)
#
# ==============================================================================

validar_codigos_ciecl <- function(codigos, verbose = TRUE) {
  
  # Verificar que ciecl está disponible
  if (!requireNamespace("ciecl", quietly = TRUE)) {
    stop("El paquete 'ciecl' es necesario. Instalar con: remotes::install_github('Rodotasso/ciecl')")
  }
  
  # Eliminar NAs
  codigos_limpio <- codigos[!is.na(codigos)]
  
  if (verbose) {
    cat("Validando", length(codigos_limpio), "codigos...\n")
  }
  
  # Validar con ciecl
  validacion <- ciecl::cie_validate_vector(codigos_limpio)
  
  resultado <- data.frame(
    codigo = codigos_limpio,
    valido = validacion,
    stringsAsFactors = FALSE
  )
  
  if (verbose) {
    n_validos <- sum(validacion)
    n_invalidos <- sum(!validacion)
    pct_validos <- (n_validos / length(validacion)) * 100
    
    cat("\n\u2550\u2550\u2550 RESULTADO DE VALIDACION \u2550\u2550\u2550\n")
    cat("  \u2022 Codigos validos:", format(n_validos, big.mark = ","), 
        sprintf("(%.1f%%)", pct_validos), "\n")
    cat("  \u2022 Codigos invalidos:", format(n_invalidos, big.mark = ","), 
        sprintf("(%.1f%%)", 100 - pct_validos), "\n\n")
    
    if (n_invalidos > 0 && n_invalidos <= 10) {
      cat("Codigos invalidos encontrados:\n")
      invalidos <- resultado$codigo[!resultado$valido]
      cat("  -", paste(invalidos, collapse = "\n  - "), "\n\n")
    }
  }
  
  return(resultado)
}
