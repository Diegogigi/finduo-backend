# 🔍 Verificar Backend y Base de Datos en Railway

Esta guía te ayudará a verificar que el backend y la base de datos estén configurados correctamente en Railway.

## 📋 Variables de Entorno Necesarias

### 🗄️ **Base de Datos PostgreSQL**

#### Variables del servicio PostgreSQL:
Railway crea automáticamente estas variables en el servicio de PostgreSQL:

1. **`DATABASE_URL`** ✅ (Automática)
   - Ejemplo: `postgresql://postgres:password@host:port/railway`
   - Esta variable se crea automáticamente cuando creas el servicio PostgreSQL

### 🔧 **Backend (finduo-backend)**

#### Variables necesarias en el servicio de backend:

1. **`DATABASE_URL`** ✅ **OBLIGATORIA**
   - **Descripción**: URL de conexión a la base de datos PostgreSQL
   - **Cómo obtenerla**:
     1. Ve a Railway Dashboard
     2. Selecciona tu proyecto
     3. Haz clic en el servicio **PostgreSQL**
     4. Ve a la pestaña **"Variables"**
     5. Copia el valor de `DATABASE_URL`
     6. Ve al servicio de **backend** (finduo-backend)
     7. Ve a **"Variables"**
     8. Agrega o actualiza `DATABASE_URL` con el valor copiado
   - **Formato**: `postgresql://usuario:contraseña@host:puerto/nombre_base_datos`

2. **`SECRET_KEY`** ✅ **RECOMENDADA** (Opcional pero recomendada)
   - **Descripción**: Clave secreta para firmar tokens JWT
   - **Valor por defecto**: `"your-secret-key-change-in-production"`
   - **Cómo generarla**: Usa cualquier string aleatorio seguro
   - **Ejemplo**: `mi-clave-secreta-super-segura-123456`
   - **Dónde configurarla**: Servicio backend → Variables → `SECRET_KEY`

3. **`EMAIL_USER`** ✅ **OBLIGATORIA** (Solo si usas sincronización de correos)
   - **Descripción**: Dirección de correo de Gmail para sincronización
   - **Ejemplo**: `tu_correo@gmail.com`
   - **Dónde configurarla**: Servicio backend → Variables → `EMAIL_USER`

4. **`EMAIL_PASSWORD`** ✅ **OBLIGATORIA** (Solo si usas sincronización de correos)
   - **Descripción**: Contraseña de aplicación de Gmail (App Password)
   - **Ejemplo**: `abcdefghijklmnop` (16 caracteres sin espacios)
   - **Dónde configurarla**: Servicio backend → Variables → `EMAIL_PASSWORD`

5. **`PORT`** ✅ (Automática)
   - Railway inyecta automáticamente el puerto
   - No necesitas configurarla manualmente

## 🔍 Verificación Paso a Paso

### Paso 1: Verificar que el Backend esté Desplegado

1. **Ve a Railway Dashboard**
   - https://railway.app
   - Inicia sesión y selecciona tu proyecto

2. **Verifica el Servicio de Backend**
   - Debe estar en color **verde** (activo)
   - Si está rojo, hay un error

3. **Revisa los Logs**
   - Haz clic en el servicio de backend
   - Ve a la pestaña **"Logs"**
   - Busca: `Application startup complete`
   - Si ves errores, anótalos

### Paso 2: Verificar Variables de Entorno del Backend

1. **En el servicio de backend, ve a "Variables"**
2. **Verifica que existan estas variables:**
   - ✅ `DATABASE_URL` (OBLIGATORIA)
   - ✅ `SECRET_KEY` (Recomendada)
   - ⚠️ `EMAIL_USER` (Solo si usas correos)
   - ⚠️ `EMAIL_PASSWORD` (Solo si usas correos)

3. **Si falta `DATABASE_URL`:**
   - Ve al servicio PostgreSQL
   - Copia el valor de `DATABASE_URL`
   - Vuelve al servicio backend
   - Agrega la variable `DATABASE_URL` con el valor copiado
   - Guarda los cambios
   - El backend se reiniciará automáticamente

### Paso 3: Verificar que PostgreSQL esté Activo

1. **Verifica el Servicio PostgreSQL**
   - Debe estar en color **verde** (activo)

2. **Verifica las Variables de PostgreSQL**
   - Debe tener `DATABASE_URL` creada automáticamente

3. **Verifica las Tablas**
   - Ve a la pestaña **"Data"** o **"Query"**
   - Ejecuta: `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';`
   - Debes ver: `users`, `duo_rooms`, `duo_memberships`, `transactions`

### Paso 4: Verificar que los Endpoints estén Disponibles

1. **Obtén la URL del Backend**
   - En Railway, ve al servicio de backend
   - Ve a la pestaña **"Settings"**
   - Busca **"Domains"** o **"Public URL"**
   - Copia la URL (algo como: `https://finduo-backend-production.up.railway.app`)

2. **Prueba el Endpoint de Health**
   - Abre un navegador
   - Ve a: `https://tu-backend-url.railway.app/health`
   - Debe responder: `{"status":"ok"}`

3. **Prueba la Documentación (Swagger)**
   - Ve a: `https://tu-backend-url.railway.app/docs`
   - Debe mostrar la documentación de FastAPI
   - Busca el endpoint: `POST /auth/register`
   - Si no aparece, el backend no tiene el código actualizado

### Paso 5: Verificar la URL en la App Móvil

1. **Verifica el archivo `api_config.dart`**
   - Debe tener la URL correcta de Railway
   - Ejemplo: `https://finduo-backend-production.up.railway.app`

2. **Si la URL es incorrecta:**
   - Actualiza `lib/config/api_config.dart`
   - Vuelve a compilar e instalar la app

## 🚨 Solución de Problemas

### Error: "Not Found" al registrar usuario

**Causas posibles:**
1. ❌ El endpoint `/auth/register` no existe en el backend
2. ❌ La URL del backend en la app es incorrecta
3. ❌ El backend no está desplegado correctamente

**Soluciones:**

1. **Verificar que Railway haya desplegado el código actualizado:**
   - Ve a Railway → Servicio backend → "Deployments"
   - Verifica que el último despliegue sea reciente (hoy)
   - Si no, haz clic en "Redeploy" o "Deploy Latest"

2. **Verificar que los endpoints existan:**
   - Ve a: `https://tu-backend-url.railway.app/docs`
   - Busca: `POST /auth/register` y `POST /auth/login`
   - Si no aparecen, el backend no tiene el código de autenticación

3. **Verificar la URL en la app móvil:**
   - Abre `lib/config/api_config.dart`
   - Verifica que `baseUrl` sea la URL correcta de Railway
   - Debe ser algo como: `https://finduo-backend-production.up.railway.app`

4. **Verificar los logs del backend:**
   - En Railway, ve a Logs del backend
   - Busca errores al iniciar
   - Busca: `ModuleNotFoundError`, `ImportError`, etc.

### Error: "Database connection failed"

**Causas:**
- ❌ `DATABASE_URL` no está configurada en el backend
- ❌ `DATABASE_URL` tiene un valor incorrecto

**Solución:**
1. Ve al servicio PostgreSQL en Railway
2. Copia el valor de `DATABASE_URL`
3. Ve al servicio backend
4. Agrega o actualiza `DATABASE_URL` con el valor copiado
5. Guarda los cambios
6. El backend se reiniciará automáticamente

## ✅ Checklist Final

Antes de probar la app móvil, verifica:

- [ ] Backend está activo (verde) en Railway
- [ ] `DATABASE_URL` está configurada en el backend
- [ ] `SECRET_KEY` está configurada (o usa el default)
- [ ] PostgreSQL está activo (verde) en Railway
- [ ] Tabla `users` tiene `password_hash` y `created_at`
- [ ] El endpoint `/health` responde `{"status":"ok"}`
- [ ] El endpoint `/docs` muestra la documentación
- [ ] Los endpoints `/auth/register` y `/auth/login` aparecen en `/docs`
- [ ] La URL del backend en `api_config.dart` es correcta
- [ ] La app móvil está actualizada con la última versión

## 📝 Resumen de Variables

### **PostgreSQL (Automáticas - Railway las crea):**
- `DATABASE_URL` ✅

### **Backend (Debes configurarlas):**
- `DATABASE_URL` ✅ **OBLIGATORIA** (Copia del servicio PostgreSQL)
- `SECRET_KEY` ⚠️ Recomendada (Puede usar default)
- `EMAIL_USER` ⚠️ Solo si usas correos
- `EMAIL_PASSWORD` ⚠️ Solo si usas correos

## 🔗 Enlaces Útiles

- [Railway Dashboard](https://railway.app)
- [FastAPI Docs](https://fastapi.tiangolo.com/)
- Tu backend: `https://tu-backend-url.railway.app/docs`

