# 🔧 Solucionar Error 404 en `/auth/register`

Si estás recibiendo errores **404 Not Found** al intentar registrar usuarios, sigue esta guía paso a paso.

## 🔍 Diagnóstico del Problema

El error `404 Not Found` en `/auth/register` significa que:
- ❌ El endpoint no existe en el backend desplegado
- ❌ Railway no ha desplegado el código con autenticación
- ❌ Hay un problema con el routing de FastAPI

## ✅ Solución Paso a Paso

### Paso 1: Verificar que el Código Esté en GitHub

1. **Ve a tu repositorio en GitHub:**
   - https://github.com/Diegogigi/finduo-backend
   - Ve a la rama `main`
   - Busca el archivo: `app/main.py`

2. **Verifica que exista el endpoint:**
   - Abre `app/main.py`
   - Busca: `@app.post("/auth/register")`
   - Si NO existe, el código no está en GitHub

3. **Si el código NO está en GitHub:**
   ```bash
   cd finduo_backend
   git add app/main.py app/auth.py
   git commit -m "Agregar endpoints de autenticación"
   git push origin main
   ```

### Paso 2: Verificar que Railway Haya Desplegado

1. **Ve a Railway Dashboard:**
   - https://railway.app
   - Selecciona tu proyecto
   - Haz clic en el servicio **finduo-backend**

2. **Ve a la pestaña "Deployments":**
   - Verifica que el **último despliegue sea reciente** (de hoy)
   - Verifica que el commit sea el correcto (debe incluir "autenticación")

3. **Si el despliegue es antiguo:**
   - Haz clic en **"Redeploy"** o **"Deploy Latest"**
   - Espera 2-3 minutos para que termine el despliegue

### Paso 3: Verificar Root Directory en Railway

1. **En Railway, ve al servicio backend**
2. **Haz clic en "Settings"**
3. **Ve a "Source"**
4. **Verifica "Root Directory":**
   - Debe ser: `finduo_backend` (no `.` ni vacío)
   - Si está mal, cámbialo a `finduo_backend`
   - Guarda los cambios
   - Railway hará un nuevo despliegue

### Paso 4: Verificar que los Endpoints Existan

1. **Obtén la URL del backend:**
   - En Railway → Servicio backend → "Settings" → "Domains"
   - Copia la URL pública (ejemplo: `https://finduo-backend-production.up.railway.app`)

2. **Prueba el endpoint de salud:**
   - Abre un navegador
   - Ve a: `https://tu-backend-url.railway.app/health`
   - Debe responder: `{"status":"ok"}`

3. **Prueba la documentación (Swagger):**
   - Ve a: `https://tu-backend-url.railway.app/docs`
   - Debe mostrar la documentación de FastAPI
   - **Busca estos endpoints:**
     - ✅ `POST /auth/register`
     - ✅ `POST /auth/login`
     - ✅ `GET /auth/me`
   - **Si NO aparecen estos endpoints:**
     - El backend no tiene el código de autenticación
     - Sigue los pasos anteriores para desplegar el código

### Paso 5: Verificar los Logs del Backend

1. **En Railway, ve al servicio backend**
2. **Haz clic en "Logs"**
3. **Busca errores al iniciar:**
   - `ModuleNotFoundError` → Falta una dependencia
   - `ImportError` → Error al importar módulos
   - `AttributeError` → Error en el código
   - `Application startup complete` → ✅ Backend inició correctamente

4. **Si hay errores:**
   - Anota el error específico
   - Verifica que todas las dependencias estén en `requirements.txt`
   - Verifica que `app/auth.py` exista y esté correcto

### Paso 6: Verificar la URL en la App Móvil

1. **Verifica el archivo `lib/config/api_config.dart`:**
   ```dart
   static const String baseUrl = 'https://finduo-backend-production.up.railway.app';
   ```

2. **Verifica que sea la URL correcta:**
   - Debe ser la misma URL que obtuviste en Railway
   - No debe tener `/` al final
   - Debe usar `https://` (no `http://`)

3. **Si la URL es incorrecta:**
   - Actualiza `lib/config/api_config.dart`
   - Vuelve a compilar e instalar la app

### Paso 7: Forzar un Nuevo Despliegue

Si nada funciona, fuerza un nuevo despliegue:

1. **En Railway, ve al servicio backend**
2. **Haz clic en los tres puntos (⋯)**
3. **Selecciona "Redeploy" o "Deploy Latest"**
4. **Espera 2-3 minutos**
5. **Verifica los logs para ver si hay errores**

## 🚨 Verificaciones Rápidas

### ✅ Checklist de Verificación

- [ ] El código está en GitHub (con `/auth/register`)
- [ ] Railway ha desplegado recientemente (hoy)
- [ ] Root Directory es `finduo_backend`
- [ ] El endpoint `/health` responde `{"status":"ok"}`
- [ ] El endpoint `/docs` muestra la documentación
- [ ] Los endpoints `/auth/register` y `/auth/login` aparecen en `/docs`
- [ ] La URL del backend en `api_config.dart` es correcta
- [ ] No hay errores en los logs del backend
- [ ] El archivo `app/auth.py` existe en GitHub

## 🔍 Comandos Útiles para Verificar

### Verificar que el endpoint existe en el código:

```bash
# En el repositorio local
cd finduo_backend
grep -r "/auth/register" app/main.py
```

**Debe mostrar:**
```
@app.post("/auth/register", response_model=TokenResponse)
```

### Verificar que auth.py existe:

```bash
ls -la app/auth.py
```

**Debe existir el archivo**

### Verificar requirements.txt:

```bash
grep -E "python-jose|passlib" requirements.txt
```

**Debe mostrar:**
```
python-jose[cryptography]
passlib[bcrypt]
```

## 💡 Solución Rápida

Si necesitas una solución rápida, sigue estos pasos en orden:

1. **Sube el código a GitHub** (si falta algo)
   ```bash
   cd finduo_backend
   git add .
   git commit -m "Asegurar que endpoints de autenticación estén incluidos"
   git push origin main
   ```

2. **En Railway, verifica Root Directory:**
   - Settings → Source → Root Directory = `finduo_backend`

3. **En Railway, haz Redeploy:**
   - Servicio backend → ⋯ → Redeploy

4. **Espera 2-3 minutos y verifica:**
   - Ve a: `https://tu-backend-url.railway.app/docs`
   - Busca: `POST /auth/register`
   - Si aparece, el problema está resuelto

5. **Si sigue sin aparecer:**
   - Revisa los logs del backend
   - Busca errores específicos
   - Verifica que `app/auth.py` esté en GitHub

## 📝 Notas Importantes

- **El código en GitHub debe estar actualizado** antes de que Railway lo despliegue
- **Railway despliega automáticamente** cuando haces push a `main`
- **El Root Directory debe ser correcto** (`finduo_backend`)
- **Los logs te dirán qué está mal** si hay un problema

## 🔗 Archivos Relacionados

- [VERIFICAR_BACKEND_RAILWAY.md](./VERIFICAR_BACKEND_RAILWAY.md) - Verificación completa del backend
- [SOLUCIONAR_404_AUTH.md](./SOLUCIONAR_404_AUTH.md) - Solución alternativa para 404
- [VARIABLES_ENTORNO.md](./VARIABLES_ENTORNO.md) - Variables necesarias

