# Script para correr la app Flutter en Android por USB
# Asegúrate de tener tu dispositivo Android conectado por USB con depuración USB habilitada

Write-Host "Verificando dispositivos conectados..." -ForegroundColor Cyan
flutter devices

Write-Host "`nInstalando dependencias..." -ForegroundColor Cyan
flutter pub get

Write-Host "`nEjecutando app en dispositivo Android..." -ForegroundColor Green
Write-Host "NOTA: Si tienes múltiples dispositivos, puedes especificar uno con:" -ForegroundColor Yellow
Write-Host "  flutter run -d <device-id>" -ForegroundColor Yellow
Write-Host "`nPara encontrar tu IP local (necesaria para conectar al backend):" -ForegroundColor Yellow
Write-Host "  ipconfig | findstr IPv4" -ForegroundColor Yellow
Write-Host "`nLuego actualiza lib/config/api_config.dart con tu IP" -ForegroundColor Yellow
Write-Host "`nIniciando app..." -ForegroundColor Green
flutter run

