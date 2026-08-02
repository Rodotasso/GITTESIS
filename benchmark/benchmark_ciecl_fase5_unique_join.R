# =============================================================================
# Benchmark fase 5 — patron unique + join sobre el corpus real (20.957.003)
# Mide (no proyecta) el pipeline ciecl con el patron recomendado para datos
# masivos: unique -> operar sobre unicos -> mapear de vuelta con match/join.
# Diseno: 10 repeticiones intercaladas (manual vs ciecl unique+join), mediana,
# P25-P75, IC 95% bootstrap de la mediana (10.000 remuestreos, seed 42),
# cociente pareado por repeticion. Intercalado = misma maquina para ambos brazos.
# Misma rama dev y setup que fase 4 (0f1f87e) para comparabilidad.
# Salida: benchmark/benchmark-fase5-uniquejoin-2026-08-01.csv
# =============================================================================

devtools::load_all(".", quiet = TRUE)  # ejecutar desde la raiz del repo ciecl
suppressPackageStartupMessages(library(readxl))
suppressPackageStartupMessages(library(dplyr))

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

# --- Pipelines ----------------------------------------------------------------

# Brazo manual completo: normalizacion + validacion + enriquecimiento
pipeline_manual <- function(x, cat) {
  nm <- manual_norm(x)
  vm <- nm %in% cat
  enr <- cat[match(nm, cat)]
  list(norm = nm, valid = vm, desc = enr)
}

# Brazo ciecl con patron unique + join (lotes de 500: la rama dev no trocea
# internamente; el fix B1 vive en wip/hallazgos-post-auditoria)
pipeline_ciecl_uj <- function(x) {
  u <- unique(x)
  nu <- cie_norm(u)
  vu <- cie_validate_vector(nu)
  partes <- split(nu, ceiling(seq_along(nu) / 500))
  suppressMessages(lk <- bind_rows(lapply(partes, cie_lookup)))
  idx <- match(x, u)
  list(norm = nu[idx], valid = vu[idx],
       desc = lk$descripcion[match(nu[idx], lk$codigo)])
}

# --- Verificacion de equivalencia (una vez) -----------------------------------
# El patron debe producir exactamente el mismo resultado que la aplicacion
# directa sobre el vector completo.

cat("\n=== Equivalencia unique+join vs aplicacion directa ===\n")
res_uj <- pipeline_ciecl_uj(codigos)
norm_directa <- cie_norm(codigos)
cat("  cie_norm: identical() =", identical(res_uj$norm, norm_directa), "\n")
cat(sprintf("  cobertura unique+join: %.2f%% | registros rescatados: %s\n",
            100 * mean(res_uj$valid),
            format(sum(res_uj$valid), big.mark = ",")))
cat("  codigos unicos:", length(unique(codigos)), "\n")
rm(norm_directa); gc(verbose = FALSE)

# --- Desglose por etapa (una corrida instrumentada) ---------------------------

cat("\n=== Desglose por etapa (corrida unica) ===\n")
u <- unique(codigos)
t_unique <- system.time(u <- unique(codigos))["elapsed"]
t_nu <- system.time(nu <- cie_norm(u))["elapsed"]
t_vu <- system.time(vu <- cie_validate_vector(nu))["elapsed"]
t_lk <- system.time({
  partes <- split(nu, ceiling(seq_along(nu) / 500))
  suppressMessages(lk <- bind_rows(lapply(partes, cie_lookup)))
})["elapsed"]
t_join <- system.time({
  idx <- match(codigos, u)
  desc <- lk$descripcion[match(nu[idx], lk$codigo)]
})["elapsed"]
cat(sprintf("  unique %5.2f | norm %5.2f | validate %5.2f | lookup %5.2f | join %5.2f s\n",
            t_unique, t_nu, t_vu, t_lk, t_join))
rm(u, nu, vu, lk, partes, idx, desc, res_uj); gc(verbose = FALSE)

# --- 10 repeticiones intercaladas ---------------------------------------------

K <- 10
reps <- data.frame(rep = integer(), manual_total = numeric(),
                   ciecl_uj_total = numeric())

cat(sprintf("\n=== %d repeticiones intercaladas (20M reales) ===\n", K))
for (i in seq_len(K)) {
  t1 <- system.time(rm_ <- pipeline_manual(codigos, codigos_cat))["elapsed"]
  rm(rm_); gc(verbose = FALSE)
  t2 <- system.time(rc_ <- pipeline_ciecl_uj(codigos))["elapsed"]
  rm(rc_); gc(verbose = FALSE)
  reps <- rbind(reps, data.frame(rep = i, manual_total = t1,
                                 ciecl_uj_total = t2))
  cat(sprintf("  rep %2d | manual %6.1f | ciecl unique+join %6.1f s\n", i, t1, t2))
}

# --- Estadisticos --------------------------------------------------------------

boot_mediana <- function(x, B = 10000) {
  boots <- replicate(B, median(sample(x, replace = TRUE)))
  quantile(boots, c(0.025, 0.975))
}

resumen <- data.frame(
  operacion = character(), mediana = numeric(), p25 = numeric(),
  p75 = numeric(), ic95_inf = numeric(), ic95_sup = numeric(),
  stringsAsFactors = FALSE
)
manual_total <- reps$manual_total
ciecl_uj_total <- reps$ciecl_uj_total
cociente <- reps$ciecl_uj_total / reps$manual_total
for (nom in c("manual_total", "ciecl_uj_total", "cociente")) {
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

write.csv(reps, file.path(out_dir, "benchmark-fase5-uniquejoin-reps-2026-08-01.csv"),
          row.names = FALSE)
write.csv(resumen, file.path(out_dir, "benchmark-fase5-uniquejoin-2026-08-01.csv"),
          row.names = FALSE)
cat("\nSesion:", R.version.string, "|", as.character(Sys.time()), "\n")
