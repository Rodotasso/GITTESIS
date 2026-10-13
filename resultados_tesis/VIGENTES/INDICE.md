# Índice de resultados vigentes de tesis

> Carpeta canónica de artefactos que respaldan las cifras del documento de tesis
> vigente y de la presentación de defensa. Es la **única** subcarpeta de
> `resultados_tesis/` que se publica (GitHub/Zenodo); el resto de
> `resultados_tesis/` es material local de trabajo (gitignored).
>
> **Formato de publicación (decisión del autor, 2026-10-11):** solo HTML
> autocontenido (imágenes embebidas) + CSV + este índice. No se publican DOCX
> ni figuras sueltas: las figuras van embebidas en los HTML temáticos.
>
> **Organización por temas de la tesis** (no por lotes de trabajo):
> `concordancia/` (Obj. 1-3, Cap. 1), `indicadores/` (Obj. 4, Cap. 2),
> `perfiles/` (perfiles CIE-10, Cap. 2) y `sesgo_supervivencia/` (anexo de
> sensibilidad RSH/CONADI).
>
> Actualizado: 2026-10-11 (reorganización por temas); 2026-10-13 (incorporación
> de `recalcular_ccc_nuble_corregido.html` a `concordancia/`).

## Tabla de artefactos

| Tema | Figura/Cuadro en docx | Artefacto | Generado por | Fecha | Cifra clave |
|---|---|---|---|---|---|
| concordancia | Tabla 13 (insumo) | `concordancia/ccc_regiones_nuble_corregido.csv` | `analisis/03_concordancia/recalcular_ccc_nuble_corregido.qmd` | 2026-09-13 | CCC Ñuble 0,0766; global 0,7712 |
| concordancia | Tabla 13 (insumo) | `concordancia/kappa_pares_fuentes.csv` | `99_TEMP/fase1_kappa_pares_fuentes.R` (auditoría interna) | 2026-10-04 | Kappa VE×EH 0,694; VE×RSH 0,572; VE×CONADI 0,404 |
| concordancia | Tabla 13 (insumo) | `concordancia/kappa_eh_conadi_anio_condicion.csv` | `99_TEMP/fase1_kappa_pares_fuentes.R` (auditoría interna) | 2026-10-04 | Kappa EH×CONADI por año y condición de egreso |
| concordancia | Tabla 13 y CCC | `concordancia/Concord_nuevas_modular.html` | `analisis/03_concordancia/Concord_nuevas_modular.qmd` | 2026-10-11 | CCC global 0,7712; verificado sin valores obsoletos (0,0897/0,7647) |
| concordancia | Figura 5 (tendencias por fuente) | `concordancia/grafico_pertenencia_modular.html` | `analisis/02_tendencias/grafico_pertenencia_modular.qmd` | 2026-10-11 | Tendencia de pertenencia según fuente (regenerado F2) |
| concordancia | Tabla 13 (trazabilidad) | `concordancia/recalcular_ccc_nuble_corregido.html` | `analisis/03_concordancia/recalcular_ccc_nuble_corregido.qmd` | 2026-09-13 | Recálculo CCC con mapeo Ñuble corregido; CCC Ñuble 0,0766; tabla publicados vs recalculados |
| indicadores | Insumo Fig. 12 y TBE regional | `indicadores/tbe_regional_sexo_po.csv` | `analisis/05_perfiles_cie10/perfiles_diagnosticos_desagregados.qmd` | 2026-09-28 | TBE por región, sexo y grupo; usa censo de Ñuble corregido (2026-09-13) |
| indicadores | TLI ajustada | `indicadores/tli_ajustada_edad_capitulo_indirecto.csv` | `analisis/05_perfiles_cie10/tli_ajustada_edad.qmd` | 2026-09-28 | TLI ajustada por edad, método indirecto, por capítulo CIE-10 |
| indicadores | Tabla TBE regional | `indicadores/tabla_tbe_regional.csv` | `R/analisis/generar_tablas_na_y_tbe_regional.R` | 2026-10-12 | TBE anual x 1.000 hab.; Ñuble PI 32,9 / PG 71,4 (denominador PG = base respondedores INE, p16 IN (1,2)) |
| indicadores | Tabla de NA de pertenencia | `indicadores/tabla_na_pertenencia_consolidada.csv` | `R/analisis/generar_tablas_na_y_tbe_regional.R` | 2026-09-29 | NA de pertenencia: 104.326 de 20.957.004 egresos (0,50%) |
| indicadores | Cuadro 3 | `indicadores/cuadro_descriptivo_egresos.html` | `analisis/00_descriptivos/cuadro_descriptivo_egresos.qmd` | 2026-10-11 | Descriptivo de egresos por paciente único (regenerado F2) |
| indicadores | Descriptiva general | `indicadores/E_descriptiva_modular.html` | `analisis/01_descriptivos/E_descriptiva_modular.qmd` | 2026-10-11 | Estadística descriptiva general (regenerado F2) |
| indicadores | Indicadores Cap. 2 | `indicadores/indicadores_epidemiologicos.html` | `analisis/05_perfiles_cie10/indicadores_epidemiologicos.qmd` | 2026-10-11 | TBE/TLI/PEC/PDE por capítulo (regenerado F2) |
| indicadores | Figura 12 (análisis) | `indicadores/fig12_heatmap_tbe_capitulo_region.html` | `analisis/05_perfiles_cie10/fig12_heatmap_tbe_capitulo_region.qmd` | 2026-10-11 | Heatmap TBE región x capítulo con trazabilidad (regenerado F2) |
| indicadores | Figuras 10, 11, 12 y 13 | `indicadores/figuras_tesis_indicadores.html` | `analisis/05_perfiles_cie10/figuras_tesis_indicadores.qmd` (compañero de publicación) | 2026-10-11 | Figuras del docx embebidas con pies exactos |
| perfiles | CIE-10 por previsión | `perfiles/graf_cie_prev_modular.html` | `analisis/04_sociodemografico/graf_cie_prev_modular.qmd` | 2026-10-11 | Distribución CIE-10 por tramo de previsión (regenerado F2) |
| perfiles | Figuras 7, 8, 9 y S1 | `perfiles/figuras_tesis_perfiles.html` | `analisis/05_perfiles_cie10/figuras_tesis_perfiles.qmd` (compañero de publicación) | 2026-10-11 | Figuras del docx embebidas con pies exactos |
| sesgo_supervivencia | Tabla S2 | `sesgo_supervivencia/tabla_distribucion_enlace.csv` | `R/graficos/fig_distribucion_enlace_rsh_conadi.R` | 2026-09-19 | Tasa de enlace por sexo, grupo etario y región (enlace único RSH/CONADI) |
| sesgo_supervivencia | Tabla resumen enlace | `sesgo_supervivencia/tabla_enlace_por_condicion_egreso.csv` | `R/graficos/fig_sesgo_supervivencia_rsh_conadi.R` | 2026-09-19 | Serie anual de enlace por condición de egreso |
| sesgo_supervivencia | Figuras 2, 3, S2 y S6 | `sesgo_supervivencia/figuras_sesgo_supervivencia.html` | `analisis/03_concordancia/figuras_sesgo_supervivencia.qmd` (compañero de publicación) | 2026-10-11 | Figuras del anexo embebidas con pies exactos; S6: CONADI retiene 56-89%, RSH 0-17% en fallecidos enlazados |

Notas de asignación temática (HTML regenerados en F2, redistribuidos desde la
antigua carpeta `html/`): `grafico_pertenencia_modular.html` va en
`concordancia/` por tratar las fuentes de pertenencia (Cap. 1);
`cuadro_descriptivo_egresos.html`, `E_descriptiva_modular.html`,
`indicadores_epidemiologicos.html` y `fig12_heatmap_tbe_capitulo_region.html`
van en `indicadores/` (Cap. 2); `graf_cie_prev_modular.html` va en `perfiles/`
(CIE-10). El HTML `concordancia/recalcular_ccc_nuble_corregido.html`
(2026-09-13) se incorporó a VIGENTES el 2026-10-13 (copia desde
`analisis/03_concordancia/`, que conserva el original): documenta la cifra
vigente de la tesis (CCC Ñuble 0,0766) y es la trazabilidad legible de
`concordancia/ccc_regiones_nuble_corregido.csv`.

## Notas de exclusión

Decisiones del autor registradas el 2026-10-11:

- **CSV de loteC (Anexo 4 etario/regional): excluidos de la publicación.** El
  correctivo del denominador PG (~3,3%) fue APROBADO y APLICADO el 2026-10-12:
  los CSV de `resultados_tesis/indicadores_epidemiologicos/anexo4_etario/`
  fueron regenerados con denominador PG = base oficial INE de respondedores
  (p16 IN (1,2); verificación dif = 0 por grupo etario). Permanecen fuera de
  VIGENTES solo por la decisión de publicación del autor, no por el correctivo.
  Reubicados localmente en
  `resultados_tesis/indicadores_epidemiologicos/anexo4_etario/` (3 CSV +
  `pli_cruda_vs_ajustada.jpg`); los scripts generadores y QMD de respaldo
  quedaron en `archivo/loteC_20260922/` y los HTML de respaldo (cifras
  pre-correctivo) en `archivo/html_precorreccion/loteC/`.
- **DOCX fuera de la publicación** (regla: solo HTML autocontenido + CSV):
  `Tabla_13_Concordancias.docx` y `Cuadro_3_Descriptivo_Egresos.docx`
  (originales en `resultados_tesis/final_resultados/`) y
  `Tabla_1_Fuentes_Unificada.docx` (original en
  `analisis/01_descriptivos/resultados_tesis/final_resultados/`; proviene de
  ruta alterna y su vigencia queda pendiente de verificar).
- **Material del artículo SPM fuera:** Cuadros I, IIA y IIB y las figuras
  `Figura_*_REVISTA`, `Figura_4B_heatmap` y `Figura_4E_forest_heatmap`
  (pipeline del artículo, pre-corrección, may-2026). Originales intactos en
  `resultados_tesis/final_resultados/`.
- **Figuras sueltas fuera:** la carpeta `figuras_tesis/` y los PNG/JPG sueltos
  de `sesgo_supervivencia/` se retiraron de VIGENTES; las figuras se publican
  embebidas en los HTML temáticos. Originales intactos en
  `DOCUMENTOS TESIS/FINAL-TESIS/figuras_nuevas/salida/` y
  `resultados_tesis/sesgo_supervivencia/`.

## Carpeta `html/`

Disuelta el 2026-10-11: con la reorganización por temas, sus 7 HTML regenerados
en F2 se redistribuyeron a `concordancia/`, `indicadores/` y `perfiles/`
(ver notas de asignación temática). Ya no existe como subcarpeta de VIGENTES.

## Advertencia conocida

**Resuelta el 2026-10-11.** Las 7 figuras con supuesto fondo magenta no estaban
corruptas en sus pixeles: eran JPEG codificados en espacio RGB (marcador APP14
Adobe, componentes R,G,B) escritos por el device JPEG de ggsave; los
decodificadores que ignoran APP14 los mostraban con colores invertidos
(magenta/verde). Se regeneraron desde sus QMD fuente con el workaround sano
(PNG nativo + conversión a JPEG YCbCr estándar vía magick, implementado en
`DOCUMENTOS TESIS/FINAL-TESIS/figuras_nuevas/scripts/guardar_multiformato.R`).
Los 8 archivos de `figuras_nuevas/salida/` quedaron verificados a nivel de
archivo (sin APP14, componentes 1,2,3) y visualmente (fondo blanco, paleta
correcta). Los originales quedan respaldados como `*_OLD.jpg` en la misma
carpeta.

Nota de mapeo: la **Figura 7** del docx (dos paneles: IC95% + evolución
temporal) se embebe desde `resultados_tesis/final_resultados/Figura_3E_forest_heatmap.jpg`,
que es la imagen que calza con su pie. `figura_3_brecha_divergente.jpg`
(regenerada limpia) es un panel único sin IC y queda en `salida/` sin embeber,
pendiente de confirmación del autor sobre su rol en el documento.
