# ==============================================================================
# SCRIPT: Crear base de datos CIE-10 desde archivo Excel FONASA
# ==============================================================================

source("renv/activate.R")
library(readxl)
library(dplyr)
library(stringr)

cat("═══════════════════════════════════════════════════\n")
cat("  PROCESANDO CIE-10 FONASA (ESPAÑOL)\n")
cat("═══════════════════════════════════════════════════\n\n")

# 1. CARGAR ARCHIVO EXCEL
cat("1. Cargando archivo CIE-10 de FONASA...\n")
archivo <- "DATOS ABIERTOS/icd102019enMeta/CIE-10.xlsx"
cie10_raw <- read_excel(archivo, sheet = "CIE 10")

cat("   ✓", format(nrow(cie10_raw), big.mark = ","), "códigos cargados\n\n")

# 2. PROCESAR Y LIMPIAR DATOS
cat("2. Procesando datos...\n")

cie10_limpia <- cie10_raw %>%
  rename(
    version = Versión,
    codigo = Código,
    descripcion = Descripción,
    categoria = Categoría,
    seccion = Sección,
    capitulo = Capítulo
  ) %>%
  mutate(
    # Limpiar y estandarizar código
    codigo = str_replace_all(codigo, "\\.", ""),  # Quitar puntos
    codigo = str_trim(codigo),
    codigo = toupper(codigo),
    
    # Limpiar descripción
    descripcion = str_trim(descripcion),
    
    # Extraer información adicional
    codigo_raiz = str_extract(codigo, "^[A-Z][0-9]+"),
    tiene_subcategoria = str_detect(codigo, "^[A-Z][0-9]{3,4}$"),
    
    # Limpiar capítulo y sección
    capitulo_num = str_extract(capitulo, "Cap\\.\\d+"),
    capitulo_nombre = str_trim(str_replace(capitulo, "Cap\\.\\d+\\s+", "")),
    
    seccion_rango = str_extract(seccion, "^[A-Z][0-9]+-[A-Z][0-9]+"),
    seccion_nombre = str_trim(str_replace(seccion, "^[A-Z][0-9]+-[A-Z][0-9]+\\s+", ""))
  )

cat("   ✓ Datos procesados\n\n")

# 3. CREAR VERSIONES SIMPLIFICADAS
cat("3. Creando versiones de la tabla...\n")

# Versión SIMPLE: Solo código + descripción (para concatenación)
cie10_simple <- cie10_limpia %>%
  select(codigo, descripcion) %>%
  distinct() %>%
  arrange(codigo)

cat("   ✓ Tabla simple:", format(nrow(cie10_simple), big.mark = ","), "códigos únicos\n")

# Versión COMPLETA: Toda la información
cie10_completa <- cie10_limpia %>%
  select(
    codigo, descripcion, categoria, 
    seccion_rango, seccion_nombre,
    capitulo_num, capitulo_nombre,
    codigo_raiz, tiene_subcategoria
  ) %>%
  distinct() %>%
  arrange(codigo)

cat("   ✓ Tabla completa:", format(nrow(cie10_completa), big.mark = ","), "códigos únicos\n\n")

# 4. VALIDAR CÓDIGOS FRECUENTES
cat("4. Validando códigos frecuentes en datos...\n")

# Cargar datos para verificar
if (file.exists("BBDD_homologados.RData")) {
  load("BBDD_homologados.RData")
  
  # Top 20 códigos en datos
  top_codigos <- datos_homologados %>%
    filter(!is.na(DIAG1)) %>%
    count(DIAG1, sort = TRUE) %>%
    head(20)
  
  # Verificar si están en CIE-10
  validacion <- top_codigos %>%
    left_join(cie10_simple, by = c("DIAG1" = "codigo"))
  
  cat("\n   Top 10 diagnósticos en datos:\n")
  print(validacion %>% select(DIAG1, n, descripcion) %>% head(10))
  
  encontrados <- sum(!is.na(validacion$descripcion))
  cat("\n   ✓", encontrados, "de 20 códigos encontrados en CIE-10\n")
  
  if (encontrados < 20) {
    faltantes <- validacion %>% filter(is.na(descripcion))
    cat("   ✗ Códigos no encontrados:", paste(faltantes$DIAG1, collapse = ", "), "\n")
  }
} else {
  cat("   (Omitido - BBDD_homologados.RData no encontrada)\n")
}

cat("\n")

# 5. GUARDAR BASES DE DATOS
cat("5. Guardando bases de datos...\n")

# Crear directorio si no existe
if (!dir.exists("Lock_sensible")) {
  dir.create("Lock_sensible")
}

# Guardar versión simple (para concatenación rápida)
save(cie10_simple, file = "Lock_sensible/cie10_simple.RData")
cat("   ✓ Lock_sensible/cie10_simple.RData\n")

# Guardar versión completa (para análisis detallado)
save(cie10_completa, file = "Lock_sensible/cie10_completa.RData")
cat("   ✓ Lock_sensible/cie10_completa.RData\n")

# Guardar también como CSV para referencia
write.csv(cie10_simple, "Lock_sensible/cie10_simple.csv", 
          row.names = FALSE, fileEncoding = "UTF-8")
cat("   ✓ Lock_sensible/cie10_simple.csv\n\n")

# 6. ESTADÍSTICAS FINALES
cat("═══════════════════════════════════════════════════\n")
cat("  RESUMEN\n")
cat("═══════════════════════════════════════════════════\n\n")

cat("Total códigos CIE-10:", format(nrow(cie10_simple), big.mark = ","), "\n")
cat("Total capítulos:", length(unique(cie10_completa$capitulo_num)), "\n")
cat("Total secciones:", length(unique(cie10_completa$seccion_rango)), "\n\n")

cat("Ejemplos:\n")
print(head(cie10_simple, 10))

cat("\n✓ Proceso completado exitosamente\n")
cat("✓ Archivos guardados en: Lock_sensible/\n")
cat("✓ Descripciones en ESPAÑOL (FONASA)\n")
