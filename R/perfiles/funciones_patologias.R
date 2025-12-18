# ═══════════════════════════════════════════════════════════════════════════
# FUNCIONES PARA PERFILES DE PATOLOGÍAS ESPECÍFICAS
# ═══════════════════════════════════════════════════════════════════════════
# Descripción: Funciones para crear perfiles epidemiológicos de patologías
#              específicas usando el paquete ciecl
# Autor: Rodolfo Tasso
# Fecha: 2025-12-14
# ═══════════════════════════════════════════════════════════════════════════

#' Crear perfil epidemiológico de una patología específica
#'
#' @description
#' Crea un perfil epidemiológico completo para una patología específica,
#' comparando Pueblos Originarios vs Población General.
#'
#' @param datos Data frame con los datos de egresos hospitalarios (debe incluir
#'        DIAG1, PERTENENCIA2, DIAG_COMPLETO)
#' @param codigos_base Vector de códigos CIE-10 base (ej: c("J44", "J45"))
#' @param nombre_patologia Nombre descriptivo de la patología
#' @param pob_po Población Pueblos Originarios (denominador)
#' @param pob_pg Población General (denominador)
#' @param anos_estudio Número de años del período de estudio
#' @param total_egresos_po Total de egresos PO (para calcular porcentajes)
#' @param total_egresos_pg Total de egresos PG (para calcular porcentajes)
#' @param expandir Lógico. Si TRUE, expande los códigos a subcategorías usando ciecl
#' @param top_n Número de diagnósticos top a mostrar. Si 0, no muestra top
#' @param verbose Lógico. Si TRUE, imprime resultados en consola
#'
#' @return Lista invisible con:
#'   - datos: Data frame filtrado para la patología
#'   - n_po: Número de egresos PO
#'   - n_pg: Número de egresos PG
#'   - tasa_po: Tasa anual PO (x1000 persona-años)
#'   - tasa_pg: Tasa anual PG (x1000 persona-años)
#'   - rr: Riesgo Relativo (PO vs PG)
#'   - top_diagnosticos: Data frame con top diagnósticos (si top_n > 0)
#'
#' @examples
#' \dontrun{
#' # Perfil de diabetes
#' perfil_diabetes <- crear_perfil_patologia(
#'   datos = datos_diag_preparados,
#'   codigos_base = c("E10", "E11", "E12", "E13", "E14"),
#'   nombre_patologia = "Diabetes Mellitus",
#'   pob_po = 139455,
#'   pob_pg = 7356234,
#'   anos_estudio = 13,
#'   total_egresos_po = 500000,
#'   total_egresos_pg = 25000000,
#'   expandir = TRUE,
#'   top_n = 10,
#'   verbose = TRUE
#' )
#' }
#'
#' @export
crear_perfil_patologia <- function(datos, 
                                   codigos_base, 
                                   nombre_patologia, 
                                   pob_po, 
                                   pob_pg, 
                                   anos_estudio,
                                   total_egresos_po, 
                                   total_egresos_pg,
                                   expandir = TRUE, 
                                   top_n = 10,
                                   verbose = TRUE) {
  
  # Validaciones
  if(expandir && !requireNamespace("ciecl", quietly = TRUE)) {
    if(verbose) {
      warning("El paquete ciecl no está disponible. Se usarán códigos base sin expandir.")
    }
    expandir <- FALSE
  }
  
  if(!all(c("DIAG1", "PERTENENCIA2", "DIAG_COMPLETO") %in% names(datos))) {
    stop("El data frame debe contener las columnas: DIAG1, PERTENENCIA2, DIAG_COMPLETO")
  }
  
  # Expandir códigos si se solicita
  if(expandir && requireNamespace("purrr", quietly = TRUE)) {
    if(verbose) cat("Expandiendo códigos de", nombre_patologia, "...\n")
    
    # Verificar si cie_expand está disponible
    tiene_ciecl <- requireNamespace("ciecl", quietly = TRUE) && exists("cie_expand", where = "package:ciecl", mode = "function")
    
    if(tiene_ciecl) {
      codigos_expandidos <- purrr::map_dfr(codigos_base, function(cod) {
        tryCatch({
          ciecl::cie_expand(codigo_base = cod, nivel = "subcategoria")
        }, error = function(e) {
          if(verbose) warning("No se pudo expandir código ", cod, ": ", e$message)
          tibble(codigo = cod)
        })
      }) %>%
        distinct(codigo, .keep_all = TRUE)
      
      codigos_finales <- codigos_expandidos$codigo
      
      if(verbose) {
        cat("  Códigos base:", length(codigos_base), 
            "→ Expandidos:", length(codigos_finales), "\n\n")
      }
    } else {
      if(verbose) cat("  ⚠ ciecl::cie_expand() no disponible, usando códigos base\n\n")
      codigos_finales <- codigos_base
    }
  } else {
    codigos_finales <- codigos_base
  }
  
  # Filtrar datos
  datos_filtrados <- datos %>%
    filter(DIAG1 %in% codigos_finales)
  
  # Calcular estadísticas
  n_po <- sum(datos_filtrados$PERTENENCIA2 == 1, na.rm = TRUE)
  n_pg <- sum(datos_filtrados$PERTENENCIA2 == 0, na.rm = TRUE)
  
  persona_anos_po <- pob_po * anos_estudio
  persona_anos_pg <- pob_pg * anos_estudio
  
  tasa_po <- (n_po / persona_anos_po) * 1000
  tasa_pg <- (n_pg / persona_anos_pg) * 1000
  rr <- if_else(tasa_pg > 0, tasa_po / tasa_pg, NA_real_)
  
  # Imprimir resultados si verbose = TRUE
  if(verbose) {
    cat("═══", toupper(nombre_patologia), "═══\n\n")
    cat("EGRESOS:\n")
    cat("  • PO:", format(n_po, big.mark = ","), 
        sprintf("(%.1f%% del total)\n", (n_po/total_egresos_po)*100))
    cat("  • PG:", format(n_pg, big.mark = ","), 
        sprintf("(%.1f%% del total)\n\n", (n_pg/total_egresos_pg)*100))
    
    cat("TASAS ANUALES (x1000 persona-años):\n")
    cat("  • PO:", sprintf("%.2f\n", tasa_po))
    cat("  • PG:", sprintf("%.2f\n", tasa_pg))
    
    if(!is.na(rr)) {
      cat("  • RR:", sprintf("%.2f", rr),
          sprintf("(PO tiene %.0f%% %s)\n\n",
                  abs((rr - 1) * 100),
                  if_else(rr > 1, "más riesgo", "menos riesgo")))
    } else {
      cat("  • RR: No calculable\n\n")
    }
  }
  
  # Top diagnósticos
  top_diag <- NULL
  if(top_n > 0) {
    top_diag <- datos_filtrados %>%
      group_by(DIAG_COMPLETO) %>%
      summarise(
        n_po = sum(PERTENENCIA2 == 1, na.rm = TRUE),
        n_pg = sum(PERTENENCIA2 == 0, na.rm = TRUE),
        total = n(),
        .groups = "drop"
      ) %>%
      mutate(
        tasa_po = (n_po / persona_anos_po) * 1000,
        tasa_pg = (n_pg / persona_anos_pg) * 1000,
        rr = if_else(tasa_pg > 0, tasa_po / tasa_pg, NA_real_)
      ) %>%
      arrange(desc(total)) %>%
      slice(1:top_n)
    
    if(verbose) {
      cat("TOP", top_n, "DIAGNÓSTICOS:\n")
      for(i in 1:nrow(top_diag)) {
        cat(sprintf("%d. %s\n", i, top_diag$DIAG_COMPLETO[i]))
        cat(sprintf("   PO: %s | PG: %s | RR: %.2f\n",
                    format(top_diag$n_po[i], big.mark = ","),
                    format(top_diag$n_pg[i], big.mark = ","),
                    top_diag$rr[i]))
      }
      cat("\n")
    }
  }
  
  # Retornar resultados
  invisible(list(
    datos = datos_filtrados,
    n_po = n_po,
    n_pg = n_pg,
    tasa_po = tasa_po,
    tasa_pg = tasa_pg,
    rr = rr,
    top_diagnosticos = top_diag,
    codigos_utilizados = codigos_finales
  ))
}


#' Comparar múltiples patologías
#'
#' @description
#' Compara múltiples patologías simultáneamente, calculando tasas y RR para cada una.
#'
#' @param datos Data frame con los datos de egresos hospitalarios
#' @param lista_patologias Lista nombrada donde cada elemento es un vector de códigos CIE-10.
#'        Los nombres de la lista son los nombres de las patologías.
#'        Ej: list("Diabetes" = c("E10", "E11"), "EPOC" = c("J44"))
#' @param pob_po Población Pueblos Originarios
#' @param pob_pg Población General
#' @param anos_estudio Número de años del período de estudio
#' @param total_egresos_po Total de egresos PO
#' @param total_egresos_pg Total de egresos PG
#' @param expandir Lógico. Si TRUE, expande códigos a subcategorías
#' @param verbose Lógico. Si TRUE, imprime resultados en consola
#'
#' @return Data frame con comparación de todas las patologías:
#'   - patologia: Nombre de la patología
#'   - n_po, n_pg: Número de egresos
#'   - tasa_po, tasa_pg: Tasas anuales (x1000 p-a)
#'   - rr: Riesgo Relativo
#'   - dif_tasa: Diferencia de tasas
#'   - clasificacion: Sobrerrepresentado/Subrepresentado/Similar
#'
#' @examples
#' \dontrun{
#' patologias <- list(
#'   "Diabetes" = c("E10", "E11"),
#'   "EPOC" = c("J44"),
#'   "Hipertensión" = c("I10", "I11")
#' )
#'
#' comparacion <- comparar_patologias(
#'   datos = datos_diag_preparados,
#'   lista_patologias = patologias,
#'   pob_po = 139455,
#'   pob_pg = 7356234,
#'   anos_estudio = 13,
#'   total_egresos_po = 500000,
#'   total_egresos_pg = 25000000
#' )
#' }
#'
#' @export
comparar_patologias <- function(datos,
                                lista_patologias,
                                pob_po,
                                pob_pg,
                                anos_estudio,
                                total_egresos_po,
                                total_egresos_pg,
                                expandir = TRUE,
                                verbose = TRUE) {
  
  if(!requireNamespace("purrr", quietly = TRUE)) {
    stop("El paquete purrr es requerido")
  }
  
  if(verbose) {
    cat("\n═══ COMPARACIÓN ENTRE PATOLOGÍAS ═══\n\n")
    cat("Analizando", length(lista_patologias), "patologías...\n\n")
  }
  
  # Calcular para cada patología
  resultados <- purrr::map_dfr(names(lista_patologias), function(nombre) {
    resultado <- crear_perfil_patologia(
      datos = datos,
      codigos_base = lista_patologias[[nombre]],
      nombre_patologia = nombre,
      pob_po = pob_po,
      pob_pg = pob_pg,
      anos_estudio = anos_estudio,
      total_egresos_po = total_egresos_po,
      total_egresos_pg = total_egresos_pg,
      expandir = expandir,
      top_n = 0,  # No mostrar top diagnósticos en comparación
      verbose = verbose
    )
    
    tibble(
      patologia = nombre,
      n_po = resultado$n_po,
      n_pg = resultado$n_pg,
      tasa_po = resultado$tasa_po,
      tasa_pg = resultado$tasa_pg,
      rr = resultado$rr
    )
  })
  
  # Agregar clasificación y diferencia
  resultados <- resultados %>%
    mutate(
      dif_tasa = tasa_po - tasa_pg,
      clasificacion = case_when(
        rr >= 1.5 ~ "Sobrerrepresentado",
        rr <= 0.67 ~ "Subrepresentado",
        TRUE ~ "Similar"
      )
    ) %>%
    arrange(desc(abs(dif_tasa)))
  
  if(verbose) {
    cat("\n═══ RESUMEN COMPARATIVO ═══\n\n")
    for(i in 1:nrow(resultados)) {
      cat(sprintf("%d. %s\n", i, resultados$patologia[i]))
      cat(sprintf("   • Tasas: PO %.2f | PG %.2f (x1000 p-a)\n",
                  resultados$tasa_po[i], resultados$tasa_pg[i]))
      cat(sprintf("   • Diferencia: %.2f x1000 p-a\n", resultados$dif_tasa[i]))
      cat(sprintf("   • RR: %.2f - %s\n\n",
                  resultados$rr[i], resultados$clasificacion[i]))
    }
  }
  
  return(resultados)
}


#' Analizar desglose por subtipos de patología
#'
#' @description
#' Desglosa una patología en sus subtipos usando un campo de clasificación.
#' Útil para analizar, por ejemplo, diferentes tipos de diabetes.
#'
#' @param datos Data frame filtrado para una patología específica
#' @param clasificacion_fn Función que clasifica cada registro en un subtipo.
#'        Debe aceptar el data frame y retornar un vector de clasificaciones.
#' @param pob_po Población Pueblos Originarios
#' @param pob_pg Población General
#' @param anos_estudio Número de años del período de estudio
#' @param verbose Lógico. Si TRUE, imprime resultados
#'
#' @return Data frame con estadísticas por subtipo
#'
#' @examples
#' \dontrun{
#' # Clasificar tipos de diabetes
#' clasificar_diabetes <- function(datos) {
#'   case_when(
#'     str_detect(datos$DIAG1, "^E10") ~ "Tipo 1",
#'     str_detect(datos$DIAG1, "^E11") ~ "Tipo 2",
#'     TRUE ~ "Otras"
#'   )
#' }
#'
#' desglose <- desglosar_por_subtipo(
#'   datos = datos_diabetes,
#'   clasificacion_fn = clasificar_diabetes,
#'   pob_po = 139455,
#'   pob_pg = 7356234,
#'   anos_estudio = 13
#' )
#' }
#'
#' @export
desglosar_por_subtipo <- function(datos,
                                   clasificacion_fn,
                                   pob_po,
                                   pob_pg,
                                   anos_estudio,
                                   verbose = TRUE) {
  
  # Aplicar clasificación
  datos_clasificados <- datos %>%
    mutate(subtipo = clasificacion_fn(.))
  
  # Calcular persona-años
  persona_anos_po <- pob_po * anos_estudio
  persona_anos_pg <- pob_pg * anos_estudio
  
  # Calcular estadísticas por subtipo
  desglose <- datos_clasificados %>%
    group_by(subtipo, PERTENENCIA2) %>%
    summarise(n = n(), .groups = "drop") %>%
    pivot_wider(
      names_from = PERTENENCIA2, 
      values_from = n, 
      values_fill = 0,
      names_prefix = "pert_"
    ) %>%
    mutate(
      n_po = if("pert_1" %in% names(.)) pert_1 else 0,
      n_pg = if("pert_0" %in% names(.)) pert_0 else 0
    ) %>%
    select(-starts_with("pert_")) %>%
    mutate(
      pct_po = (n_po / sum(n_po)) * 100,
      pct_pg = (n_pg / sum(n_pg)) * 100,
      tasa_po = (n_po / persona_anos_po) * 1000,
      tasa_pg = (n_pg / persona_anos_pg) * 1000,
      rr = if_else(tasa_pg > 0, tasa_po / tasa_pg, NA_real_)
    ) %>%
    arrange(desc(n_po))
  
  if(verbose) {
    cat("\n═══ DESGLOSE POR SUBTIPO ═══\n\n")
    for(i in 1:nrow(desglose)) {
      cat(sprintf("%s:\n", desglose$subtipo[i]))
      cat(sprintf("   • Egresos: PO %s (%.1f%%) | PG %s (%.1f%%)\n",
                  format(desglose$n_po[i], big.mark = ","),
                  desglose$pct_po[i],
                  format(desglose$n_pg[i], big.mark = ","),
                  desglose$pct_pg[i]))
      cat(sprintf("   • Tasas: PO %.2f | PG %.2f x1000 p-a\n",
                  desglose$tasa_po[i], desglose$tasa_pg[i]))
      cat(sprintf("   • RR: %.2f\n\n", desglose$rr[i]))
    }
  }
  
  return(desglose)
}
