# =============================================================================
# Benchmark fase 2 — flujo tradicional (xlsx + R base) vs ciecl
# Catalogo: CIE-10 v2013 Chile en xlsx (39.873 codigos), copia local en
#   benchmark/datos/CIE-10 (1).xlsx (NO incluida en el repo, licencias DEIS)
# Brazo A (tradicional): lectura del xlsx + normalizacion manual con regex +
#   validacion con %in% + enriquecimiento con match().
# Brazo B (ciecl): cie_norm + cie_validate_vector + cie_lookup por lotes.
# Salida: benchmark/benchmark-fase2-2026-07-31.csv
# =============================================================================

devtools::load_all(".", quiet = TRUE)  # ejecutar desde la raiz del repo ciecl
suppressPackageStartupMessages(library(readxl))
suppressPackageStartupMessages(library(writexl))

# Datos NO incluidos en el repo (licencias DEIS/MINSAL): colocar el catalogo
# oficial en benchmark/datos/ (ver README.md, "Data availability note")
ruta_xlsx <- file.path("benchmark", "datos", "CIE-10 (1).xlsx")
out_dir <- "benchmark"

resultados <- data.frame(
  brazo = character(), operacion = character(), n = numeric(),
  elapsed_s = numeric(), stringsAsFactors = FALSE
)

registrar <- function(brazo, operacion, n, elapsed) {
  resultados <<- rbind(resultados, data.frame(
    brazo = brazo, operacion = operacion, n = n,
    elapsed_s = round(elapsed, 2)
  ))
  cat(sprintf("  [%s] %-28s n=%9s | %9.2f s\n",
              brazo, operacion, format(n, big.mark = ","), elapsed))
}

# --- Costo fijo: cargar el catalogo desde xlsx (brazo tradicional) -----------

cat("=== Carga del catalogo ===\n")
t <- system.time(catalogo <- read_excel(ruta_xlsx))
registrar("tradicional", "carga catalogo xlsx (readxl)", nrow(catalogo), t["elapsed"])

codigos_cat <- catalogo[[2]]  # columna Codigo (evita problemas de encoding)
cat("  Codigos en catalogo xlsx:", length(codigos_cat), "\n")

# ciecl: el catalogo viene embebido (SQLite), costo de carga ~ 0
data("cie10_cl", package = "ciecl", envir = environment())
t <- system.time(codigos_ciecl <- cie10_cl$codigo)
registrar("ciecl", "carga catalogo embebido", length(codigos_ciecl), t["elapsed"])

# Cruce de versiones (informativo)
cat("  En xlsx pero no en ciecl:", length(setdiff(codigos_cat, codigos_ciecl)),
    "| en ciecl pero no en xlsx:", length(setdiff(codigos_ciecl, codigos_cat)), "\n\n")

# --- Datos sinteticos de egresos (Pareto, desde el catalogo xlsx) ------------

set.seed(42)
top_500 <- sample(codigos_cat, 500)
resto <- setdiff(codigos_cat, top_500)

generar_codigos <- function(n, prop_top = 0.8, prop_sucios = 0.05) {
  n_top <- round(n * prop_top)
  x <- c(sample(top_500, n_top, replace = TRUE),
         sample(resto, n - n_top, replace = TRUE))
  # 5% con problemas tipicos de digitacion: sin punto, espacios, minusculas
  n_sucios <- round(n * prop_sucios)
  if (n_sucios > 0) {
    idx <- sample(seq_len(n), n_sucios)
    tercio <- split(idx, cut(seq_along(idx), 3, labels = FALSE))
    x[tercio[[1]]] <- gsub("\\.", "", x[tercio[[1]]])
    x[tercio[[2]]] <- paste0(" ", x[tercio[[2]]], " ")
    x[tercio[[3]]] <- tolower(x[tercio[[3]]])
  }
  x
}

# --- Flujo tradicional: normalizacion y validacion "a mano" ------------------

manual_norm <- function(x) {
  x <- toupper(trimws(x))
  x <- gsub("[^A-Z0-9]", "", x)
  sub("^([A-Z][0-9]{2})([0-9].*)$", "\\1.\\2", x)
}

manual_validate <- function(x, catalogo_codigos) {
  grepl("^[A-Z][0-9]{2}(\\.[0-9]+)?$", x) & x %in% catalogo_codigos
}

# --- Comparacion en 1M / 5M / 20M --------------------------------------------

escalas <- c(1e6, 5e6, 20e6)

for (n in escalas) {
  cat(sprintf("=== n = %s ===\n", format(n, big.mark = ",")))
  codigos_sim <- generar_codigos(n)

  # Brazo A: tradicional
  t <- system.time(norm_manual <- manual_norm(codigos_sim))
  registrar("tradicional", "normalizacion manual (regex)", n, t["elapsed"])

  t <- system.time(val_manual <- manual_validate(norm_manual, codigos_cat))
  registrar("tradicional", "validacion %in% + regex", n, t["elapsed"])

  t <- system.time({
    idx <- match(norm_manual, codigos_cat)
    desc <- catalogo[[3]][idx]  # Descripcion
  })
  registrar("tradicional", "enriquecimiento match()", n, t["elapsed"])

  # Brazo B: ciecl
  t <- system.time(norm_ciecl <- cie_norm(codigos_sim))
  registrar("ciecl", "cie_norm()", n, t["elapsed"])

  t <- system.time(val_ciecl <- cie_validate_vector(norm_ciecl))
  registrar("ciecl", "cie_validate_vector()", n, t["elapsed"])

  t <- system.time({
    unicos <- unique(norm_ciecl)
    partes <- split(unicos, ceiling(seq_along(unicos) / 500))
    suppressMessages(lookup <- dplyr::bind_rows(lapply(partes, cie_lookup)))
    enriquecido <- lookup[match(norm_ciecl, lookup$codigo), ]
  })
  registrar("ciecl", "cie_lookup() lotes + join", n, t["elapsed"])

  # Concordancia entre brazos (control de calidad del benchmark)
  cat(sprintf("  validos manual: %.2f%% | validos ciecl: %.2f%%\n\n",
              100 * mean(val_manual), 100 * mean(val_ciecl)))

  rm(codigos_sim, norm_manual, val_manual, norm_ciecl, val_ciecl,
     idx, desc, unicos, partes, lookup, enriquecido)
  gc(verbose = FALSE)
}

# --- Costo de I/O del formato xlsx (un archivo "anual" de 1M filas) ----------

cat("=== I/O xlsx: archivo de egresos de 1M filas ===\n")
cat("(limite de Excel: 1.048.576 filas/hoja; un año de egresos Chile ~1,5M)\n")
set.seed(7)
df_egresos <- data.frame(
  id = seq_len(1e6),
  codigo = generar_codigos(1e6, prop_sucios = 0),
  stringsAsFactors = FALSE
)
ruta_tmp <- file.path(tempdir(), "egresos_1m.xlsx")

t <- system.time(write_xlsx(df_egresos, ruta_tmp))
registrar("tradicional", "escritura xlsx 1M filas (writexl)", 1e6, t["elapsed"])

t <- system.time(df_leido <- read_excel(ruta_tmp))
registrar("tradicional", "lectura xlsx 1M filas (readxl)", 1e6, t["elapsed"])

rm(df_egresos, df_leido)
invisible(file.remove(ruta_tmp))
gc(verbose = FALSE)

# --- Salida -------------------------------------------------------------------

write.csv(resultados, file.path(out_dir, "benchmark-fase2-2026-07-31.csv"),
          row.names = FALSE)

cat("\n=== Resumen ===\n")
print(resultados)
cat("\nSesion:", R.version.string, "|", as.character(Sys.time()), "\n")
