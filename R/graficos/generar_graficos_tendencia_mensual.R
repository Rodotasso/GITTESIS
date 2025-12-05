# ==============================================================================
# FUNCION: generar_graficos_tendencia_mensual
# ==============================================================================
# 
# DESCRIPCION:
#   Genera un gráfico de tendencia mensual para cada año disponible en los datos,
#   comparando las 4 fuentes de pertenencia (RSH, CONADI, Egresos, Variable Enriquecida)
#
# PARAMETROS:
#   @param data  Data frame con datos de egresos que debe contener:
#                - FECHA_EGRESO_FMT_DEIS: Fecha del egreso
#                - RSH, CONADI, PUEBLO_ORIGINARIO_BIN, PERTENENCIA2: Variables de pertenencia
#
# RETORNA:
#   Lista nombrada con gráficos ggplot (un elemento por año)
#   NULL si no se encuentra la variable FECHA_EGRESO_FMT_DEIS
#
# EFECTOS SECUNDARIOS:
#   Guarda gráficos JPG en resultados_tesis/tendencia_mensual_YYYY.jpg
#
# DEPENDENCIAS:
#   - dplyr (mutate, filter, group_by, summarise, bind_rows)
#   - ggplot2 (ggplot, geom_line, geom_point, scale_color_manual, labs, theme_minimal)
#   - lubridate (month, year, as.Date)
#   - scales (para formateo de porcentajes)
#
# ARCHIVO ORIGEN:
#   - grafico_pertenencia.qmd
#
# NOTAS:
#   - Genera un gráfico por año (2010-2022 típicamente = 13 gráficos)
#   - Cada gráfico muestra variación mensual dentro del año
#   - Colores fijos: RSH=rojo, CONADI=verde, Egresos=azul, Enriquecida=naranja
#
# EJEMPLO:
#   graficos <- generar_graficos_tendencia_mensual(datos_ordenados)
#   print(graficos[["2015"]])  # Ver gráfico del año 2015
#   length(graficos)  # Contar cuántos años se procesaron
#
# ==============================================================================

generar_graficos_tendencia_mensual <- function(data) {
  
  # Verificar que exista variable de fecha
  if(!("FECHA_EGRESO_FMT_DEIS" %in% names(data))) {
    message("No se encuentra la variable FECHA_EGRESO_FMT_DEIS en los datos")
    return(NULL)
  }
  
  # Preparar datos: extraer mes y año de la fecha de egreso
  datos_prep <- data %>%
    mutate(
      FECHA_EGRESO = as.Date(FECHA_EGRESO_FMT_DEIS),
      MES = month(FECHA_EGRESO),
      MES_NOMBRE = factor(month.abb[MES], levels = month.abb),
      AÑO_NUM = year(FECHA_EGRESO)
    ) %>%
    filter(!is.na(FECHA_EGRESO), !is.na(AÑO_NUM))
  
  # Obtener años disponibles
  años_disponibles <- sort(unique(datos_prep$AÑO_NUM))
  
  # Lista para almacenar gráficos
  lista_graficos <- list()
  
  # Generar un gráfico por cada año
  for(año_actual in años_disponibles) {
    
    # Filtrar datos del año actual
    datos_año <- datos_prep %>%
      filter(AÑO_NUM == año_actual)
    
    # Calcular proporciones mensuales para cada variable
    
    # RSH
    datos_rsh <- datos_año %>%
      group_by(MES, MES_NOMBRE) %>%
      summarise(
        pertenece = sum(RSH == 1, na.rm = TRUE),
        total = n(),
        porcentaje = (pertenece / total) * 100,
        .groups = "drop"
      ) %>%
      mutate(Variable = "RSH")
    
    # CONADI
    datos_conadi <- datos_año %>%
      group_by(MES, MES_NOMBRE) %>%
      summarise(
        pertenece = sum(CONADI == 1, na.rm = TRUE),
        total = n(),
        porcentaje = (pertenece / total) * 100,
        .groups = "drop"
      ) %>%
      mutate(Variable = "CONADI")
    
    # Egresos hospitalarios
    datos_egresos <- datos_año %>%
      group_by(MES, MES_NOMBRE) %>%
      summarise(
        pertenece = sum(PUEBLO_ORIGINARIO_BIN == 1, na.rm = TRUE),
        total = n(),
        porcentaje = (pertenece / total) * 100,
        .groups = "drop"
      ) %>%
      mutate(Variable = "Egresos Hospitalarios")
    
    # Variable enriquecida
    datos_enriquecida <- datos_año %>%
      group_by(MES, MES_NOMBRE) %>%
      summarise(
        pertenece = sum(PERTENENCIA2 == 1, na.rm = TRUE),
        total = n(),
        porcentaje = (pertenece / total) * 100,
        .groups = "drop"
      ) %>%
      mutate(Variable = "Variable Enriquecida")
    
    # Combinar todos los datos
    datos_combinados <- bind_rows(
      datos_rsh,
      datos_conadi,
      datos_egresos,
      datos_enriquecida
    ) %>%
      mutate(Variable = factor(Variable, 
                               levels = c("RSH", "CONADI", "Egresos Hospitalarios", 
                                        "Variable Enriquecida")))
    
    # Crear el gráfico
    grafico <- ggplot(datos_combinados, aes(x = MES_NOMBRE, y = porcentaje, 
                                            color = Variable, group = Variable)) +
      geom_line(linewidth = 1.2) +
      geom_point(size = 3, alpha = 0.7) +
      scale_color_manual(
        values = c(
          "RSH" = "#E41A1C",              # Rojo
          "CONADI" = "#4DAF4A",           # Verde
          "Egresos Hospitalarios" = "#377EB8", # Azul
          "Variable Enriquecida" = "#FF7F00"   # Naranja
        )
      ) +
      scale_y_continuous(
        labels = function(x) paste0(round(x, 1), "%"),
        breaks = seq(0, 100, by = 5)
      ) +
      labs(
        title = paste("Tendencia mensual de pertenencia a pueblos originarios -", año_actual),
        subtitle = "Comparación entre RSH, CONADI, Egresos Hospitalarios y Variable Enriquecida",
        x = "Mes",
        y = "Porcentaje de pertenencia (%)",
        color = "Fuente de datos",
        caption = paste0(
          "n = ", format(nrow(datos_año), big.mark = ","), " registros | ",
          "Variable Enriquecida combina información de todas las fuentes\n",
          "NOTA: Este gráfico muestra la variación MENSUAL dentro del año ", año_actual, ".\n",
          "Los niveles absolutos de porcentaje varían entre años por cambios en cobertura de registros administrativos (RSH, CONADI, egresos).")
      ) +
      theme_minimal() +
      theme(
        legend.position = "bottom",
        panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
        axis.text.y = element_text(size = 10),
        axis.title = element_text(size = 11, face = "bold"),
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 11),
        plot.caption = element_text(hjust = 0, size = 9, color = "gray40"),
        legend.text = element_text(size = 10),
        panel.grid.major = element_line(color = "gray90"),
        panel.border = element_rect(color = "gray70", fill = NA)
      )
    
    # Agregar a la lista con nombre del año
    lista_graficos[[as.character(año_actual)]] <- grafico
    
    # Guardar gráfico individual
    ggsave(
      filename = paste0("resultados_tesis/tendencia_mensual_", año_actual, ".jpg"),
      plot = grafico,
      width = 14,
      height = 8,
      dpi = 300,
      bg = "white"
    )
  }
  
  return(lista_graficos)
}
