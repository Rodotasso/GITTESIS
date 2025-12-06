# RESUMEN DE MODULARIZACIÓN DE PERFILES EPIDEMIOLÓGICOS

**Fecha**: 6 de diciembre de 2025  
**Archivo**: perfiles_diagnosticos_modular.qmd  
**Líneas reducidas**: 471 → 330 (~30% reducción)

## FUNCIONES CREADAS (5 nuevas)

### 1. calcular_perfil_diagnostico()
**Ubicación**: `R/perfiles/calcular_perfil_diagnostico.R`  
**Líneas**: 94

**Propósito**: Calcular top N diagnósticos con tasas epidemiológicas

**Parámetros**:
- `datos`: Dataset con DIAG1, DIAG_COMPLETO, PERTENENCIA2
- `pertenencia`: 1 (PO) o 0 (PG)
- `poblacion`: Población del Censo 2017
- `total_egresos`: Total de egresos del grupo
- `anos_estudio`: Años del período (default 13)
- `top_n`: Número de diagnósticos (default 20)
- `min_casos`: Casos mínimos (default 1)
- `verbose`: Mensajes de progreso (default TRUE)

**Retorna**: Tibble con ranking, DIAG_COMPLETO, n_casos, tasa_anual, prop_x1000_egresos, pct_total, pct_acumulado

**Metodología**: Bonita 2006 (persona-años = población × años estudio)

---

### 2. comparar_perfiles_po_pg()
**Ubicación**: `R/perfiles/comparar_perfiles_po_pg.R`  
**Líneas**: 139

**Propósito**: Comparar perfiles epidemiológicos entre PO y PG

**Parámetros**:
- `datos`: Dataset con DIAG1, DIAG_COMPLETO, PERTENENCIA2
- `poblacion_po`: Población PO (Censo 2017)
- `poblacion_pg`: Población PG (Censo 2017)
- `total_egresos_po`: Total egresos PO
- `total_egresos_pg`: Total egresos PG
- `anos_estudio`: Años del período (default 13)
- `min_casos_po`: Casos mínimos en PO (default 100)
- `top_n`: Número de diagnósticos (default 20)
- `ordenar_por`: "dif_tasa" o "rr" (default "dif_tasa")
- `verbose`: Mensajes de progreso (default TRUE)

**Retorna**: Tibble con casos_po, casos_pg, tasa_anual_po, tasa_anual_pg, dif_tasa_anual, rr_crudo, direccion, DIAG_COMPLETO

**Cálculos**:
- `rr_crudo`: tasa_po / tasa_pg (SIN ajuste por edad)
- `direccion`: ↑↑ PO (RR≥1.5), ↑ PO (>1), ↓ PG (<1), ↓↓ PG (≤0.67)

**ADVERTENCIA**: RR crudo sin ajuste por edad

---

### 3. crear_tabla_perfil()
**Ubicación**: `R/perfiles/crear_tabla_perfil.R`  
**Líneas**: 140

**Propósito**: Generar tablas flextable estandarizadas

**Parámetros**:
- `datos`: Output de calcular_perfil_diagnostico() o comparar_perfiles_po_pg()
- `tipo`: "perfil" o "comparacion"
- `titulo`: Título de la tabla
- `resaltar_umbral`: Umbral para resaltar (default NULL)
- `col_umbral`: Columna para umbral (default NULL)
- `color_resaltado`: Color de fondo (default "#E8F4F8")
- `tamano_fuente`: Tamaño de fuente (default 8)

**Modos**:

**tipo="perfil"**:
- Columnas: #, Diagnóstico, N° Egresos, Tasa Anual (x1000 p-a), Proporción (x1000 egresos), % Total, % Acum.
- Resalta filas donde col_umbral > resaltar_umbral
- Font size: 8

**tipo="comparacion"**:
- Columnas: Diagnóstico, Egresos PO, Egresos PG, Tasa PO, Tasa PG, Diferencia (PO-PG), RR crudo, Dir.
- Color automático: Rojo (#FFE6E6) si RR≥1.5, Azul (#E6F5FF) si RR≤0.67
- Font size: 7.5

**Retorna**: Objeto flextable formateado

---

### 4. graficar_perfil_top()
**Ubicación**: `R/perfiles/graficar_perfil_top.R`  
**Líneas**: 72

**Propósito**: Gráfico de barras horizontales para top N diagnósticos

**Parámetros**:
- `datos`: Output de calcular_perfil_diagnostico()
- `titulo`: Título del gráfico
- `subtitulo`: Subtítulo (default NULL)
- `color_barras`: Color de barras (default "#0A2351")
- `mostrar_etiquetas`: Mostrar valores (default TRUE)
- `tamano_etiquetas`: Tamaño etiquetas (default 2.5)
- `caption`: Pie de gráfico (default automático)

**Retorna**: Objeto ggplot2

**Caption automático**: Muestra n total y % del total de egresos

---

### 5. graficar_diferencias_tasas()
**Ubicación**: `R/perfiles/graficar_diferencias_tasas.R`  
**Líneas**: 118

**Propósito**: Gráfico divergente de diferencias de tasas PO vs PG

**Parámetros**:
- `datos`: Output de comparar_perfiles_po_pg()
- `top_n`: Número de diagnósticos (default 15)
- `ordenar_por`: "abs", "positivo" o "negativo" (default "abs")
- `titulo`: Título del gráfico
- `subtitulo`: Subtítulo (default NULL)
- `color_po`: Color PO (default "#C62828" rojo)
- `color_pg`: Color PG (default "#1565C0" azul)
- `mostrar_etiquetas`: Mostrar valores (default TRUE)
- `tamano_etiquetas`: Tamaño etiquetas (default 2.3)

**Retorna**: Objeto ggplot2

**Visualización**: 
- Barras positivas (rojo): Mayor tasa en PO
- Barras negativas (azul): Mayor tasa en PG
- Línea en 0 para referencia

---

## ARCHIVO MODULAR CREADO

**Nombre**: `perfiles_diagnosticos_modular.qmd`  
**Líneas**: 330 (vs 471 original)  
**Reducción**: 141 líneas (~30%)

### Estructura:

1. **Configuración** (setup)
   - Carga de librerías y datos
   - source("R/cargar_funciones.R")

2. **Preparación y Denominadores**
   - Concatenación CIE-10 con descripciones
   - Cálculo de poblaciones Censo 2017
   - Total egresos por grupo
   - Tasas acumuladas y anuales

3. **Estandarización por Edad** (pendiente)
   - Sección con callout-warning
   - Código en eval=FALSE
   - Requiere función extraer_poblacion_censo_edad()

4. **Top 20 Diagnósticos PO**
   - Tabla: calcular_perfil_diagnostico() + crear_tabla_perfil()
   - Gráfico: graficar_perfil_top()

5. **Comparación PO vs PG**
   - Cálculo: comparar_perfiles_po_pg()
   - Tabla: crear_tabla_perfil(tipo="comparacion")
   - Gráfico: graficar_diferencias_tasas()

6. **Resumen**
   - Denominadores
   - Indicadores calculados
   - Análisis generados
   - Funciones utilizadas
   - Limitaciones metodológicas

---

## VERIFICACIÓN

### Test de carga:
```r
source("R/cargar_funciones.R")
# ✓ 46 funciones cargadas (100% COMPLETO)
# ✓ Perfiles Epidemiológicos: 5 funciones (NUEVO)
```

### Funciones verificadas:
- ✓ calcular_perfil_diagnostico
- ✓ comparar_perfiles_po_pg
- ✓ crear_tabla_perfil
- ✓ graficar_perfil_top
- ✓ graficar_diferencias_tasas

---

## VARIABLES DEL ENTORNO

**Del QMD modular**:
- `datos_homologados`: Base original (BBDD_homologados.RData)
- `datos_diag_preparados`: Con DIAG_COMPLETO agregado
- `pob_po`, `pob_pg`: Poblaciones Censo 2017
- `total_egresos_po`, `total_egresos_pg`: Totales de egresos
- `anos_estudio`: 13 (2010-2022)
- `persona_anos_po`, `persona_anos_pg`: Denominadores

**De las funciones**:
- Esperan columnas: DIAG1, DIAG_COMPLETO, PERTENENCIA2
- DIAG_COMPLETO debe estar creado con concatenar_diag_cie10()
- PERTENENCIA2: 1 (PO) o 0 (PG)

---

## ORGANIZACIÓN DE ARCHIVOS

### Archivos modulares (root):
- ✓ `Concord_nuevas_modular.qmd`
- ✓ `perfiles_diagnosticos_modular.qmd` (NUEVO)
- ✓ `E_descriptiva_modular.qmd`
- ✓ `graf_cie_prev_modular.qmd`
- ✓ `grafico_pertenencia_modular.qmd`

### Archivos no modulares (QMD_NO_MODULARES/):
- `Concord_nuevas.qmd`
- `perfiles_diagnosticos.qmd` (MOVIDO)
- `E_descriptiva.qmd`
- `E_descriptiva2.qmd`
- `graf_cie_prev.qmd`
- `grafico_pertenencia.qmd`

### Funciones (R/):
- `R/graficos/` (10 funciones)
- `R/analisis/` (6 funciones)
- `R/concordancias/` (9 funciones)
- `R/perfiles/` (5 funciones - NUEVO)
- `R/utilidades/` (5 funciones)
- `R/tablas/` (5 funciones)

**Total**: 46 funciones

---

## LIMITACIONES DOCUMENTADAS

1. **RR crudos sin ajuste por edad**
   - Explícitamente documentado en funciones
   - Mensaje verbose en comparar_perfiles_po_pg()
   - Callout-warning en sección 3 del QMD

2. **Población fija Censo 2017**
   - No hay proyecciones anuales por pertenencia
   - Denominador constante para todo el período

3. **Sin ajuste por otros confusores**
   - No ajusta por región
   - No ajusta por acceso a salud
   - No ajusta por factores socioeconómicos

4. **Estandarización pendiente**
   - Requiere función extraer_poblacion_censo_edad()
   - Código preparado pero eval=FALSE
   - Documentado como trabajo futuro

---

## PRÓXIMOS PASOS

1. **Implementar estandarización por edad**
   - Crear extraer_poblacion_censo_edad()
   - Activar código en sección 3
   - Calcular RR ajustado por edad

2. **Renderizar y verificar**
   - Probar perfiles_diagnosticos_modular.qmd
   - Verificar tablas y gráficos
   - Comprobar consistencia con versión original

3. **Actualizar documentación**
   - R/README.md con sección perfiles
   - EJEMPLO_USO.md con ejemplos
   - RESUMEN_PROYECTO.md con nuevas funciones

---

**ESTADO**: Modularización completada ✓  
**FUNCIONES**: 5 nuevas funciones operativas ✓  
**QMD MODULAR**: Creado y listo para renderizar ✓  
**TEST**: Todas las funciones cargan correctamente ✓
