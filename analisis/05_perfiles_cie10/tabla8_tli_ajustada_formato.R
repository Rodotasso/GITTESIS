# ==============================================================================
# SCRIPT: tabla8_tli_ajustada_formato.R
# ==============================================================================
#
# DESCRIPCIÓN:
#   Deriva la Tabla 8 de la tesis (razón de letalidad intrahospitalaria ajustada
#   por edad, método indirecto) desde el artefacto ya validado
#   `tli_ajustada_edad_capitulo_indirecto.csv`, en el formato que necesita el
#   manuscrito.
#
#   NO recalcula nada: el CSV de entrada lo produce el qmd canónico
#   `analisis/05_perfiles_cie10/tli_ajustada_edad.qmd` (estandarización
#   indirecta, referencia = población No PO). Este script solo proyecta,
#   reordena y formatea columnas.
#
# UNIDADES DEL CONTRATO DE SALIDA (documentadas aquí y en los nombres):
#   - egresos_PO, defunciones_obs_PO : conteos enteros, sin decimales.
#   - defunciones_esp_PO             : defunciones esperadas (conteo modelado,
#                                      no entero por definición), 1 decimal.
#   - TLI_cruda_*_por1000            : tasa de letalidad POR 1.000 egresos,
#   - TLI_ajustada_*_por1000          2 decimales fijos. Se usa per-1.000 y no
#                                      porcentaje para que el capítulo Embarazo,
#                                      parto y puerperio (TLI < 1%) no colapse a
#                                      0,005 y distorsione la razón implícita.
#   - razon_cruda, razon_ajustada    : razón observada/esperada, 3 decimales.
#   Todos los decimales se fijan con formatC (no round) para que el CSV conserve
#   el número exacto de decimales, incluidos los ceros finales.
#
# ORDEN DE FILAS:
#   Alfabético por capítulo (criterio previo, vía `sort(method = "radix")` para
#   orden determinista independiente del locale).
#
# FILA RESIDUAL:
#   El capítulo residual «Otros» (el único egreso con DIAG1 vacío, sin capítulo
#   asignable) NO forma parte de la tabla: se excluye del CSV y se documenta
#   como nota al pie en un archivo de texto aparte (ver SALIDA).
#
# VALIDACIONES (stopifnot, abortan antes de escribir):
#   - El insumo trae 21 capítulos CIE-10 con egresos (el capítulo 20, causas
#     externas V/W/X/Y, no tiene códigos en la base) y, cuando existe, la fila
#     residual «Otros». La tabla de salida queda en 21 filas en ambos casos.
#   - 21 capítulos únicos y a lo sumo un «Otros» en el insumo.
#   - La fila residual, cuando existe, suma exactamente 1 egreso: es la cifra
#     que sostiene el texto de la nota al pie.
#   - egresos_PO + egresos_NoPO == 20.957.004 (total de la base homologada),
#     control que suma el residual excluido de la tabla.
#   - Ausencia de NA en las columnas de entrada de los 21 capítulos y en la
#     tabla formateada.
#
# ENTRADA (no se modifica):
#   resultados_tesis/VIGENTES/indicadores/tli_ajustada_edad_capitulo_indirecto.csv
#
# SALIDA:
#   resultados_tesis/indicadores_epidemiologicos/tabla8_tli_ajustada_edad_docx.csv
#   resultados_tesis/indicadores_epidemiologicos/tabla8_nota_pie.txt
#   Back up del CSV anterior (si existe): <salida>.bak  (no se sobreescribe)
#
# USO:
#   Rscript "analisis/05_perfiles_cie10/tabla8_tli_ajustada_formato.R"
#
# ==============================================================================

if (!exists("project_root")) {
  project_root <- rprojroot::find_root(rprojroot::has_file("BBDD_homologados.RData"))
}

IN_CSV <- file.path(project_root, "resultados_tesis", "VIGENTES", "indicadores",
                    "tli_ajustada_edad_capitulo_indirecto.csv")
OUT_DIR <- file.path(project_root, "resultados_tesis", "indicadores_epidemiologicos")
OUT_CSV <- file.path(OUT_DIR, "tabla8_tli_ajustada_edad_docx.csv")
OUT_NOTA <- file.path(OUT_DIR, "tabla8_nota_pie.txt")

# Totales de referencia de la base homologada (20.957.004 egresos)
N_TOTAL_ESPERADO <- 20957004L
# Capitulos CIE-10 con al menos un egreso: 1-19, 21 y 22 (el 20 no tiene
# codigos V/W/X/Y en la base). El residual «Otros» suma una fila cuando existe.
N_CAPITULOS_ESPERADOS <- 21L
# Egresos sin capitulo asignable (DIAG1 vacio). Sostienen el texto de la nota.
N_RESIDUAL_ESPERADO <- 1L
CAPITULO_RESIDUAL <- "Otros"
DIGITOS_TASA <- 2L
DIGITOS_RAZON <- 3L
DIGITOS_ESPERADOS <- 1L

# --- Lectura y validación del contrato de entrada ------------------------------
if (!file.exists(IN_CSV)) {
  stop("No existe el insumo requerido: ", IN_CSV)
}

suministrado <- data.table::fread(IN_CSV, encoding = "UTF-8")

req_cols <- c("capitulo", "egresos_PO", "egresos_NoPO", "def_obs_PO",
              "def_esp_PO", "TLI_cruda_PO_pct", "TLI_ajustada_PO_pct",
              "TLI_cruda_NoPO_pct", "razon_cruda", "razon_ajustada")
faltan <- setdiff(req_cols, names(suministrado))
if (length(faltan) > 0) {
  stop("Faltan columnas en el insumo: ", paste(faltan, collapse = ", "))
}

# Formateador único: decimales fijos, punto decimal (independiente del locale).
# Las celdas sin estimación (fila residual sin TLI) se escriben en blanco, no "NA".
fmt <- function(x, digits) {
  salida <- formatC(x, format = "f", digits = digits, decimal.mark = ".")
  salida[is.na(x)] <- ""
  salida
}

# --- Validaciones de integridad del insumo (antes de transformar) --------------
# El residual es opcional: existe mientras quede algun egreso sin capitulo
# asignable (DIAG1 vacio). Si no existe, la tabla queda en 21 filas.
tiene_residual <- CAPITULO_RESIDUAL %in% suministrado$capitulo
n_filas_esperadas <- N_CAPITULOS_ESPERADOS + as.integer(tiene_residual)
filas_capitulo <- suministrado$capitulo != CAPITULO_RESIDUAL

stopifnot(
  "El insumo debe tener 21 capitulos (+ el residual 'Otros' si existe)" =
    nrow(suministrado) == n_filas_esperadas,
  "El insumo no debe tener NA en las filas de capitulo" =
    !anyNA(suministrado[filas_capitulo, ..req_cols]),
  "Los conteos de la fila residual deben estar informados" =
    !anyNA(suministrado[!filas_capitulo,
                        c("egresos_PO", "egresos_NoPO", "def_obs_PO"),
                        with = FALSE]),
  "Los capitulos deben ser unicos" =
    !anyDuplicated(suministrado$capitulo),
  "A lo sumo una fila residual 'Otros'" =
    sum(suministrado$capitulo == CAPITULO_RESIDUAL) == as.integer(tiene_residual),
  "egresos_PO + egresos_NoPO debe sumar 20.957.004" =
    sum(suministrado$egresos_PO) + sum(suministrado$egresos_NoPO) == N_TOTAL_ESPERADO
)

# --- Exclusion de la fila residual (va a la nota al pie, no a la tabla) -------
# Los conteos del residual se conservan solo para el control de suma total.
egresos_residual <- if (tiene_residual) {
  sum(suministrado$egresos_PO[!filas_capitulo]) +
    sum(suministrado$egresos_NoPO[!filas_capitulo])
} else {
  0L
}

stopifnot(
  "La fila residual debe sumar exactamente 1 egreso" =
    egresos_residual == as.integer(tiene_residual) * N_RESIDUAL_ESPERADO
)

tabla_fuente <- suministrado[filas_capitulo]

# --- Proyección con el contrato de salida de la Tabla 8 -----------------------
tabla8 <- data.table::data.table(
  capitulo = tabla_fuente$capitulo,
  egresos_PO = as.integer(tabla_fuente$egresos_PO),
  defunciones_obs_PO = as.integer(tabla_fuente$def_obs_PO),
  defunciones_esp_PO = fmt(tabla_fuente$def_esp_PO, DIGITOS_ESPERADOS),
  TLI_cruda_PO_por1000 = fmt(tabla_fuente$TLI_cruda_PO_pct * 10, DIGITOS_TASA),
  TLI_ajustada_PO_por1000 = fmt(tabla_fuente$TLI_ajustada_PO_pct * 10, DIGITOS_TASA),
  TLI_cruda_NoPO_por1000 = fmt(tabla_fuente$TLI_cruda_NoPO_pct * 10, DIGITOS_TASA),
  razon_cruda = fmt(tabla_fuente$razon_cruda, DIGITOS_RAZON),
  razon_ajustada = fmt(tabla_fuente$razon_ajustada, DIGITOS_RAZON)
)

# --- Orden: alfabético determinista (radix), 21 capítulos ---------------------
tabla8 <- tabla8[match(sort(tabla8$capitulo, method = "radix"), tabla8$capitulo)]

# --- Validaciones de la tabla formateada --------------------------------------
stopifnot(
  "La tabla final debe tener 21 capitulos (sin la fila residual)" =
    nrow(tabla8) == N_CAPITULOS_ESPERADOS,
  "La tabla final no debe contener la fila residual 'Otros'" =
    !CAPITULO_RESIDUAL %in% tabla8$capitulo,
  "La tabla final no debe tener NA" = !anyNA(tabla8),
  "Los capitulos de salida deben ser unicos" = !anyDuplicated(tabla8$capitulo),
  "Los egresos PO deben conservar el total" =
    sum(tabla8$egresos_PO) == sum(tabla_fuente$egresos_PO),
  "egresos_PO + egresos_NoPO (+ residual) debe sumar 20.957.004" =
    sum(tabla8$egresos_PO) + sum(tabla_fuente$egresos_NoPO) +
      egresos_residual == N_TOTAL_ESPERADO
)

# --- Nota al pie (texto aparte: no se publica como fila de la tabla) ----------
# Las tildes van escapadas para mantener el fuente ASCII y el .txt en UTF-8.
nota_pie <- c(
  paste0(
    "Nota: un egreso (1 de 20.957.004) no registra c\u00f3digo de " ,
    "diagn\u00f3stico principal y no se incluye en la tabla."
  ),
  paste0(
    "El cap\u00edtulo XX (Causas externas de morbilidad y mortalidad, " ,
    "c\u00f3digos V-W-X-Y) no registra egresos en la base analizada; los " ,
    "traumatismos y envenenamientos (c\u00f3digos S y T) se presentan en " ,
    "el cap\u00edtulo XIX."
  )
)

# --- Escritura (back up del anterior + UTF-8) ---------------------------------
# Back up no destructivo: preserva el artefacto original, no lo sobreescribe en
# corridas sucesivas.
if (!dir.exists(OUT_DIR)) dir.create(OUT_DIR, recursive = TRUE)
BACKUP_CSV <- paste0(OUT_CSV, ".bak")
if (file.exists(OUT_CSV) && !file.exists(BACKUP_CSV)) {
  file.copy(OUT_CSV, BACKUP_CSV, overwrite = FALSE)
  cat("Back up del CSV anterior en:", BACKUP_CSV, "\n")
}
data.table::fwrite(tabla8, OUT_CSV, bom = TRUE, quote = "auto")

con_nota <- file(OUT_NOTA, open = "w", encoding = "UTF-8")
writeLines(nota_pie, con_nota, useBytes = FALSE)
close(con_nota)

cat("\nTabla 8 escrita en:", OUT_CSV, "\n")
cat("Nota al pie escrita en:", OUT_NOTA, "\n")
cat("Filas:", nrow(tabla8), "| Columnas:", ncol(tabla8), "\n")
cat("Validaciones: 21 filas (sin 'Otros'), sin NA, capitulos unicos, suma egresos",
    "(+ residual excluido) =",
    format(sum(tabla8$egresos_PO) + sum(tabla_fuente$egresos_NoPO) +
             egresos_residual, big.mark = ".", decimal.mark = ","), "\n\n")
print(tabla8, nrows = 100L)
