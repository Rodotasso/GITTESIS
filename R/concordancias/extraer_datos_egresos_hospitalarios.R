#' Extraer datos de Egresos Hospitalarios (PUEBLO_ORIGINARIO_BIN) con desagregaciones
#'
#' Procesa la variable PUEBLO_ORIGINARIO_BIN de los egresos hospitalarios y calcula 
#' porcentajes de pertenencia a pueblos originarios por diferentes desagregaciones:
#' nacional, región, sexo, grupo etario y cruces.
#'
#' @param datos_homologados Data frame con los datos de egresos hospitalarios
#' @param verbose Lógico. Si TRUE, muestra mensajes de progreso.
#' 
#' @return Lista con 9 elementos (misma estructura que extraer_datos_censo):
#' \itemize{
#'   \item datos_individuales: Data frame con registros individuales preparados
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
#' load("BBDD_homologados.RData")
#' datos_egresos <- extraer_datos_egresos_hospitalarios(datos_homologados, verbose = TRUE)
#' 
#' # Porcentaje nacional
#' datos_egresos$nacional
#' }
#' 
#' @export
extraer_datos_egresos_hospitalarios <- function(datos_homologados, verbose = TRUE) {
  
  if(verbose) cat("═══ EXTRAYENDO DATOS DE EGRESOS HOSPITALARIOS ═══\n\n")
  
  # --- PASO 1: PREPARAR DATOS ---
  if(verbose) cat("1. Preparando datos de Egresos Hospitalarios...\n")
  
  datos_prep <- datos_homologados %>%
    dplyr::filter(!is.na(PUEBLO_ORIGINARIO_BIN)) %>%
    dplyr::mutate(
      egresos_bin = PUEBLO_ORIGINARIO_BIN,
      region = as.integer(CODIGO_REGION),
      sexo = GLOSA_SEXO,
      grupo_etario = factor(as.character(GRUPO_ETARIO), 
                           levels = c("0-4", "5-14", "15-24", "25-44", "45-64", "65-74", "75+"))
    ) %>%
    dplyr::filter(!is.na(sexo), sexo %in% c("HOMBRE", "MUJER"),
           !is.na(grupo_etario),
           !is.na(region))
  
  if(verbose) {
    cat("   Total de registros:", format(nrow(datos_prep), big.mark = ","), "\n")
  }
  
  # --- PASO 2: CALCULAR PORCENTAJES POR DESAGREGACION ---
  if(verbose) cat("\n2. Calculando porcentajes por desagregación...\n")
  
  # 2.1 TOTAL NACIONAL
  egresos_total <- datos_prep %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(egresos_bin == 1, na.rm = TRUE),
      porcentaje_egresos = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Nacional: ", round(egresos_total$porcentaje_egresos, 2), "%\n")
  }
  
  # 2.2 POR REGION
  egresos_region <- datos_prep %>%
    dplyr::group_by(region) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(egresos_bin == 1, na.rm = TRUE),
      porcentaje_egresos = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Por región: ", nrow(egresos_region), " regiones\n")
  }
  
  # 2.3 POR SEXO
  egresos_sexo <- datos_prep %>%
    dplyr::group_by(sexo) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(egresos_bin == 1, na.rm = TRUE),
      porcentaje_egresos = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Por sexo: ", nrow(egresos_sexo), " categorías\n")
  }
  
  # 2.4 POR GRUPO ETARIO
  egresos_grupo_etario <- datos_prep %>%
    dplyr::group_by(grupo_etario, .drop = FALSE) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(egresos_bin == 1, na.rm = TRUE),
      porcentaje_egresos = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    dplyr::filter(total > 0)
  
  if(verbose) {
    cat("   Por grupo etario: ", nrow(egresos_grupo_etario), " grupos\n")
  }
  
  # 2.5 CRUCE REGION x SEXO
  egresos_region_sexo <- datos_prep %>%
    dplyr::group_by(region, sexo) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(egresos_bin == 1, na.rm = TRUE),
      porcentaje_egresos = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Cruce región x sexo: ", nrow(egresos_region_sexo), " combinaciones\n")
  }
  
  # 2.6 CRUCE REGION x GRUPO ETARIO
  egresos_region_edad <- datos_prep %>%
    dplyr::group_by(region, grupo_etario) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(egresos_bin == 1, na.rm = TRUE),
      porcentaje_egresos = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Cruce región x grupo etario: ", nrow(egresos_region_edad), " combinaciones\n")
  }
  
  # 2.7 CRUCE SEXO x GRUPO ETARIO
  egresos_sexo_edad <- datos_prep %>%
    dplyr::group_by(sexo, grupo_etario) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(egresos_bin == 1, na.rm = TRUE),
      porcentaje_egresos = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Cruce sexo x grupo etario: ", nrow(egresos_sexo_edad), " combinaciones\n")
  }
  
  # 2.8 CRUCE TRIPLE REGION x SEXO x GRUPO ETARIO
  egresos_region_sexo_edad <- datos_prep %>%
    dplyr::group_by(region, sexo, grupo_etario) %>%
    dplyr::summarise(
      total = dplyr::n(),
      pertenece = sum(egresos_bin == 1, na.rm = TRUE),
      porcentaje_egresos = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Cruce triple: ", nrow(egresos_region_sexo_edad), " combinaciones\n")
  }
  
  # --- PASO 3: RETORNAR LISTA ---
  if(verbose) cat("\n✓ Extracción completada\n\n")
  
  return(list(
    datos_individuales = datos_prep,
    nacional = egresos_total,
    por_region = egresos_region,
    por_sexo = egresos_sexo,
    por_grupo_etario = egresos_grupo_etario,
    region_sexo = egresos_region_sexo,
    region_edad = egresos_region_edad,
    sexo_edad = egresos_sexo_edad,
    region_sexo_edad = egresos_region_sexo_edad
  ))
}
