# ==============================================================================
# SCRIPT: Instalación del Paquete ciecl
# ==============================================================================
# 
# DESCRIPCIÓN:
#   Instala el paquete ciecl desde el directorio local del proyecto
#   El paquete proporciona herramientas para trabajar con CIE-10 Chile
#
# AUTOR: Rodolfo Tasso
# FECHA: 2025-12-14
#
# ==============================================================================

cat("═══════════════════════════════════════════════════\n")
cat("  INSTALACIÓN DEL PAQUETE ciecl\n")
cat("═══════════════════════════════════════════════════\n\n")

# Ruta al paquete local
ruta_ciecl <- "D:/MAGISTER/01_Paquete_R/ciecl"

# Verificar que existe el directorio
if (!dir.exists(ruta_ciecl)) {
  stop(paste(
    "❌ No se encuentra el paquete ciecl en:", ruta_ciecl, "\n",
    "Verifique la ruta del paquete"
  ))
}

cat("✓ Paquete encontrado en:", ruta_ciecl, "\n\n")

# Verificar dependencias
cat("Verificando dependencias...\n")

dependencias <- c(
  "dplyr", "DBI", "RSQLite", "stringdist", 
  "httr", "jsonlite", "gt", "comorbidity"
)

faltantes <- dependencias[!dependencias %in% installed.packages()[, "Package"]]

if (length(faltantes) > 0) {
  cat("⚠ Instalando dependencias faltantes:", paste(faltantes, collapse = ", "), "\n")
  install.packages(faltantes, dependencies = TRUE, quiet = TRUE)
} else {
  cat("✓ Todas las dependencias están instaladas\n")
}

cat("\n")

# Instalar paquete ciecl
cat("Instalando paquete ciecl...\n\n")

if (!requireNamespace("devtools", quietly = TRUE)) {
  cat("Instalando devtools...\n")
  install.packages("devtools", quiet = TRUE)
}

# Instalar desde directorio local
devtools::install_local(
  path = ruta_ciecl,
  upgrade = "never",  # No actualizar dependencias
  force = TRUE,       # Reinstalar si ya existe
  quiet = FALSE,
  build_vignettes = FALSE  # No construir viñetas para instalación rápida
)

cat("\n")

# Verificar instalación
cat("═══════════════════════════════════════════════════\n")
cat("  VERIFICACIÓN DE INSTALACIÓN\n")
cat("═══════════════════════════════════════════════════\n\n")

if (requireNamespace("ciecl", quietly = TRUE)) {
  library(ciecl)
  
  cat("✅ Paquete ciecl instalado exitosamente\n\n")
  
  # Mostrar versión
  paquete_info <- packageDescription("ciecl")
  cat("INFORMACIÓN DEL PAQUETE:\n")
  cat("  • Nombre:", paquete_info$Package, "\n")
  cat("  • Versión:", paquete_info$Version, "\n")
  cat("  • Título:", paquete_info$Title, "\n")
  cat("  • Autor:", paquete_info$Author, "\n")
  cat("  • Licencia:", paquete_info$License, "\n\n")
  
  # Listar funciones exportadas
  cat("FUNCIONES DISPONIBLES:\n")
  funciones <- ls("package:ciecl")
  for (f in sort(funciones)) {
    cat("  •", f, "\n")
  }
  
  cat("\n")
  
  # Prueba rápida
  cat("PRUEBA RÁPIDA:\n")
  cat("Buscando código J44 (EPOC)...\n\n")
  
  resultado <- try({
    cie_lookup(
      codigos = "J44",
      tipo = "codigo",
      output = "simple"
    )
  }, silent = TRUE)
  
  if (!inherits(resultado, "try-error") && !is.null(resultado)) {
    print(resultado)
    cat("\n✅ Prueba exitosa: El paquete funciona correctamente\n")
  } else {
    cat("⚠ La prueba falló, pero el paquete está instalado\n")
    cat("  Puede que necesite cargar datos con: generar_cie10_cl()\n")
  }
  
} else {
  cat("❌ Error: El paquete no se instaló correctamente\n")
  cat("   Intente instalar manualmente:\n")
  cat("   devtools::install_local('", ruta_ciecl, "')\n", sep = "")
}

cat("\n═══════════════════════════════════════════════════\n")
cat("USO DEL PAQUETE:\n")
cat("═══════════════════════════════════════════════════\n\n")

cat("# Cargar paquete\n")
cat("library(ciecl)\n\n")

cat("# Buscar código\n")
cat("cie_lookup(codigos = 'J44', tipo = 'codigo')\n\n")

cat("# Búsqueda difusa\n")
cat("cie_search(termino = 'neumonia', tipo = 'descripcion', metodo = 'fuzzy')\n\n")

cat("# Validar códigos\n")
cat("cie_validate_vector(codigos = c('J44', 'A00', 'Z999'))\n\n")

cat("# Calcular índice de Charlson\n")
cat("cie_comorbid(data = datos, id_col = 'id', codigo_col = 'codigo')\n\n")

cat("# Documentación\n")
cat("?ciecl::cie_lookup\n")
cat("browseVignettes('ciecl')\n\n")

cat("═══════════════════════════════════════════════════\n")
cat("✓ INSTALACIÓN COMPLETADA\n")
cat("═══════════════════════════════════════════════════\n")
