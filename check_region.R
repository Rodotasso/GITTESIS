load("BBDD_homologados.RData")
cat("\n=== VALORES UNICOS DE CODIGO_REGION ===\n")
regiones_unicas <- sort(unique(datos_homologados$CODIGO_REGION))
print(regiones_unicas)
cat("\nTotal regiones:", length(regiones_unicas), "\n")

cat("\n=== DISTRIBUCION POR REGION ===\n")
tabla_regiones <- table(datos_homologados$CODIGO_REGION, datos_homologados$NOMBRE_REGION)
print(tabla_regiones)

cat("\n=== RESUMEN ===\n")
if(16 %in% regiones_unicas) {
  cat("✓ La base YA incluye region 16 (Ñuble)\n")
} else {
  cat("✗ La base NO incluye region 16 (Ñuble separada)\n")
  cat("  Ñuble probablemente está dentro de region 8 (Biobío)\n")
}
