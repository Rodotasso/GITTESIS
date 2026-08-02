# =============================================================================
# Benchmark ciecl — Analisis 4 (eficiencia de procesamiento)
# Mide: cie_validate_vector, cie_normalizar y patron GITTESIS
#       (unique -> cie_lookup -> left_join) en 1M / 5M / 20M codigos.
# Datos sinteticos con distribucion Pareto (top 500 codigos = 80%), seed fija.
# Uso (desde la raiz del repo): Rscript benchmark/benchmark_ciecl_analisis4.R
# =============================================================================

devtools::load_all(".", quiet = TRUE)  # ejecutar desde la raiz del repo ciecl
suppressPackageStartupMessages(library(dplyr))

set.seed(42)

# Codigos reales del catalogo del paquete
data("cie10_cl", package = "ciecl", envir = environment())
todos_codigos <- cie10_cl$codigo
cat("ciecl cargado via load_all | codigos en catalogo:", length(todos_codigos), "\n")
cat("Funciones:", all(sapply(
  c("cie_validate_vector", "cie_normalizar", "cie_lookup"), exists
)), "\n\n")

# Distribucion Pareto: top 500 codigos concentran ~80% de la frecuencia
top_500 <- sample(todos_codigos, min(500, length(todos_codigos)))
resto <- setdiff(todos_codigos, top_500)

generar_codigos <- function(n, prop_top = 0.8) {
  n_top <- round(n * prop_top)
  c(
    sample(top_500, n_top, replace = TRUE),
    sample(resto, n - n_top, replace = TRUE)
  )
}

resultados <- data.frame(
  funcion = character(), n = numeric(),
  unicos = integer(), elapsed_s = numeric(),
  stringsAsFactors = FALSE
)

registrar <- function(funcion, n, unicos, elapsed) {
  resultados <<- rbind(resultados, data.frame(
    funcion = funcion, n = n, unicos = unicos, elapsed_s = round(elapsed, 2)
  ))
  cat(sprintf("  %-22s n=%9s | unicos=%6d | %8.2f s | %12.0f reg/s\n",
              funcion, format(n, big.mark = ","), unicos, elapsed,
              n / max(elapsed, 1e-6)))
}

escalas <- c(1e6, 5e6, 20e6)

cat("=== cie_validate_vector() ===\n")
for (n in escalas) {
  codigos_sim <- generar_codigos(n)
  t <- system.time(cie_validate_vector(codigos_sim))
  registrar("cie_validate_vector", n, length(unique(codigos_sim)), t["elapsed"])
  rm(codigos_sim); gc(verbose = FALSE)
}

cat("\n=== cie_norm() ===\n")
for (n in escalas) {
  codigos_sim <- generar_codigos(n)
  # variaciones realistas: sin punto y con espacios
  codigos_sim[1:1000] <- gsub("\\.", "", codigos_sim[1:1000])
  codigos_sim[1001:2000] <- paste0(" ", codigos_sim[1001:2000], " ")
  t <- system.time(cie_norm(codigos_sim))
  registrar("cie_norm", n, length(unique(codigos_sim)), t["elapsed"])
  rm(codigos_sim); gc(verbose = FALSE)
}

# cie_lookup() falla con >999 codigos por limite de variables SQL;
# se procesa en lotes de 500 (patron recomendado para catalogos completos)
cie_lookup_lotes <- function(codigos, tam = 500) {
  partes <- split(codigos, ceiling(seq_along(codigos) / tam))
  dplyr::bind_rows(lapply(partes, cie_lookup))
}

cat("\n=== Patron GITTESIS: unique() -> cie_lookup() por lotes -> left_join() ===\n")
for (n in escalas) {
  codigos_sim <- generar_codigos(n)
  df_sim <- tibble(id = seq_len(n), codigo = codigos_sim)
  t <- system.time({
    unicos <- unique(codigos_sim)
    lookup <- cie_lookup_lotes(unicos)
    df_final <- left_join(df_sim, lookup, by = "codigo")
  })
  registrar("patron_unique_lookup_join", n, length(unicos), t["elapsed"])
  rm(codigos_sim, df_sim, unicos, lookup, df_final); gc(verbose = FALSE)
}

# Salida
# Datos NO incluidos en el repo (licencias): colocar en benchmark/ el archivo
# diag1-codigos-reales.csv (ver README.md, "Data availability note")
out_dir <- "benchmark"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
write.csv(resultados, file.path(out_dir, "benchmark-analisis4-2026-07-31.csv"),
          row.names = FALSE)

cat("\n=== Resumen ===\n")
print(resultados)
cat("\nSesion:", R.version.string, "|", Sys.time(), "\n")
