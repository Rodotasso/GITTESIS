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
#   ├── concordancias/     # Funciones de análisis de concordancia (Kappa, CCC)
#   ├── perfiles/          # Funciones de perfiles epidemiológicos (NUEVO)
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
source(file.path(directorio_r, "graficos", "crear_paleta_disparidad.R"))
source(file.path(directorio_r, "graficos", "crear_tamanios_linea.R"))
source(file.path(directorio_r, "graficos", "grafico_evolucion_disparidades.R"))
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
cat("  ✓ crear_paleta_disparidad (NUEVA)\n")
cat("  ✓ crear_tamanios_linea (NUEVA)\n")
cat("  ✓ grafico_evolucion_disparidades (NUEVA)\n")

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
source(file.path(directorio_r, "analisis", "calcular_tendencia_pertenencia2.R"))
source(file.path(directorio_r, "analisis", "calcular_pct_variable_enriquecida.R"))
source(file.path(directorio_r, "analisis", "identificar_grupos_disparidad.R"))
source(file.path(directorio_r, "analisis", "generar_resumen_disparidades.R"))
cat("  ✓ analizar_pertenencia\n")
cat("  ✓ analizar_pertenencia_sexo\n")
cat("  ✓ analizar_variable\n")
cat("  ✓ analizar_cie10_top\n")
cat("  ✓ analizar_por_sexo\n")
cat("  ✓ analizar_variable_solo_po\n")
cat("  ✓ calcular_tendencia_pertenencia2 (NUEVA)\n")
cat("  ✓ calcular_pct_variable_enriquecida (NUEVA)\n")
cat("  ✓ identificar_grupos_disparidad (NUEVA)\n")
cat("  ✓ generar_resumen_disparidades (NUEVA)\n")

# ------------------------------------------------------------------------------
# FUNCIONES DE CONCORDANCIA
# ------------------------------------------------------------------------------
cat("\nCargando funciones de concordancia...\n")
source(file.path(directorio_r, "concordancias", "calcular_concordancia_desctools.R"))
source(file.path(directorio_r, "concordancias", "formatear_resultado_ccc.R"))
source(file.path(directorio_r, "concordancias", "extraer_datos_censo.R"))
source(file.path(directorio_r, "concordancias", "extraer_datos_variable_enriquecida.R"))
source(file.path(directorio_r, "concordancias", "extraer_datos_egresos_hospitalarios.R"))
source(file.path(directorio_r, "concordancias", "obtener_poblacion_censo.R"))
source(file.path(directorio_r, "concordancias", "calcular_ccc_desagregacion.R"))
source(file.path(directorio_r, "concordancias", "calcular_ccc_detallado.R"))
source(file.path(directorio_r, "concordancias", "calcular_ccc_temporal.R"))
source(file.path(directorio_r, "concordancias", "crear_tabla_ccc.R"))
cat("  ✓ calcular_concordancia_desctools\n")
cat("  ✓ formatear_resultado_ccc\n")
cat("  ✓ extraer_datos_censo\n")
cat("  ✓ extraer_datos_variable_enriquecida\n")
cat("  ✓ extraer_datos_egresos_hospitalarios\n")
cat("  ✓ obtener_poblacion_censo\n")
cat("  ✓ calcular_ccc_desagregacion (NUEVA)\n")
cat("  ✓ calcular_ccc_detallado (NUEVA)\n")
cat("  ✓ calcular_ccc_temporal (NUEVA)\n")
cat("  ✓ crear_tabla_ccc (NUEVA)\n")

# ------------------------------------------------------------------------------
# FUNCIONES DE PERFILES EPIDEMIOLOGICOS
# ------------------------------------------------------------------------------
cat("\nCargando funciones de perfiles epidemiológicos...\n")
source(file.path(directorio_r, "perfiles", "calcular_perfil_diagnostico.R"))
source(file.path(directorio_r, "perfiles", "comparar_perfiles_po_pg.R"))
source(file.path(directorio_r, "perfiles", "crear_tabla_perfil.R"))
source(file.path(directorio_r, "perfiles", "graficar_perfil_top.R"))
source(file.path(directorio_r, "perfiles", "graficar_diferencias_tasas.R"))
source(file.path(directorio_r, "perfiles", "funciones_patologias.R"))
cat("  ✓ calcular_perfil_diagnostico\n")
cat("  ✓ comparar_perfiles_po_pg\n")
cat("  ✓ crear_tabla_perfil\n")
cat("  ✓ graficar_perfil_top\n")
cat("  ✓ graficar_diferencias_tasas\n")
cat("  ✓ crear_perfil_patologia (NUEVA)\n")
cat("  ✓ comparar_patologias (NUEVA)\n")
cat("  ✓ desglosar_por_subtipo (NUEVA)\n")

# ------------------------------------------------------------------------------
# FUNCIONES DE UTILIDADES
# ------------------------------------------------------------------------------
cat("\nCargando funciones de utilidades...\n")
source(file.path(directorio_r, "utilidades", "concatenar_diag_cie10.R"))
source(file.path(directorio_r, "utilidades", "guardar_tabla_jpg.R"))
source(file.path(directorio_r, "utilidades", "crear_region_nuble.R"))
cat("  ✓ concatenar_diag_cie10\n")
cat("  ✓ guardar_tabla_jpg\n")
cat("  ✓ crear_region_nuble\n")

# ------------------------------------------------------------------------------
# FUNCIONES DE TABLAS
# ------------------------------------------------------------------------------
cat("\nCargando funciones de tablas...\n")
source(file.path(directorio_r, "tablas", "guardar_como_jpg.R"))
source(file.path(directorio_r, "tablas", "guardar_tabla_png.R"))
source(file.path(directorio_r, "tablas", "crear_tabla_resumen_horizontal.R"))
source(file.path(directorio_r, "tablas", "flex_to_df.R"))
source(file.path(directorio_r, "tablas", "save_flex_as_html.R"))
source(file.path(directorio_r, "tablas", "guardar_tabla_html.R"))
cat("  ✓ guardar_como_jpg (PNG/JPG mejorado)\n")
cat("  ✓ guardar_tabla_png (PNG alta calidad - RECOMENDADO)\n")
cat("  ✓ crear_tabla_resumen_horizontal\n")
cat("  ✓ flex_to_df\n")
cat("  ✓ save_flex_as_html\n")
cat("  ✓ guardar_tabla_html\n")
cat("\nFunciones disponibles:\n\n")
cat("GRÁFICOS (13 funciones):\n")
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
cat("  - crear_paleta_disparidad(clasificacion_grupos) [NUEVA]\n")
cat("  - crear_tamanios_linea(clasificacion_grupos) [NUEVA]\n")
cat("  - grafico_evolucion_disparidades(datos, tendencia, pct_ve, ...) [NUEVA]\n")
cat("\nANÁLISIS (10 funciones):\n")
cat("  - analizar_pertenencia(data, var_nombre, var_etiqueta)\n")
cat("  - analizar_pertenencia_sexo(data, var_nombre, var_etiqueta)\n")
cat("  - analizar_variable(data, variable_col, titulo, limite_top)\n")
cat("  - analizar_cie10_top(data, limite_top)\n")
cat("  - analizar_por_sexo(data, variable_col, titulo, limite_top)\n")
cat("  - analizar_variable_solo_po(data, variable_col, titulo, limite_top, n_columnas)\n")
cat("  - calcular_tendencia_pertenencia2(datos) [NUEVA]\n")
cat("  - calcular_pct_variable_enriquecida(datos) [NUEVA]\n")
cat("  - identificar_grupos_disparidad(datos, tendencia, umbral) [NUEVA]\n")
cat("  - generar_resumen_disparidades(datos, pct_ve) [NUEVA]\n")
cat("\nCONCORDANCIA (9 funciones):\n")
cat("  - calcular_concordancia_desctools(datos, col_verdad, col_estimado, nombre_fuente)\n")
cat("  - formatear_resultado_ccc(resultado_ccc, nombre_desagregacion)\n")
cat("  - extraer_datos_censo(conexion, verbose)\n")
cat("  - extraer_datos_variable_enriquecida(datos_homologados, verbose)\n")
cat("  - obtener_poblacion_censo(verbose)\n")
cat("  - calcular_ccc_desagregacion(datos_censo, datos_comparacion, columnas_join, nombre)\n")
cat("  - calcular_ccc_detallado(datos_censo, datos_comparacion, columnas_join, nombre)\n")
cat("  - calcular_ccc_temporal(datos_censo, datos_egresos, col_anio, col_pertenencia)\n")
cat("  - crear_tabla_ccc(datos, titulo, subtitulo, aplicar_colores)\n")
cat("\nPERFILES EPIDEMIOLOGICOS (8 funciones):\n")
cat("  - calcular_perfil_diagnostico(datos, pertenencia, poblacion, total_egresos)\n")
cat("  - comparar_perfiles_po_pg(datos, poblacion_po, poblacion_pg, egresos_po, egresos_pg)\n")
cat("  - crear_tabla_perfil(datos, tipo, titulo)\n")
cat("  - graficar_perfil_top(datos, titulo, subtitulo)\n")
cat("  - graficar_diferencias_tasas(datos, top_n, titulo)\n")
cat("  - crear_perfil_patologia(datos, codigos_base, nombre_patologia) [NUEVA]\n")
cat("  - comparar_patologias(datos, lista_patologias, pob_po, pob_pg) [NUEVA]\n")
cat("  - desglosar_por_subtipo(datos, clasificacion_fn, pob_po, pob_pg) [NUEVA]\n")
cat("\nUTILIDADES (5 funciones):\n")
cat("  - concatenar_diag_cie10(data, col_diag, col_destino, tabla_cie10)\n")
cat("  - cargar_tabla_cie10_espanol(ruta_archivo)\n")
cat("  - concatenar_diag_cie10_tabla(data, tabla_cie10, col_diag, col_destino)\n")
cat("  - guardar_tabla_jpg(tabla_ft, nombre_archivo, dir_salida, vwidth, vheight)\n")
cat("  - crear_region_nuble(datos, col_region, col_comuna, verbose)\n")
cat("\nTABLAS (5 funciones):\n")
cat("  - crear_tabla_resumen_horizontal(data, var_label, etiqueta_variable)\n")
cat("  - flex_to_df(ft)\n")
cat("  - save_flex_as_html(ft, path)\n")
cat("  - guardar_tabla_html(tabla, nombre_archivo)\n")
cat("  - guardar_como_jpg(tabla_ft, nombre_archivo)\n")

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("- TODAS LAS FUNCIONES CARGADAS EXITOSAMENTE (56 funciones)\n")
cat("═══════════════════════════════════════════════════════════════\n\n")
cat("Total: 56 funciones cargadas (100% COMPLETO)\n")
cat("  * Gráficos: 13 funciones (+3 NUEVAS)\n")
cat("  * Análisis: 10 funciones (+4 NUEVAS)\n")
cat("  * Concordancia: 9 funciones\n")
cat("  * Perfiles Epidemiológicos: 8 funciones (+3 NUEVAS)\n")
cat("  * Utilidades: 5 funciones\n")
cat("  * Tablas: 5 funciones\n")
cat("Para más información, consulte: R/README.md\n")
cat("================================================================================\n\n")
