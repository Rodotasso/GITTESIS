# Discusión integrada Cap.2 + paper SPM — Diseño

**Fecha:** 2026-06-08
**Autor:** Rodolfo Tasso
**Origen:** comentario id=11 de Sandra Flores sobre `Cap2 Resultados y Discusión.docx` ("no corresponde discusión separada; integrar con la del paper en una única discusión final").
**Revierte:** `project_estructura_tesis_final` (que establecía "Cap.2 con discusión propia").

---

## 1. Objetivo

Refundir la discusión del Cap.2 con la del artículo SPM en **una sola discusión final**, en **voz única**, eliminando todo desdoblamiento Cap.1↔Cap.2. El Cap.1 (paper SPM) queda como una "foto" intocable y se anexa íntegro; la discusión integrada vive al cierre del Cap.2. Tras la operación, el Cap.2 queda como **solo Resultados**.

## 2. Operación sobre `Cap2 Resultados y Discusión.docx`

- **Respaldo previo obligatorio:** copia fechada del `.docx` antes de cualquier modificación (ya existe `_DISCUSION_Cap2_respaldo.docx`; generar uno adicional con timestamp).
- **Corte:** eliminar el bloque `Discusión Cap2` (párrafo 52 hasta el final del documento). Los Resultados (párrafos 0–51, Figuras 2.1 a 2.9 y sus subtítulos) quedan **intactos**.
- El bloque cortado es contiguo y separable: no hay dependencias de los Resultados hacia la Discusión.

## 3. Salida: borrador `.md` específico

- **Archivo:** `DOCUMENTOS TESIS/FINAL-TESIS/_DISCUSION_INTEGRADA_borrador.md`
- Citas Vancouver `[@clave]` en texto plano (ver `feedback_citas_vancouver`). El autor maqueta luego al `.docx` final.
- No se redacta directo en el `.docx` ni en `.qmd`: el `.md` es la única superficie de trabajo de la redacción.

## 4. Estructura (5 bloques aprobados)

Sigue el esqueleto de la discusión del paper SPM (`articulo completo FINAL.docx`, párrafos 44–57) y expande el bloque de perfiles con la discusión del Cap.2.

1. **Completitud y calidad del dato** — base copiada del paper SPM.
2. **Mejora de la concordancia por integración de fuentes** — base copiada del paper.
3. **Heterogeneidad regional del CCC** — base copiada del paper.
4. **Perfiles diagnósticos diferenciados** — se inyecta toda la discusión del Cap.2 en una sola voz, expandida en 6 sub-bloques:
   - 4.1 Concentración obstétrica y estructura etaria joven
   - 4.2 Sobrerrepresentación respiratoria y digestiva
   - 4.3 Subrepresentación de enfermedades crónicas y neoplasias
   - 4.4 Letalidad intrahospitalaria menor en población indígena
   - 4.5 Días de estada (salud mental)
   - 4.6 Patrón territorial y sexo × región
   - **Cierre del bloque 4 — nota metodológica reformulada:** justifica el reporte de DPP agregada del periodo completo (pondera cada egreso por su masa), conserva las citas `[@randall2013statistical; @ops2018indicadores]`, **sin** mencionar "el capítulo anterior" ni el desdoblamiento de métricas (deriva del párr. 79).
5. **Fortalezas, limitaciones e implicaciones** — fusión de las fortalezas/limitaciones del paper con las tres líneas de acción de política sanitaria del Cap.2 (párr. 84: sistema único de identificación; programas focalizados; agenda de investigación sobre subrepresentaciones).

## 5. Reglas de redacción

- **Eliminar comparaciones espejo:** frases tipo "+3,6 pp en el capítulo 1", "el mismo patrón en el capítulo anterior" se reescriben reportando **un solo número definitivo** (la DPP agregada del periodo completo, p.ej. +5,57 pp en obstétrico; −1,92 pp en neoplasias).
- **Sustituir "brecha" → DPP / disparidades / diferencias** (ver `feedback_no_guiones_largos` y la regla del repo sobre "brecha"). Limpiar las 4 ocurrencias presentes en los párr. 79 y 84.
- **No usar guiones largos (em-dash):** usar comas, paréntesis u otra puntuación.
- **Eliminar** la nota suelta del párr. 81 ("NO SE SI ESTO TAMBIÉN SE AGREGA… Esto ya es muy loco").

## 6. Agentes especializados y verificación

| Fase | Agente / herramienta | Tarea |
|------|----------------------|-------|
| Mapeo de citas | `deep-research-team/fact-checker` | Mapear citas numéricas del paper SPM (11, 23, 3…) a claves `.bib`; verificar que cada `[@clave]` exista en `referencias_tesis.bib`. |
| Redacción | Academic Writer Spanish / `academic-write` | Redacción en español académico, registro SPM, IMRaD, voz única. |
| Auditoría final | `academic-paper-reviewer` | Auditoría multi-capa (formal, científico, STROBE, editorial, redacción). |

## 7. Guía de referencias para el protocolo (paso final)

- Listar **solo las claves NUEVAS** usadas en la discusión integrada que aún NO estén en la bibliografía del protocolo.
- Comparar las `[@clave]` de la discusión contra la bibliografía actual del protocolo (`Protocolo_Tesis_RTS_v2_20260514.md` / `_BIBLIO_unificada.md`).
- Entregar la guía después de estabilizar las citas de la discusión.

## 8. Archivos fuente

- Discusión paper SPM: `DOCUMENTOS TESIS/FINAL-TESIS/articulo completo FINAL.docx` (párr. 44–57; 5 bloques).
- Discusión Cap.2 a migrar: `DOCUMENTOS TESIS/FINAL-TESIS/Cap2 Resultados y Discusión.docx` (párr. 52–final).
- Bibliografía: `referencias_tesis.bib` + `vancouver-superscript.csl`.
- Estructura tesis: `DOCUMENTOS TESIS/FINAL-TESIS/ESTRUCTURA_TESIS.md`.

## 9. Orden de ejecución

1. Respaldo fechado del `.docx` Cap.2.
2. Extraer texto de las discusiones fuente (paper SPM párr. 44–57; Cap.2 párr. 52–final) a texto plano.
3. `fact-checker`: mapear citas numéricas del paper → claves `.bib`.
4. Redactar `_DISCUSION_INTEGRADA_borrador.md` con los 5 bloques (Academic Writer Spanish).
5. Aplicar reglas de redacción (sin espejo, sin "brecha", sin em-dash, sin párr. 81).
6. `academic-paper-reviewer`: auditoría final; aplicar correcciones.
7. Cortar `Discusión Cap2` del `.docx` (deja solo Resultados).
8. Generar guía de referencias nuevas para el protocolo.
