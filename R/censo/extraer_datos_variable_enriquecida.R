# ==============================================================================
# FUNCION: extraer_datos_variable_enriquecida
# ==============================================================================
# 
# DESCRIPCION:
#   Extrae datos de Variable Enriquecida (PERTENENCIA2) desde datos_homologados
#   y calcula porcentajes con múltiples desagregaciones
#
# PARAMETROS:
#   @param datos_homologados  data.frame con variable PERTENENCIA2
#   @param verbose           Mostrar mensajes de progreso (default: TRUE)
#
# RETORNA:
#   Lista con 9 elementos:
#     - datos_individuales: data.frame filtrado con variables relevantes
#     - nacional: totales nacionales
#     - por_region: desagregación por región
#     - por_sexo: desagregación por sexo
#     - por_grupo_etario: desagregación por grupos de edad
#     - region_sexo: cruce región x sexo
#     - region_edad: cruce región x grupo etario
#     - sexo_edad: cruce sexo x grupo etario
#     - region_sexo_edad: cruce triple
#
# EFECTOS SECUNDARIOS:
#   - Muestra mensajes en consola si verbose=TRUE
#
# DEPENDENCIAS:
#   - dplyr (filter, mutate, group_by, summarise)
#
# VARIABLES GLOBALES:
#   Ninguna
#
# ARCHIVO ORIGEN:
#   - Concord_nuevas.qmd (líneas 709-820)
#
# NOTAS:
#   - Grupos etarios: 0-4, 5-14, 15-24, 25-44, 45-64, 65-74, 75+
#   - Filtros: PERTENENCIA2 no nulo, sexo HOMBRE/MUJER, grupo_etario no nulo
#   - enriquecida_bin: directo de PERTENENCIA2 (1=pertenece, 0=no pertenece)
#   - Requiere columnas: PERTENENCIA2, CODIGO_REGION, GLOSA_SEXO, GRUPO_ETARIO
#
# EJEMPLO:
#   # Cargar datos homologados
#   load("BBDD_homologados.RData")
#   
#   # Extraer datos de variable enriquecida
#   datos_pert2 <- extraer_datos_variable_enriquecida(datos_homologados)
#   
#   # Ver porcentaje nacional
#   datos_pert2$nacional$porcentaje_pert2
#   
#   # Ver por región
#   head(datos_pert2$por_region)
#   
#   # Modo silencioso
#   datos_pert2 <- extraer_datos_variable_enriquecida(datos_homologados, verbose = FALSE)
#
# ==============================================================================

extraer_datos_variable_enriquecida <- function(datos_homologados, verbose = TRUE) {
  
  if(verbose) cat("=== EXTRAYENDO DATOS DE VARIABLE ENRIQUECIDA ===\n\n")
  
  # --- PASO 1: PREPARAR DATOS ---
  if(verbose) cat("1. Preparando datos de Variable Enriquecida...\n")
  
  datos_prep <- datos_homologados %>%
    filter(!is.na(PERTENENCIA2)) %>%
    mutate(
      enriquecida_bin = PERTENENCIA2,
      region = as.integer(CODIGO_REGION),
      sexo = GLOSA_SEXO,
      grupo_etario = factor(as.character(GRUPO_ETARIO), 
                           levels = c("0-4", "5-14", "15-24", "25-44", "45-64", "65-74", "75+"))
    ) %>%
    filter(!is.na(sexo), sexo %in% c("HOMBRE", "MUJER"),
           !is.na(grupo_etario),
           !is.na(region))
  
  if(verbose) {
    cat("   Total de registros:", format(nrow(datos_prep), big.mark = ","), "\n")
  }
  
  # --- PASO 2: CALCULAR PORCENTAJES POR DESAGREGACION ---
  if(verbose) cat("\n2. Calculando porcentajes por desagregacion...\n")
  
  # 2.1 TOTAL NACIONAL
  pert2_total <- datos_prep %>%
    summarise(
      total = n(),
      pertenece = sum(enriquecida_bin == 1, na.rm = TRUE),
      porcentaje_pert2 = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Nacional: ", round(pert2_total$porcentaje_pert2, 2), "%\n")
  }
  
  # 2.2 POR REGION
  pert2_region <- datos_prep %>%
    group_by(region) %>%
    summarise(
      total = n(),
      pertenece = sum(enriquecida_bin == 1, na.rm = TRUE),
      porcentaje_pert2 = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Por region: ", nrow(pert2_region), " regiones\n")
  }
  
  # 2.3 POR SEXO
  pert2_sexo <- datos_prep %>%
    group_by(sexo) %>%
    summarise(
      total = n(),
      pertenece = sum(enriquecida_bin == 1, na.rm = TRUE),
      porcentaje_pert2 = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Por sexo: ", nrow(pert2_sexo), " categorias\n")
  }
  
  # 2.4 POR GRUPO ETARIO
  pert2_grupo_etario <- datos_prep %>%
    group_by(grupo_etario, .drop = FALSE) %>%
    summarise(
      total = n(),
      pertenece = sum(enriquecida_bin == 1, na.rm = TRUE),
      porcentaje_pert2 = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    filter(total > 0)
  
  if(verbose) {
    cat("   Por grupo etario: ", nrow(pert2_grupo_etario), " grupos\n")
  }
  
  # 2.5 CRUCE REGION x SEXO
  pert2_region_sexo <- datos_prep %>%
    group_by(region, sexo) %>%
    summarise(
      total = n(),
      pertenece = sum(enriquecida_bin == 1, na.rm = TRUE),
      porcentaje_pert2 = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Cruce region x sexo: ", nrow(pert2_region_sexo), " combinaciones\n")
  }
  
  # 2.6 CRUCE REGION x GRUPO ETARIO
  pert2_region_edad <- datos_prep %>%
    group_by(region, grupo_etario) %>%
    summarise(
      total = n(),
      pertenece = sum(enriquecida_bin == 1, na.rm = TRUE),
      porcentaje_pert2 = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Cruce region x grupo etario: ", nrow(pert2_region_edad), " combinaciones\n")
  }
  
  # 2.7 CRUCE SEXO x GRUPO ETARIO
  pert2_sexo_edad <- datos_prep %>%
    group_by(sexo, grupo_etario) %>%
    summarise(
      total = n(),
      pertenece = sum(enriquecida_bin == 1, na.rm = TRUE),
      porcentaje_pert2 = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Cruce sexo x grupo etario: ", nrow(pert2_sexo_edad), " combinaciones\n")
  }
  
  # 2.8 CRUCE TRIPLE: REGION x SEXO x GRUPO ETARIO
  pert2_region_sexo_edad <- datos_prep %>%
    group_by(region, sexo, grupo_etario) %>%
    summarise(
      total = n(),
      pertenece = sum(enriquecida_bin == 1, na.rm = TRUE),
      porcentaje_pert2 = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Cruce region x sexo x grupo etario: ", nrow(pert2_region_sexo_edad), " combinaciones\n")
  }
  
  if(verbose) cat("\n=== EXTRACCION COMPLETADA ===\n\n")
  
  # --- RETORNAR LISTA CON TODOS LOS RESULTADOS ---
  return(list(
    datos_individuales = datos_prep,
    nacional = pert2_total,
    por_region = pert2_region,
    por_sexo = pert2_sexo,
    por_grupo_etario = pert2_grupo_etario,
    region_sexo = pert2_region_sexo,
    region_edad = pert2_region_edad,
    sexo_edad = pert2_sexo_edad,
    region_sexo_edad = pert2_region_sexo_edad
  ))
}
