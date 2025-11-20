# 🗄️ Variables de Entorno para Base de Datos PostgreSQL en Railway

Esta guía explica qué variables necesita la base de datos PostgreSQL en Railway.

## ✅ Respuesta Corta: **NINGUNA**

Railway configura automáticamente todas las variables necesarias para PostgreSQL. **No necesitas configurar nada manualmente** en el servicio de PostgreSQL.

## 📋 Variables Automáticas de PostgreSQL en Railway

Cuando creas un servicio **PostgreSQL** en Railway, Railway crea automáticamente estas variables:

### 1. `DATABASE_URL` ✅ **Automática**
   - **Descripción**: URL completa de conexión a la base de datos
   - **Formato**: `postgresql://usuario:contraseña@host:puerto/nombre_base_datos`
   - **Ejemplo**: `postgresql://postgres:abc123xyz@containers-us-west-123.railway.app:5432/railway`
   - **Dónde se crea**: Automáticamente en el servicio PostgreSQL
   - **⚠️ Importante**: Esta variable **NO** se configura manualmente en PostgreSQL

### 2. `PGHOST` ✅ **Automática**
   - **Descripción**: Host del servidor PostgreSQL
   - **Ejemplo**: `containers-us-west-123.railway.app`
   - **Dónde se crea**: Automáticamente en el servicio PostgreSQL

### 3. `PGPORT` ✅ **Automática**
   - **Descripción**: Puerto del servidor PostgreSQL
   - **Ejemplo**: `5432`
   - **Dónde se crea**: Automáticamente en el servicio PostgreSQL

### 4. `PGUSER` ✅ **Automática**
   - **Descripción**: Usuario de la base de datos
   - **Ejemplo**: `postgres`
   - **Dónde se crea**: Automáticamente en el servicio PostgreSQL

### 5. `PGPASSWORD` ✅ **Automática**
   - **Descripción**: Contraseña de la base de datos
   - **Ejemplo**: `abc123xyz` (generada automáticamente por Railway)
   - **Dónde se crea**: Automáticamente en el servicio PostgreSQL

### 6. `PGDATABASE` ✅ **Automática**
   - **Descripción**: Nombre de la base de datos
   - **Ejemplo**: `railway`
   - **Dónde se crea**: Automáticamente en el servicio PostgreSQL

## 🔧 ¿Qué Debes Hacer?

### Paso 1: Crear el Servicio PostgreSQL (si no existe)
1. Ve a Railway Dashboard
2. Selecciona tu proyecto
3. Haz clic en **"+ New"**
4. Selecciona **"Database"** → **"Add PostgreSQL"**
5. Railway creará automáticamente el servicio con todas las variables

### Paso 2: Copiar `DATABASE_URL` al Backend
1. En Railway, ve al servicio **PostgreSQL**
2. Haz clic en la pestaña **"Variables"**
3. Busca `DATABASE_URL`
4. **Copia el valor completo** (haz clic en el ícono de copiar)
5. Ve al servicio de **Backend** (finduo-backend)
6. Haz clic en la pestaña **"Variables"**
7. Haz clic en **"+ New Variable"**
8. Nombre: `DATABASE_URL`
9. Valor: Pega el valor que copiaste
10. Guarda los cambios

### Paso 3: Verificar que Funcione
1. El backend se reiniciará automáticamente
2. Ve a los **Logs** del backend
3. Busca: `Application startup complete`
4. Si ves errores de conexión a la base de datos, verifica que `DATABASE_URL` sea correcta

## 📝 Resumen de Variables

### **Servicio PostgreSQL:**
- ❌ **NO necesitas configurar ninguna variable manualmente**
- ✅ Railway las crea automáticamente
- ✅ Solo necesitas copiar `DATABASE_URL` al backend

### **Servicio Backend:**
- ✅ `DATABASE_URL` **OBLIGATORIA** (Copia del servicio PostgreSQL)
- ✅ `SECRET_KEY` **Recomendada** (Para autenticación JWT)
- ⚠️ `EMAIL_USER` (Solo si usas sincronización de correos)
- ⚠️ `EMAIL_PASSWORD` (Solo si usas sincronización de correos)

## 🔍 Verificar Variables de PostgreSQL

Para ver todas las variables automáticas de PostgreSQL:

1. **En Railway, ve al servicio PostgreSQL**
2. **Haz clic en "Variables"**
3. **Deberías ver automáticamente:**
   - `DATABASE_URL`
   - `PGHOST`
   - `PGPORT`
   - `PGUSER`
   - `PGPASSWORD`
   - `PGDATABASE`

**Nota:** Estas variables **NO** aparecen en la interfaz web de Railway, pero están disponibles para ser usadas por otros servicios a través de `DATABASE_URL`.

## ✅ Checklist de Configuración

### PostgreSQL:
- [ ] Servicio PostgreSQL creado en Railway
- [ ] Servicio PostgreSQL está activo (verde)
- [ ] Variables automáticas creadas (Railway las crea)

### Backend:
- [ ] `DATABASE_URL` configurada en el backend (copiada de PostgreSQL)
- [ ] `SECRET_KEY` configurada (recomendada)
- [ ] Backend está activo (verde)
- [ ] No hay errores de conexión a la base de datos en los logs

## 🚨 Problemas Comunes

### Error: "Database connection failed"
**Causa:** `DATABASE_URL` no está configurada en el backend o es incorrecta

**Solución:**
1. Ve al servicio PostgreSQL en Railway
2. Copia el valor de `DATABASE_URL`
3. Ve al servicio backend
4. Agrega o actualiza `DATABASE_URL` con el valor copiado
5. Guarda los cambios

### Error: "No module named 'psycopg2'"
**Causa:** Falta la dependencia `psycopg2-binary` en `requirements.txt`

**Solución:**
- Verifica que `requirements.txt` incluya: `psycopg2-binary`
- Si no está, agrégalo y haz commit y push a GitHub
- Railway lo instalará automáticamente

### Error: "relation does not exist"
**Causa:** Las tablas no se han creado en la base de datos

**Solución:**
- Las tablas se crean automáticamente cuando el backend inicia
- Verifica que `DATABASE_URL` esté correcta
- Revisa los logs del backend para ver si hay errores al crear las tablas

## 📝 Notas Importantes

1. **PostgreSQL no necesita variables manuales:**
   - Railway configura todo automáticamente
   - Solo necesitas crear el servicio PostgreSQL

2. **`DATABASE_URL` es la única variable que necesitas copiar:**
   - Contiene toda la información de conexión
   - El backend la usa para conectarse a PostgreSQL

3. **Las variables de PostgreSQL son privadas:**
   - Solo están disponibles dentro de Railway
   - No puedes verlas en la interfaz web
   - Solo puedes usar `DATABASE_URL` para conectarte

4. **Si eliminas y recreas PostgreSQL:**
   - `DATABASE_URL` cambiará
   - Debes actualizar `DATABASE_URL` en el backend
   - Todos los datos se perderán (a menos que hagas backup)

## 🔗 Enlaces Relacionados

- [VARIABLES_ENTORNO.md](./VARIABLES_ENTORNO.md) - Variables del backend
- [CREAR_BASE_DATOS_RAILWAY.md](./CREAR_BASE_DATOS_RAILWAY.md) - Cómo crear PostgreSQL
- [VERIFICAR_BACKEND_RAILWAY.md](./VERIFICAR_BACKEND_RAILWAY.md) - Verificar backend completo

