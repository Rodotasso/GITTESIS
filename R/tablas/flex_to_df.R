# ==============================================================================
# FUNCION: flex_to_df
# ==============================================================================
# 
# DESCRIPCION:
#   Convierte un objeto flextable a data.frame extrayendo el dataset interno
#
# PARAMETROS:
#   @param ft  Objeto flextable a convertir
#
# RETORNA:
#   data.frame con los datos del flextable, o NULL si ft es NULL
#
# EFECTOS SECUNDARIOS:
#   Ninguno
#
# DEPENDENCIAS:
#   - base::as.data.frame
#
# VARIABLES GLOBALES:
#   Ninguna
#
# ARCHIVO ORIGEN:
#   - E_descriptiva2.qmd (línea 470)
#
# NOTAS:
#   - Accede al componente interno: ft$body$dataset
#   - Útil para exportar datos desde flextables
#   - Retorna NULL si el input es NULL (manejo seguro)
#
# EJEMPLO:
#   tabla_flex <- flextable(data.frame(A=1:3, B=4:6))
#   df_recuperado <- flex_to_df(tabla_flex)
#   print(df_recuperado)
#
# ==============================================================================

flex_to_df <- function(ft) {
  if(is.null(ft)) return(NULL)
  return(as.data.frame(ft$body$dataset))
}
