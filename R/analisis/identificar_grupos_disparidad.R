#' Identificar Grupos CIE-10 con Sobre/Subrepresentación
#'
#' Identifica grupos diagnósticos CIE-10 que muestran sobre o subrepresentación
#' de pueblos originarios comparado con la tendencia de PERTENENCIA2.
#'
#' @param datos Data frame con los datos de egresos hospitalarios
#' @param tendencia_pertenencia2 Data frame con tendencia anual (output de calcular_tendencia_pertenencia2)
#' @param umbral Numeric. Umbral mínimo de diferencia en puntos porcentuales (default: 1.5)
#' @param grupos_forzar Character vector. Nombres de grupos a incluir siempre (default: NULL)
#' @param verbose Logical. Si TRUE, imprime diagnóstico detallado (default: TRUE)
#'
#' @return List con dos elementos:
#'   - diferencias_grupos: Data frame con todas las diferencias calculadas
#'   - grupos_relevantes: Character vector con nombres de grupos seleccionados
#'
#' @examples
#' tendencia <- calcular_tendencia_pertenencia2(datos_homologados)
#' resultado <- identificar_grupos_disparidad(
#'   datos_homologados, 
#'   tendencia,
#'   umbral = 1.5,
#'   grupos_forzar = c("XV. Embarazo, parto y puerperio")
#' )
#'
#' @export
identificar_grupos_disparidad <- function(datos, 
                                          tendencia_pertenencia2, 
                                          umbral = 1.5,
                                          grupos_forzar = NULL,
                                          verbose = TRUE) {
  
  # Validaciones
  if (!is.data.frame(datos)) {
    stop("El argumento 'datos' debe ser un data frame")
  }
  
  required_cols <- c("AÑO", "Grupo_CIE10", "PERTENENCIA2")
  missing_cols <- setdiff(required_cols, names(datos))
  if (length(missing_cols) > 0) {
    stop("Faltan las siguientes columnas en 'datos': ", paste(missing_cols, collapse = ", "))
  }
  
  if (!all(c("AÑO", "pct_po") %in% names(tendencia_pertenencia2))) {
    stop("'tendencia_pertenencia2' debe tener columnas AÑO y pct_po")
  }
  
  # Calcular % PO en cada grupo CIE-10 por año
  datos_grupos <- datos %>%
    filter(AÑO != "No reportado", !is.na(Grupo_CIE10)) %>%
    group_by(AÑO, Grupo_CIE10, PERTENENCIA2) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(AÑO, Grupo_CIE10) %>%
    mutate(
      total_grupo = sum(n),
      porcentaje = (n / total_grupo) * 100
    ) %>%
    ungroup() %>%
    filter(PERTENENCIA2 == 1)
  
  # Calcular diferencias vs tendencia
  diferencias_grupos <- datos_grupos %>%
    left_join(tendencia_pertenencia2 %>% select(AÑO, pct_po), by = "AÑO") %>%
    mutate(diferencia = porcentaje - pct_po) %>%
    group_by(Grupo_CIE10) %>%
    summarise(
      diferencia_promedio = mean(diferencia),
      diferencia_absoluta = mean(abs(diferencia)),
      pct_promedio = mean(porcentaje),
      n_años = n(),
      .groups = "drop"
    ) %>%
    arrange(desc(diferencia_promedio))
  
  # Filtrar grupos según umbral
  grupos_relevantes <- diferencias_grupos %>%
    filter(abs(diferencia_promedio) >= umbral) %>%
    pull(Grupo_CIE10)
  
  # Agregar grupos forzados si se especifican
  if (!is.null(grupos_forzar)) {
    grupos_forzar_encontrados <- diferencias_grupos %>%
      filter(grepl(paste(grupos_forzar, collapse = "|"), Grupo_CIE10, ignore.case = TRUE)) %>%
      pull(Grupo_CIE10)
    
    grupos_relevantes <- unique(c(grupos_relevantes, grupos_forzar_encontrados))
  }
  
  # Verbose output
  if (verbose) {
    cat("\n═══ IDENTIFICACIÓN DE GRUPOS CON DISPARIDAD ═══\n")
    cat("Umbral:", sprintf("%.1f", umbral), "puntos porcentuales\n\n")
    
    cat("=== TOP 10 SOBRERREPRESENTADOS ===\n")
    print(diferencias_grupos %>% 
            head(10) %>% 
            select(Grupo_CIE10, diferencia_promedio, pct_promedio))
    
    cat("\n=== TOP 10 SUBREPRESENTADOS ===\n")
    print(diferencias_grupos %>% 
            tail(10) %>% 
            arrange(diferencia_promedio) %>%
            select(Grupo_CIE10, diferencia_promedio, pct_promedio))
    
    cat(sprintf("\n✓ Total grupos seleccionados: %d\n", length(grupos_relevantes)))
  }
  
  return(list(
    diferencias_grupos = diferencias_grupos,
    grupos_relevantes = grupos_relevantes
  ))
}
