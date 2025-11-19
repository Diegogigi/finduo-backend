# Script para subir el backend a GitHub
# Usuario GitHub: diegogigi

Write-Host "=== Subiendo FinDuo Backend a GitHub ===" -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "app\main.py")) {
    Write-Host "Error: Este script debe ejecutarse desde el directorio finduo_backend" -ForegroundColor Red
    exit 1
}

# Verificar estado de git
Write-Host "Verificando estado del repositorio..." -ForegroundColor Yellow
$status = git status --porcelain
if ($status) {
    Write-Host "Hay cambios sin commitear. ¿Deseas agregarlos? (S/N)" -ForegroundColor Yellow
    $respuesta = Read-Host
    if ($respuesta -eq "S" -or $respuesta -eq "s") {
        git add .
        $mensaje = Read-Host "Mensaje del commit"
        if (-not $mensaje) {
            $mensaje = "Update: cambios en el backend"
        }
        git commit -m $mensaje
    }
}

# Verificar si ya existe el remote
$remote = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Remote 'origin' ya existe: $remote" -ForegroundColor Green
    Write-Host "¿Deseas cambiarlo? (S/N)" -ForegroundColor Yellow
    $cambiar = Read-Host
    if ($cambiar -eq "S" -or $cambiar -eq "s") {
        git remote remove origin
    } else {
        Write-Host "Usando el remote existente..." -ForegroundColor Green
        git push -u origin master
        exit 0
    }
}

Write-Host ""
Write-Host "IMPORTANTE: Primero debes crear el repositorio en GitHub:" -ForegroundColor Yellow
Write-Host "1. Ve a https://github.com/new" -ForegroundColor Cyan
Write-Host "2. Nombre del repositorio: finduo-backend" -ForegroundColor Cyan
Write-Host "3. NO marques 'Initialize with README'" -ForegroundColor Cyan
Write-Host "4. Click en 'Create repository'" -ForegroundColor Cyan
Write-Host ""
Write-Host "¿Ya creaste el repositorio en GitHub? (S/N)" -ForegroundColor Yellow
$creado = Read-Host

if ($creado -ne "S" -and $creado -ne "s") {
    Write-Host "Por favor crea el repositorio primero y luego ejecuta este script de nuevo." -ForegroundColor Red
    exit 1
}

# Agregar remote
Write-Host ""
Write-Host "Agregando remote de GitHub..." -ForegroundColor Green
git remote add origin https://github.com/diegogigi/finduo-backend.git

# Verificar la rama
$branch = git branch --show-current
Write-Host "Rama actual: $branch" -ForegroundColor Cyan

# Intentar push
Write-Host ""
Write-Host "Subiendo código a GitHub..." -ForegroundColor Green
Write-Host "Si te pide credenciales, usa tu Personal Access Token (no tu contraseña)" -ForegroundColor Yellow
Write-Host ""

try {
    git push -u origin $branch
    Write-Host ""
    Write-Host "¡Éxito! El código ha sido subido a GitHub." -ForegroundColor Green
    Write-Host "Repositorio: https://github.com/diegogigi/finduo-backend" -ForegroundColor Cyan
} catch {
    Write-Host ""
    Write-Host "Error al subir. Posibles causas:" -ForegroundColor Red
    Write-Host "- El repositorio no existe en GitHub" -ForegroundColor Yellow
    Write-Host "- Problemas de autenticación (necesitas Personal Access Token)" -ForegroundColor Yellow
    Write-Host "- La rama en GitHub es 'main' pero local es 'master' (o viceversa)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Si la rama es diferente, intenta:" -ForegroundColor Cyan
    Write-Host "  git branch -M main" -ForegroundColor Cyan
    Write-Host "  git push -u origin main" -ForegroundColor Cyan
}

