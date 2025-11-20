# 🔧 Solucionar Servicio Duplicado en Railway

## ⚠️ Problema

Al reconectar el repositorio en Railway, apareció un nuevo servicio llamado `feisty-solace` al lado de `finduo-backend`.

## ✅ Solución

### Opción 1: Usar el Servicio Existente (RECOMENDADO)

1. **Mantén el servicio `finduo-backend`** (el original)
2. **Elimina el servicio `feisty-solace`** (el nuevo):
   - Click en el servicio `feisty-solace`
   - Ve a **Settings** → **General**
   - Desplázate hacia abajo
   - Click en **"Delete Service"** o **"Remove"**
   - Confirma la eliminación

3. **Configura el servicio `finduo-backend` correctamente:**
   - Click en el servicio `finduo-backend`
   - Ve a **Settings** → **Source**
   - Verifica o configura:
     - **Repository**: `Diegogigi/finduo-backend`
     - **Branch**: `main`
     - **Root Directory**: `finduo_backend` ⚠️ CRÍTICO
   - Guarda los cambios

4. **Reconecta el webhook manualmente:**
   - En el servicio `finduo-backend`, Settings → Source
   - Si dice "Disconnected" o similar, click en **"Connect Repository"**
   - Selecciona: `Diegogigi/finduo-backend`
   - Selecciona rama: `main`
   - Root Directory: `finduo_backend`
   - Guarda

### Opción 2: Usar el Nuevo Servicio

Si prefieres usar `feisty-solace`:

1. **Configura `feisty-solace` correctamente:**
   - Click en `feisty-solace`
   - Ve a **Settings** → **Source**
   - Configura:
     - **Repository**: `Diegogigi/finduo-backend`
     - **Branch**: `main`
     - **Root Directory**: `finduo_backend`
   - Guarda

2. **Elimina el servicio `finduo-backend`** (si no lo necesitas)

3. **Renombra `feisty-solace`** (opcional):
   - Settings → General
   - Cambia el nombre a `finduo-backend`
   - Guarda

## 🔍 Verificar Configuración

Independientemente de qué servicio uses, verifica:

1. **Settings → Source:**
   - ✅ Repository: `Diegogigi/finduo-backend`
   - ✅ Branch: `main`
   - ✅ Root Directory: `finduo_backend`

2. **Variables de Entorno (Settings → Variables):**
   - ✅ `EMAIL_USER`
   - ✅ `EMAIL_PASSWORD`
   - ✅ `DATABASE_URL` (si usas PostgreSQL)

3. **Webhook en GitHub:**
   - Ve a: https://github.com/Diegogigi/finduo-backend/settings/hooks
   - Debe haber un webhook activo de Railway
   - Si hay múltiples webhooks, verifica cuál está activo

## 🚀 Probar Despliegue Automático

Después de configurar:

1. Haz un cambio pequeño (ej: un comentario en `app/main.py`)
2. Commit y push:
   ```powershell
   git add finduo_backend/app/main.py
   git commit -m "Test: verificar despliegue automático"
   git push origin main
   ```
3. Ve a Railway → El servicio que configuraste → **Deployments**
4. Debe aparecer un nuevo despliegue automáticamente

## 📝 Recomendación

**Recomiendo usar el servicio `finduo-backend` original** porque:
- Ya tiene las variables de entorno configuradas
- Ya tiene el dominio/configuración establecida
- Es más limpio mantener el servicio original

Solo necesitas asegurarte de que tenga la configuración correcta en **Settings → Source**.

