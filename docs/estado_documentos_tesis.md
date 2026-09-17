# Estado de los documentos de tesis

> Mapa de la organización por **estado** de `DOCUMENTOS TESIS/`. Objetivo: saber sin explorar qué documento está vigente, enviado, respaldado, en auditoría, es insumo o es temporal. Ver también `docs/estructura_repositorio.md`.

Reorganización aplicada: 2026-07-16. Criterio: solo se movieron archivos; nada se eliminó. Los documentos abiertos en Word (lock `~$*.docx`) no se movieron. Actualizado 2026-08-30: documento vigente de tesis y materiales de defensa.

---

## Carpetas de estado en `DOCUMENTOS TESIS/`

| Carpeta | Estado | Contenido |
|---|---|---|
| `00_VIGENTE/` | Gobierna el proceso | Orientaciones oficiales MSP V6 (PDF con anexos). |
| `01_ARTICULOS_ENVIADOS/` | Enviado / sometido | Manuscritos SPM y CSP (ambos **rechazados**) y versión sometida a **RPSP (OPS), en revisión**; paquetes de envío por revista: `Envío SPM-20260809T234137Z-1-001.zip`, `Envío CSP-20260809T234158Z-1-001.zip`, `Envío OPS-20260809T234112Z-1-001.zip` (este último contiene `Main document.docx`, `Figura_1-3.eps`, `Pie de figuras.docx`, cuadros y declaraciones RPSP); cartas de sometimiento, declaración de conflicto de intereses, leyendas de figuras/cuadros de los artículos, `17h15 RodolfoTassoSuazo.pdf`. |
| `02_RESPALDOS/` | Superado / respaldo | Backups y versiones previas: `Cap2…BACKUP/PRE_*.docx`, protocolos antiguos, `articulo_SPM_v2.md`, builds `articulo_CSP_*` (pandoc/temp/(1)), `referencias_vancouver.*`, verificaciones y ejemplos previos. |
| `03_AUDITORIAS/` | Reporte de revisión | Auditorías, diffs y recomendaciones: `diagnostico_auditoria_SPM_v2.md`, `Cap2_…REVIEW.md`, `CAMBIOS_PROTOCOLO_vs_SPM_*`, `DIFERENCIAS_VERSION_*`, `RECOMENDACIONES_TESIS.md`, `fixes-cap2-docx.md`, `PROPUESTAS INDICADORES *.docx`. |
| `04_INSUMOS/` | Material de apoyo | Bibliografía (`referencias_tesis.bib`, `.csl`, listados de referencias), datos (`CIE-10.xlsx`, `GES…`, `Becker…`, `DEIS…`), guías/lineamientos de revistas, templates de journal, audios y transcripciones, `INDICADORES_FORMULAS.md`, `UNIDAD_EVENTO_TEMPORAL_INDICADORES.*`, `Presentacion-CongresoPostgrado2025.pptx`. |
| `99_TEMP/` | Temporal / descarte | Scratch a revisar/eliminar: `_tmp_bibkeys.txt`, `Jungle Parade at Dawnv2.wav`. |
| `FINAL-TESIS/` | Área de trabajo activa | Documento final en construcción y sus fuentes vigentes (ver abajo). |

## `FINAL-TESIS/` (área activa)

Documentos **vigentes** en la raíz de `FINAL-TESIS/`:

| Archivo | Rol |
|---|---|
| `Tesis_final_RTS_revSFA_revAAC.docx` | **Documento final de la tesis (VIGENTE desde 2026-08-14)**. Supera a `Tesis_final_para_rev_RTS.docx` (2026-07-17) y a `FUTURO DOC TESIS con updates.docx`. |
| `FUTURO DOC TESIS con updates.docx` | Superado (era el documento final en edición al 2026-07-16). |
| `Presentacion_Defensa_Tesis.pptx` | **Presentación de defensa (vigente)**. 13 slides, estructura IMRaD según orientaciones AFE (resultados descriptivos; interpretación en Discusión I/II). Respaldo previo a reestructura en `temp_read/backup_pptx_defensa/`. |
| `Guion_Defensa_20min.md` / `Guion_Defensa_20min.docx` | **Guión de defensa (vigente)**, 13 secciones D mapeadas 1:1 con la presentación; el .docx se regenera desde el .md con pandoc. Cifras auditadas contra la tesis vigente (2026-08-30). |
| `9_Limitaciones_propuesta.md` | Sección de limitaciones (propuesta; el autor cura la versión que va al docx). |
| `10_Conclusiones_propuesta.md` | Sección de conclusiones (propuesta anclada a hallazgos). |
| `ESTRUCTURA_TESIS.md` | Composición del documento final (Parte 1 + Cap.1 + Cap.2). |
| `ORIENTACIONES_PROCESO_TESIS_AFE_2025.md` | Orientaciones oficiales (versión md). Fuente de las rúbricas en `docs/`. |
| `GUIA_TESIS_COMPLETA.md` | Guía de referencia. |
| `Cap2 Resultados y Discusión_CORREGIDO.docx` | Cap.2 vigente. |
| `articulo completo FINAL2.docx`, `Protocolo_Tesis_RTS_v2_20260514.md`, `Leyendas.docx`, `PROPUESTA_discusion_enriquecida.*`, `PLAN_enriquecimiento_protocolo.md` | Fuentes vigentes de trabajo. |

Subcarpetas de limpieza dentro de `FINAL-TESIS/`:

| Subcarpeta | Contenido |
|---|---|
| `_intermedios/` | Scratch y productos intermedios (`_AUDIT_*`, `_AUDITORIA_*`, `_src_*`, `_DUMP_*`, `_INSERCIONES_*`, `_BIBLIO_*`, `_tmp_*`, `_discusion_tmp_*`, `_DISCUSION_INTEGRADA_borrador.md`). |
| `_respaldos/` | Backups (`_DISCUSION_Cap2_respaldo.docx`, `Cap2…PRE_CORRECCIONES_*.docx`). |

## Reglas de mantenimiento

- Cuando un documento cambie de estado (p. ej. una propuesta pasa a integrarse al docx final), muévelo a la carpeta que corresponda y actualiza esta tabla.
- No mover archivos de bloqueo `~$*.docx`: indican un documento abierto en Word.
- `99_TEMP/` es antesala de borrado: revisar periódicamente y eliminar lo que ya no sirva.
