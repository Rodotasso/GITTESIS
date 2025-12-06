# TEST DE CARGA DE FUNCIONES DE PERFILES
# Este script verifica que todas las funciones se carguen correctamente

cat("═══════════════════════════════════════════════════\n")
cat("TEST DE FUNCIONES DE PERFILES EPIDEMIOLÓGICOS\n")
cat("═══════════════════════════════════════════════════\n\n")

# Cargar funciones
source("R/cargar_funciones.R")

cat("\n═══ VERIFICANDO FUNCIONES DE PERFILES ═══\n\n")

# Lista de funciones a verificar
funciones_perfiles <- c(
  "calcular_perfil_diagnostico",
  "comparar_perfiles_po_pg",
  "crear_tabla_perfil",
  "graficar_perfil_top",
  "graficar_diferencias_tasas"
)

# Verificar existencia
for (func in funciones_perfiles) {
  existe <- exists(func, mode = "function")
  if (existe) {
    cat(sprintf("  ✓ %s - OK\n", func))
  } else {
    cat(sprintf("  ✗ %s - NO ENCONTRADA\n", func))
  }
}

cat("\n═══ TEST COMPLETADO ═══\n")
cat("Total funciones de perfiles: 5\n")
cat("Total funciones en proyecto: 46\n")
