# GUÍA PASO A PASO: CONTINUAR EXTRACCIÓN DE FUNCIONES

Esta guía te ayudará a continuar extrayendo las 28 funciones restantes de forma ordenada y eficiente.

---

## 📋 PREPARACIÓN

### Antes de comenzar:

1. **Hacer backup**
   ```powershell
   # Desde la raíz del proyecto
   git add .
   git commit -m "Backup antes de continuar extracción de funciones"
   ```

2. **Verificar funciones ya completadas**
   - ✅ guardar_multiformato
   - ✅ grafico_comparativo_fuentes
   - ✅ analizar_pertenencia

3. **Tener abierto para consulta**
   - `R/README.md` (lista completa de funciones)
   - Archivo .qmd de origen de la función
   - Plantilla de documentación (ver más abajo)

---

## 🔄 PROCESO DE EXTRACCIÓN (REPETIR PARA CADA FUNCIÓN)

### Paso 1: Seleccionar Función

Consulta `R/README.md` y elige la siguiente función pendiente. 

**Recomendación**: Extraer en este orden:
1. Funciones de gráficos (más simples)
2. Funciones de análisis
3. Funciones de tablas
4. Funciones de concordancia/censo/utilidades

### Paso 2: Localizar Función en Archivo Original

Ejemplo para `grafico_tendencia_pertenencia`:

```powershell
# Buscar en el código
grep -n "grafico_tendencia_pertenencia <- function" *.qmd
```

O usar búsqueda en VSCode: `Ctrl+Shift+F`

### Paso 3: Copiar Función Completa

1. Abrir archivo .qmd de origen
2. Localizar la definición: `nombre_funcion <- function(...)`
3. Copiar desde la línea de definición hasta el `}` final
4. **Importante**: Incluir comentarios internos si existen

### Paso 4: Crear Archivo R

Nombre del archivo: `R/<categoria>/<nombre_funcion>.R`

Categorías:
- `graficos/` - Funciones de visualización
- `analisis/` - Funciones de análisis estadístico
- `tablas/` - Funciones de creación/exportación de tablas
- `concordancia/` - Funciones de análisis de concordancia
- `censo/` - Funciones de datos del censo
- `utilidades/` - Funciones auxiliares

### Paso 5: Agregar Documentación

Usar esta plantilla al inicio del archivo:

```r
# ==============================================================================
# FUNCION: <nombre_funcion>
# ==============================================================================
# 
# DESCRIPCION:
#   <Breve descripción de qué hace la función>
#
# PARAMETROS:
#   @param param1  Descripción del parámetro 1
#   @param param2  Descripción del parámetro 2 (default: valor)
#
# RETORNA:
#   <Descripción de qué retorna: objeto, lista, NULL, etc.>
#
# DEPENDENCIAS:
#   - paquete1::funcion1
#   - paquete2::funcion2
#
# VARIABLES GLOBALES:
#   - variable1: Descripción (si requiere alguna variable del entorno)
#
# ARCHIVO ORIGEN:
#   - archivo.qmd
#
# EJEMPLO:
#   resultado <- nombre_funcion(datos, parametro1)
#   print(resultado)
#
# NOTAS:
#   - Nota adicional 1
#   - Nota adicional 2
#
# ==============================================================================

nombre_funcion <- function(param1, param2 = valor_default) {
  # Código de la función...
}
```

### Paso 6: Verificar Dependencias

1. **Identificar paquetes usados** dentro de la función:
   - `filter()`, `group_by()`, `mutate()` → `dplyr`
   - `ggplot()`, `geom_line()` → `ggplot2`
   - `flextable()` → `flextable`
   - etc.

2. **Listar en sección DEPENDENCIAS** del encabezado

3. **Verificar variables globales** (ej: `colores_analisis`)

### Paso 7: Agregar a cargar_funciones.R

Editar `R/cargar_funciones.R`:

```r
# En la sección correspondiente, agregar:
source(file.path(directorio_r, "categoria", "nombre_funcion.R"))
cat("  ✓ nombre_funcion\n")

# Y en el resumen final:
cat("  - nombre_funcion(param1, param2)\n")
```

### Paso 8: Actualizar README.md

En `R/README.md`, cambiar el estado de la función:

```markdown
#### `nombre_funcion()` ~~(PENDIENTE)~~ ✅
- **Archivo**: `categoria/nombre_funcion.R`
- **Origen**: `archivo.qmd`
- **Descripción**: ...
```

Y actualizar el contador en la sección "Estado del Proyecto".

### Paso 9: Probar la Función

Crear bloque de prueba en `TEST_funciones.qmd`:

````markdown
## Prueba: nombre_funcion

```{r prueba_nombre_funcion}
# Probar función
resultado <- nombre_funcion(datos_ordenados, param1)

# Verificar resultado
print(resultado)

# Si es gráfico, mostrarlo
if(inherits(resultado, "ggplot")) {
  print(resultado)
}
```
````

### Paso 10: Ejecutar Prueba

```r
# En R o RStudio
source("R/cargar_funciones.R")
load("BBDD_ordenados.RData")

# Probar función
resultado <- nombre_funcion(datos_ordenados, param1)
```

Si funciona correctamente: ✅ Pasar a la siguiente función

Si hay errores: 🔧 Depurar y corregir

---

## 📊 PLANTILLA DE TRABAJO RÁPIDO

Para trabajar más rápido, usa este checklist:

```
FUNCION: ____________________

□ 1. Localizada en archivo: ________________
□ 2. Copiada completa
□ 3. Archivo R creado en: R/___________/
□ 4. Documentación agregada
□ 5. Dependencias identificadas
□ 6. Agregada a cargar_funciones.R
□ 7. README.md actualizado
□ 8. Prueba agregada a TEST_funciones.qmd
□ 9. Prueba ejecutada: ☐ OK  ☐ ERROR
□ 10. Git commit realizado

NOTAS:
_________________________________
_________________________________
```

---

## 🎯 ORDEN RECOMENDADO DE EXTRACCIÓN

### Prioridad 1: Funciones de Gráficos (Faltantes: 8)

Estas son más simples y no tienen interdependencias complejas:

1. ✅ `guardar_multiformato` (COMPLETADO)
2. ✅ `grafico_comparativo_fuentes` (COMPLETADO)
3. ⏳ `grafico_tendencia_pertenencia`
4. ⏳ `grafico_tendencia_completa`
5. ⏳ `generar_graficos_tendencia_mensual`
6. ⏳ `grafico_prevision_po`
7. ⏳ `grafico_diagnosticos_po`
8. ⏳ `grafico_cie10_po`
9. ⏳ `grafico_evolucion_prevision_po`
10. ⏳ `grafico_promedio_prevision_po`

### Prioridad 2: Funciones de Análisis (Faltantes: 5)

Estas pueden usar las funciones de gráficos:

1. ✅ `analizar_pertenencia` (COMPLETADO)
2. ⏳ `analizar_pertenencia_sexo`
3. ⏳ `analizar_variable`
4. ⏳ `analizar_cie10_top`
5. ⏳ `analizar_por_sexo`
6. ⏳ `analizar_variable_solo_po`

### Prioridad 3: Funciones de Tablas (Faltantes: 5)

Funciones auxiliares de exportación:

1. ⏳ `guardar_como_jpg`
2. ⏳ `crear_tabla_resumen_horizontal`
3. ⏳ `flex_to_df`
4. ⏳ `save_flex_as_html`
5. ⏳ `guardar_tabla_html`

### Prioridad 4: Funciones Especializadas (Faltantes: 6)

Concordancia, censo y utilidades:

1. ⏳ `calcular_concordancia_desctools`
2. ⏳ `formatear_resultado_ccc`
3. ⏳ `extraer_datos_censo`
4. ⏳ `extraer_datos_variable_enriquecida`
5. ⏳ `clasificar_grupo`
6. ⏳ `crear_grafico_tendencia`

---

## ⚡ MODO RÁPIDO (Si tienes experiencia)

Para usuarios avanzados, proceso simplificado:

```powershell
# 1. Crear archivo
New-Item -Path "R/categoria/funcion.R" -ItemType File

# 2. Copiar función + agregar documentación

# 3. Actualizar cargar_funciones.R (agregar source + cat)

# 4. Probar rápido en consola R
source("R/cargar_funciones.R")
resultado <- funcion(datos_ordenados, params)

# 5. Si OK, hacer commit
git add R/
git commit -m "Extraída función: nombre_funcion"
```

---

## 🚨 PROBLEMAS COMUNES Y SOLUCIONES

### Problema 1: "objeto no encontrado"

**Causa**: La función usa variables globales no definidas

**Solución**: 
- Agregar sección VARIABLES GLOBALES en documentación
- Asegurar que `cargar_funciones.R` mencione qué definir antes

### Problema 2: "no se pudo encontrar la función"

**Causa**: Falta cargar un paquete

**Solución**:
- Identificar qué función falta
- Agregar `library(paquete)` en setup del .qmd
- Documentar en sección DEPENDENCIAS

### Problema 3: Función usa otras funciones personalizadas

**Causa**: Dependencias internas entre funciones

**Solución**:
- Extraer función dependiente primero
- Documentar la dependencia
- Asegurar orden correcto en `cargar_funciones.R`

### Problema 4: Errores al ejecutar función extraída

**Causa**: Puede faltar contexto del .qmd original

**Solución**:
- Revisar código antes/después de la función en .qmd
- Buscar variables creadas previamente
- Agregar parámetros si es necesario

---

## 📈 SEGUIMIENTO DE PROGRESO

Mantén actualizado este contador en `R/README.md`:

```markdown
## Estado del Proyecto

### ✅ COMPLETADO (X funciones)
[Lista de funciones completadas]

### 🔄 PENDIENTE (Y funciones)
[Lista de funciones pendientes]
```

---

## 🎓 CONSEJOS FINALES

1. **No te apures**: Mejor hacerlo bien que rápido
2. **Documenta todo**: Tu yo del futuro te lo agradecerá
3. **Prueba siempre**: Cada función debe funcionar antes de continuar
4. **Haz commits frecuentes**: Cada 2-3 funciones extraídas
5. **Pide ayuda si te atascas**: No dudes en consultar documentación

---

## ✨ MOTIVACIÓN

```
Funciones completadas: 3 / 31  [▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░] 10%

¡Ya has completado el 10% del trabajo!
Cada función extraída mejora la calidad de tu código.
¡Sigue así! 💪
```

---

**¡Éxito en la extracción de funciones!**

Recuerda: Este proceso convertirá tu código en algo más profesional, mantenible y reutilizable.

---
