# ==============================================================================
# FUNCION: concatenar_diag_cie10
# ==============================================================================
# 
# DESCRIPCION:
#   Concatena el código DIAG1 con su descripción CIE-10 en español
#   Ejemplo: "J189" -> "J189 - Neumonía, no especificada"
#   Usa tabla CIE-10 de FONASA con descripciones en español
#
# PARAMETROS:
#   @param data          Data frame con columna DIAG1
#   @param col_diag      Nombre de la columna con códigos diagnóstico (default: "DIAG1")
#   @param col_destino   Nombre de la nueva columna con código + descripción (default: "DIAG_COMPLETO")
#   @param tabla_cie10   Tabla CIE-10 opcional. Si NULL, carga automáticamente.
#
# RETORNA:
#   Data frame con nueva columna concatenada
#
# DEPENDENCIAS:
#   - dplyr (mutate, left_join)
#   - stringr (str_trim)
#
# VARIABLES GLOBALES:
#   Carga: Lock_sensible/cie10_simple.RData (cie10_simple)
#
# NOTAS:
#   - Usa tabla CIE-10 de FONASA en español
#   - Si no encuentra descripción, devuelve solo el código
#   - Tabla debe tener columnas: codigo, descripcion
#
# EJEMPLO:
#   datos_con_desc <- concatenar_diag_cie10(datos_homologados)
#   # DIAG1: "J189"
#   # DIAG_COMPLETO: "J189 - Neumonía, no especificada"
#
# ==============================================================================

concatenar_diag_cie10 <- function(data, 
                                   col_diag = "DIAG1", 
                                   col_destino = "DIAG_COMPLETO",
                                   tabla_cie10 = NULL) {
  
  # Verificar que exista la columna
  if (!(col_diag %in% names(data))) {
    stop(paste("La columna", col_diag, "no existe en los datos"))
  }
  
  # Cargar tabla CIE-10 si no se proporcionó
  if (is.null(tabla_cie10)) {
    ruta_tabla <- "Lock_sensible/cie10_simple.RData"
    
    if (!file.exists(ruta_tabla)) {
      stop(paste(
        "No se encuentra la tabla CIE-10:",  ruta_tabla, "\n",
        "Ejecutar: source('crear_bbdd_cie10_fonasa.R')"
      ))
    }
    
    cat("Cargando tabla CIE-10 FONASA...\n")
    load(ruta_tabla)  # Carga objeto 'cie10_simple'
    tabla_cie10 <- cie10_simple
  }
  
  # Verificar estructura de la tabla
  if (!all(c("codigo", "descripcion") %in% names(tabla_cie10))) {
    stop("La tabla CIE-10 debe tener columnas 'codigo' y 'descripcion'")
  }
  
  # Realizar join con tabla CIE-10
  cat("Concatenando códigos diagnósticos con descripciones...\n")
  
  data_resultado <- data %>%
    left_join(tabla_cie10, by = setNames("codigo", col_diag)) %>%
    mutate(
      !!col_destino := ifelse(
        !is.na(descripcion),
        paste0(.data[[col_diag]], " - ", descripcion),
        as.character(.data[[col_diag]])
      )
    ) %>%
    select(-descripcion)
  
  # Reportar estadísticas
  total_codigos <- sum(!is.na(data[[col_diag]]))
  con_descripcion <- sum(!is.na(data_resultado[[col_destino]]) & 
                        str_detect(data_resultado[[col_destino]], " - "))
  pct_exito <- (con_descripcion / total_codigos) * 100
  
  cat("✓", format(con_descripcion, big.mark = ","), "de", 
      format(total_codigos, big.mark = ","), 
      sprintf("(%.1f%%)", pct_exito), "códigos con descripción\n")
  
  return(data_resultado)
}

# ==============================================================================
# FUNCION: cargar_tabla_cie10_espanol
# ==============================================================================
# 
# DESCRIPCION:
#   Carga una tabla de referencia CIE-10 en español desde archivo CSV/Excel
#   Formato esperado: columnas "codigo" y "descripcion"
#
# PARAMETROS:
#   @param ruta_archivo  Ruta al archivo CSV o Excel con tabla CIE-10
#
# RETORNA:
#   Data frame con códigos CIE-10 y descripciones en español
#
# EJEMPLO:
#   tabla_cie10 <- cargar_tabla_cie10_espanol("data/cie10_espanol.csv")
#
# ==============================================================================

cargar_tabla_cie10_espanol <- function(ruta_archivo) {
  if (!file.exists(ruta_archivo)) {
    stop(paste("No se encuentra el archivo:", ruta_archivo))
  }
  
  # Detectar extensión
  extension <- tools::file_ext(ruta_archivo)
  
  if (extension %in% c("csv", "txt")) {
    tabla <- read.csv(ruta_archivo, stringsAsFactors = FALSE, encoding = "UTF-8")
  } else if (extension %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("El paquete 'readxl' es necesario para leer archivos Excel")
    }
    tabla <- readxl::read_excel(ruta_archivo)
  } else {
    stop("Formato de archivo no soportado. Use CSV o Excel")
  }
  
  # Verificar columnas esperadas
  if (!all(c("codigo", "descripcion") %in% names(tabla))) {
    stop("El archivo debe contener columnas 'codigo' y 'descripcion'")
  }
  
  return(tabla)
}

# ==============================================================================
# FUNCION: concatenar_diag_cie10_tabla
# ==============================================================================
# 
# DESCRIPCION:
#   Concatena DIAG1 con descripción usando tabla de referencia en español
#
# PARAMETROS:
#   @param data          Data frame con columna DIAG1
#   @param tabla_cie10   Data frame con códigos y descripciones CIE-10
#   @param col_diag      Nombre de la columna con códigos diagnóstico
#   @param col_destino   Nombre de la nueva columna resultante
#
# RETORNA:
#   Data frame con columna concatenada
#
# EJEMPLO:
#   tabla_cie10 <- cargar_tabla_cie10_espanol("cie10_espanol.csv")
#   datos <- concatenar_diag_cie10_tabla(datos_homologados, tabla_cie10)
#
# ==============================================================================

concatenar_diag_cie10_tabla <- function(data, 
                                         tabla_cie10,
                                         col_diag = "DIAG1",
                                         col_destino = "DIAG_COMPLETO") {
  
  if (!(col_diag %in% names(data))) {
    stop(paste("La columna", col_diag, "no existe en los datos"))
  }
  
  # Renombrar columnas de tabla para el join
  names(tabla_cie10)[names(tabla_cie10) == "codigo"] <- col_diag
  names(tabla_cie10)[names(tabla_cie10) == "descripcion"] <- "desc_temp"
  
  # Join y concatenación
  data <- data %>%
    left_join(tabla_cie10, by = col_diag) %>%
    mutate(
      !!col_destino := ifelse(
        !is.na(desc_temp),
        paste0(.data[[col_diag]], " - ", desc_temp),
        as.character(.data[[col_diag]])
      )
    ) %>%
    select(-desc_temp)
  
  return(data)
}
