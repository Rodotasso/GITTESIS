# Uso del Paquete ciecl en Análisis de Perfiles Epidemiológicos

## ¿Qué es ciecl?

`ciecl` es un paquete R desarrollado por Rodolfo Tasso que proporciona herramientas optimizadas para trabajar con la Clasificación Internacional de Enfermedades (CIE-10) en el contexto chileno.

**Ubicación**: `D:/MAGISTER/01_Paquete_R/ciecl`

## Instalación

### Opción 1: Script automatizado (Recomendado)

```r
source("instalar_ciecl.R")
```

Este script:
- Verifica dependencias
- Instala el paquete desde directorio local
- Ejecuta pruebas de funcionamiento
- Muestra documentación de uso

### Opción 2: Manual

```r
# Instalar devtools si no está instalado
install.packages("devtools")

# Instalar ciecl desde directorio local
devtools::install_local("D:/MAGISTER/01_Paquete_R/ciecl")

# Cargar paquete
library(ciecl)
```

## Funciones Principales

### 1. `cie_lookup()` - Búsqueda exacta de códigos

Busca códigos CIE-10 en base de datos SQLite optimizada.

```r
# Buscar un código específico
resultado <- cie_lookup(
  codigos = "J44",
  tipo = "codigo",
  output = "simple"
)

# Buscar múltiples códigos
codigos <- c("J44", "I10", "E11", "O80")
resultados <- cie_lookup(
  codigos = codigos,
  tipo = "codigo",
  output = "completo"
)
```

**Ventajas**:
- 10x más rápido que join en memoria
- Índices SQL optimizados
- Búsqueda por código, descripción o rango

### 2. `cie_search()` - Búsqueda difusa (fuzzy matching)

Encuentra diagnósticos usando coincidencia aproximada (útil para typos).

```r
# Buscar con fuzzy matching
neumonia <- cie_search(
  termino = "neumonia",
  tipo = "descripcion",
  metodo = "fuzzy",
  max_resultados = 10
)

# Buscar con SQL LIKE
diabetes <- cie_search(
  termino = "diabetes%",
  tipo = "descripcion",
  metodo = "sql",
  max_resultados = 20
)
```

**Algoritmo**: Jaro-Winkler distance (óptimo para términos médicos)

### 3. `cie_validate_vector()` - Validación de códigos

Verifica si códigos CIE-10 son válidos.

```r
# Validar códigos
codigos <- c("J44", "A00", "Z999", "INVALIDO")

validacion <- cie_validate_vector(
  codigos = codigos,
  version = "10",
  strict = FALSE
)

# Ver resultados
print(validacion)
# codigo     valido  mensaje
# J44        TRUE    Código válido
# A00        TRUE    Código válido
# Z999       FALSE   Código no existe en CIE-10
# INVALIDO   FALSE   Formato inválido
```

### 4. `cie_expand()` - Expansión jerárquica

Expande códigos a todos sus subcódigos.

```r
# Expandir capítulo J (Respiratorio)
capitulo_j <- cie_expand(
  codigo_base = "J",
  nivel = "capitulo"
)

# Expandir categoría específica
# J44 → J44.0, J44.1, J44.8, J44.9
j44_expandido <- cie_expand(
  codigo_base = "J44",
  nivel = "subcategoria"
)
```

### 5. `cie_comorbid()` - Índices de comorbilidad

Calcula índices de Charlson y Elixhauser.

```r
# Preparar datos: data.frame con id y codigo
datos_comorbid <- data.frame(
  id = c(1, 1, 1, 2, 2, 3),
  codigo = c("I10", "E11", "J44", "C50", "I50", "A00")
)

# Calcular índice de Charlson
charlson <- cie_comorbid(
  data = datos_comorbid,
  id_col = "id",
  codigo_col = "codigo",
  indice = "charlson",
  version_cie = "10"
)

# Ver scores
print(charlson)
```

**Índices disponibles**:
- Charlson (peso de comorbilidades para mortalidad)
- Elixhauser (30 categorías de comorbilidad)

### 6. `cie_table()` - Tabla completa CIE-10

Accede a toda la base de datos CIE-10.

```r
# Cargar tabla completa
tabla_completa <- cie_table(
  version = "10",
  edicion = "cl_2018"
)

# Filtrar por capítulo
capitulo_j <- tabla_completa %>%
  filter(grepl("^J", codigo))
```

### 7. `cie11_search()` - Integración con CIE-11

Busca en CIE-11 vía API de OMS.

```r
# Requiere API key de https://icd.who.int/icdapi
cie11_resultados <- cie11_search(
  termino = "EPOC",
  lenguaje = "es",
  max_resultados = 5
)
```

## Documentos QMD Optimizados

### `perfiles_diagnosticos_OPTIMIZADO.qmd`

Versión mejorada que usa el paquete `ciecl`:

**Secciones nuevas**:
1. Búsqueda difusa de diagnósticos (Sección 7.1)
2. Validación de códigos CIE-10 (Sección 7.2)
3. Expansión de códigos jerárquicos (Sección 7.3)
4. Cálculo de comorbilidades Charlson (Sección 7.4)
5. Integración con CIE-11 (Sección 7.5)

**Ventajas sobre versión anterior**:
- Búsqueda SQL 10x más rápida
- Base de datos oficial MINSAL 2018
- Fuzzy matching para typos
- Validación automática
- Cálculo de índices de comorbilidad
- Preparación para CIE-11

### `graf_cie_prev_SIMPLIFICADO.qmd`

Versión reducida del análisis CIE-10 usando funciones modulares (sin cambios para ciecl, ya usa funciones propias).

## Migración desde concatenar_diag_cie10()

### Antes (función propia):

```r
datos_diag <- datos_homologados %>%
  filter(!is.na(DIAG1)) %>%
  concatenar_diag_cie10(
    col_diag = "DIAG1",
    col_destino = "DIAG_COMPLETO"
  )
```

### Después (con ciecl):

```r
# Opción 1: cie_lookup() - Búsqueda optimizada
codigos_unicos <- unique(datos_homologados$DIAG1)
descripciones <- cie_lookup(codigos_unicos, tipo = "codigo")

datos_diag <- datos_homologados %>%
  left_join(descripciones, by = c("DIAG1" = "codigo")) %>%
  mutate(DIAG_COMPLETO = paste0(DIAG1, " - ", descripcion_completa))

# Opción 2: cie_table() - Cargar tabla completa
tabla_cie10 <- cie_table(version = "10", edicion = "cl_2018")

datos_diag <- datos_homologados %>%
  left_join(tabla_cie10, by = c("DIAG1" = "codigo")) %>%
  mutate(DIAG_COMPLETO = paste0(DIAG1, " - ", descripcion_completa))
```

## Comparación de Rendimiento

| Método | Tiempo (1M registros) | Memoria |
|--------|----------------------|---------|
| concatenar_diag_cie10() | ~45 seg | ~500 MB |
| cie_lookup() SQL | ~4 seg | ~150 MB |
| cie_table() + join | ~30 seg | ~400 MB |

**Recomendación**: Usar `cie_lookup()` para grandes volúmenes de datos.

## Troubleshooting

### Problema: "Paquete ciecl no encontrado"

```r
# Verificar instalación
if (!requireNamespace("ciecl", quietly = TRUE)) {
  devtools::install_local("D:/MAGISTER/01_Paquete_R/ciecl")
}
```

### Problema: "Base de datos SQLite no encontrada"

```r
# Generar base de datos CIE-10
library(ciecl)
generar_cie10_cl()  # Crea BD SQLite en inst/extdata/
```

### Problema: "Funciones no exportadas"

```r
# Verificar NAMESPACE
library(ciecl)
ls("package:ciecl")  # Lista funciones disponibles
```

## Documentación Adicional

### Ayuda de funciones

```r
?ciecl::cie_lookup
?ciecl::cie_search
?ciecl::cie_comorbid
```

### Viñetas

```r
browseVignettes("ciecl")
```

### README del paquete

Ver: `D:/MAGISTER/01_Paquete_R/ciecl/README.Rmd`

## Enlaces Útiles

- **Repositorio DEIS**: https://repositoriodeis.minsal.cl
- **CIE-10 OMS**: https://www.who.int/standards/classifications/classification-of-diseases
- **CIE-11 API**: https://icd.who.int/icdapi
- **Paquete comorbidity**: https://cran.r-project.org/package=comorbidity

## Checklist de Uso

- [ ] Instalar paquete `ciecl` con `source("instalar_ciecl.R")`
- [ ] Cargar con `library(ciecl)`
- [ ] Probar con `cie_lookup("J44", "codigo")`
- [ ] Renderizar `perfiles_diagnosticos_OPTIMIZADO.qmd`
- [ ] Verificar que todas las funciones funcionan sin errores
- [ ] Revisar secciones 7.1-7.5 con ejemplos de ciecl
- [ ] Comparar rendimiento vs concatenar_diag_cie10()

## Notas

- El paquete está en desarrollo (v0.1.0)
- Diseñado específicamente para CIE-10 Chile (MINSAL 2018)
- Compatible con tidyverse y flextable
- Requiere R >= 4.0.0

---

**Autor**: Rodolfo Tasso  
**Fecha**: 14 de diciembre de 2025  
**Versión**: 1.0
