#' Extraer datos del Censo 2017 con desagregaciones
#'
#' Extrae datos del Censo 2017 usando el paquete censo2017 y calcula porcentajes
#' de pertenencia a pueblos originarios por diferentes desagregaciones:
#' nacional, región, sexo, grupo etario y cruces.
#'
#' Variables del Censo 2017:
#' - p16: Pertenencia a pueblos originarios (1 = pertenece, 2 = no pertenece)
#' - p09: Edad en años (0-120)
#' - p08: Sexo (1 = Hombre, 2 = Mujer)
#' - geocodigo: Código geográfico (primeros 2 dígitos = región)
#'
#' @param conexion Conexión a la base de datos del censo. Si NULL, se crea una nueva.
#' @param verbose Lógico. Si TRUE, muestra mensajes de progreso.
#' 
#' @return Lista con 9 elementos:
#' \itemize{
#'   \item datos_individuales: Data frame con registros individuales
#'   \item nacional: Porcentaje nacional
#'   \item por_region: Porcentajes por región
#'   \item por_sexo: Porcentajes por sexo
#'   \item por_grupo_etario: Porcentajes por grupo de edad
#'   \item region_sexo: Cruce región x sexo
#'   \item region_edad: Cruce región x grupo etario
#'   \item sexo_edad: Cruce sexo x grupo etario
#'   \item region_sexo_edad: Cruce triple
#' }
#' 
#' @examples
#' \dontrun{
#' datos_censo <- extraer_datos_censo(verbose = TRUE)
#' 
#' # Porcentaje nacional
#' datos_censo$nacional
#' 
#' # Por región
#' datos_censo$por_region
#' }
#' 
#' @export
extraer_datos_censo <- function(conexion = NULL, verbose = TRUE) {
  
  # Verificar que el paquete censo2017 esté disponible
  if (!requireNamespace("censo2017", quietly = TRUE)) {
    stop("El paquete 'censo2017' no está instalado.\n",
         "Instalar con: renv::install('pachamaltese/censo2017')")
  }
  
  # Verificar si hay conexión activa, si no, crear una
  crear_conexion <- is.null(conexion)
  if(crear_conexion) {
    con_censo <- censo2017::censo_conectar()
  } else {
    con_censo <- conexion
  }
  
  if(verbose) cat("═══ EXTRAYENDO DATOS DEL CENSO 2017 ═══\n\n")
  
  # --- PASO 1: EXTRAER DATOS INDIVIDUALES ---
  if(verbose) cat("1. Extrayendo datos individuales del censo...\n")
  
  query_censo_individual <- "
  SELECT 
    p16 as pertenencia,
    CAST(SUBSTR(z.geocodigo, 1, 2) AS INTEGER) as region,
    CAST(SUBSTR(z.geocodigo, 3, 3) AS INTEGER) as comuna,
    p09 as edad,
    p08 as sexo
  FROM personas p
  JOIN hogares h ON p.hogar_ref_id = h.hogar_ref_id
  JOIN viviendas v ON h.vivienda_ref_id = v.vivienda_ref_id
  JOIN zonas z ON v.zonaloc_ref_id = z.zonaloc_ref_id
  WHERE p.p16 IS NOT NULL 
    AND p.p09 IS NOT NULL
    AND p.p09 BETWEEN 0 AND 120
    AND p.p08 IN (1, 2)
    AND z.geocodigo IS NOT NULL
  "
  
  datos_censo <- dplyr::tbl(con_censo, dbplyr::sql(query_censo_individual)) %>% 
    dplyr::collect() %>%
    dplyr::mutate(
      pertenencia_bin = ifelse(pertenencia == 1, 1, 0),
      sexo_txt = ifelse(sexo == 1, "HOMBRE", "MUJER"),
      grupo_etario = dplyr::case_when(
        edad < 5 ~ "0-4",
        edad < 15 ~ "5-14",
        edad < 25 ~ "15-24",
        edad < 45 ~ "25-44",
        edad < 65 ~ "45-64",
        edad < 75 ~ "65-74",
        edad >= 75 ~ "75+",
        TRUE ~ NA_character_
      )
    ) %>%
    dplyr::filter(!is.na(grupo_etario)) %>%
    dplyr::mutate(
      grupo_etario = factor(grupo_etario, 
                           levels = c("0-4", "5-14", "15-24", "25-44", "45-64", "65-74", "75+"))
    )
  
  if(verbose) {
    cat("   Total de registros:", format(nrow(datos_censo), big.mark = ","), "\n")
  }
  
  # --- PASO 2: CALCULAR PORCENTAJES POR DESAGREGACION ---
  if(verbose) cat("\n2. Calculando porcentajes por desagregación...\n")
  
  # 2.1 TOTAL NACIONAL
  censo_total <- datos_censo %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Nacional: ", round(censo_total$porcentaje_censo, 2), "%\n")
  }
  
  # 2.2 POR REGION
  censo_region <- datos_censo %>%
    dplyr::group_by(region) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Por región: ", nrow(censo_region), " regiones\n")
  }
  
  # 2.3 POR SEXO
  censo_sexo <- datos_censo %>%
    dplyr::group_by(sexo_txt) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    dplyr::rename(sexo = sexo_txt)
  
  if(verbose) {
    cat("   Por sexo: ", nrow(censo_sexo), " categorías\n")
  }
  
  # 2.4 POR GRUPO ETARIO
  censo_grupo_etario <- datos_censo %>%
    dplyr::group_by(grupo_etario) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Por grupo etario: ", nrow(censo_grupo_etario), " grupos\n")
  }
  
  # 2.5 CRUCE REGION x SEXO
  censo_region_sexo <- datos_censo %>%
    dplyr::group_by(region, sexo_txt) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    dplyr::rename(sexo = sexo_txt)
  
  if(verbose) {
    cat("   Cruce región x sexo: ", nrow(censo_region_sexo), " combinaciones\n")
  }
  
  # 2.6 CRUCE REGION x GRUPO ETARIO
  censo_region_edad <- datos_censo %>%
    dplyr::group_by(region, grupo_etario) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Cruce región x grupo etario: ", nrow(censo_region_edad), " combinaciones\n")
  }
  
  # 2.7 CRUCE SEXO x GRUPO ETARIO
  censo_sexo_edad <- datos_censo %>%
    dplyr::group_by(sexo_txt, grupo_etario) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    dplyr::rename(sexo = sexo_txt)
  
  if(verbose) {
    cat("   Cruce sexo x grupo etario: ", nrow(censo_sexo_edad), " combinaciones\n")
  }
  
  # 2.8 CRUCE TRIPLE: REGION x SEXO x GRUPO ETARIO
  censo_region_sexo_edad <- datos_censo %>%
    dplyr::group_by(region, sexo_txt, grupo_etario) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    dplyr::rename(sexo = sexo_txt)
  
  if(verbose) {
    cat("   Cruce región x sexo x grupo etario: ", nrow(censo_region_sexo_edad), " combinaciones\n")
  }
  
  # --- PASO 2.9: CREAR REGIÓN DE ÑUBLE (16) ---
  # Ñuble se creó el 5 sept 2018 desde 21 comunas de Biobío
  # Comunas: códigos del 8301 al 8321 (región 8, comunas 301-321)
  if(verbose) cat("\n3. Creando Región de Ñuble (16) desde comunas de Biobío...\n")
  
  # Códigos de comunas de Ñuble (rango 301-321 de región 8)
  comunas_nuble <- 301:321
  
  # Extraer datos de Ñuble desde datos individuales
  datos_nuble <- datos_censo %>%
    dplyr::filter(region == 8, comuna %in% comunas_nuble) %>%
    dplyr::mutate(region = 16)  # Reasignar a región 16
  
  # Eliminar comunas de Ñuble de Biobío
  datos_censo <- datos_censo %>%
    dplyr::filter(!(region == 8 & comuna %in% comunas_nuble))
  
  # Agregar datos de Ñuble
  datos_censo <- dplyr::bind_rows(datos_censo, datos_nuble)
  
  # Recalcular porcentajes por región con Ñuble
  censo_region <- datos_censo %>%
    dplyr::group_by(region) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Región 16 (Ñuble) creada\n")
    cat("   Total regiones:", nrow(censo_region), "\n")
  }
  
  # Recalcular cruces con región que incluyen Ñuble
  censo_region_sexo <- datos_censo %>%
    dplyr::group_by(region, sexo_txt) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    dplyr::rename(sexo = sexo_txt)
  
  censo_region_edad <- datos_censo %>%
    dplyr::group_by(region, grupo_etario) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  censo_region_sexo_edad <- datos_censo %>%
    dplyr::group_by(region, sexo_txt, grupo_etario) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    dplyr::rename(sexo = sexo_txt)
  
  # --- PASO 3: CERRAR CONEXION SI FUE CREADA ---
  if(crear_conexion) {
    censo2017::censo_desconectar()
  }
  
  if(verbose) cat("\n═══ EXTRACCIÓN COMPLETADA ═══\n\n")
  
  # --- RETORNAR LISTA CON TODOS LOS RESULTADOS ---
  return(list(
    datos_individuales = datos_censo,
    nacional = censo_total,
    por_region = censo_region,
    por_sexo = censo_sexo,
    por_grupo_etario = censo_grupo_etario,
    region_sexo = censo_region_sexo,
    region_edad = censo_region_edad,
    sexo_edad = censo_sexo_edad,
    region_sexo_edad = censo_region_sexo_edad
  ))
}
