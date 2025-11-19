# Script para iniciar el backend localmente en Windows PowerShell
# Asegúrate de tener configuradas las variables EMAIL_USER y EMAIL_PASSWORD

Write-Host "Iniciando backend FinDuo localmente..." -ForegroundColor Green

# Activar entorno virtual
if (Test-Path ".venv\Scripts\Activate.ps1") {
    .\.venv\Scripts\Activate.ps1
    Write-Host "Entorno virtual activado" -ForegroundColor Cyan
} else {
    Write-Host "Error: No se encontró el entorno virtual. Ejecuta: python -m venv .venv" -ForegroundColor Red
    exit 1
}

# Verificar variables de entorno
if (-not $env:EMAIL_USER -or -not $env:EMAIL_PASSWORD) {
    Write-Host "Advertencia: EMAIL_USER y EMAIL_PASSWORD no están configuradas" -ForegroundColor Yellow
    Write-Host "Configúralas con:" -ForegroundColor Yellow
    Write-Host '  $env:EMAIL_USER="tu_correo@gmail.com"' -ForegroundColor Yellow
    Write-Host '  $env:EMAIL_PASSWORD="tu_app_password"' -ForegroundColor Yellow
}

# Iniciar servidor
Write-Host "Iniciando servidor en http://localhost:8000" -ForegroundColor Green
uvicorn app.main:app --reload

