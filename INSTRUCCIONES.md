# Instrucciones de Configuración - FinDuo

## ✅ Tareas Completadas

### 1. Backend Local
- ✅ Entorno virtual creado en `finduo_backend/.venv`
- ✅ Dependencias instaladas
- ✅ Configuración para Railway preparada

### 2. Backend Railway
- ✅ Dockerfile actualizado para Railway
- ✅ `railway.json` creado
- ✅ Soporte para PostgreSQL agregado
- ✅ `database.py` actualizado para usar variables de entorno

### 3. Proyecto Flutter
- ✅ Nuevo proyecto Flutter creado: `finduo_flutter`
- ✅ Archivos `lib/` y `pubspec.yaml` copiados
- ✅ Dependencias instaladas
- ✅ Configurado para Android por USB

---

## 🚀 Cómo Levantar el Backend Localmente

### Opción 1: Usar el script (Windows PowerShell)
```powershell
cd finduo_backend
.\start_local.ps1
```

### Opción 2: Comandos manuales
```powershell
cd finduo_backend

# Activar entorno virtual
.\.venv\Scripts\Activate.ps1

# Configurar variables de entorno (opcional, solo si vas a usar sincronización de emails)
$env:EMAIL_USER="tu_correo@gmail.com"
$env:EMAIL_PASSWORD="tu_app_password"

# Iniciar servidor
uvicorn app.main:app --reload
```

El servidor estará disponible en: **http://localhost:8000**

### Probar el backend:
- Health check: http://localhost:8000/health
- Transacciones: http://localhost:8000/transactions

---

## ☁️ Desplegar en Railway

1. **Crear cuenta en Railway**: https://railway.app
2. **Conectar repositorio**: Selecciona la carpeta `finduo_backend`
3. **Configurar variables de entorno**:
   - `EMAIL_USER`: Tu correo de Gmail
   - `EMAIL_PASSWORD`: Tu App Password de Gmail
4. **Agregar PostgreSQL** (opcional pero recomendado):
   - Railway configurará automáticamente `DATABASE_URL`
5. **Desplegar**: Railway detectará el Dockerfile automáticamente

Ver `finduo_backend/README_RAILWAY.md` para más detalles.

---

## 📱 Ejecutar App Flutter en Android por USB

### Requisitos:
1. Dispositivo Android conectado por USB
2. Depuración USB habilitada en el dispositivo
3. Backend corriendo localmente (o URL de Railway configurada)

### Pasos:

**1. Configurar URL del backend:**
Edita `finduo_flutter/lib/config/api_config.dart`:
- **Dispositivo físico**: Usa la IP local de tu PC
  ```dart
  static const String baseUrl = 'http://192.168.1.100:8000';
  ```
  Encuentra tu IP con: `ipconfig` (busca "IPv4")
- **Emulador**: Ya está configurado con `http://10.0.2.2:8000`
- **Producción**: URL de Railway

**2. Ejecutar la app:**

**Opción A: Script (recomendado)**
```powershell
cd finduo_flutter
.\run_android.ps1
```

**Opción B: Comandos manuales**
```powershell
cd finduo_flutter
flutter devices  # Ver dispositivos conectados
flutter run      # Ejecutar en el dispositivo
```

### Solución de problemas:

**Dispositivo no aparece:**
- Verifica depuración USB habilitada
- Desconecta y reconecta el USB
- Ejecuta `flutter doctor`

**No se conecta al backend:**
- Verifica que el backend esté corriendo
- Si usas dispositivo físico, usa la IP local (no localhost)
- Asegúrate de estar en la misma red WiFi
- Revisa el firewall de Windows

---

## 📁 Estructura del Proyecto

```
finduo_project/
├── finduo_backend/          # Backend FastAPI
│   ├── app/                 # Código de la aplicación
│   ├── .venv/               # Entorno virtual (creado)
│   ├── Dockerfile           # Para Railway
│   ├── railway.json         # Configuración Railway
│   ├── requirements.txt     # Dependencias Python
│   └── start_local.ps1     # Script para iniciar localmente
│
├── finduo_flutter/          # App Flutter (nuevo proyecto)
│   ├── lib/                 # Código de la app (copiado)
│   ├── pubspec.yaml         # Dependencias (copiado)
│   └── run_android.ps1      # Script para ejecutar en Android
│
└── finduo_app/              # Código original (referencia)
```

---

## 🔗 URLs Importantes

- **Backend local**: http://localhost:8000
- **Backend Railway**: https://tu-proyecto.up.railway.app (después de desplegar)
- **Documentación API**: http://localhost:8000/docs (FastAPI Swagger)

---

## 📝 Notas

- El backend usa SQLite localmente por defecto
- En Railway, se recomienda usar PostgreSQL
- La sincronización de emails requiere configuración de `EMAIL_USER` y `EMAIL_PASSWORD`
- Para desarrollo local con dispositivo físico, asegúrate de que ambos estén en la misma red

