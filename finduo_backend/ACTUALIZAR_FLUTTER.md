# 🔄 Actualizar App Flutter con URL de Railway

## Pasos Rápidos

### 1. Obtener la URL de Railway

1. Ve a: https://railway.app
2. Selecciona tu proyecto
3. Click en el servicio desplegado
4. Ve a **"Settings"** → **"Domains"**
5. Copia la URL (ejemplo: `https://finduo-backend-production-xxxx.up.railway.app`)

### 2. Actualizar Flutter

Edita el archivo: `finduo_flutter/lib/config/api_config.dart`

Reemplaza la línea:
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

Por:
```dart
static const String baseUrl = 'https://TU-URL-DE-RAILWAY.up.railway.app';
```

### 3. Verificar

1. Prueba el backend: `https://TU-URL.up.railway.app/health`
2. Deberías ver: `{"status":"ok"}`
3. Ejecuta la app Flutter y verifica que se conecte al backend

---

## Comando Rápido

Si ya tienes la URL, ejecuta este comando (reemplaza TU_URL):

```powershell
cd C:\Users\hp\Desktop\finduo_project\finduo_flutter
(Get-Content lib\config\api_config.dart) -replace "http://10.0.2.2:8000", "https://TU_URL.up.railway.app" | Set-Content lib\config\api_config.dart
```

