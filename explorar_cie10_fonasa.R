# Script para explorar el archivo Excel CIE-10 de FONASA
source("renv/activate.R")
library(readxl)
library(dplyr)

cat("═══════════════════════════════════════════════════\n")
cat("  EXPLORANDO ARCHIVO CIE-10 FONASA\n")
cat("═══════════════════════════════════════════════════\n\n")

archivo <- "DATOS ABIERTOS/icd102019enMeta/CIE-10.xlsx"

# Ver hojas disponibles
cat("Hojas en el archivo:\n")
hojas <- excel_sheets(archivo)
print(hojas)

cat("\n")

# Leer primera hoja
cat("Leyendo primera hoja:", hojas[1], "\n\n")
datos <- read_excel(archivo, sheet = 1)

cat("Dimensiones:", nrow(datos), "filas x", ncol(datos), "columnas\n\n")

cat("Nombres de columnas:\n")
print(names(datos))

cat("\n\nPrimeras 20 filas:\n")
print(head(datos, 20))

cat("\n\nÚltimas 10 filas:\n")
print(tail(datos, 10))

cat("\n\nEstructura:\n")
print(str(datos))
