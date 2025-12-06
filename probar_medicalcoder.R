# Probar medicalcoder para obtener descripciones ICD-10
source("renv/activate.R")
library(medicalcoder)

# Códigos de ejemplo
codigos_prueba <- c("J189", "I10", "E119", "N179", "K219", "I2510")

cat("═══ PROBANDO MEDICALCODER ═══\n\n")

# Ver qué funciones tiene disponibles
cat("Funciones disponibles en medicalcoder:\n")
print(ls("package:medicalcoder"))

cat("\n═══ PROBANDO DIFERENTES FUNCIONES ═══\n\n")

# Probar diferentes aproximaciones
cat("1. Usando icd10_map_cc_pcs:\n")
if (exists("icd10_map_cc_pcs", where = "package:medicalcoder")) {
  print(head(icd10_map_cc_pcs))
}

cat("\n2. Buscando datasets ICD:\n")
data_names <- data(package = "medicalcoder")$results[, "Item"]
print(data_names)
