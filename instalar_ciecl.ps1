# ==============================================================================
# SCRIPT: Instalación del Paquete ciecl desde PowerShell
# ==============================================================================
# 
# USO: .\instalar_ciecl.ps1
# O desde R: source("instalar_ciecl.R")
#
# ==============================================================================

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  INSTALACIÓN DEL PAQUETE ciecl" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Ruta al paquete local
$rutaCiecl = "D:\MAGISTER\01_Paquete_R\ciecl"

# Verificar que existe el directorio
if (-not (Test-Path $rutaCiecl)) {
    Write-Host "❌ No se encuentra el paquete ciecl en: $rutaCiecl" -ForegroundColor Red
    Write-Host "   Verifique la ruta del paquete" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Paquete encontrado en: $rutaCiecl" -ForegroundColor Green
Write-Host ""

# Crear script R temporal
$scriptR = @"
cat('Instalando paquete ciecl desde R...\n\n')

# Verificar y instalar devtools si es necesario
if (!requireNamespace('devtools', quietly = TRUE)) {
  cat('Instalando devtools...\n')
  install.packages('devtools', repos = 'https://cloud.r-project.org', quiet = TRUE)
}

# Instalar ciecl
cat('Instalando paquete ciecl...\n\n')
devtools::install_local(
  path = '$($rutaCiecl -replace '\\', '/')',
  upgrade = 'never',
  force = TRUE,
  quiet = FALSE,
  build_vignettes = FALSE
)

# Verificar instalación
if (requireNamespace('ciecl', quietly = TRUE)) {
  library(ciecl)
  cat('\n✅ Paquete ciecl instalado exitosamente\n\n')
  
  # Información del paquete
  pkg_info <- packageDescription('ciecl')
  cat('INFORMACIÓN DEL PAQUETE:\n')
  cat('  • Nombre:', pkg_info`$Package, '\n')
  cat('  • Versión:', pkg_info`$Version, '\n')
  cat('  • Título:', pkg_info`$Title, '\n\n')
  
  # Funciones disponibles
  cat('FUNCIONES DISPONIBLES:\n')
  funcs <- sort(ls('package:ciecl'))
  for (f in funcs) {
    cat('  •', f, '\n')
  }
  
  cat('\n✅ Instalación completada exitosamente\n')
} else {
  cat('\n❌ Error en la instalación\n')
  quit(status = 1)
}
"@

# Guardar script temporal
$tempScript = Join-Path $env:TEMP "install_ciecl_temp.R"
$scriptR | Out-File -FilePath $tempScript -Encoding UTF8

Write-Host "Ejecutando instalación en R..." -ForegroundColor Yellow
Write-Host ""

# Ejecutar script en R
try {
    # Buscar Rscript.exe
    $rscript = Get-Command Rscript.exe -ErrorAction SilentlyContinue
    
    if ($null -eq $rscript) {
        # Intentar rutas comunes de instalación de R
        $possiblePaths = @(
            "C:\Program Files\R\R-*\bin\Rscript.exe",
            "C:\Program Files\R\R-*\bin\x64\Rscript.exe"
        )
        
        foreach ($path in $possiblePaths) {
            $found = Get-Item $path -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $rscript = $found.FullName
                break
            }
        }
    } else {
        $rscript = $rscript.Source
    }
    
    if ($null -eq $rscript) {
        throw "No se encuentra Rscript.exe. Asegúrese de que R está instalado."
    }
    
    Write-Host "Usando: $rscript" -ForegroundColor Gray
    Write-Host ""
    
    # Ejecutar
    & $rscript --vanilla $tempScript
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host "  ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host ""
        Write-Host "Para usar el paquete en R:" -ForegroundColor Cyan
        Write-Host "  library(ciecl)" -ForegroundColor White
        Write-Host "  ?ciecl::cie_lookup" -ForegroundColor White
    } else {
        throw "Error durante la instalación"
    }
    
} catch {
    Write-Host ""
    Write-Host "❌ ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "ALTERNATIVA: Ejecutar desde R directamente" -ForegroundColor Yellow
    Write-Host "  1. Abrir R o RStudio" -ForegroundColor White
    Write-Host "  2. Ejecutar: source('instalar_ciecl.R')" -ForegroundColor White
    exit 1
} finally {
    # Limpiar archivo temporal
    if (Test-Path $tempScript) {
        Remove-Item $tempScript -Force
    }
}
