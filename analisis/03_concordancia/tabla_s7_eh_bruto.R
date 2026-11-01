# ======================================================================
# Tabla S7 extendida: efecto del enriquecimiento de la variable de
# pertenencia a pueblos indigenas, por region (comentario [167]).
#
# Tres columnas de % PO:
#   1. EH en bruto: PUEBLO_ORIGINARIO_BIN (declaracion del registro de
#      egresos; 1 si el campo PUEBLO_ORIGINARIO esta en "1".."10").
#      Construccion: preparacion/BBDD Limpia.qmd lineas 57-63.
#   2. Enriquecida: PERTENENCIA2 (union de EH + RSH + CONADI, con los
#      104.326 triple-NA reasignados a 0). Construccion:
#      preparacion/BBDD Limpia.qmd lineas 120-128 y 161+.
#   3. Censo 2017 (residencia): insumo validado
#      temp_read/fase2_caracterizacion/censo2017_po_region_corregido.csv,
#      generado por temp_read/fase2_caracterizacion/fase2_censo_regional.R
#      (replica la logica canonica de R/concordancias/extraer_datos_censo.R,
#      incluida la reasignacion de las 21 comunas de Nuble a la region 16).
#
# NOTA sobre PERTENENCIA: NO es la variable EH en bruto. En la base
# homologada, PERTENENCIA ya es la union de las tres fuentes y sus
# positivos son identicos a los de PERTENENCIA2 (3.117.578); solo difiere
# en que conserva NA para los 104.326 registros triple-NA. Verificado en
# docs/verificacion_pertenencia_2026-10.md (tabla cruzada) y en el log
# temp_read/fase2_caracterizacion/fase2_log.txt. Por eso la columna
# "EH en bruto" usa PUEBLO_ORIGINARIO_BIN.
#
# Solo lectura de BBDD_homologados.RData. Salida:
#   resultados_tesis/VIGENTES/concordancias/tabla_s7_extendida_eh_bruto.csv
# ======================================================================

options(encoding = "UTF-8")

if (!exists("project_root")) {
  project_root <- rprojroot::find_root(rprojroot::has_file("BBDD_homologados.RData"))
}
source(file.path(project_root, "R/utilidades/cargar_datos_homologados.R"))

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required but not available.")
}
library(data.table)

ruta_censo <- file.path(project_root, "temp_read/fase2_caracterizacion",
                        "censo2017_po_region_corregido.csv")
ruta_referencia_p2 <- file.path(project_root, "temp_read/fase2_caracterizacion",
                                "regional_po_eh.csv")
dir_salida <- file.path(project_root, "resultados_tesis/VIGENTES/concordancias")
dir.create(dir_salida, recursive = TRUE, showWarnings = FALSE)
ruta_salida <- file.path(dir_salida, "tabla_s7_extendida_eh_bruto.csv")

# ----------------------------------------------------------------------
# 1. Carga de la base (solo lectura; sin la derivacion CIE-10, no aplica)
# ----------------------------------------------------------------------
t0 <- Sys.time()
dt <- cargar_datos_homologados(actualizar_capitulos = FALSE)
setDT(dt)
cat("Filas base:", format(nrow(dt), big.mark = "."),
    "| carga:", format(difftime(Sys.time(), t0, units = "mins")), "\n")

# ----------------------------------------------------------------------
# 2. Mitad EH: conteos regionales de PO segun ambas versiones
# ----------------------------------------------------------------------
reg <- dt[, .(
  n_egresos        = .N,
  n_po_eh_bruto    = sum(PUEBLO_ORIGINARIO_BIN == 1, na.rm = TRUE),
  n_po_enriquecida = sum(PERTENENCIA2 == 1, na.rm = TRUE)
), by = .(codigo_region = suppressWarnings(as.integer(CODIGO_REGION)))]

rm(dt)
gc(verbose = FALSE)

n_total_base <- sum(reg$n_egresos)
sin_region <- reg[is.na(codigo_region)]
reg <- reg[!is.na(codigo_region)]
stopifnot(nrow(reg) == 16L)

reg[, `:=`(
  pct_po_eh_bruto    = 100 * n_po_eh_bruto / n_egresos,
  pct_po_enriquecida = 100 * n_po_enriquecida / n_egresos
)]

cat("Egresos totales:", format(n_total_base, big.mark = "."),
    "| sin region:", format(sin_region$n_egresos, big.mark = "."),
    "| con region:", format(sum(reg$n_egresos), big.mark = "."), "\n")

# ----------------------------------------------------------------------
# 3. Cruce con el Censo 2017 y diferencias en puntos porcentuales
# ----------------------------------------------------------------------
censo <- fread(ruta_censo)
stopifnot(nrow(censo) == 16L)

tabla <- merge(reg, censo[, .(codigo_region = as.integer(region),
                              n_censo = total, n_po_censo = pertenece)],
               by = "codigo_region")
tabla[, pct_po_censo2017 := 100 * n_po_censo / n_censo]
tabla[, `:=`(
  dif_eh_bruto_censo_pp    = pct_po_eh_bruto - pct_po_censo2017,
  dif_enriquecida_censo_pp = pct_po_enriquecida - pct_po_censo2017
)]

# Orden geografico del documento (norte a sur, Nuble tras Maule)
orden_docx <- c(15L, 1L, 2L, 3L, 4L, 5L, 6L, 7L, 16L, 8L, 9L, 14L, 10L, 11L, 12L, 13L)
nombre_region <- c(
  "15" = "Arica y Parinacota", "1" = "Tarapac\u00e1", "2" = "Antofagasta",
  "3" = "Atacama", "4" = "Coquimbo", "5" = "Valpara\u00edso",
  "6" = "O'Higgins", "7" = "Maule", "16" = "\u00d1uble", "8" = "Biob\u00edo",
  "9" = "La Araucan\u00eda", "14" = "Los R\u00edos", "10" = "Los Lagos",
  "11" = "Ays\u00e9n", "12" = "Magallanes", "13" = "Metropolitana"
)
tabla[, region := nombre_region[as.character(codigo_region)]]
stopifnot(!any(is.na(tabla$region)))
tabla[, orden := match(codigo_region, orden_docx)]
setorder(tabla, orden)
tabla[, orden := NULL]

# ----------------------------------------------------------------------
# 4. Verificaciones (abortan si algo no calza)
# ----------------------------------------------------------------------
# 4.1 Denominador: 20.957.004 totales, 208.033 sin region (nota Tabla S7)
stopifnot(n_total_base == 20957004L, sin_region$n_egresos == 208033L,
          sum(tabla$n_egresos) == 20957004L - 208033L)

# 4.2 Totales nacionales de PO (conteos verificados 2026-10,
#     docs/verificacion_pertenencia_2026-10.md)
n_po_enr_nac <- sum(tabla$n_po_enriquecida) + sin_region$n_po_enriquecida
n_po_ehb_nac <- sum(tabla$n_po_eh_bruto) + sin_region$n_po_eh_bruto
stopifnot(n_po_enr_nac == 3117578L, n_po_ehb_nac == 1779963L)
pct_enr_nac <- 100 * n_po_enr_nac / n_total_base
cat("Nacional enriquecida:", round(pct_enr_nac, 2),
    "% (publicado: 14,9) | EH en bruto nacional:",
    round(100 * n_po_ehb_nac / n_total_base, 2), "%\n")
stopifnot(round(pct_enr_nac, 1) == 14.9)

# 4.3 Calce de p2 con la mitad EH ya verificada (fase2, insumo del Anexo 4)
ref <- fread(ruta_referencia_p2)
ref <- ref[!is.na(CODIGO_REGION), .(codigo_region = as.integer(CODIGO_REGION),
                                    pct_p2_ref = pct_po_en_region_p2)]
chequeo <- merge(tabla[, .(codigo_region, pct_po_enriquecida)], ref,
                 by = "codigo_region")
chequeo[, desvio := abs(pct_po_enriquecida - pct_p2_ref)]
stopifnot(nrow(chequeo) == 16L, max(chequeo$desvio) < 0.0005)
cat("Calce p2 vs regional_po_eh.csv: max desvio",
    format(max(chequeo$desvio), digits = 3), "\n")

# 4.4 Calce de p2 con los valores publicados en el docx (1 decimal)
pub <- c("15" = 24.3, "1" = 20.6, "2" = 16.2, "3" = 20.9, "4" = 5.6,
         "5" = 6.2, "6" = 13.8, "7" = 7.7, "16" = 2.5, "8" = 8.9,
         "9" = 34.6, "14" = 26.5, "10" = 31.3, "11" = 65.7, "12" = 33.2,
         "13" = 13.3)
calc_1d <- round(tabla$pct_po_enriquecida, 1)
names(calc_1d) <- as.character(tabla$codigo_region)
stopifnot(identical(unname(calc_1d[names(pub)]), unname(pub)))
cat("Calce p2 vs docx (16/16 regiones, 1 decimal): OK\n")

# 4.5 Aysen es el menor denominador regional (clausula del asterisco)
stopifnot(tabla[region == "Ays\u00e9n", n_egresos] == min(tabla$n_egresos))
cat("Menor denominador regional:",
    tabla[which.min(n_egresos), region], "con",
    format(min(tabla$n_egresos), big.mark = "."), "egresos\n")

# ----------------------------------------------------------------------
# 5. Salida: CSV en formato chileno (separador ; y decimal ,)
# ----------------------------------------------------------------------
salida <- tabla[, .(
  region, codigo_region, n_egresos,
  n_po_eh_bruto,
  pct_po_eh_bruto        = round(pct_po_eh_bruto, 1),
  n_po_enriquecida,
  pct_po_enriquecida     = round(pct_po_enriquecida, 1),
  pct_po_censo2017       = round(pct_po_censo2017, 1),
  dif_enriquecida_censo_pp = round(dif_enriquecida_censo_pp, 1),
  dif_eh_bruto_censo_pp    = round(dif_eh_bruto_censo_pp, 1)
)]
fwrite(salida, ruta_salida, sep = ";", dec = ",")
cat("\nCSV escrito en:", ruta_salida, "\n\n")
print(salida)

# Tabla en consola con formato del documento (coma decimal, signo en difs)
fmt <- function(x) formatC(x, format = "f", digits = 1, decimal.mark = ",")
fmt_signo <- function(x) ifelse(x >= 0, paste0("+", fmt(x)), fmt(x))
vista <- salida[, .(
  Region = region,
  `n egresos` = format(n_egresos, big.mark = ".", scientific = FALSE),
  `%PO EH bruto` = fmt(pct_po_eh_bruto),
  `%PO enriquecida` = fmt(pct_po_enriquecida),
  `%PO Censo 2017` = fmt(pct_po_censo2017),
  `Dif enriquecida-censo (pp)` = fmt_signo(dif_enriquecida_censo_pp),
  `Dif EH bruto-censo (pp)` = fmt_signo(dif_eh_bruto_censo_pp)
)]
cat("\n== Vista con formato del documento ==\n")
print(vista, row.names = FALSE, right = FALSE)
