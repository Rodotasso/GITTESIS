#' Ordenar regiones geográficamente (Norte a Sur)
#'
#' Ordena un dataframe por región de Chile de norte a sur.
#' Funciona con códigos numéricos (1-16, 15) o nombres de regiones.
#'
#' @param data Data frame con columna de región
#' @param col_region Nombre de la columna que contiene la región (default: "region")
#' @param tipo Tipo de valor en la columna: "codigo" o "nombre" (default: "codigo")
#'
#' @return Data frame ordenado de norte a sur
#'
#' @examples
#' datos <- data.frame(region = c(13, 1, 8, 15), valor = c(10, 20, 30, 40))
#' ordenar_regiones_geografico(datos, "region", "codigo")
#'
#' @export
ordenar_regiones_geografico <- function(data, col_region = "region", tipo = "codigo") {


  # Orden geográfico norte a sur (códigos)
  orden_codigos <- c(15, 1, 2, 3, 4, 5, 13, 6, 7, 16, 8, 9, 14, 10, 11, 12)

  # Nombres de regiones en orden geográfico norte a sur
  orden_nombres <- c(
    "Arica y Parinacota",
    "Tarapaca",
    "Tarapacá",
    "Antofagasta",
    "Atacama",
    "Coquimbo",
    "Valparaiso",
    "Valparaíso",
    "Metropolitana",
    "Metropolitana de Santiago",
    "Region Metropolitana",
    "Región Metropolitana",
    "O'Higgins",
    "Libertador General Bernardo O'Higgins",
    "Maule",
    "Nuble",
    "Ñuble",
    "Biobio",
    "Biobío",
    "Bio-Bio",
    "La Araucania",
    "La Araucanía",
    "Araucania",
    "Araucanía",
    "Los Rios",
    "Los Ríos",
    "Los Lagos",
    "Aysen",
    "Aysén",
    "Aysen del General Carlos Ibanez del Campo",
    "Aysén del General Carlos Ibáñez del Campo",
    "Magallanes",
    "Magallanes y de la Antartica Chilena",
    "Magallanes y de la Antártica Chilena"
  )

  if (tipo == "codigo") {
    # Crear factor ordenado por códigos
    data[[col_region]] <- factor(data[[col_region]], levels = orden_codigos, ordered = TRUE)
  } else if (tipo == "nombre") {
    # Normalizar nombres y ordenar
    data <- data %>%
      dplyr::mutate(
        .orden_region = dplyr::case_when(
          stringr::str_detect(.data[[col_region]], stringr::regex("arica|parinacota", ignore_case = TRUE)) ~ 1,
          stringr::str_detect(.data[[col_region]], stringr::regex("tarapac", ignore_case = TRUE)) ~ 2,
          stringr::str_detect(.data[[col_region]], stringr::regex("antofagasta", ignore_case = TRUE)) ~ 3,
          stringr::str_detect(.data[[col_region]], stringr::regex("atacama", ignore_case = TRUE)) ~ 4,
          stringr::str_detect(.data[[col_region]], stringr::regex("coquimbo", ignore_case = TRUE)) ~ 5,
          stringr::str_detect(.data[[col_region]], stringr::regex("valpara", ignore_case = TRUE)) ~ 6,
          stringr::str_detect(.data[[col_region]], stringr::regex("metropolit", ignore_case = TRUE)) ~ 7,
          stringr::str_detect(.data[[col_region]], stringr::regex("higgins", ignore_case = TRUE)) ~ 8,
          stringr::str_detect(.data[[col_region]], stringr::regex("maule", ignore_case = TRUE)) ~ 9,
          stringr::str_detect(.data[[col_region]], stringr::regex("uble|ñuble", ignore_case = TRUE)) ~ 10,
          stringr::str_detect(.data[[col_region]], stringr::regex("bio.?bio|biobio", ignore_case = TRUE)) ~ 11,
          stringr::str_detect(.data[[col_region]], stringr::regex("araucan", ignore_case = TRUE)) ~ 12,
          stringr::str_detect(.data[[col_region]], stringr::regex("los r", ignore_case = TRUE)) ~ 13,
          stringr::str_detect(.data[[col_region]], stringr::regex("los lagos", ignore_case = TRUE)) ~ 14,
          stringr::str_detect(.data[[col_region]], stringr::regex("ays", ignore_case = TRUE)) ~ 15,
          stringr::str_detect(.data[[col_region]], stringr::regex("magallanes", ignore_case = TRUE)) ~ 16,
          TRUE ~ 99
        )
      )
  }

  # Ordenar
  data <- data %>%
    dplyr::arrange(!!rlang::sym(col_region))

  # Remover columna auxiliar si existe
  if (".orden_region" %in% names(data)) {
    data <- data %>%
      dplyr::arrange(.orden_region) %>%
      dplyr::select(-.orden_region)
  }

  return(data)
}


#' Obtener tabla de referencia de regiones
#'
#' Devuelve un tibble con códigos, nombres cortos y nombres largos
#' de las regiones de Chile, ordenados de norte a sur.
#'
#' @return tibble con columnas: codigo, nombre_corto, nombre_largo, orden
#'
#' @examples
#' regiones <- obtener_tabla_regiones()
#'
#' @export
obtener_tabla_regiones <- function() {
  tibble::tibble(
    orden = 1:16,
    codigo = c(15, 1, 2, 3, 4, 5, 13, 6, 7, 16, 8, 9, 14, 10, 11, 12),
    nombre_corto = c(
      "Arica y Parinacota",
      "Tarapacá",
      "Antofagasta",
      "Atacama",
      "Coquimbo",
      "Valparaíso",
      "Metropolitana",
      "O'Higgins",
      "Maule",
      "Ñuble",
      "Biobío",
      "La Araucanía",
      "Los Ríos",
      "Los Lagos",
      "Aysén",
      "Magallanes"
    ),
    nombre_largo = c(
      "Arica y Parinacota",
      "Tarapacá",
      "Antofagasta",
      "Atacama",
      "Coquimbo",
      "Valparaíso",
      "Región Metropolitana de Santiago",
      "Libertador General Bernardo O'Higgins",
      "Maule",
      "Ñuble",
      "Biobío",
      "La Araucanía",
      "Los Ríos",
      "Los Lagos",
      "Aysén del General Carlos Ibáñez del Campo",
      "Magallanes y de la Antártica Chilena"
    )
  )
}


#' Convertir código de región a nombre
#'
#' @param codigo Vector de códigos de región (1-16, 15 para Arica)
#' @param tipo "corto" o "largo" (default: "corto")
#'
#' @return Vector de nombres de regiones
#'
#' @examples
#' codigo_a_nombre_region(c(15, 1, 13))
#'
#' @export
codigo_a_nombre_region <- function(codigo, tipo = "corto") {
  tabla <- obtener_tabla_regiones()

  if (tipo == "corto") {
    nombres <- tabla$nombre_corto[match(codigo, tabla$codigo)]
  } else {
    nombres <- tabla$nombre_largo[match(codigo, tabla$codigo)]
  }

  return(nombres)
}


#' Crear factor de región ordenado geográficamente
#'
#' @param regiones Vector de regiones (códigos o nombres)
#' @param tipo "codigo" o "nombre"
#'
#' @return Factor ordenado de norte a sur
#'
#' @examples
#' crear_factor_region_ordenado(c(13, 1, 8, 15), "codigo")
#'
#' @export
crear_factor_region_ordenado <- function(regiones, tipo = "codigo") {
  tabla <- obtener_tabla_regiones()

  if (tipo == "codigo") {
    factor(regiones, levels = tabla$codigo, ordered = TRUE)
  } else {
    # Detectar si son nombres cortos o largos
    if (any(regiones %in% tabla$nombre_corto)) {
      factor(regiones, levels = tabla$nombre_corto, ordered = TRUE)
    } else {
      factor(regiones, levels = tabla$nombre_largo, ordered = TRUE)
    }
  }
}
