# ==============================================================================
# PALETA DE COLORES CENTRALIZADA DEL PROYECTO
# ==============================================================================
#
# Paleta canonica para todas las visualizaciones y tablas.
# Basada en Material Design, consistente con las figuras principales
# del articulo (forest plot, barras divergentes, heatmap temporal).
#
# USO:
#   source("R/utilidades/paleta_colores.R")
#   # o via source("R/cargar_funciones.R")
#
# ==============================================================================

# --- Pertenencia a Pueblos Originarios vs Poblacion General ---
colores_pertenencia <- c(

  "PO" = "#C62828",
  "PG" = "#1565C0"
)

# Fondos claros para tablas (filas resaltadas)
colores_pertenencia_fondo <- c(
  "PO" = "#FFEBEE",
  "PG" = "#E3F2FD"
)

# --- Sexo ---
colores_sexo <- c(
  "Hombre"  = "#2E86AB",
  "HOMBRE"  = "#2E86AB",
  "Mujer"   = "#A23B72",
  "MUJER"   = "#A23B72"
)

# --- Neutro / sin diferencia ---
color_neutro <- "#757575"

# --- Direccionalidad (para graficos de razon/diferencia) ---
colores_direccion <- c(
  "Mayor PO" = "#C62828",
  "Mayor PG" = "#1565C0"
)
