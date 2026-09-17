# Cap2 — Correcciones gráficas y de tabla (revisión Sandra)

Fecha: 2026-06-04
Estado: aprobado por el autor (2026-06-04)

## Contexto

El capítulo 2 (Perfiles diagnósticos CIE-10, Objetivo 4) recibió 12 comentarios de
Sandra Flores Alvarado sobre `DOCUMENTOS TESIS/FINAL-TESIS/Cap2 Resultados y Discusión.docx`
(fechas 2026-05-29). Las correcciones de texto/tabla ya se aplicaron en el .docx en una
sesión previa; quedaron diferidas las correcciones **gráficas**, que requieren regenerar
las figuras desde los QMD. Este spec cubre exactamente esas correcciones gráficas más la
modificación de la tabla maestra.

Las figuras del .docx (2.1–2.9) provienen de dos QMD:
- `analisis/05_perfiles_cie10/perfiles_diagnosticos_objetivo4.qmd` → Fig 2.1–2.5 + tabla maestra.
- `analisis/05_perfiles_cie10/perfiles_diagnosticos_desagregados.qmd` → Fig 2.6–2.9.

## Mapa autoritativo comentario → objeto → acción

| Comentario (anclaje) | Objeto | Acción |
|----------------------|--------|--------|
| id=3 "¿por qué brechas solo para PEC?" | Columna DPP/BPP de la tabla maestra | Eliminar columna; reordenar por PEC_PI desc |
| id=2 estilo de tablas | Tabla maestra y estratificadas | Estilo único: solo líneas horizontales (`theme_booktabs`), negrita solo en encabezado |
| id=4 juntar 2.1 y 2.2 | Fig 2.1 + 2.2 (top causas PI/PG) | Consolidar en una figura de 2 paneles (patchwork), título no redundante, etiquetas de causas más grandes |
| id=5/id=6 subtítulo cortado + leyenda azul + abreviación | Fig 2.3 (divergente DPP) | Eliminar la figura por completo (queda resuelto al borrarla) |
| id=9 panel 2 columnas | Fig 2.7 (disparidades por edad) | Faceta a `ncol = 2`, etiquetas de diagnósticos más grandes, tamaño página completa |
| id=10 equivalente en población general | Fig 2.9 (TBE región×sexo en PI) | Añadir figura/panel gemelo para población general |

## Decisiones tomadas

1. **Alcance del "quitar DPP":** se limita a (a) la columna DPP/BPP de la tabla maestra del
   objetivo4 y (b) la Figura 2.3 divergente. Las figuras de sobre/subrepresentación por
   sexo (2.6) y edad (2.7) SE MANTIENEN — son los hallazgos sustantivos y Sandra pidió
   conservarlas (id=8) y mejorarlas (id=9). `BPP` se conserva en
   `calcular_indicadores_estratificados` (lo consumen 2.6/2.7); se elimina solo de
   `calcular_indicadores_objetivo4`.
2. **Consolidación 2.1+2.2:** dos paneles lado a lado (patchwork), conservando el orden
   propio de cada grupo.
3. **"Gráfico de brecha por sexo":** es la Figura 2.9. Recibe una versión equivalente para
   población general para comparar el patrón mujer-hombre entre PI y PG.
4. **Scatter Fig 2.5 (PEC vs TLI):** sin comentario de Sandra, pero el autor reporta leyenda
   cortada; se corrige el recorte de la leyenda al regenerar.

## Cambios por archivo

### `R/graficos/graficos_objetivo4.R`
- Nueva función `grafico_barras_top_pec_panel(datos_obj4, top_n = 10)`: construye los dos
  top-N (PI y PG) reutilizando la lógica actual y los une con `patchwork` (2 paneles), con
  título común no redundante, subtítulo por panel y `axis.text.y` ampliado.
- `grafico_cuadrantes_severidad()`: ajustar leyenda para que no se corte (posición/filas,
  márgenes); coordinar con dimensiones de exportación.
- `grafico_divergente_bpp()`: queda sin uso; se conserva la definición o se marca como
  deprecada (no se elimina para no romper otros QMD que pudieran referenciarla).

### `R/perfiles/calcular_indicadores_objetivo4.R`
- `calcular_indicadores_objetivo4()`: eliminar el cálculo y ensamblado de `BPP`.
- `crear_tabla_maestra_perfiles()`: quitar `BPP` de select/header/color/bold; ordenar por
  `PEC_PI` desc; verificar estilo `theme_booktabs` + negrita solo encabezado.

### `analisis/05_perfiles_cie10/perfiles_diagnosticos_objetivo4.qmd`
- Reemplazar las dos celdas de barras (Fig 1/2) por una sola que llame a la nueva función.
- Eliminar la sección "Gráfico Divergente de Brechas (BPP)" (Fig 3) y su prosa.
- Renumerar referencias de figuras en la prosa según corresponda.

### `analisis/05_perfiles_cie10/perfiles_diagnosticos_desagregados.qmd`
- `graficar_disparidades_facet()` (definida inline, línea 68): aceptar `ncol` y usarlo para
  la figura de edad (2 columnas); ampliar `axis.text`.
- Sección 6 (Fig 2.9, ggplot inline): añadir versión equivalente de TBE región×sexo para
  población general (panel o figura gemela), exportada con `guardar_multiformato`/equivalente.

## Verificación

- Regenerar cada figura/tabla afectada ejecutando las celdas pertinentes sobre la BBDD real.
- Revisión visual: leyenda completa en scatter; 2 paneles consolidados con etiquetas legibles;
  edad en 2 columnas a página completa; figura gemela PG presente y comparable.
- No se modifican objetivos del protocolo. No hay commits/push sin OK explícito del autor.

## Fuera de alcance

- Ediciones de texto en el .docx (id=0, id=1, id=7, id=11): ya aplicadas o manuales en Word.
- Numeración "Tabla 5.2.n" en el documento (decisión editorial del autor en Word).
