# Análisis de Diferencias en Valores de Cohen's Kappa

**Fecha**: 9 de diciembre de 2025  
**Archivos Comparados**:
- Versión Modular: `Concord_nuevas_modular.qmd`
- Versión No Modular: `QMD_NO_MODULARES/Concord_nuevas.qmd`

---

## 🎯 Resumen Ejecutivo

Se identificaron diferencias en la implementación de la función `calcular_concordancia_desctools()` entre las versiones modular y no modular. **La diferencia clave es un filtro adicional de valores NA en la versión modular que podría resultar en valores de kappa diferentes.**

---

## 📊 Comparación de Implementaciones

### 1. Preparación de Datos (IDÉNTICA en ambas versiones)

Ambas versiones usan exactamente el mismo código para preparar los datos:

```r
datos_kappa <- datos_homologados %>%
  select(PERTENENCIA2, RSH, CONADI, PUEBLO_ORIGINARIO_BIN) %>%
  mutate(
    RSH = ifelse(is.na(RSH), 0, RSH),
    CONADI = ifelse(is.na(CONADI), 0, CONADI),
    Egresos_Hospitalarios = ifelse(is.na(PUEBLO_ORIGINARIO_BIN), 0, PUEBLO_ORIGINARIO_BIN)
  ) %>%
  filter(!is.na(PERTENENCIA2))
```

**Nota**: Ambas versiones:
- ✅ Usan los mismos datos (`datos_homologados` - sin eliminar duplicados)
- ✅ Aplican las mismas transformaciones
- ✅ Filtran NA en PERTENENCIA2

---

### 2. Función de Cálculo (DIFERENTE)

#### Versión NO MODULAR (definida inline)

```r
calcular_concordancia_desctools <- function(datos, col_verdad, col_estimado, nombre_fuente) {
  # DescTools::CohenKappa requiere una tabla de contingencia o dos vectores
  resultado_kappa <- CohenKappa(
    x = datos[[col_verdad]], 
    y = datos[[col_estimado]],
    conf.level = 0.95
  )
  
  valor_kappa <- resultado_kappa["kappa"]
  ic_inferior <- resultado_kappa["lwr.ci"]
  ic_superior <- resultado_kappa["upr.ci"]
  
  tibble(
    `Fuente de Datos` = nombre_fuente,
    `Concordancia con Variable Enriquecida` = "Cohen's Kappa",
    `Valor Kappa` = round(valor_kappa, 4),
    `IC 95% Inf` = round(ic_inferior, 4),
    `IC 95% Sup` = round(ic_superior, 4),
    `Interpretación (Landis & Koch)` = case_when(
      valor_kappa < 0.00 ~ "Pobre",
      valor_kappa < 0.20 ~ "Leve",
      valor_kappa < 0.40 ~ "Aceptable",
      valor_kappa < 0.60 ~ "Moderada",
      valor_kappa < 0.80 ~ "Sustancial",
      TRUE ~ "Casi Perfecta"
    )
  )
}
```

**Características**:
- ❌ Sin validación de columnas
- ❌ Sin filtro adicional de NA
- ⚠️ Asume que los datos están limpios

---

#### Versión MODULAR (R/concordancias/calcular_concordancia_desctools.R)

```r
calcular_concordancia_desctools <- function(datos, col_verdad, col_estimado, nombre_fuente) {
  
  # Verificar que las columnas existen
  if (!col_verdad %in% names(datos)) {
    stop("La columna '", col_verdad, "' no existe en los datos")
  }
  if (!col_estimado %in% names(datos)) {
    stop("La columna '", col_estimado, "' no existe en los datos")
  }
  
  # ⚠️ DIFERENCIA CLAVE: Filtrar NAs si existen
  if (any(is.na(datos[[col_verdad]])) || any(is.na(datos[[col_estimado]]))) {
    warning("Hay valores NA en las columnas. Se filtrarán automáticamente.")
    datos <- datos %>% 
      filter(!is.na(.data[[col_verdad]]), !is.na(.data[[col_estimado]]))
  }
  
  # DescTools::CohenKappa requiere una tabla de contingencia o dos vectores
  resultado_kappa <- DescTools::CohenKappa(
    x = datos[[col_verdad]], 
    y = datos[[col_estimado]],
    conf.level = 0.95
  )
  
  valor_kappa <- resultado_kappa["kappa"]
  ic_inferior <- resultado_kappa["lwr.ci"]
  ic_superior <- resultado_kappa["upr.ci"]
  
  # Crear tibble con resultados
  tibble::tibble(
    `Fuente de Datos` = nombre_fuente,
    `Concordancia con Variable Enriquecida` = "Cohen's Kappa",
    `Valor Kappa` = round(valor_kappa, 4),
    `IC 95% Inf` = round(ic_inferior, 4),
    `IC 95% Sup` = round(ic_superior, 4),
    `Interpretación (Landis & Koch)` = dplyr::case_when(
      valor_kappa < 0.00 ~ "Pobre",
      valor_kappa < 0.20 ~ "Leve",
      valor_kappa < 0.40 ~ "Aceptable",
      valor_kappa < 0.60 ~ "Moderada",
      valor_kappa < 0.80 ~ "Sustancial",
      TRUE ~ "Casi Perfecta"
    )
  )
}
```

**Características**:
- ✅ Validación de columnas
- ✅ **Filtro adicional de NA (líneas 42-46)**
- ✅ Namespace explícito (`DescTools::`, `tibble::`, `dplyr::`)
- ✅ Más robusto y defensivo

---

## 🔍 ¿Por Qué Podrían Diferir los Valores de Kappa?

### Causa Principal: Filtro Adicional de NA

La versión modular tiene este código adicional:

```r
if (any(is.na(datos[[col_verdad]])) || any(is.na(datos[[col_estimado]]))) {
  warning("Hay valores NA en las columnas. Se filtrarán automáticamente.")
  datos <- datos %>% 
    filter(!is.na(.data[[col_verdad]]), !is.na(.data[[col_estimado]]))
}
```

**Problema**: Este filtro es **redundante** porque la preparación de datos ya convierte los NA en 0:

```r
# En la preparación de datos (ambas versiones):
RSH = ifelse(is.na(RSH), 0, RSH),
CONADI = ifelse(is.na(CONADI), 0, CONADI),
Egresos_Hospitalarios = ifelse(is.na(PUEBLO_ORIGINARIO_BIN), 0, PUEBLO_ORIGINARIO_BIN)
```

**Conclusión**: Si después de la conversión `NA → 0` todavía existen NA en las columnas, entonces:
- **Versión NO Modular**: Los incluye en el cálculo (posiblemente causando error)
- **Versión Modular**: Los filtra antes del cálculo

---

## ✅ Verificación

### Escenario 1: No hay NA después de la preparación

Si `datos_kappa` no tiene NA después de aplicar `ifelse(is.na(...), 0, ...)`, entonces:

```
Versión NO Modular: N registros
Versión Modular: N registros (sin filtrar nada)
→ Kappa values IDÉNTICOS ✅
```

### Escenario 2: Hay NA residuales

Si después de la preparación todavía existen NA (por ejemplo, en PERTENENCIA2):

```
Versión NO Modular: N registros (con NA)
Versión Modular: N - K registros (filtró K registros con NA)
→ Kappa values DIFERENTES ❌
```

---

## 🎓 Recomendaciones

### 1. Para Entender las Diferencias

Ejecuta este código en ambas versiones para verificar:

```r
# Después de preparar datos_kappa
cat("Registros totales:", nrow(datos_kappa), "\n")
cat("NA en PERTENENCIA2:", sum(is.na(datos_kappa$PERTENENCIA2)), "\n")
cat("NA en RSH:", sum(is.na(datos_kappa$RSH)), "\n")
cat("NA en CONADI:", sum(is.na(datos_kappa$CONADI)), "\n")
cat("NA en Egresos_Hospitalarios:", sum(is.na(datos_kappa$Egresos_Hospitalarios)), "\n")
```

### 2. Para Resolver las Diferencias

**Opción A: Usar la Versión Modular (RECOMENDADO)**

Es más robusta y tiene validaciones adicionales.

**Opción B: Alinear la Versión No Modular**

Agregar el mismo filtro de NA en la versión no modular:

```r
calcular_concordancia_desctools <- function(datos, col_verdad, col_estimado, nombre_fuente) {
  
  # Agregar este bloque:
  if (any(is.na(datos[[col_verdad]])) || any(is.na(datos[[col_estimado]]))) {
    warning("Hay valores NA en las columnas. Se filtrarán automáticamente.")
    datos <- datos %>% 
      filter(!is.na(.data[[col_verdad]]), !is.na(.data[[col_estimado]]))
  }
  
  # Resto del código igual...
}
```

**Opción C: Remover el Filtro de la Versión Modular**

Si estás seguro de que no hay NA después de la preparación, puedes remover el filtro de la función modular para que coincida con la no modular.

### 3. Para tu Tesis

**Reporta**:
- Qué versión usaste (modular recomendada)
- Número de registros incluidos en el análisis
- Si se filtraron NA adicionales y cuántos

**Texto sugerido**:

> "Se calculó el coeficiente Kappa de Cohen utilizando DescTools::CohenKappa() con intervalo de confianza del 95% calculado mediante error estándar asintótico (Fleiss et al., 2003). Los valores NA fueron convertidos a 0 durante la preparación de datos. Se analizaron [N] registros para cada comparación."

---

## 📋 Resumen de Diferencias

| Aspecto | Versión NO Modular | Versión Modular |
|---------|-------------------|-----------------|
| **Fuente de datos** | `datos_homologados` | `datos_homologados` |
| **Preparación** | Convierte NA → 0 | Convierte NA → 0 |
| **Filtro adicional NA** | ❌ No | ✅ Sí (dentro de función) |
| **Validación columnas** | ❌ No | ✅ Sí |
| **Namespace explícito** | ❌ No | ✅ Sí |
| **Documentación** | ❌ No | ✅ Sí (roxygen2) |
| **¿Kappa igual?** | Depende de si hay NA residuales | |

---

## 🔧 Próximos Pasos

1. **Verificar**: Ejecutar ambas versiones y comparar:
   - Número de registros usados
   - Valores de kappa obtenidos
   - Presencia de warnings sobre NA

2. **Decidir**: Si hay diferencias, elegir qué versión usar:
   - **Modular**: Más robusta, recomendada
   - **No Modular**: Más simple, pero menos validación

3. **Documentar**: Reportar en tu tesis qué versión usaste y por qué

---

## 📚 Referencias

- Fleiss, J. L., Levin, B., & Paik, M. C. (2003). *Statistical methods for rates and proportions* (3rd ed.). John Wiley & Sons.
- Cohen, J. (1960). A coefficient of agreement for nominal scales. *Educational and Psychological Measurement*, 20(1), 37-46.
- Landis, J. R., & Koch, G. G. (1977). The measurement of observer agreement for categorical data. *Biometrics*, 33(1), 159-174.

---

**Conclusión**: Las diferencias en los valores de kappa (si existen) se deben al **filtro adicional de NA** en la versión modular. Ambas versiones deberían dar resultados idénticos si no hay NA residuales después de la preparación de datos.
