# ==============================================================================
# SCRIPT: Crear base de datos CIE-10 desde archivos OMS 2019
# ==============================================================================

library(dplyr)
library(stringr)
library(readr)

cat("═══════════════════════════════════════════════════\n")
cat("  PROCESANDO ARCHIVOS CIE-10 (OMS 2019)\n")
cat("═══════════════════════════════════════════════════\n\n")

# 1. CARGAR CAPÍTULOS
cat("1. Cargando capítulos...\n")
capitulos <- read_delim(
  "icd_2019/icd102019syst_chapters.txt",
  delim = ";",
  col_names = c("capitulo_num", "capitulo_descripcion"),
  col_types = "cc",
  locale = locale(encoding = "UTF-8")
)
cat("   ✓", nrow(capitulos), "capítulos cargados\n\n")

# 2. CARGAR GRUPOS
cat("2. Cargando grupos...\n")
grupos <- read_delim(
  "icd_2019/icd102019syst_groups.txt",
  delim = ";",
  col_names = c("codigo_inicio", "codigo_fin", "capitulo_num", "grupo_descripcion"),
  col_types = "cccc",
  locale = locale(encoding = "UTF-8")
)
cat("   ✓", nrow(grupos), "grupos cargados\n\n")

# 3. CARGAR CÓDIGOS
cat("3. Cargando códigos diagnósticos...\n")
codigos_raw <- read_delim(
  "icd_2019/icd102019syst_codes.txt",
  delim = ";",
  col_names = FALSE,
  col_types = cols(.default = "c"),
  locale = locale(encoding = "UTF-8")
)

# Las columnas importantes son:
# X7: código con punto (ej: A00.0)
# X8: código sin punto (ej: A000)
# X9: descripción completa
# X10: descripción corta/grupo
# X11: descripción específica (si existe)

codigos <- codigos_raw %>%
  select(
    codigo_punto = X7,
    codigo_compacto = X8,
    descripcion_completa = X9,
    descripcion_grupo = X10,
    descripcion_especifica = X11
  ) %>%
  mutate(
    # Limpiar códigos
    codigo_punto = str_trim(codigo_punto),
    codigo_compacto = str_trim(codigo_compacto),
    # Usar descripción específica si existe, si no usar completa
    descripcion = ifelse(
      !is.na(descripcion_especifica) & descripcion_especifica != "",
      descripcion_especifica,
      descripcion_completa
    ),
    # Extraer capítulo del código (primera letra o dos)
    capitulo_letra = str_sub(codigo_compacto, 1, 1)
  )

cat("   ✓", format(nrow(codigos), big.mark = ","), "códigos diagnósticos cargados\n\n")

# 4. CREAR TABLA CONSOLIDADA PARA R
cat("4. Creando tabla consolidada...\n")

# Crear versión simple para concatenación (código sin punto + descripción)
cie10_simple <- codigos %>%
  select(
    codigo = codigo_compacto,
    descripcion = descripcion,
    codigo_punto = codigo_punto
  ) %>%
  distinct() %>%
  arrange(codigo)

# Crear versión completa con información de grupos y capítulos
cie10_completa <- codigos %>%
  left_join(capitulos, by = c("capitulo_letra" = "capitulo_num")) %>%
  select(
    codigo = codigo_compacto,
    codigo_punto = codigo_punto,
    descripcion = descripcion,
    descripcion_completa = descripcion_completa,
    descripcion_grupo = descripcion_grupo,
    capitulo_letra = capitulo_letra,
    capitulo_descripcion = capitulo_descripcion
  ) %>%
  distinct() %>%
  arrange(codigo)

cat("   ✓ Tabla simple:", format(nrow(cie10_simple), big.mark = ","), "códigos únicos\n")
cat("   ✓ Tabla completa:", format(nrow(cie10_completa), big.mark = ","), "códigos únicos\n\n")

# 5. GUARDAR BASES DE DATOS
cat("5. Guardando bases de datos...\n")

# Guardar versión simple (para concatenación rápida)
save(cie10_simple, file = "Lock_sensible/cie10_simple.RData")
cat("   ✓ Lock_sensible/cie10_simple.RData\n")

# Guardar versión completa (para análisis detallado)
save(cie10_completa, file = "Lock_sensible/cie10_completa.RData")
cat("   ✓ Lock_sensible/cie10_completa.RData\n")

# Guardar también como CSV para referencia
write.csv(cie10_simple, "Lock_sensible/cie10_simple.csv", row.names = FALSE, fileEncoding = "UTF-8")
cat("   ✓ Lock_sensible/cie10_simple.csv\n\n")

# 6. RESUMEN FINAL
cat("═══════════════════════════════════════════════════\n")
cat("  RESUMEN\n")
cat("═══════════════════════════════════════════════════\n\n")

cat("Total capítulos:", nrow(capitulos), "\n")
cat("Total grupos:", nrow(grupos), "\n")
cat("Total códigos únicos:", format(nrow(cie10_simple), big.mark = ","), "\n\n")

cat("Ejemplos de códigos:\n")
print(head(cie10_simple, 10))

cat("\n✓ Proceso completado exitosamente\n")
cat("✓ Archivos guardados en: Lock_sensible/\n\n")

cat("NOTA: Las descripciones están en INGLÉS\n")
cat("      Para español, se requiere traducción o tabla del MINSAL\n")
