# =============================================================================
# Benchmark fase 3 — flujo tradicional (xlsx + R base) vs ciecl
# sobre los 20.957.004 codigos DIAG1 REALES de egresos Chile 2010-2022.
# Entrada: benchmark/diag1-codigos-reales.csv (1 columna; NO incluida en el
#   repo, dato sensible DEIS — regenerar con extraer_diag1_egresos.py)
# Catalogo brazo tradicional: CIE-10 v2013 xlsx (39.873 codigos)
# Salida: benchmark/benchmark-fase3-2026-07-31.csv
# =============================================================================

devtools::load_all(".", quiet = TRUE)  # ejecutar desde la raiz del repo ciecl
suppressPackageStartupMessages(library(readxl))

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

# --- Catalogos ----------------------------------------------------------------

catalogo <- read_excel(file.path(out_dir, "datos", "CIE-10 (1).xlsx"))
codigos_cat <- catalogo[[2]]
data("cie10_cl", package = "ciecl", envir = environment())
cat("  catalogo xlsx:", length(codigos_cat), "| catalogo ciecl:",
    length(cie10_cl$codigo), "\n\n")

# --- Flujo tradicional --------------------------------------------------------

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
cat(sprintf("=== Benchmark sobre %s egresos reales ===\n",
            format(n, big.mark = ",")))

# validos sin tocar (linea base)
t <- system.time(val_crudo <- codigos %in% codigos_cat)
registrar("tradicional", "validacion cruda (%in%)", t["elapsed"])

t <- system.time(norm_manual <- manual_norm(codigos))
registrar("tradicional", "normalizacion manual (regex)", t["elapsed"])

t <- system.time(val_manual <- norm_manual %in% codigos_cat)
registrar("tradicional", "validacion post-normalizacion", t["elapsed"])

t <- system.time({
  idx <- match(norm_manual, codigos_cat)
  desc <- catalogo[[3]][idx]
})
registrar("tradicional", "enriquecimiento match()", t["elapsed"])

# --- ciecl --------------------------------------------------------------------

t <- system.time(norm_ciecl <- cie_norm(codigos))
registrar("ciecl", "cie_norm()", t["elapsed"])

t <- system.time(val_ciecl <- cie_validate_vector(norm_ciecl))
registrar("ciecl", "cie_validate_vector()", t["elapsed"])

t <- system.time({
  unicos <- unique(norm_ciecl)
  partes <- split(unicos, ceiling(seq_along(unicos) / 500))
  suppressMessages(lookup <- dplyr::bind_rows(lapply(partes, cie_lookup)))
  enriquecido <- lookup[match(norm_ciecl, lookup$codigo), ]
})
registrar("ciecl", "cie_lookup() lotes + join", t["elapsed"])

# --- Resultados de cobertura --------------------------------------------------

cat("\n=== Cobertura (sobre datos reales) ===\n")
cat(sprintf("  validos crudos (sin normalizar):  %.2f%%\n", 100 * mean(val_crudo)))
cat(sprintf("  validos manual (regex):           %.2f%%\n", 100 * mean(val_manual)))
cat(sprintf("  validos ciecl (cie_norm):         %.2f%%\n", 100 * mean(val_ciecl)))
cat(sprintf("  rescatados por manual: %s | por ciecl: %s\n",
            format(sum(val_manual & !val_crudo), big.mark = ","),
            format(sum(val_ciecl & !val_crudo), big.mark = ",")))
cat(sprintf("  concordancia manual==ciecl: %.2f%%\n",
            100 * mean(val_manual == val_ciecl)))
cat(sprintf("  validos solo ciecl: %s | solo manual: %s\n",
            format(sum(val_ciecl & !val_manual), big.mark = ","),
            format(sum(val_manual & !val_ciecl), big.mark = ",")))

# muestra de codigos que ciecl rescata y manual no (para el informe)
solo_ciecl <- unique(codigos[val_ciecl & !val_manual])
cat("  ejemplos solo-ciecl:", paste(head(solo_ciecl, 10), collapse = ", "), "\n")

write.csv(resultados, file.path(out_dir, "benchmark-fase3-2026-07-31.csv"),
          row.names = FALSE)
cat("\nSesion:", R.version.string, "|", as.character(Sys.time()), "\n")
