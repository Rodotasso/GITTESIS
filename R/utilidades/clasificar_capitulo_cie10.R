# ==============================================================================
# FUNCION: asignar_capitulo_cie10
# ==============================================================================
#
# DESCRIPCION:
#   Deriva el capitulo CIE-10 (1 a 22) de un vector de codigos diagnosticos
#   usando el catalogo oficial MINSAL/DEIS v2018 embebido en el paquete ciecl
#   (cie10_cl, 39.877 codigos con capitulo_nombre sin NA).
#
#   Es una capa de derivacion NO destructiva: no escribe la base ni la columna
#   persistida Grupo_CIE10; clasifica en tiempo de analisis a partir de DIAG1.
#
#   Motivo: la clasificacion persistida en Grupo_CIE10 proviene del regex
#   clasificar_grupo(), cuyos patrones ^H0|^H1 y ^H6|^H7 dejan fuera
#   H20-H59 (ojo) y H80-H95 (oido), y que no contempla el codigo U
#   (capitulo 22); todos esos egresos caen en "Otros".
#
# PARAMETROS:
#   @param diag1   Vector character (o factor) de codigos CIE-10, tipicamente
#                  la columna DIAG1 de datos_homologados, en formato DEIS sin
#                  punto ("J189", "I10", "U071", "H259").
#   @param fuente  "ciecl" (default): resuelve con ciecl::cie_lookup() y cae al
#                  regex solo cuando ciecl no resuelve. "regex": clasifica todo
#                  con el regex heredado clasificar_grupo() (no usa ciecl).
#   @param verbose Resumen por consola con los conteos por origen (default TRUE).
#
# RETORNA:
#   data.frame de la MISMA longitud y orden que diag1, con cuatro columnas:
#     capitulo        integer 1-22; NA cuando no fue posible clasificar
#     capitulo_nombre character; nombre oficial del capitulo segun ciecl
#                     (p. ej. "Cap.07  ENFERMEDADES DEL OJO Y SUS ANEXOS
#                     (H00-H59)"). NA cuando origen != "ciecl", porque en esa
#                     ruta no hay nombre canonico disponible
#     seccion         character; seccion ciecl del codigo (p. ej.
#                     "H25-H28  TRASTORNOS DEL CRISTALINO"). NA fuera de ciecl
#     origen          character con tres valores posibles, ver seccion ORIGEN
#   Atributo "diagnostico": lista con n_total, n_codigos_unicos, n_ciecl,
#   n_fallback, n_sin_clasificar, n_codigos_fuera_de_taxonomia, pct_ciecl,
#   pct_fallback, pct_sin_clasificar, fuente y ciecl_version. Se lee con
#   attr(x, "diagnostico").
#
# ORIGEN (columna origen):
#   "ciecl"          el codigo fue resuelto por ciecl y el capitulo se extrajo
#                    de capitulo_nombre ("Cap.NN ...").
#   "fallback"       ciecl no lo resolvio (o el capitulo no fue extraible) y se
#                    aplico el regex heredado clasificar_grupo(); el capitulo
#                    sale de la letra inicial. Reproduce EXACTAMENTE el sesgo
#                    antiguo: es la red de seguridad, no una mejora.
#   "sin_clasificar" diag1 es NA, o el codigo es vacio/invalido y el regex lo
#                    manda a "Otros". Incluye todo codigo U en la ruta fallback,
#                    igual que la clasificacion persistida. Incluye tambien los
#                    codigos que ciecl reconoce pero deja fuera de la
#                    taxonomia de capitulos (morfologias CIE-O "M8000/3",
#                    1.153 en el catalogo, que nunca aparecen en DIAG1).
#
# NORMALIZACION (que y por que):
#   Se replica el preprocesamiento interno de ciecl::cie_lookup()
#   (toupper + eliminacion de espacios + normalizador del paquete con
#   search_db/buscar_db = FALSE) y luego se consulta cie_lookup() con la
#   normalizacion desactivada. Asi la clave de union es el propio codigo
#   normalizado que devuelve ciecl, sin doble normalizacion y sin depender de
#   la version del paquete (0.9.x expone cie_normalizar(buscar_db = );
#   1.0.x expone cie_norm(search_db = )).
#   Es el mismo criterio de union que usa concatenar_diag_ciecl(): ver
#   R/utilidades/concatenar_diag_ciecl.R, lineas 99-108, donde el codigo se
#   reduce a mayusculas sin punto ("H259") antes del left_join; aqui se usa el
#   normalizador del paquete en vez de un gsub() sobre el punto.
#
# DEPENDENCIAS:
#   - ciecl (opcional: solo para fuente = "ciecl"); guardia requireNamespace().
#   - clasificar_grupo() de R/utilidades/clasificar_grupo.R (fallback).
#
# NOTAS:
#   - Solo lee: no modifica diag1, no escribe archivos, no toca la base.
#   - Determinista: unique() + match() preservan el orden de entrada; no se
#     ordena por character en ningun punto (sin dependencia de locale).
#   - Memoria: sobre 20,9 millones de egresos el resultado ronda 0,6 GB
#     (3 columnas character de punteros + 1 integer). En bases grandes conviene
#     asignar por referencia solo la columna necesaria.
#   - Errores con clase de condicion propia (asignar_capitulo_cie10_input_error,
#     asignar_capitulo_cie10_dependencia_faltante) capturables con tryCatch().
#
# EJEMPLO:
#   source("R/cargar_funciones.R")
#   cap <- asignar_capitulo_cie10(datos_homologados$DIAG1)
#   attr(cap, "diagnostico")$pct_fallback
#   datos_homologados[, capitulo_cie10 := cap$capitulo]
#
# ==============================================================================

# Entorno de memoizacion del mapa etiqueta -> capitulo (depende solo del codigo
# de clasificar_grupo(), por lo que es seguro reutilizarlo entre llamadas).
.capitulo_cie10_cache <- new.env(parent = emptyenv())

# ------------------------------------------------------------------------------
# INTERNO: aborta con clase de condicion propia, sin dependencias externas
# ------------------------------------------------------------------------------
.abortar_capitulo <- function(message, class) {
  cond <- structure(
    class = c(class, "asignar_capitulo_cie10_error", "error", "condition"),
    list(message = message, call = NULL)
  )
  stop(cond)
}

# ------------------------------------------------------------------------------
# INTERNO: codigos representativos de cada capitulo para reconstruir el mapa
# etiqueta_regex -> numero de capitulo sin escribir las etiquetas a mano.
# El capitulo 22 (U00-U99) no tiene representante: el regex heredado lo manda a
# "Otros", que es precisamente el defecto diagnosticado.
# ------------------------------------------------------------------------------
.codigos_representativos_capitulo <- function() {
  c(
    "1" = "A00", "2" = "C00", "3" = "D50", "4" = "E00", "5" = "F00",
    "6" = "G00", "7" = "H00", "8" = "H60", "9" = "I00", "10" = "J00",
    "11" = "K00", "12" = "L00", "13" = "M00", "14" = "N00", "15" = "O00",
    "16" = "P00", "17" = "Q00", "18" = "R00", "19" = "S00", "20" = "V00",
    "21" = "Z00"
  )
}

# ------------------------------------------------------------------------------
# INTERNO: mapa etiqueta de clasificar_grupo() -> capitulo (integer), memoizado
# ------------------------------------------------------------------------------
.mapa_etiqueta_capitulo <- function() {
  if (!is.null(.capitulo_cie10_cache$mapa)) {
    return(.capitulo_cie10_cache$mapa)
  }

  if (!exists("clasificar_grupo", mode = "function")) {
    .abortar_capitulo(
      "Falta la funcion 'clasificar_grupo()'; cargue R/utilidades/clasificar_grupo.R.",
      "asignar_capitulo_cie10_dependencia_faltante"
    )
  }

  representativos <- .codigos_representativos_capitulo()
  etiquetas <- vapply(
    representativos, clasificar_grupo, character(1),
    USE.NAMES = FALSE
  )
  numeros <- as.integer(names(representativos))

  # Ante etiquetas repetidas se conserva el primer capitulo (orden fijo de
  # representativos): resultado estable entre llamadas.
  sin_duplicados <- !duplicated(etiquetas)
  mapa <- stats::setNames(numeros[sin_duplicados], etiquetas[sin_duplicados])

  .capitulo_cie10_cache$mapa <- mapa
  mapa
}

# ------------------------------------------------------------------------------
# INTERNO: clasifica con el regex heredado y traduce la etiqueta a capitulo
# ------------------------------------------------------------------------------
.clasificar_grupo_vec <- function(codigos) {
  if (!exists("clasificar_grupo", mode = "function")) {
    .abortar_capitulo(
      "Falta la funcion 'clasificar_grupo()'; cargue R/utilidades/clasificar_grupo.R.",
      "asignar_capitulo_cie10_dependencia_faltante"
    )
  }
  vapply(codigos, clasificar_grupo, character(1), USE.NAMES = FALSE)
}

# ------------------------------------------------------------------------------
# INTERNO: extrae el numero de capitulo desde capitulo_nombre ("Cap.07  ...")
# ------------------------------------------------------------------------------
.capitulo_desde_nombre <- function(nombres) {
  sin_cap <- !grepl("^Cap\\.[0-9]{2}", nombres)
  capitulo <- suppressWarnings(
    as.integer(sub("^Cap\\.([0-9]{2}).*$", "\\1", nombres))
  )
  capitulo[sin_cap] <- NA_integer_
  capitulo[!is.na(capitulo) & (capitulo < 1L | capitulo > 22L)] <- NA_integer_
  capitulo
}

# ------------------------------------------------------------------------------
# INTERNO: normaliza igual que ciecl::cie_lookup() antes de buscar
# Compatibilidad 0.9.x (cie_normalizar/buscar_db) y 1.0.x (cie_norm/search_db)
# ------------------------------------------------------------------------------
.normalizar_codigo_ciecl <- function(codigos) {
  entrada <- gsub("\\s+", "", toupper(trimws(codigos)))
  ns <- asNamespace("ciecl")

  if (exists("cie_norm", envir = ns, inherits = FALSE)) {
    return(suppressWarnings(ciecl::cie_norm(entrada, search_db = FALSE)))
  }
  if (exists("cie_normalizar", envir = ns, inherits = FALSE)) {
    return(suppressWarnings(
      ciecl::cie_normalizar(entrada, buscar_db = FALSE)
    ))
  }
  if (exists("cie_normalize", envir = ns, inherits = FALSE)) {
    return(suppressWarnings(
      ciecl::cie_normalize(entrada, search_db = FALSE)
    ))
  }

  .abortar_capitulo(
    paste0(
      "La version instalada de 'ciecl' no expone un normalizador ",
      "compatible (cie_norm/cie_normalizar/cie_normalize)."
    ),
    "asignar_capitulo_cie10_dependencia_faltante"
  )
}

# ------------------------------------------------------------------------------
# INTERNO: consulta cie_lookup() sobre codigos YA normalizados (sin renombrar
# argumentos entre versiones) y devuelve solo las tres columnas necesarias.
# Se procesa por lotes para no acercarse al limite de parametros de SQLite.
# ------------------------------------------------------------------------------
.buscar_codigos_ciecl <- function(codigos_norm, lote = 20000L) {
  argumentos <- names(formals(ciecl::cie_lookup))
  arg_codigo <- if ("code" %in% argumentos) "code" else "codigo"
  arg_normalizar <- if ("normalize" %in% argumentos) "normalize" else "normalizar"

  lotes <- split(
    codigos_norm,
    ceiling(seq_along(codigos_norm) / lote)
  )

  partes <- lapply(lotes, function(bloque) {
    llamada <- list(bloque, FALSE)
    names(llamada) <- c(arg_codigo, arg_normalizar)
    tabla <- suppressMessages(do.call(ciecl::cie_lookup, llamada))

    faltantes <- setdiff(c("codigo", "capitulo_nombre", "seccion"), names(tabla))
    if (length(faltantes) > 0) {
      .abortar_capitulo(
        paste0(
          "ciecl::cie_lookup() no devolvio las columnas esperadas: ",
          paste(faltantes, collapse = ", ")
        ),
        "asignar_capitulo_cie10_dependencia_faltante"
      )
    }

    as.data.frame(tabla[, c("codigo", "capitulo_nombre", "seccion")])
  })

  do.call(rbind, partes)
}

# ==============================================================================
# FUNCION PUBLICA
# ==============================================================================
asignar_capitulo_cie10 <- function(diag1,
                                   fuente = c("ciecl", "regex"),
                                   verbose = TRUE) {
  fuente <- match.arg(fuente)

  if (is.factor(diag1)) {
    diag1 <- as.character(diag1)
  }
  if (!is.character(diag1)) {
    .abortar_capitulo(
      "'diag1' debe ser un vector character (o factor) con codigos CIE-10.",
      "asignar_capitulo_cie10_input_error"
    )
  }

  usar_ciecl <- identical(fuente, "ciecl")
  if (usar_ciecl && !requireNamespace("ciecl", quietly = TRUE)) {
    .abortar_capitulo(
      paste0(
        "Falta el paquete 'ciecl' (install.packages('ciecl')). ",
        "Use fuente = 'regex' para la clasificacion heredada."
      ),
      "asignar_capitulo_cie10_dependencia_faltante"
    )
  }

  n_total <- length(diag1)
  # Clasificar una sola vez por codigo distinto y expandir con match(): el
  # costo depende del numero de codigos unicos, no del numero de egresos.
  codigos <- unique(diag1[!is.na(diag1)])
  n_codigos <- length(codigos)

  capitulo <- rep(NA_integer_, n_codigos)
  nombre <- rep(NA_character_, n_codigos)
  seccion <- rep(NA_character_, n_codigos)
  origen <- rep("sin_clasificar", n_codigos)
  # ciecl reconocio el codigo pero su capitulo_nombre no es "Cap.NN ...":
  # son los 1.153 codigos de morfologia CIE-O ("M8000/3", con barra), que no
  # pertenecen a ningun capitulo CIE-10. No se mandan al regex: ciecl ya dijo
  # que estan fuera de la taxonomia de capitulos, quedan sin_clasificar.
  fuera_de_taxonomia <- rep(FALSE, n_codigos)

  # ---- Ruta 1: catalogo oficial (ciecl) --------------------------------------
  if (usar_ciecl && n_codigos > 0L) {
    normalizados <- .normalizar_codigo_ciecl(codigos)
    tabla <- .buscar_codigos_ciecl(normalizados)

    indice <- match(normalizados, tabla$codigo)
    resuelto <- !is.na(indice)

    if (any(resuelto)) {
      filas <- indice[resuelto]
      cap_ciecl <- .capitulo_desde_nombre(tabla$capitulo_nombre[filas])
      valido <- !is.na(cap_ciecl)
      fuera_de_taxonomia[which(resuelto)[!valido]] <- TRUE

      if (any(valido)) {
        posicion <- which(resuelto)[valido]
        capitulo[posicion] <- cap_ciecl[valido]
        nombre[posicion] <- tabla$capitulo_nombre[filas[valido]]
        seccion[posicion] <- tabla$seccion[filas[valido]]
        origen[posicion] <- "ciecl"
      }
    }
  }

  # ---- Ruta 2: fallback al regex heredado ------------------------------------
  pendientes <- which(is.na(capitulo) & !fuera_de_taxonomia)
  if (length(pendientes) > 0L) {
    etiquetas <- .clasificar_grupo_vec(codigos[pendientes])
    cap_regex <- unname(.mapa_etiqueta_capitulo()[etiquetas])
    con_capitulo <- !is.na(cap_regex)

    if (any(con_capitulo)) {
      posicion <- pendientes[con_capitulo]
      capitulo[posicion] <- cap_regex[con_capitulo]
      origen[posicion] <- "fallback"
    }
  }

  # ---- Expansion al largo original (mismo orden, NAs preservados) -----------
  fila_de_codigo <- match(diag1, codigos)
  resultado <- data.frame(
    capitulo = capitulo[fila_de_codigo],
    capitulo_nombre = nombre[fila_de_codigo],
    seccion = seccion[fila_de_codigo],
    origen = origen[fila_de_codigo],
    stringsAsFactors = FALSE
  )
  resultado$origen[is.na(resultado$origen)] <- "sin_clasificar"

  # ---- Conteo por origen (insumo del reporte de fallback) --------------------
  conteo <- table(resultado$origen)
  n_de <- function(etiqueta) {
    if (etiqueta %in% names(conteo)) as.integer(conteo[[etiqueta]]) else 0L
  }
  n_ciecl <- n_de("ciecl")
  n_fallback <- n_de("fallback")
  n_sin_clasificar <- n_de("sin_clasificar")
  n_codigos_fuera_de_taxonomia <- sum(fuera_de_taxonomia)
  denominador <- if (n_total > 0L) n_total else 1L

  diagnostico <- list(
    fuente = fuente,
    n_total = n_total,
    n_codigos_unicos = n_codigos,
    n_ciecl = n_ciecl,
    n_fallback = n_fallback,
    n_sin_clasificar = n_sin_clasificar,
    n_codigos_fuera_de_taxonomia = n_codigos_fuera_de_taxonomia,
    pct_ciecl = 100 * n_ciecl / denominador,
    pct_fallback = 100 * n_fallback / denominador,
    pct_sin_clasificar = 100 * n_sin_clasificar / denominador,
    ciecl_version = if (usar_ciecl) {
      as.character(utils::packageVersion("ciecl"))
    } else {
      NA_character_
    }
  )
  attr(resultado, "diagnostico") <- diagnostico

  if (isTRUE(verbose)) {
    message(sprintf(
      paste0(
        "asignar_capitulo_cie10(): %s egresos | ciecl: %s | ",
        "fallback regex: %s (%.4f%%) | sin clasificar: %s (%.4f%%)"
      ),
      format(diagnostico$n_total, big.mark = ","),
      format(n_ciecl, big.mark = ","),
      format(n_fallback, big.mark = ","),
      diagnostico$pct_fallback,
      format(n_sin_clasificar, big.mark = ","),
      diagnostico$pct_sin_clasificar
    ))
  }

  resultado
}
