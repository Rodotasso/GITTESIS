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
#   ├── perfiles/          # Funciones de perfiles epidemiológicos
#   ├── utilidades/        # Funciones auxiliares y de propósito general
#   └── funciones/         # Misceláneas NO cargadas por este loader (carga manual)
#
# NOTAS DE CARGA (2026-10-11):
#   - Los 3 scripts de sesgo RSH/CONADI en graficos/ son autocontenidos:
#     verifican paquetes y adjuntan dplyr/readr/tidyr/ggplot2/flextable/
#     patchwork al cargar, pero su main() solo se ejecuta al correrlos
#     directamente (guarda `if (sys.nframe() == 0L)`).
#   - `analisis/generar_tablas_na_y_tbe_regional.R` es un script ejecutable
#     (lee y escribe CSV al cargar): NO se sourcea aquí; se corre con Rscript.
#   - `funciones/` (ordenar_regiones.R, visualizaciones_cie10.R) no las carga
#     este loader: se sourcean manualmente donde se usan.
#
# FECHA CREACION: Enero 2025
# AUTOR: Proyecto GITTESIS
#
# ==============================================================================

# Mensaje de inicio
cat("================================================================================\n")
cat("CARGANDO FUNCIONES PERSONALIZADAS\n")
cat("================================================================================\n\n")

# Obtener directorio base del proyecto (compatible con source() desde cualquier path)
# Primero intenta la ubicación del script (funciona con source("../../R/cargar_funciones.R"))
directorio_base <- tryCatch({
  script_path <- sys.frames()[[1]]$filename
  if (!is.null(script_path) && nzchar(script_path)) {
    normalizePath(file.path(dirname(script_path), ".."), mustWork = FALSE)
  } else {
    getwd()
  }
}, error = function(e) getwd())

directorio_r <- file.path(directorio_base, "R")

# Si no encontró R/ con el path del script, intentar subiendo desde getwd()
if (!dir.exists(directorio_r)) {
  # Buscar raíz subiendo directorios hasta encontrar R/
  dir_actual <- getwd()
  for (i in 1:5) {
    if (dir.exists(file.path(dir_actual, "R"))) {
      directorio_base <- dir_actual
      directorio_r <- file.path(directorio_base, "R")
      break
    }
    dir_actual <- dirname(dir_actual)
  }
}

if (!dir.exists(directorio_r)) {
  stop("ERROR: No se encuentra el directorio R/ en el proyecto.")
}

cat("Directorio base:", directorio_base, "\n")

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
source(file.path(directorio_r, "graficos", "graficos_objetivo4.R"))
# Scripts autocontenidos de sesgo RSH/CONADI: definen funciones y su main()
# queda inerte al sourcear (guarda sys.nframe). Verifican paquetes al cargar.
source(file.path(directorio_r, "graficos", "fig_sesgo_supervivencia_rsh_conadi.R"))
source(file.path(directorio_r, "graficos", "fig_distribucion_enlace_rsh_conadi.R"))
source(file.path(directorio_r, "graficos", "grafico_S6_retencion_pertenencia_conadi_rsh.R"))
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
cat("  ✓ graficos_objetivo4 (NUEVA)\n")
cat("  ✓ fig_sesgo_supervivencia_rsh_conadi (script autocontenido)\n")
cat("  ✓ fig_distribucion_enlace_rsh_conadi (script autocontenido)\n")
cat("  ✓ grafico_S6_retencion_pertenencia_conadi_rsh (script autocontenido)\n")

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
# NOTA: `analisis/generar_tablas_na_y_tbe_regional.R` NO se carga aquí:
# es un script ejecutable (lee fuentes y escribe CSV finales al sourcearse).
# Uso: Rscript R/analisis/generar_tablas_na_y_tbe_regional.R
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
source(file.path(directorio_r, "perfiles", "calcular_top_patologias_desglose.R"))
source(file.path(directorio_r, "perfiles", "calcular_indicadores_protocolo.R"))
source(file.path(directorio_r, "perfiles", "unificar_por_run.R"))
source(file.path(directorio_r, "perfiles", "calcular_indicadores_objetivo4.R"))
source(file.path(directorio_r, "perfiles", "calcular_indicadores_desagregados.R"))
cat("  ✓ calcular_perfil_diagnostico\n")
cat("  ✓ comparar_perfiles_po_pg\n")
cat("  ✓ crear_tabla_perfil\n")
cat("  ✓ graficar_perfil_top\n")
cat("  ✓ graficar_diferencias_tasas\n")
cat("  ✓ crear_perfil_patologia (NUEVA)\n")
cat("  ✓ comparar_patologias (NUEVA)\n")
cat("  ✓ desglosar_por_subtipo (NUEVA)\n")
cat("  ✓ calcular_top_patologias_desglose (NUEVA)\n")
cat("  ✓ crear_tabla_desglose (NUEVA)\n")
cat("  ✓ calcular_indicadores_globales (NUEVA)\n")
cat("  ✓ calcular_indicadores_desagregados (NUEVA)\n")
cat("  ✓ crear_tabla_indicadores (NUEVA)\n")
cat("  ✓ unificar_por_run (NUEVA)\n")
cat("  ✓ calcular_indicadores_objetivo4 (NUEVA)\n")
cat("  ✓ preparar_denominador_estrato\n")
cat("  ✓ calcular_indicadores_estratificados\n")

# ------------------------------------------------------------------------------
# FUNCIONES DE UTILIDADES
# ------------------------------------------------------------------------------
cat("\nCargando funciones de utilidades...\n")
source(file.path(directorio_r, "utilidades", "paleta_colores.R"))
source(file.path(directorio_r, "utilidades", "concatenar_diag_cie10.R"))
source(file.path(directorio_r, "utilidades", "concatenar_diag_ciecl.R"))
source(file.path(directorio_r, "utilidades", "guardar_tabla_jpg.R"))
source(file.path(directorio_r, "utilidades", "crear_region_nuble.R"))
source(file.path(directorio_r, "utilidades", "clasificar_grupo.R"))
source(file.path(directorio_r, "utilidades", "crear_grafico_tendencia.R"))
cat("  ✓ paleta_colores (centralizada)\n")
cat("  ✓ concatenar_diag_cie10\n")
cat("  ✓ concatenar_diag_ciecl (paquete ciecl)\n")
cat("  ✓ guardar_tabla_jpg\n")
cat("  ✓ crear_region_nuble\n")
cat("  ✓ clasificar_grupo\n")
cat("  ✓ crear_grafico_tendencia\n")

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
source(file.path(directorio_r, "tablas", "tabla_indicadores_desagregados.R"))
cat("  ✓ guardar_como_jpg (PNG/JPG mejorado)\n")
cat("  ✓ guardar_tabla_png (PNG alta calidad - RECOMENDADO)\n")
cat("  ✓ crear_tabla_resumen_horizontal\n")
cat("  ✓ flex_to_df\n")
cat("  ✓ save_flex_as_html\n")
cat("  ✓ guardar_tabla_html\n")
cat("  ✓ tabla_indicadores_desagregados\n")
cat("\nFunciones disponibles:\n\n")
cat("GRÁFICOS (17 scripts):\n")
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
cat("  - fig_sesgo_supervivencia_rsh_conadi.R: main() figuras+tabla sesgo (script)\n")
cat("  - fig_distribucion_enlace_rsh_conadi.R: main() Tabla S2 + Figura S3 (script)\n")
cat("  - grafico_S6_retencion_pertenencia_conadi_rsh.R: main() Figura S6 (script)\n")
cat("\nANÁLISIS (10 scripts):\n")
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
cat("\nCONCORDANCIA (10 scripts):\n")
cat("  - calcular_concordancia_desctools(datos, col_verdad, col_estimado, nombre_fuente)\n")
cat("  - formatear_resultado_ccc(resultado_ccc, nombre_desagregacion)\n")
cat("  - extraer_datos_censo(conexion, verbose)\n")
cat("  - extraer_datos_variable_enriquecida(datos_homologados, verbose)\n")
cat("  - obtener_poblacion_censo(verbose)\n")
cat("  - calcular_ccc_desagregacion(datos_censo, datos_comparacion, columnas_join, nombre)\n")
cat("  - calcular_ccc_detallado(datos_censo, datos_comparacion, columnas_join, nombre)\n")
cat("  - calcular_ccc_temporal(datos_censo, datos_egresos, col_anio, col_pertenencia)\n")
cat("  - crear_tabla_ccc(datos, titulo, subtitulo, aplicar_colores)\n")
cat("\nPERFILES EPIDEMIOLOGICOS (11 scripts):\n")
cat("  - calcular_perfil_diagnostico(datos, pertenencia, poblacion, total_egresos)\n")
cat("  - comparar_perfiles_po_pg(datos, poblacion_po, poblacion_pg, egresos_po, egresos_pg)\n")
cat("  - crear_tabla_perfil(datos, tipo, titulo)\n")
cat("  - graficar_perfil_top(datos, titulo, subtitulo)\n")
cat("  - graficar_diferencias_tasas(datos, top_n, titulo)\n")
cat("  - crear_perfil_patologia(datos, codigos_base, nombre_patologia) [NUEVA]\n")
cat("  - comparar_patologias(datos, lista_patologias, pob_po, pob_pg) [NUEVA]\n")
cat("  - desglosar_por_subtipo(datos, clasificacion_fn, pob_po, pob_pg) [NUEVA]\n")
cat("  - unificar_por_run(datos, modo, col_pertenencia, col_ano) [NUEVA]\n")
cat("\nUTILIDADES (7 scripts):\n")
cat("  - concatenar_diag_cie10(data, col_diag, col_destino, tabla_cie10)\n")
cat("  - cargar_tabla_cie10_espanol(ruta_archivo)\n")
cat("  - concatenar_diag_cie10_tabla(data, tabla_cie10, col_diag, col_destino)\n")
cat("  - guardar_tabla_jpg(tabla_ft, nombre_archivo, dir_salida, vwidth, vheight)\n")
cat("  - crear_region_nuble(datos, col_region, col_comuna, verbose)\n")
cat("  - clasificar_grupo(codigo)\n")
cat("  - crear_grafico_tendencia(data, var_label, titulo_variable)\n")
cat("\nTABLAS (7 scripts):\n")
cat("  - crear_tabla_resumen_horizontal(data, var_label, etiqueta_variable)\n")
cat("  - flex_to_df(ft)\n")
cat("  - save_flex_as_html(ft, path)\n")
cat("  - guardar_tabla_html(tabla, nombre_archivo)\n")
cat("  - guardar_como_jpg(tabla_ft, nombre_archivo)\n")

cat("\n═══════════════════════════════════════════════════════════════\n")
cat("- TODOS LOS SCRIPTS CARGADOS EXITOSAMENTE (62 scripts)\n")
cat("═══════════════════════════════════════════════════════════════\n\n")
cat("Total: 62 scripts cargados (100% COMPLETO)\n")
cat("  * Gráficos: 17 scripts (14 de funciones + 3 autocontenidos de sesgo RSH/CONADI)\n")
cat("  * Análisis: 10 scripts\n")
cat("  * Concordancia: 10 scripts\n")
cat("  * Perfiles Epidemiológicos: 11 scripts\n")
cat("  * Utilidades: 7 scripts\n")
cat("  * Tablas: 7 scripts\n")
cat("Carga manual (no las carga este archivo):\n")
cat("  * R/analisis/generar_tablas_na_y_tbe_regional.R (script ejecutable: Rscript)\n")
cat("  * R/funciones/ordenar_regiones.R y R/funciones/visualizaciones_cie10.R\n")
cat("Para más información, consulte: README.md\n")
cat("================================================================================\n\n")
