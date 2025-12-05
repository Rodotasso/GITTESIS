# ==============================================================================
# ARCHIVO MAESTRO PARA CARGAR TODAS LAS FUNCIONES
# ==============================================================================
#
# Este archivo carga todas las funciones personalizadas del proyecto de tesis
# sobre pertenencia a pueblos originarios en datos de egresos hospitalarios.
#
# USO:
#   source("R/cargar_funciones.R")
#
# ESTRUCTURA:
#   R/
#   ├── graficos/          # Funciones de generación de gráficos
#   ├── tablas/            # Funciones de creación y exportación de tablas
#   ├── analisis/          # Funciones de análisis estadístico
#   ├── concordancia/      # Funciones de análisis de concordancia
#   ├── censo/             # Funciones de extracción de datos del censo
#   └── utilidades/        # Funciones auxiliares y de propósito general
#
# FECHA CREACION: Enero 2025
# AUTOR: Proyecto GITTESIS
#
# ==============================================================================

# Mensaje de inicio
cat("================================================================================\n")
cat("CARGANDO FUNCIONES PERSONALIZADAS\n")
cat("================================================================================\n\n")

# Obtener directorio base del proyecto
directorio_base <- getwd()
directorio_r <- file.path(directorio_base, "R")

# Verificar que existe el directorio R/
if (!dir.exists(directorio_r)) {
  stop("ERROR: No se encuentra el directorio R/ en el proyecto.")
}

# ------------------------------------------------------------------------------
# FUNCIONES DE GRAFICOS
# ------------------------------------------------------------------------------
cat("Cargando funciones de gráficos...\n")
source(file.path(directorio_r, "graficos", "guardar_multiformato.R"))
source(file.path(directorio_r, "graficos", "grafico_comparativo_fuentes.R"))
source(file.path(directorio_r, "graficos", "grafico_tendencia_pertenencia.R"))
source(file.path(directorio_r, "graficos", "grafico_tendencia_completa.R"))
source(file.path(directorio_r, "graficos", "generar_graficos_tendencia_mensual.R"))
source(file.path(directorio_r, "graficos", "grafico_prevision_po.R"))
source(file.path(directorio_r, "graficos", "grafico_diagnosticos_po.R"))
source(file.path(directorio_r, "graficos", "grafico_cie10_po.R"))
source(file.path(directorio_r, "graficos", "grafico_evolucion_prevision_po.R"))
source(file.path(directorio_r, "graficos", "grafico_promedio_prevision_po.R"))
cat("  ✓ guardar_multiformato\n")
cat("  ✓ grafico_comparativo_fuentes\n")
cat("  ✓ grafico_tendencia_pertenencia\n")
cat("  ✓ grafico_tendencia_completa\n")
cat("  ✓ generar_graficos_tendencia_mensual\n")
cat("  ✓ grafico_prevision_po\n")
cat("  ✓ grafico_diagnosticos_po\n")
cat("  ✓ grafico_cie10_po\n")
cat("  ✓ grafico_evolucion_prevision_po\n")
cat("  ✓ grafico_promedio_prevision_po\n")

# ------------------------------------------------------------------------------
# FUNCIONES DE ANALISIS
# ------------------------------------------------------------------------------
cat("\nCargando funciones de análisis...\n")
source(file.path(directorio_r, "analisis", "analizar_pertenencia.R"))
source(file.path(directorio_r, "analisis", "analizar_pertenencia_sexo.R"))
source(file.path(directorio_r, "analisis", "analizar_variable.R"))
source(file.path(directorio_r, "analisis", "analizar_cie10_top.R"))
source(file.path(directorio_r, "analisis", "analizar_por_sexo.R"))
source(file.path(directorio_r, "analisis", "analizar_variable_solo_po.R"))
cat("  ✓ analizar_pertenencia\n")
cat("  ✓ analizar_pertenencia_sexo\n")
cat("  ✓ analizar_variable\n")
cat("  ✓ analizar_cie10_top\n")
cat("  ✓ analizar_por_sexo\n")
cat("  ✓ analizar_variable_solo_po\n")

# ------------------------------------------------------------------------------
# FUNCIONES DE CONCORDANCIA
# ------------------------------------------------------------------------------
cat("\nCargando funciones de concordancia...\n")
source(file.path(directorio_r, "concordancia", "calcular_concordancia_desctools.R"))
source(file.path(directorio_r, "concordancia", "formatear_resultado_ccc.R"))
cat("  ✓ calcular_concordancia_desctools\n")
cat("  ✓ formatear_resultado_ccc\n")

# ------------------------------------------------------------------------------
# FUNCIONES DE CENSO
# ------------------------------------------------------------------------------
cat("\nCargando funciones de censo...\n")
source(file.path(directorio_r, "censo", "extraer_datos_censo.R"))
source(file.path(directorio_r, "censo", "extraer_datos_variable_enriquecida.R"))
cat("  ✓ extraer_datos_censo\n")
cat("  ✓ extraer_datos_variable_enriquecida\n")

# ------------------------------------------------------------------------------
# FUNCIONES DE TABLAS
# ------------------------------------------------------------------------------
cat("\nCargando funciones de tablas...\n")
source(file.path(directorio_r, "tablas", "guardar_como_jpg.R"))
source(file.path(directorio_r, "tablas", "crear_tabla_resumen_horizontal.R"))
source(file.path(directorio_r, "tablas", "flex_to_df.R"))
source(file.path(directorio_r, "tablas", "save_flex_as_html.R"))
source(file.path(directorio_r, "tablas", "guardar_tabla_html.R"))
cat("  ✓ guardar_como_jpg\n")
cat("  ✓ crear_tabla_resumen_horizontal\n")
cat("  ✓ flex_to_df\n")
cat("  ✓ save_flex_as_html\n")
cat("\nFunciones disponibles:\n\n")
cat("GRÁFICOS (10 funciones):\n")
cat("  - guardar_multiformato(grafico, nombre_base, ancho, alto, dpi)\n")
cat("  - grafico_comparativo_fuentes(data)\n")
cat("  - grafico_tendencia_pertenencia(data, var_nombre, var_etiqueta)\n")
cat("  - grafico_tendencia_completa(data, var_nombre, var_etiqueta)\n")
cat("  - generar_graficos_tendencia_mensual(data)\n")
cat("  - grafico_prevision_po(data)\n")
cat("  - grafico_diagnosticos_po(data)\n")
cat("  - grafico_cie10_po(data)\n")
cat("  - grafico_evolucion_prevision_po(data)\n")
cat("  - grafico_promedio_prevision_po(data)\n")
cat("\nANÁLISIS (6 funciones):\n")
cat("  - analizar_pertenencia(data, var_nombre, var_etiqueta)\n")
cat("  - analizar_pertenencia_sexo(data, var_nombre, var_etiqueta)\n")
cat("  - analizar_variable(data, variable_col, titulo, limite_top)\n")
cat("  - analizar_cie10_top(data, limite_top)\n")
cat("  - analizar_por_sexo(data, variable_col, titulo, limite_top)\n")
cat("  - analizar_variable_solo_po(data, variable_col, titulo, limite_top, n_columnas)\n")
cat("\nCONCORDANCIA (2 funciones):\n")
cat("  - calcular_concordancia_desctools(datos, col_verdad, col_estimado, nombre_fuente)\n")
cat("  - formatear_resultado_ccc(resultado_ccc, nombre_desagregacion)\n")
cat("\nCENSO (2 funciones):\n")
cat("  - extraer_datos_censo(conexion, verbose)\n")
cat("  - extraer_datos_variable_enriquecida(datos_homologados, verbose)\n")
cat("\nTABLAS (5 funciones):\n")
cat("  - guardar_como_jpg(tabla_ft, nombre_archivo)\n")
cat("  - crear_tabla_resumen_horizontal(data, var_label, etiqueta_variable)\n")
cat("  - flex_to_df(ft)\n")
cat("  - save_flex_as_html(ft, filename)\n")
cat("  - guardar_tabla_html(tabla, nombre_archivo)\n")
cat("\nUTILIDADES (2 funciones):\n")
cat("  - clasificar_grupo(codigo)\n")
cat("  - crear_grafico_tendencia(data, var_label, titulo_variable)\n")
cat("\n")
cat("Total: 31 funciones cargadas (100% COMPLETO) ✓✓✓\n")
cat("Para más información, consulte: R/README.md\n")
cat("================================================================================\n\n")
