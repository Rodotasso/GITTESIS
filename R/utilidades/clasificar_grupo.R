# ==============================================================================
# FUNCION: clasificar_grupo
# ==============================================================================
# 
# DESCRIPCION:
#   Clasifica códigos CIE-10 en grupos diagnósticos mayores según la letra inicial
#
# PARAMETROS:
#   @param codigo  String con código CIE-10 (ej: "A01", "C50", "J44")
#
# RETORNA:
#   String con nombre del grupo diagnóstico CIE-10
#
# EFECTOS SECUNDARIOS:
#   Ninguno
#
# DEPENDENCIAS:
#   - base::grepl
#
# VARIABLES GLOBALES:
#   Ninguna
#
# ARCHIVO ORIGEN:
#   - BBDD Limpia.qmd (líneas 134-158)
#
# NOTAS:
#   - Clasificación basada en CIE-10 (OMS)
#   - 22 categorías principales + "Otros"
#   - Usa expresiones regulares para patrones
#   - Casos especiales: D0-4 (neoplasias), D5-9 (sangre), H0-1 (ojo), H6-7 (oído)
#
# GRUPOS CIE-10:
#   A-B: Infecciosas y parasitarias
#   C, D0-4: Neoplasias
#   D5-9: Enfermedades de la sangre
#   E: Endocrinos, nutricionales y metabólicos
#   F: Mentales y del comportamiento
#   G: Sistema nervioso
#   H0-1: Ojo y anexos
#   H6-7: Oído y mastoides
#   I: Sistema circulatorio
#   J: Sistema respiratorio
#   K: Sistema digestivo
#   L: Piel y tejido subcutáneo
#   M: Sistema musculoesquelético
#   N: Sistema genitourinario
#   O: Embarazo, parto y puerperio
#   P: Período perinatal
#   Q: Malformaciones congénitas
#   R: Síntomas y signos anormales
#   S-T: Traumatismos y envenenamientos
#   V-Y: Causas externas
#   Z: Factores en estado de salud
#
# EJEMPLO:
#   clasificar_grupo("A09")  # "Enfermedades infecciosas y parasitarias"
#   clasificar_grupo("C50")  # "Neoplasias"
#   clasificar_grupo("J44")  # "Enfermedades del sistema respiratorio"
#   clasificar_grupo("O80")  # "Embarazo, parto y puerperio"
#
# ==============================================================================

clasificar_grupo <- function(codigo) {
  if (grepl("^A|^B", codigo)) return("Enfermedades infecciosas y parasitarias")
  if (grepl("^C|^D[0-4]", codigo)) return("Neoplasias")
  if (grepl("^D[5-9]", codigo)) return("Enfermedades de la sangre y órganos hematopoyéticos")
  if (grepl("^E", codigo)) return("Trastornos endocrinos, nutricionales y metabólicos")
  if (grepl("^F", codigo)) return("Trastornos mentales y del comportamiento")
  if (grepl("^G", codigo)) return("Enfermedades del sistema nervioso")
  if (grepl("^H0|^H1", codigo)) return("Enfermedades del ojo y sus anexos")
  if (grepl("^H6|^H7", codigo)) return("Enfermedades del oído y mastoides")
  if (grepl("^I", codigo)) return("Enfermedades del sistema circulatorio")
  if (grepl("^J", codigo)) return("Enfermedades del sistema respiratorio")
  if (grepl("^K", codigo)) return("Enfermedades del sistema digestivo")
  if (grepl("^L", codigo)) return("Enfermedades de la piel y tejido subcutáneo")
  if (grepl("^M", codigo)) return("Enfermedades del sistema musculoesquelético")
  if (grepl("^N", codigo)) return("Enfermedades del sistema genitourinario")
  if (grepl("^O", codigo)) return("Embarazo, parto y puerperio")
  if (grepl("^P", codigo)) return("Ciertas afecciones originadas en el período perinatal")
  if (grepl("^Q", codigo)) return("Malformaciones congénitas, deformidades y anomalías cromosómicas")
  if (grepl("^R", codigo)) return("Síntomas, signos y hallazgos clínicos anormales")
  if (grepl("^S|^T", codigo)) return("Traumatismos, envenenamientos y otras consecuencias de causas externas")
  if (grepl("^V|^W|^X|^Y", codigo)) return("Causas externas de morbilidad y mortalidad")
  if (grepl("^Z", codigo)) return("Factores que influyen en el estado de salud")
  return("Otros")
}
