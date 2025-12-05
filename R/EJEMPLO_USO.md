# EJEMPLO DE USO: SISTEMA DE FUNCIONES MODULARIZADAS

Este archivo muestra cómo usar el nuevo sistema de funciones modularizadas en tus análisis.

## Configuración Inicial

```r
# 1. Cargar todas las bibliotecas necesarias
library(dplyr)
library(ggplot2)
library(ggpubr)
library(tidyr)
library(flextable)
library(officer)
library(webshot2)

# 2. Definir variables globales de colores (requeridas por las funciones)
colores_analisis <- c(
  "Pertenece a Pueblos Originarios" = "#E69F00",
  "Población General" = "#0072B2"
)

colores_fuentes <- c(
  "RSH" = "#E41A1C",
  "CONADI" = "#4DAF4A",
  "Egresos Hospitalarios" = "#377EB8",
  "Variable Enriquecida" = "#FF7F00"
)

# 3. Cargar todas las funciones personalizadas
source("R/cargar_funciones.R")

# 4. Cargar tus datos
load("BBDD_ordenados.RData")  # o el archivo que uses
```

## Ejemplo 1: Análisis de Pertenencia

```r
# Analizar pertenencia según RSH
resultado_rsh <- analizar_pertenencia(
  data = datos_ordenados,
  var_nombre = "RSH",
  var_etiqueta = "Registro Social de Hogares"
)

# Ver el gráfico anual
print(resultado_rsh$anual)

# Ver el gráfico de promedios
print(resultado_rsh$promedio)

# Ver los datos procesados
View(resultado_rsh$datos_anual)
View(resultado_rsh$datos_promedio)

# Guardar los gráficos
guardar_multiformato(resultado_rsh$anual, "rsh_anual", ancho = 12, alto = 8)
guardar_multiformato(resultado_rsh$promedio, "rsh_promedio", ancho = 10, alto = 6)
```

## Ejemplo 2: Comparación de Fuentes

```r
# Generar gráfico comparativo de todas las fuentes
comparacion <- grafico_comparativo_fuentes(datos_ordenados)

# Ver el gráfico
print(comparacion$grafico)

# Ver los datos procesados
View(comparacion$datos)

# Guardar el gráfico
guardar_multiformato(comparacion$grafico, "comparacion_fuentes", ancho = 14, alto = 8)

# Exportar datos a CSV para análisis adicional
write.csv(comparacion$datos, "resultados_tesis/comparacion_fuentes_datos.csv", row.names = FALSE)
```

## Ejemplo 3: Análisis Múltiple

```r
# Analizar todas las variables de pertenencia
variables <- list(
  list(nombre = "RSH", etiqueta = "Registro Social de Hogares"),
  list(nombre = "CONADI", etiqueta = "CONADI"),
  list(nombre = "PUEBLO_ORIGINARIO_BIN", etiqueta = "Egresos Hospitalarios"),
  list(nombre = "PERTENENCIA2", etiqueta = "Variable Enriquecida")
)

# Generar análisis para cada una
resultados <- lapply(variables, function(var) {
  analizar_pertenencia(datos_ordenados, var$nombre, var$etiqueta)
})

# Guardar todos los gráficos anuales
for (i in seq_along(variables)) {
  nombre_archivo <- tolower(gsub(" ", "_", variables[[i]]$etiqueta))
  guardar_multiformato(
    resultados[[i]]$anual, 
    paste0("pertenencia_anual_", nombre_archivo)
  )
}

# Combinar todos los gráficos de promedios en uno solo
graficos_promedio <- lapply(resultados, function(r) {
  r$promedio + theme(legend.position = "none", plot.caption = element_blank())
})

grafico_combinado <- ggarrange(
  plotlist = graficos_promedio,
  common.legend = TRUE,
  legend = "bottom",
  ncol = 2, nrow = 2
)

grafico_combinado_anotado <- annotate_figure(
  grafico_combinado,
  top = text_grob("Promedio de pertenencia según diferentes fuentes", 
                  face = "bold", size = 16)
)

print(grafico_combinado_anotado)
guardar_multiformato(grafico_combinado_anotado, "promedios_combinados", ancho = 14, alto = 10)
```

## Ejemplo 4: Pipeline Completo de Análisis

```r
# Pipeline completo: cargar datos → analizar → graficar → guardar
pipeline_analisis <- function(archivo_datos, variable, etiqueta, directorio_salida = "resultados_tesis") {
  
  # 1. Cargar datos
  cat("Cargando datos desde:", archivo_datos, "\n")
  load(archivo_datos)
  
  # 2. Analizar
  cat("Analizando variable:", variable, "\n")
  resultado <- analizar_pertenencia(datos_ordenados, variable, etiqueta)
  
  if (is.null(resultado)) {
    cat("ERROR: No se pudo completar el análisis\n")
    return(NULL)
  }
  
  # 3. Guardar gráficos
  cat("Guardando gráficos...\n")
  nombre_base <- tolower(gsub(" ", "_", etiqueta))
  guardar_multiformato(resultado$anual, paste0(nombre_base, "_anual"))
  guardar_multiformato(resultado$promedio, paste0(nombre_base, "_promedio"))
  
  # 4. Exportar datos procesados
  cat("Exportando datos procesados...\n")
  write.csv(
    resultado$datos_anual, 
    file.path(directorio_salida, paste0(nombre_base, "_datos_anual.csv")),
    row.names = FALSE
  )
  write.csv(
    resultado$datos_promedio,
    file.path(directorio_salida, paste0(nombre_base, "_datos_promedio.csv")),
    row.names = FALSE
  )
  
  cat("✓ Análisis completado para:", etiqueta, "\n\n")
  
  return(resultado)
}

# Usar el pipeline
resultado_rsh <- pipeline_analisis(
  archivo_datos = "BBDD_ordenados.RData",
  variable = "RSH",
  etiqueta = "Registro Social de Hogares"
)
```

## Ejemplo 5: Crear Reporte Automatizado

```r
# Función para generar reporte completo en Rmarkdown/Quarto
crear_reporte_pertenencia <- function() {
  
  # Cargar funciones y datos
  source("R/cargar_funciones.R")
  load("BBDD_ordenados.RData")
  
  # Definir variables a analizar
  variables <- list(
    list(nombre = "RSH", etiqueta = "RSH"),
    list(nombre = "CONADI", etiqueta = "CONADI"),
    list(nombre = "PUEBLO_ORIGINARIO_BIN", etiqueta = "Egresos Hospitalarios"),
    list(nombre = "PERTENENCIA2", etiqueta = "Variable Enriquecida")
  )
  
  # Generar análisis
  resultados <- list()
  for (var in variables) {
    cat("Procesando:", var$etiqueta, "\n")
    resultados[[var$nombre]] <- analizar_pertenencia(
      datos_ordenados, 
      var$nombre, 
      var$etiqueta
    )
  }
  
  # Generar comparación
  cat("Generando comparación de fuentes\n")
  comparacion <- grafico_comparativo_fuentes(datos_ordenados)
  
  # Guardar todo
  cat("Guardando resultados\n")
  for (nombre in names(resultados)) {
    guardar_multiformato(resultados[[nombre]]$anual, paste0(nombre, "_anual"))
    guardar_multiformato(resultados[[nombre]]$promedio, paste0(nombre, "_promedio"))
  }
  guardar_multiformato(comparacion$grafico, "comparacion_fuentes")
  
  cat("✓ Reporte completado\n")
  
  return(list(
    analisis_individuales = resultados,
    comparacion = comparacion
  ))
}

# Ejecutar
reporte <- crear_reporte_pertenencia()
```

## Ventajas del Sistema Modularizado

1. **Código más limpio**: Los archivos .qmd ahora serán mucho más cortos y legibles
2. **Reutilización**: Usar las mismas funciones en múltiples análisis sin duplicar código
3. **Mantenimiento**: Actualizar una función en un solo lugar
4. **Testing**: Probar funciones individuales de forma aislada
5. **Documentación**: Todas las funciones documentadas en un solo lugar (R/README.md)
6. **Colaboración**: Más fácil trabajar en equipo

## Próximos Pasos

1. Extraer las 28 funciones restantes (ver R/README.md para lista completa)
2. Actualizar los archivos .qmd existentes para usar `source("R/cargar_funciones.R")`
3. Eliminar definiciones de funciones duplicadas de los .qmd
4. Probar cada función extraída
5. Crear tests unitarios (opcional pero recomendado)

## Notas Importantes

- **NO BORRAR** las funciones de los .qmd originales hasta que todo esté probado
- Mantener siempre actualizado el archivo `R/cargar_funciones.R`
- Documentar cualquier cambio en `R/README.md`
- Usar Git para control de versiones

---

**Fecha**: Enero 2025  
**Proyecto**: GITTESIS - Análisis Pueblos Originarios
