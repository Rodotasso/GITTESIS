# =============================================================================
# Benchmark fase 4 — repeticiones + IC 95% bootstrap (base R, sin dependencias)
# 10 repeticiones intercaladas de los brazos sobre los 20.957.003 codigos reales.
# Estadisticos: mediana, P25-P75, IC 95% bootstrap percentil de la mediana
# (10.000 remuestreos), cociente pareado ciecl/manual por repeticion.
# Salida: benchmark/benchmark-fase4-2026-07-31.csv
# =============================================================================

devtools::load_all(".", quiet = TRUE)  # ejecutar desde la raiz del repo ciecl
suppressPackageStartupMessages(library(readxl))

# Datos NO incluidos en el repo (licencias): colocar en benchmark/ el archivo
# diag1-codigos-reales.csv y en benchmark/datos/ el catalogo oficial
# CIE-10 (1).xlsx (ver README.md, "Data availability note")
out_dir <- "benchmark"
set.seed(42)

cat("=== Carga de datos ===\n")
codigos <- scan(file.path(out_dir, "diag1-codigos-reales.csv"),
                what = character(), skip = 1, quote = "", quiet = TRUE)
catalogo <- read_excel(file.path(out_dir, "datos", "CIE-10 (1).xlsx"))
codigos_cat <- catalogo[[2]]
cat(sprintf("  %s codigos | catalogo %d\n",
            format(length(codigos), big.mark = ","), length(codigos_cat)))

manual_norm <- function(x) {
  x <- toupper(trimws(x))
  x <- gsub("[^A-Z0-9]", "", x)
  sub("^([A-Z][0-9]{2})([0-9].*)$", "\\1.\\2", x)
}

K <- 10
reps <- data.frame(
  rep = integer(), manual_norm = numeric(), manual_validate = numeric(),
  cie_norm = numeric(), cie_validate = numeric()
)

cat(sprintf("\n=== %d repeticiones intercaladas (20M reales) ===\n", K))
for (i in seq_len(K)) {
  t1 <- system.time(nm <- manual_norm(codigos))["elapsed"]
  t2 <- system.time(vm <- nm %in% codigos_cat)["elapsed"]
  rm(nm, vm); gc(verbose = FALSE)
  t3 <- system.time(nc <- cie_norm(codigos))["elapsed"]
  t4 <- system.time(vc <- cie_validate_vector(nc))["elapsed"]
  rm(nc, vc); gc(verbose = FALSE)
  reps <- rbind(reps, data.frame(
    rep = i, manual_norm = t1, manual_validate = t2,
    cie_norm = t3, cie_validate = t4
  ))
  cat(sprintf("  rep %2d | manual %5.1f+%4.1f | ciecl %5.1f+%5.1f s\n",
              i, t1, t2, t3, t4))
}

# --- Estadisticos: mediana, P25-P75, IC95% bootstrap de la mediana -----------

boot_mediana <- function(x, B = 10000) {
  boots <- replicate(B, median(sample(x, replace = TRUE)))
  quantile(boots, c(0.025, 0.975))
}

resumen <- data.frame(
  operacion = character(), mediana = numeric(), p25 = numeric(),
  p75 = numeric(), ic95_inf = numeric(), ic95_sup = numeric(),
  stringsAsFactors = FALSE
)
for (op in c("manual_norm", "manual_validate", "cie_norm", "cie_validate")) {
  x <- reps[[op]]
  ic <- boot_mediana(x)
  resumen <- rbind(resumen, data.frame(
    operacion = op, mediana = median(x), p25 = quantile(x, 0.25),
    p75 = quantile(x, 0.75), ic95_inf = ic[1], ic95_sup = ic[2]
  ))
}

# pipelines completos por rep y cociente pareado
manual_total <- reps$manual_norm + reps$manual_validate
ciecl_total <- reps$cie_norm + reps$cie_validate
cociente <- ciecl_total / manual_total

for (nom in c("manual_total", "ciecl_total", "cociente")) {
  x <- get(nom)
  ic <- boot_mediana(x)
  resumen <- rbind(resumen, data.frame(
    operacion = nom, mediana = median(x), p25 = quantile(x, 0.25),
    p75 = quantile(x, 0.75), ic95_inf = ic[1], ic95_sup = ic[2]
  ))
}

cat("\n=== Resumen (segundos; cociente adimensional) ===\n")
resumen[, -1] <- round(resumen[, -1], 3)
print(resumen)

# determinismo: dos ejecuciones identicas
n1 <- cie_norm(codigos)
n2 <- cie_norm(codigos)
cat("\nDeterminismo cie_norm (2 ejecuciones identicas):", identical(n1, n2), "\n")
rm(n1, n2); gc(verbose = FALSE)

write.csv(reps, file.path(out_dir, "benchmark-fase4-reps-2026-07-31.csv"),
          row.names = FALSE)
write.csv(resumen, file.path(out_dir, "benchmark-fase4-2026-07-31.csv"),
          row.names = FALSE)
cat("\nSesion:", R.version.string, "|", as.character(Sys.time()), "\n")
