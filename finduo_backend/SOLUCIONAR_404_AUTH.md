# 🔧 Solucionar Error 404 en `/auth/register` y `/auth/login`

Si estás recibiendo errores 404 al intentar registrar o iniciar sesión, sigue estos pasos:

## 📋 Verificaciones

### 1. Verificar que Railway haya desplegado el código actualizado

**Pasos:**
1. Ve a [Railway Dashboard](https://railway.app)
2. Selecciona tu proyecto **finduo-backend**
3. Haz clic en tu servicio de backend
4. Ve a la pestaña **"Deployments"**
5. Verifica que el último despliegue sea **reciente** (debe ser de hoy)
6. Verifica que el commit sea el **más reciente** (debe incluir "autenticación")

**Si el despliegue es antiguo:**
- Haz clic en el botón **"Deploy"** o **"Redeploy"**
- O espera 1-2 minutos para que Railway despliegue automáticamente

### 2. Verificar los logs del backend

**Pasos:**
1. En Railway, ve a tu servicio de backend
2. Haz clic en la pestaña **"Logs"**
3. Busca errores relacionados con:
   - `ModuleNotFoundError`
   - `ImportError`
   - `AttributeError`
   - Errores de importación de módulos

**Si hay errores de importación:**
- Verifica que `app/auth.py` esté presente
- Verifica que las dependencias estén instaladas (`python-jose`, `passlib[bcrypt]`)

### 3. Verificar que las dependencias estén instaladas

**Revisar `requirements.txt`:**
Asegúrate de que incluya:
```txt
python-jose[cryptography]
passlib[bcrypt]
python-multipart
```

**Verificar en Railway:**
1. Ve a tu servicio de backend
2. Ve a la pestaña **"Variables"**
3. No necesitas configurar nada aquí, solo verificar

### 4. Verificar que el endpoint esté registrado

**Probar manualmente:**
1. Ve a la URL de tu backend: `https://tu-backend.railway.app/docs`
2. Deberías ver la documentación de FastAPI (Swagger UI)
3. Busca los endpoints:
   - `POST /auth/register`
   - `POST /auth/login`
   - `GET /auth/me`

**Si no aparecen:**
- El código no se ha desplegado correctamente
- Hay un error en el código que impide que se registren los endpoints

### 5. Verificar el endpoint `/health`

**Probar:**
```bash
curl https://tu-backend.railway.app/health
```

**Debería responder:**
```json
{"status": "ok"}
```

**Si no responde:**
- El backend no está funcionando
- Verifica que el servicio esté activo (verde) en Railway

## 🔍 Soluciones Comunes

### Solución 1: Forzar un nuevo despliegue

1. En Railway, ve a tu servicio de backend
2. Haz clic en los **tres puntos** (⋯) junto al nombre del servicio
3. Selecciona **"Redeploy"** o **"Deploy Latest"**
4. Espera 2-3 minutos para que termine el despliegue

### Solución 2: Verificar variables de entorno

1. Ve a tu servicio de backend en Railway
2. Haz clic en **"Variables"**
3. Verifica que **NO** haya variables conflictivas
4. Asegúrate de que `DATABASE_URL` esté configurada correctamente (si usas PostgreSQL)

### Solución 3: Revisar los logs durante el despliegue

1. Ve a la pestaña **"Logs"** en Railway
2. Haz clic en **"Redeploy"**
3. Observa los logs durante el despliegue
4. Busca errores de:
   - Instalación de dependencias (`pip install`)
   - Importación de módulos
   - Inicio del servidor

### Solución 4: Verificar que el archivo `auth.py` esté presente

**Verificar en Railway:**
1. Ve a tu servicio de backend
2. Haz clic en **"Settings"** → **"Source"**
3. Verifica que el código incluye `app/auth.py`

**O verifica en GitHub:**
1. Ve a tu repositorio en GitHub
2. Verifica que el archivo `finduo_backend/app/auth.py` esté presente
3. Verifica que esté en la rama `main`

### Solución 5: Verificar el Dockerfile y start.sh

**Verificar que existan:**
- `Dockerfile`
- `start.sh`

**Verificar el contenido de `start.sh`:**
```bash
#!/bin/bash
PORT=${PORT:-8000}
exec uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

## 🚨 Si el problema persiste

### 1. Verificar que Railway esté conectado a GitHub

1. Ve a Railway Dashboard
2. Selecciona tu proyecto
3. Ve a **"Settings"** → **"Source"**
4. Verifica que esté conectado a tu repositorio de GitHub
5. Verifica que la rama sea `main`
6. Verifica que el **Root Directory** sea correcto (probablemente `finduo_backend`)

### 2. Verificar el Root Directory

**En Railway:**
1. Ve a **"Settings"** → **"Source"**
2. Verifica el campo **"Root Directory"**
3. Debe ser `finduo_backend` (no `.` ni vacío)

**Si está mal configurado:**
- Cambia el Root Directory a `finduo_backend`
- Guarda los cambios
- Railway hará un nuevo despliegue automáticamente

### 3. Verificar que los archivos estén en la ubicación correcta

**Estructura esperada:**
```
finduo_backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── auth.py          ← Debe estar aquí
│   ├── database.py
│   ├── models.py
│   └── email_sync.py
├── Dockerfile
├── start.sh
├── requirements.txt
└── railway.json
```

## ✅ Verificación Final

Después de seguir estos pasos:

1. ✅ Verifica que Railway haya desplegado el código actualizado
2. ✅ Verifica que los logs no muestren errores
3. ✅ Verifica que los endpoints aparezcan en `/docs`
4. ✅ Prueba registrar un usuario nuevo desde la app móvil

## 📱 Probar desde la App Móvil

1. Abre la app en tu móvil
2. Intenta crear una cuenta nueva
3. Si aparece un error, revisa los logs de Railway para ver el error exacto
4. Verifica que la URL del backend sea correcta en `lib/config/api_config.dart`

## 🔗 Enlaces Útiles

- [Railway Dashboard](https://railway.app)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Railway Documentation](https://docs.railway.app/)

