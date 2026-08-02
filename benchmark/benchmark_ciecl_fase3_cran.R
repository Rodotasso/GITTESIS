# =============================================================================
# Benchmark fase 3 — replica con ciecl de CRAN
# Requiere: install.packages("ciecl") en R 4.6.0.
# Compara la version instalada desde CRAN (0.9.6) contra los resultados
# obtenidos con la rama dev (benchmark-fase3-2026-07-31.csv).
# NOTA: si CRAN no exporta cie_norm() (introducida en 0.9.8), el script usa
# cie_normalizar() con el mismo comportamiento y lo deja registrado en el log.
# Salida: benchmark/benchmark-fase3-cran.csv
# =============================================================================

suppressPackageStartupMessages(library(ciecl))
suppressPackageStartupMessages(library(readxl))

cat("ciecl version CRAN instalada:", as.character(packageVersion("ciecl")), "\n")

# Seleccionar la funcion de normalizacion disponible en la version instalada
norm_fn <- if (exists("cie_norm", where = asNamespace("ciecl"))) {
  cat("Usando cie_norm()\n")
  ciecl::cie_norm
} else {
  cat("cie_norm no existe en esta version; usando cie_normalizar()\n")
  ciecl::cie_normalizar
}

# Datos NO incluidos en el repo (licencias): colocar en benchmark/ el archivo
# diag1-codigos-reales.csv y en benchmark/datos/ el catalogo oficial
# CIE-10 (1).xlsx (ver README.md, "Data availability note")
out_dir <- "benchmark"

# --- Datos reales -------------------------------------------------------------

cat("=== Carga de codigos reales ===\n")
t <- system.time(
  codigos <- scan(file.path(out_dir, "diag1-codigos-reales.csv"),
                  what = character(), skip = 1, quote = "", quiet = TRUE)
)
cat(sprintf("  %s codigos leidos en %.1f s\n",
            format(length(codigos), big.mark = ","), t["elapsed"]))

catalogo <- read_excel(file.path(out_dir, "datos", "CIE-10 (1).xlsx"))
codigos_cat <- catalogo[[2]]
data("cie10_cl", package = "ciecl", envir = environment())
cat("  catalogo xlsx:", length(codigos_cat), "| catalogo ciecl:",
    length(cie10_cl$codigo), "\n\n")

manual_norm <- function(x) {
  x <- toupper(trimws(x))
  x <- gsub("[^A-Z0-9]", "", x)
  sub("^([A-Z][0-9]{2})([0-9].*)$", "\\1.\\2", x)
}

resultados <- data.frame(
  brazo = character(), operacion = character(),
  elapsed_s = numeric(), stringsAsFactors = FALSE
)
registrar <- function(brazo, operacion, elapsed) {
  resultados <<- rbind(resultados, data.frame(
    brazo = brazo, operacion = operacion, elapsed_s = round(elapsed, 2)
  ))
  cat(sprintf("  [%s] %-30s %8.2f s\n", brazo, operacion, elapsed))
}

n <- length(codigos)
cat(sprintf("=== Benchmark CRAN sobre %s egresos reales ===\n",
            format(n, big.mark = ",")))

t <- system.time(val_crudo <- codigos %in% codigos_cat)
registrar("tradicional", "validacion cruda (%in%)", t["elapsed"])

t <- system.time(norm_manual <- manual_norm(codigos))
registrar("tradicional", "normalizacion manual (regex)", t["elapsed"])

t <- system.time(val_manual <- norm_manual %in% codigos_cat)
registrar("tradicional", "validacion post-normalizacion", t["elapsed"])

t <- system.time(norm_ciecl <- norm_fn(codigos))
registrar("ciecl-cran", "normalizacion ciecl", t["elapsed"])

t <- system.time(val_ciecl <- cie_validate_vector(norm_ciecl))
registrar("ciecl-cran", "cie_validate_vector()", t["elapsed"])

t <- system.time({
  unicos <- unique(norm_ciecl)
  partes <- split(unicos, ceiling(seq_along(unicos) / 500))
  suppressMessages(lookup <- dplyr::bind_rows(lapply(partes, cie_lookup)))
  enriquecido <- lookup[match(norm_ciecl, lookup$codigo), ]
})
registrar("ciecl-cran", "cie_lookup() lotes + join", t["elapsed"])

# --- Cobertura ----------------------------------------------------------------

cat("\n=== Cobertura (CRAN, datos reales) ===\n")
cat(sprintf("  validos crudos:   %.2f%%\n", 100 * mean(val_crudo)))
cat(sprintf("  validos manual:   %.2f%%\n", 100 * mean(val_manual)))
cat(sprintf("  validos ciecl:    %.2f%%\n", 100 * mean(val_ciecl)))
cat(sprintf("  rescatados solo ciecl: %s | solo manual: %s\n",
            format(sum(val_ciecl & !val_manual), big.mark = ","),
            format(sum(val_manual & !val_ciecl), big.mark = ",")))

write.csv(resultados, file.path(out_dir, "benchmark-fase3-cran.csv"),
          row.names = FALSE)
cat("\nSesion:", R.version.string, "|", as.character(Sys.time()), "\n")
cat("\nComparar contra dev: benchmark/benchmark-fase3-2026-07-31.csv\n")
