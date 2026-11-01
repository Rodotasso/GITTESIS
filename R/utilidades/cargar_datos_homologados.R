# ==============================================================================
# FUNCION: cargar_datos_homologados
# ==============================================================================
#
# DESCRIPCION:
#   Carga en memoria la base homologada de egresos hospitalarios y aplica, en
#   tiempo de analisis, la clasificacion CIE-10 corregida (capitulos 1 a 22).
#
#   Es la capa de carga unica del proyecto (DRY): reemplaza el par
#       load(file.path(project_root, "BBDD_homologados.RData"))
#       datos <- datos_homologados
#   por una sola llamada. NO modifica ni reescribe la base en disco: la columna
#   persistida Grupo_CIE10 es el dato entregado y se conserva intacta en el
#   .RData; la correccion existe solo en el objeto devuelto.
#
# MOTIVO DE LA CORRECCION:
#   La clasificacion persistida proviene del regex heredado clasificar_grupo(),
#   cuyos patrones ^H0|^H1 y ^H6|^H7 dejan fuera H20-H59 (ojo) y H80-H95
#   (oido), y que no contempla el codigo U (capitulo 22): todos esos egresos
#   caen en "Otros". Ver R/utilidades/clasificar_grupo.R (lineas 70-71, 85).
#   La derivacion corregida la resuelve asignar_capitulo_cie10() contra el
#   catalogo oficial de ciecl (ver R/utilidades/clasificar_capitulo_cie10.R).
#
# PARAMETROS:
#   @param ruta                character(1) o NULL. Ruta al .RData. NULL (default)
#                              resuelve la raiz del proyecto (project_root si
#                              existe en el llamador; si no, rprojroot) y apunta
#                              a BBDD_homologados.RData.
#   @param actualizar_capitulos logical(1). TRUE (default) sobrescribe EN MEMORIA
#                              Grupo_CIE10 y agrega CAPITULO_CIE10 y
#                              CAPITULO_CIE10_FUENTE. FALSE devuelve la base tal
#                              como esta en disco (comportamiento del load()).
#
# RETORNA:
#   El objeto datos_homologados (data.table; 20.957.004 x 29 en la version
#   vigente) con tres columnas adicionales o reemplazadas en memoria:
#     Grupo_CIE10           reescrita con la etiqueta del proyecto (title case,
#                           sin rango de codigos), identica para los 22
#                           capitulos. Es la columna que consumen figuras y
#                           tablas: el texto NO cambia de estilo, solo cambian
#                           los conteos de los capitulos mal clasificados.
#     CAPITULO_CIE10        integer 1-22 derivado de DIAG1. NA en el unico
#                           egreso sin codigo (DIAG1 vacio), que queda con la
#                           etiqueta residual "Otros".
#     CAPITULO_CIE10_FUENTE character: "ciecl" (catalogo oficial),
#                           "fallback" (regex heredado, red de seguridad) o
#                           "sin_clasificar".
#
# ETIQUETAS (por que un mapeo explicito):
#   ciecl devuelve los nombres en MAYUSCULAS y con el rango de codigos, p. ej.
#   "Cap.07  ENFERMEDADES DEL OJO Y SUS ANEXOS (H00-H59)". Las figuras y tablas
#   del proyecto usan title case sin rango. Por eso el mapeo capitulo -> etiqueta
#   se escribe a mano (.etiquetas_capitulo_cie10) y se VALIDA en cada llamada
#   contra las etiquetas de la base: toda etiqueta persistida (salvo la residual
#   "Otros") debe existir caracter a caracter en el mapeo; si no, aborta en vez
#   de cambiar el rotulado de las figuras.
#
# DEPENDENCIAS:
#   - asignar_capitulo_cie10() de R/utilidades/clasificar_capitulo_cie10.R, que
#     este loader presupone cargada (R/cargar_funciones.R la sourcea antes).
#   - data.table (solo para asignar columnas por referencia; si no esta
#     disponible o la base no es data.table, se usa asignacion base).
#   - rprojroot (solo cuando ruta = NULL y no hay project_root en el llamador).
#
# NOTAS:
#   - Memoria: la base (~0,9 GB comprimida) mas la tabla de clasificacion
#     (~0,6 GB durante la derivacion). La base NO se duplica: se carga en un
#     entorno aislado y se devuelve la misma referencia.
#   - Determinista: el orden de filas no se toca; la derivacion es por codigo
#     unico (asignar_capitulo_cie10), no por fila.
#   - No escribe archivos ni toca el .RData en ningun caso.
#   - Errores con clase de condicion propia (cargar_datos_homologados_*),
#     capturables con tryCatch().
#
# EJEMPLO:
#   source(file.path(project_root, "R/cargar_funciones.R"))
#   datos_homologados <- cargar_datos_homologados()
#   datos_homologados[, .N, by = .(Grupo_CIE10, CAPITULO_CIE10)]
#
# ==============================================================================

# Nombre del objeto persistido en el .RData
.objeto_base_homologada <- "datos_homologados"

# Etiqueta del unico egreso que no admite capitulo (DIAG1 vacio)
.etiqueta_residual_cie10 <- "Otros"

# ------------------------------------------------------------------------------
# INTERNO: aborta con clase de condicion propia
# ------------------------------------------------------------------------------
.abortar_carga <- function(message, class) {
  cond <- structure(
    class = c(class, "cargar_datos_homologados_error", "error", "condition"),
    list(message = message, call = NULL)
  )
  stop(cond)
}

# ------------------------------------------------------------------------------
# INTERNO: mapeo explicito capitulo (1-22) -> etiqueta del proyecto
#
# Las 20 etiquetas de los capitulos presentes en la base se copiaron VERBATIM
# de unique(datos_homologados$Grupo_CIE10) (title case, con tildes, sin rango de
# codigos). Las dos restantes se escribieron a mano con el mismo estilo:
#   - capitulo 20: la base no tiene codigos V/W/X/Y (0 egresos); el texto se
#     toma verbatim del regex heredado clasificar_grupo() para no inventar uno.
#   - capitulo 22: no existe en la clasificacion persistida (codigos U); el
#     nombre se toma del catalogo oficial de ciecl (cie10_cl$capitulo_nombre,
#     "CODIGOS PARA SITUACIONES ESPECIALES (U00-U99)"), en title case y sin
#     rango de codigos para respetar el estilo del resto de las etiquetas.
# La coherencia de las 20 persistidas se verifica en cada llamada
# (.verificar_etiquetas_persistidas), no se confia en la copia manual.
# ------------------------------------------------------------------------------
.etiquetas_capitulo_cie10 <- function() {
  c(
    "1"  = "Enfermedades infecciosas y parasitarias",
    "2"  = "Neoplasias",
    "3"  = "Enfermedades de la sangre y órganos hematopoyéticos",
    "4"  = "Trastornos endocrinos, nutricionales y metabólicos",
    "5"  = "Trastornos mentales y del comportamiento",
    "6"  = "Enfermedades del sistema nervioso",
    "7"  = "Enfermedades del ojo y sus anexos",
    "8"  = "Enfermedades del oído y mastoides",
    "9"  = "Enfermedades del sistema circulatorio",
    "10" = "Enfermedades del sistema respiratorio",
    "11" = "Enfermedades del sistema digestivo",
    "12" = "Enfermedades de la piel y tejido subcutáneo",
    "13" = "Enfermedades del sistema musculoesquelético",
    "14" = "Enfermedades del sistema genitourinario",
    "15" = "Embarazo, parto y puerperio",
    "16" = "Ciertas afecciones originadas en el período perinatal",
    "17" = "Malformaciones congénitas, deformidades y anomalías cromosómicas",
    "18" = "Síntomas, signos y hallazgos clínicos anormales",
    "19" = "Traumatismos, envenenamientos y otras consecuencias de causas externas",
    "20" = "Causas externas de morbilidad y mortalidad",
    "21" = "Factores que influyen en el estado de salud",
    "22" = "Códigos para situaciones especiales"
  )
}

# ------------------------------------------------------------------------------
# INTERNO: etiquetas del mapeo para un vector de capitulos (NA -> residual)
# ------------------------------------------------------------------------------
.etiqueta_desde_capitulo <- function(capitulo) {
  etiquetas <- .etiquetas_capitulo_cie10()
  salida <- unname(etiquetas[as.character(capitulo)])
  salida[is.na(salida)] <- .etiqueta_residual_cie10
  salida
}

# ------------------------------------------------------------------------------
# INTERNO: verifica que las etiquetas persistidas existan en el mapeo
# Evita que un cambio de rotulado pase inadvertido a las figuras.
# ------------------------------------------------------------------------------
.verificar_etiquetas_persistidas <- function(persistidas) {
  distintas <- unique(as.character(persistidas))
  distintas <- distintas[!is.na(distintas)]
  distintas <- distintas[distintas != .etiqueta_residual_cie10]

  desconocidas <- setdiff(distintas, unname(.etiquetas_capitulo_cie10()))
  if (length(desconocidas) > 0L) {
    .abortar_carga(
      paste0(
        "Etiquetas de Grupo_CIE10 ajenas al mapeo capitulo -> etiqueta: ",
        paste(desconocidas, collapse = " | "),
        ". Revise .etiquetas_capitulo_cie10() en ",
        "R/utilidades/cargar_datos_homologados.R."
      ),
      "cargar_datos_homologados_etiquetas_inconsistentes"
    )
  }
  invisible(TRUE)
}

# ------------------------------------------------------------------------------
# INTERNO: resuelve la ruta al .RData (project_root del llamador, luego rprojroot)
# ------------------------------------------------------------------------------
.ruta_base_homologada <- function(nombre_archivo = "BBDD_homologados.RData") {
  raiz <- if (exists("project_root", envir = parent.frame(), inherits = TRUE)) {
    get("project_root", envir = parent.frame(), inherits = TRUE)
  } else {
    tryCatch(
      rprojroot::find_root(rprojroot::has_file(nombre_archivo)),
      error = function(e) NULL
    )
  }

  candidatas <- c(
    if (is.character(raiz) && length(raiz) == 1L) file.path(raiz, nombre_archivo),
    file.path(getwd(), nombre_archivo)
  )
  encontrada <- candidatas[file.exists(candidatas)]

  if (length(encontrada) == 0L) {
    .abortar_carga(
      paste0(
        "No se encontro '", nombre_archivo, "'. Buscado en: ",
        paste(candidatas, collapse = " | "),
        ". Indique la ruta con el argumento 'ruta'."
      ),
      "cargar_datos_homologados_ruta_no_encontrada"
    )
  }
  encontrada[[1L]]
}

# ------------------------------------------------------------------------------
# INTERNO: asigna columnas por referencia si es data.table, o por copia si no
# ------------------------------------------------------------------------------
.asignar_columnas_base <- function(datos, columnas) {
  es_data_table <- requireNamespace("data.table", quietly = TRUE) &&
    data.table::is.data.table(datos)

  for (nombre in names(columnas)) {
    if (es_data_table) {
      data.table::set(datos, j = nombre, value = columnas[[nombre]])
    } else {
      datos[[nombre]] <- columnas[[nombre]]
    }
  }
  datos
}

# ==============================================================================
# FUNCION PUBLICA
# ==============================================================================
cargar_datos_homologados <- function(ruta = NULL, actualizar_capitulos = TRUE) {
  # ---- Validacion de inputs en el borde publico -----------------------------
  if (!is.null(ruta)) {
    if (!is.character(ruta) || length(ruta) != 1L || is.na(ruta) || !nzchar(ruta)) {
      .abortar_carga(
        "'ruta' debe ser NULL o un character(1) no vacio.",
        "cargar_datos_homologados_input_error"
      )
    }
    if (!file.exists(ruta)) {
      .abortar_carga(
        paste0("No existe el archivo indicado en 'ruta': ", ruta),
        "cargar_datos_homologados_ruta_no_encontrada"
      )
    }
  }
  if (!is.logical(actualizar_capitulos) || length(actualizar_capitulos) != 1L ||
      is.na(actualizar_capitulos)) {
    .abortar_carga(
      "'actualizar_capitulos' debe ser TRUE o FALSE.",
      "cargar_datos_homologados_input_error"
    )
  }

  if (is.null(ruta)) {
    ruta <- .ruta_base_homologada()
  }

  # ---- Carga aislada: el .RData no contamina el entorno del llamador --------
  entorno <- new.env(parent = emptyenv())
  load(ruta, envir = entorno)

  if (!exists(.objeto_base_homologada, envir = entorno, inherits = FALSE)) {
    rm(entorno)
    .abortar_carga(
      paste0(
        "El archivo '", ruta, "' no contiene el objeto '",
        .objeto_base_homologada, "'."
      ),
      "cargar_datos_homologados_objeto_ausente"
    )
  }

  datos <- get(.objeto_base_homologada, envir = entorno)
  rm(entorno)

  if (!is.data.frame(datos)) {
    .abortar_carga(
      paste0("'", .objeto_base_homologada, "' no es un data.frame."),
      "cargar_datos_homologados_objeto_invalido"
    )
  }

  if (!isTRUE(actualizar_capitulos)) {
    return(datos)
  }

  faltantes <- setdiff(c("DIAG1", "Grupo_CIE10"), names(datos))
  if (length(faltantes) > 0L) {
    .abortar_carga(
      paste0(
        "Faltan columnas requeridas en la base: ",
        paste(faltantes, collapse = ", ")
      ),
      "cargar_datos_homologados_columnas_ausentes"
    )
  }

  # ---- Contrato de rotulado: las etiquetas persistidas deben ser las del mapa
  .verificar_etiquetas_persistidas(datos[["Grupo_CIE10"]])

  # ---- Derivacion corregida del capitulo CIE-10 -----------------------------
  clasificacion <- asignar_capitulo_cie10(datos[["DIAG1"]], verbose = FALSE)
  etiquetas <- .etiqueta_desde_capitulo(clasificacion$capitulo)

  datos <- .asignar_columnas_base(datos, list(
    Grupo_CIE10 = etiquetas,
    CAPITULO_CIE10 = as.integer(clasificacion$capitulo),
    CAPITULO_CIE10_FUENTE = as.character(clasificacion$origen)
  ))

  diagnostico <- attr(clasificacion, "diagnostico")
  rm(clasificacion)

  message(sprintf(
    paste0(
      "cargar_datos_homologados(): %s egresos | capitulo derivado con ",
      "ciecl %s: %s | fallback regex: %s | sin clasificar: %s ",
      "(quedan con la etiqueta residual '%s')"
    ),
    format(nrow(datos), big.mark = ","),
    diagnostico$ciecl_version,
    format(diagnostico$n_ciecl, big.mark = ","),
    format(diagnostico$n_fallback, big.mark = ","),
    format(diagnostico$n_sin_clasificar, big.mark = ","),
    .etiqueta_residual_cie10
  ))

  datos
}
