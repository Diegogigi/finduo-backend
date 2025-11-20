# 📱 Actualizar App Móvil con Backend de Railway

## 🔍 Paso 1: Obtener la URL de Railway

1. Ve a **https://railway.app**
2. Selecciona tu proyecto
3. Click en el servicio **`finduo-backend`**
4. Ve a **Settings** → **Networking** o busca **"Domains"**
5. Copia la URL (ejemplo: `https://finduo-backend-production-xxxx.up.railway.app`)

## ✅ Paso 2: Actualizar la Configuración

### Para `finduo_flutter`:

Edita: `finduo_flutter/lib/config/api_config.dart`

```dart
class ApiConfig {
  // URL del backend en Railway (producción)
  static const String baseUrl = 'https://TU-URL-DE-RAILWAY.up.railway.app';
  
  // Para desarrollo local, descomenta la siguiente línea y comenta la de arriba:
  // static const String baseUrl = 'http://10.0.2.2:8000'; // Emulador Android
  // static const String baseUrl = 'http://TU_IP_LOCAL:8000'; // Dispositivo físico
}
```

### Para `finduo_app`:

Edita: `finduo_app/lib/config/api_config.dart`

```dart
class ApiConfig {
  // Cambia esta URL por la de tu backend en Railway
  static const String baseUrl = 'https://TU-URL-DE-RAILWAY.up.railway.app';
}
```

## 🧪 Paso 3: Verificar que Funciona

1. **Prueba el backend:**
   - Abre en tu navegador: `https://TU-URL.up.railway.app/health`
   - Deberías ver: `{"status":"ok"}`

2. **Reconstruye la app móvil:**
   ```powershell
   # Para finduo_flutter
   cd C:\Users\hp\Desktop\finduo_project\finduo_flutter
   flutter clean
   flutter pub get
   flutter run
   
   # Para finduo_app
   cd C:\Users\hp\Desktop\finduo_project\finduo_app
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Prueba la app:**
   - La app debería conectarse al backend automáticamente
   - Prueba sincronizar correo u otras funcionalidades

## 📝 Notas Importantes

- Usa siempre `https://` (no `http://`)
- La URL debe terminar sin `/` al final
- Después de cambiar la URL, siempre ejecuta `flutter clean` y `flutter pub get`
- Si tienes la app instalada, necesitas reinstalarla o hacer un hot restart completo

## 🔄 Si la URL de Railway Cambia

Si Railway genera una nueva URL (por ejemplo, después de eliminar/recrear el servicio):

1. Obtén la nueva URL desde Railway → Settings → Networking
2. Actualiza `api_config.dart` en ambas apps
3. Reconstruye las apps
4. Vuelve a instalar en los dispositivos

