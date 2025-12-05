# ==============================================================================
# FUNCION: extraer_datos_censo
# ==============================================================================
# 
# DESCRIPCION:
#   Extrae datos del Censo 2017 desde base de datos SQLite y calcula porcentajes
#   de pertenencia a pueblos originarios con múltiples desagregaciones
#
# PARAMETROS:
#   @param conexion  Conexión DBI opcional (si NULL, crea y cierra conexión)
#   @param verbose   Mostrar mensajes de progreso (default: TRUE)
#
# RETORNA:
#   Lista con 9 elementos:
#     - datos_individuales: data.frame con datos por persona
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
#   - Si conexion=NULL, crea y cierra conexión temporal a BD Censo
#   - Muestra mensajes en consola si verbose=TRUE
#
# DEPENDENCIAS:
#   - dplyr (tbl, collect, mutate, filter, group_by, summarise, rename)
#   - dbplyr (sql)
#   - Funciones: censo_conectar(), censo_desconectar()
#
# VARIABLES GLOBALES:
#   Ninguna
#
# ARCHIVO ORIGEN:
#   - Concord_nuevas.qmd (líneas 508-708)
#
# NOTAS:
#   - Grupos etarios: 0-4, 5-14, 15-24, 25-44, 45-64, 65-74, 75+
#   - Filtros: edad 0-120, sexo 1-2, pertenencia no nula
#   - pertenencia_bin: 1=pertenece, 0=no pertenece
#   - Query SQL optimizada con JOIN de tablas personas/hogares/viviendas/zonas
#
# EJEMPLO:
#   # Uso con conexión automática
#   datos <- extraer_datos_censo()
#   
#   # Ver porcentaje nacional
#   datos$nacional$porcentaje_censo
#   
#   # Ver por región
#   head(datos$por_region)
#   
#   # Uso con conexión existente
#   con <- censo_conectar()
#   datos <- extraer_datos_censo(conexion = con)
#   censo_desconectar()
#
# ==============================================================================

extraer_datos_censo <- function(conexion = NULL, verbose = TRUE) {
  
  # Verificar si hay conexión activa, si no, crear una
  crear_conexion <- is.null(conexion)
  if(crear_conexion) {
    con_censo <- censo_conectar()
  } else {
    con_censo <- conexion
  }
  
  if(verbose) cat("=== EXTRAYENDO DATOS DEL CENSO 2017 ===\n\n")
  
  # --- PASO 1: EXTRAER DATOS INDIVIDUALES ---
  if(verbose) cat("1. Extrayendo datos individuales del censo...\n")
  
  query_censo_individual <- "
  SELECT 
    p16 as pertenencia,
    CAST(SUBSTR(z.geocodigo, 1, 2) AS INTEGER) as region,
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
  
  datos_censo <- tbl(con_censo, sql(query_censo_individual)) %>% 
    collect() %>%
    mutate(
      pertenencia_bin = ifelse(pertenencia == 1, 1, 0),
      sexo_txt = ifelse(sexo == 1, "HOMBRE", "MUJER"),
      grupo_etario = case_when(
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
    filter(!is.na(grupo_etario)) %>%
    mutate(
      grupo_etario = factor(grupo_etario, 
                           levels = c("0-4", "5-14", "15-24", "25-44", "45-64", "65-74", "75+"))
    )
  
  if(verbose) {
    cat("   Total de registros:", format(nrow(datos_censo), big.mark = ","), "\n")
  }
  
  # --- PASO 2: CALCULAR PORCENTAJES POR DESAGREGACION ---
  if(verbose) cat("\n2. Calculando porcentajes por desagregacion...\n")
  
  # 2.1 TOTAL NACIONAL
  censo_total <- datos_censo %>%
    summarise(
      total = n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Nacional: ", round(censo_total$porcentaje_censo, 2), "%\n")
  }
  
  # 2.2 POR REGION
  censo_region <- datos_censo %>%
    group_by(region) %>%
    summarise(
      total = n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Por region: ", nrow(censo_region), " regiones\n")
  }
  
  # 2.3 POR SEXO
  censo_sexo <- datos_censo %>%
    group_by(sexo_txt) %>%
    summarise(
      total = n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    rename(sexo = sexo_txt)
  
  if(verbose) {
    cat("   Por sexo: ", nrow(censo_sexo), " categorias\n")
  }
  
  # 2.4 POR GRUPO ETARIO
  censo_grupo_etario <- datos_censo %>%
    group_by(grupo_etario) %>%
    summarise(
      total = n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Por grupo etario: ", nrow(censo_grupo_etario), " grupos\n")
  }
  
  # 2.5 CRUCE REGION x SEXO
  censo_region_sexo <- datos_censo %>%
    group_by(region, sexo_txt) %>%
    summarise(
      total = n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    rename(sexo = sexo_txt)
  
  if(verbose) {
    cat("   Cruce region x sexo: ", nrow(censo_region_sexo), " combinaciones\n")
  }
  
  # 2.6 CRUCE REGION x GRUPO ETARIO
  censo_region_edad <- datos_censo %>%
    group_by(region, grupo_etario) %>%
    summarise(
      total = n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    )
  
  if(verbose) {
    cat("   Cruce region x grupo etario: ", nrow(censo_region_edad), " combinaciones\n")
  }
  
  # 2.7 CRUCE SEXO x GRUPO ETARIO
  censo_sexo_edad <- datos_censo %>%
    group_by(sexo_txt, grupo_etario) %>%
    summarise(
      total = n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    rename(sexo = sexo_txt)
  
  if(verbose) {
    cat("   Cruce sexo x grupo etario: ", nrow(censo_sexo_edad), " combinaciones\n")
  }
  
  # 2.8 CRUCE TRIPLE: REGION x SEXO x GRUPO ETARIO
  censo_region_sexo_edad <- datos_censo %>%
    group_by(region, sexo_txt, grupo_etario) %>%
    summarise(
      total = n(),
      pertenece = sum(pertenencia_bin == 1),
      porcentaje_censo = (pertenece / total) * 100,
      .groups = "drop"
    ) %>%
    rename(sexo = sexo_txt)
  
  if(verbose) {
    cat("   Cruce region x sexo x grupo etario: ", nrow(censo_region_sexo_edad), " combinaciones\n")
  }
  
  # --- PASO 3: CERRAR CONEXION SI FUE CREADA ---
  if(crear_conexion) {
    censo_desconectar()
  }
  
  if(verbose) cat("\n=== EXTRACCION COMPLETADA ===\n\n")
  
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
