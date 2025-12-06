# Script para verificar qué paquetes faltan en renv

# Paquetes usados en los archivos QMD
paquetes_usados <- c(
  "tidyverse", "data.table", "gtsummary", "flextable", 
  "scales", "tableone", "summarytools", "ggpubr",
  "corrplot", "dplyr", "ggplot2", "tidyr", 
  "lubridate", "stringr", "medicalcoder"
)

# Activar renv
source("renv/activate.R")

# Obtener paquetes instalados en renv
paquetes_renv <- installed.packages()[, "Package"]

# Identificar faltantes
faltantes <- setdiff(paquetes_usados, paquetes_renv)

cat("═══════════════════════════════════════════════════\n")
cat("  VERIFICACIÓN DE PAQUETES EN RENV\n")
cat("═══════════════════════════════════════════════════\n\n")

if (length(faltantes) > 0) {
  cat("✗ PAQUETES FALTANTES EN RENV:\n")
  for (pkg in faltantes) {
    cat("  -", pkg, "\n")
  }
  cat("\n")
  cat("Para instalarlos, ejecutar:\n")
  cat('renv::install(c("', paste(faltantes, collapse = '", "'), '"))\n', sep = "")
} else {
  cat("✓ Todos los paquetes están instalados en renv\n")
}

cat("\n═══════════════════════════════════════════════════\n")
cat("Total paquetes usados:", length(paquetes_usados), "\n")
cat("Total instalados en renv:", length(paquetes_renv), "\n")
cat("═══════════════════════════════════════════════════\n")
