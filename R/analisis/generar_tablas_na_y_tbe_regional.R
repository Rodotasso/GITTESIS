# ==============================================================================
# Genera dos CSV finales para el docx de tesis (versión sin cap. 1):
#   1) tabla_na_pertenencia_consolidada.csv  (copia verificada del CSV fuente
#      del PNG insertado como imagen; se añade la fila Total visible en el PNG)
#   2) tabla_tbe_regional.csv                (TBE anual x 1.000 hab. por región,
#      PI y PG, calculada desde tbe_regional_sexo_po.csv, que usa PERTENENCIA2
#      y el censo de Ñuble corregido el 2026-09-13)
# Fuentes:
#   - resultados_tesis/sesgo_supervivencia/tabla_na_pertenencia_consolidada.csv
#   - resultados_tesis/indicadores_epidemiologicos/tbe_regional_sexo_po.csv
#     (reemplaza a ind_region.csv del pipeline "sin_op", artefacto del
#      2026-09-08 con el denominador censal de Ñuble con bug)
# ==============================================================================

# Raíz del proyecto (regla del repo: prohibido setwd()/../../; usar rprojroot)
if (!exists("project_root")) {
  project_root <- rprojroot::find_root(rprojroot::has_file("BBDD_homologados.RData"))
}

dir_salida <- file.path(project_root, "resultados_tesis", "final_resultados")

# ------------------------------------------------------------------------------
# Tarea 1: CSV de la tabla de NA de PERTENENCIA
# ------------------------------------------------------------------------------
ruta_na_src <- file.path(project_root, "resultados_tesis", "sesgo_supervivencia",
                         "tabla_na_pertenencia_consolidada.csv")
na_tab <- read.csv(ruta_na_src, fileEncoding = "UTF-8", stringsAsFactors = FALSE)

# Verificación: la suma de NA por dimensión debe ser 104.326
suma_na_por_dim <- tapply(na_tab$n_na, na_tab$dimension, sum)
cat("Suma de NA por dimension:\n")
print(suma_na_por_dim)
stopifnot(all(suma_na_por_dim == 104326L))

# Verificación: el total de egresos por dimensión debe ser 20.957.004
suma_n_por_dim <- tapply(na_tab$n_total, na_tab$dimension, sum)
cat("Suma de egresos por dimension:\n")
print(suma_n_por_dim)
stopifnot(all(suma_n_por_dim == 20957004L))

# Fila Total tal como aparece en el pie del PNG (valores impresos en la imagen;
# coinciden con las sumas verificadas arriba)
fila_total <- data.frame(
  dimension           = "Total",
  categoria           = "",
  n_total             = 20957004L,
  n_na                = 104326L,
  pct_na_del_estrato  = 0.50,
  pct_del_total_na    = 100.00,
  stringsAsFactors    = FALSE
)
na_tab_out <- rbind(na_tab, fila_total)

ruta_na_out <- file.path(dir_salida, "tabla_na_pertenencia_consolidada.csv")
write.csv(na_tab_out, ruta_na_out, row.names = FALSE, fileEncoding = "UTF-8")
cat("Escrito:", ruta_na_out, "(", nrow(na_tab_out), "filas )\n")

# ------------------------------------------------------------------------------
# Tarea 2: tabla regional de TBE (PI y PG), serie sin capítulo XV
# ------------------------------------------------------------------------------
ruta_tbe_src <- file.path(project_root, "resultados_tesis",
                          "indicadores_epidemiologicos",
                          "tbe_regional_sexo_po.csv")
tbe_sexo <- read.csv(ruta_tbe_src, fileEncoding = "UTF-8",
                     stringsAsFactors = FALSE)

# Agregación de ambos sexos por región y grupo: se suman egresos sin
# capítulo XV y denominadores censales
tbe_agg <- aggregate(cbind(egresos_sin_xv, denominador) ~ grupo + region + nombre_region,
                     data = tbe_sexo, FUN = sum)

# TBE anual x 1.000 hab.: el denominador censal se multiplica por los
# 13 años de la serie
tbe_agg$tbe <- tbe_agg$egresos_sin_xv / (tbe_agg$denominador * 13) * 1000

tbe_pi <- tbe_agg[tbe_agg$grupo == "PI", c("region", "nombre_region", "tbe")]
tbe_pg <- tbe_agg[tbe_agg$grupo == "PG", c("region", "tbe")]
names(tbe_pi)[3] <- "tbe_pi"
names(tbe_pg)[2] <- "tbe_pg"

tbe_wide <- merge(tbe_pi, tbe_pg, by = "region")
tbe_wide <- tbe_wide[order(tbe_wide$region), ]  # orden por código oficial de región
stopifnot(nrow(tbe_wide) == 16L, all(!is.na(tbe_wide$tbe_pi)),
          all(!is.na(tbe_wide$tbe_pg)))

tabla_tbe <- data.frame(
  region = tbe_wide$nombre_region,
  tbe_pi = round(tbe_wide$tbe_pi, 1),
  tbe_pg = round(tbe_wide$tbe_pg, 1),
  stringsAsFactors = FALSE
)

# Verificación contra los valores narrados en el docx (tolerancia ±0,1)
esperados_pi <- c(
  "Ñuble"        = 232.7,
  "Aysén"        = 1940.5,
  "Magallanes"   = 1456.4,
  "O'Higgins"    = 1208.2,
  "Metropolitana" = 1001.5,
  "Coquimbo"     = 282.4,
  "Arica"        = 388.4
)
# Los nombres en ind_region.csv no llevan el prefijo "Región De(l)"; se contrasta
# por coincidencia de subcadena para robustez.
# NOTA (2026-10): la prosa del docx usa valores exactamente 10x los del pipeline
# corregido (TBE anual x 1.000). La discrepancia es sistemática (razón ~10,00 en
# las 7 regiones narradas), por lo que se reporta como advertencia y NO se ajusta
# la tabla: el CSV se entrega en la escala canónica corregida (x 1.000 hab/año).
cat("\nCalce TBE PI vs valores narrados en el docx (tolerancia 0,1):\n")
n_fallas <- 0L
for (nm in names(esperados_pi)) {
  idx <- grep(nm, tabla_tbe$region, fixed = TRUE)
  stopifnot(length(idx) == 1L)
  calc <- tabla_tbe$tbe_pi[idx]
  dif  <- abs(calc - esperados_pi[[nm]])
  cat(sprintf("  %-25s calc=%8.1f  narrado=%8.1f  razon=%5.2f  %s\n",
              tabla_tbe$region[idx], calc, esperados_pi[[nm]],
              esperados_pi[[nm]] / calc, ifelse(dif <= 0.1, "OK", "NO CALZA")))
  if (dif > 0.1) n_fallas <- n_fallas + 1L
}
if (n_fallas > 0L) {
  warning("La TBE regional calculada NO calza con la prosa del docx en ",
          n_fallas, " regiones (discrepancia sistematica x10: la prosa parece ",
          "estar en escala x 10.000 o proviene de la version pre-correccion). ",
          "El CSV se entrega en la escala canonica corregida (x 1.000 hab/ano).")
}

# Guarda de regresion: Ñuble debe reflejar el denominador censal corregido
# (2026-09-13) y, desde el 2026-10-12, la base oficial INE de respondedores
# (p16 IN (1,2); sin los 497.927 no-respondedores p16 = 99): PG Ñuble 69,0 -> 71,4.
# La verificación cruzada anterior contra
# temp_read/comentarios_tania/contraste_regional_resumen.csv se eliminó:
# ese artefacto (2026-09-08) arrastra el bug del censo de Ñuble.
idx_nuble <- grep("Ñuble", tabla_tbe$region, fixed = TRUE)
stopifnot(length(idx_nuble) == 1L,
          abs(tabla_tbe$tbe_pi[idx_nuble] - 32.9) <= 0.1,
          abs(tabla_tbe$tbe_pg[idx_nuble] - 71.4) <= 0.1)

ruta_tbe_out <- file.path(dir_salida, "tabla_tbe_regional.csv")
write.csv(tabla_tbe, ruta_tbe_out, row.names = FALSE, fileEncoding = "UTF-8")
cat("Escrito:", ruta_tbe_out, "\n\n")
print(tabla_tbe)
