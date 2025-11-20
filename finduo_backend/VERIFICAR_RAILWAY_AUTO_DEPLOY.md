# ✅ Verificación: Despliegue Automático en Railway

## 🔍 Checklist de Verificación

### 1. Configuración del Repositorio en Railway

**Pasos:**
1. Ve a **https://railway.app**
2. Selecciona tu proyecto
3. Click en el **servicio** (tu backend)
4. Ve a **Settings** → **Source**

**Verifica que esté configurado así:**
- ✅ **Repository**: `Diegogigi/finduo-backend`
- ✅ **Branch**: `main` (NO `master`)
- ✅ **Root Directory**: `finduo_backend` ⚠️ **CRÍTICO**

**Si "Root Directory" está vacío o es diferente:**
- Railway no encontrará el código
- Cambia a `finduo_backend` y guarda
- Haz un **Redeploy** manual

### 2. Verificar Webhook de GitHub

**Pasos:**
1. Ve a: https://github.com/Diegogigi/finduo-backend/settings/hooks
2. Debe haber un webhook de Railway activo
3. Si no existe:
   - Ve a Railway → Settings → Source
   - Click en "Disconnect Repository"
   - Luego "Connect Repository"
   - Selecciona `Diegogigi/finduo-backend` y rama `main`
   - Railway creará el webhook automáticamente

### 3. Verificar Estructura de Archivos

**Si Root Directory = `finduo_backend`, debe existir:**
```
finduo_backend/
  ├── Dockerfile          ✅
  ├── railway.json        ✅
  ├── requirements.txt    ✅
  ├── start.sh            ✅
  └── app/
      ├── main.py         ✅
      ├── email_sync.py   ✅
      └── ...
```

### 4. Verificar que los Archivos Estén en GitHub

**Comando:**
```powershell
git ls-files finduo_backend/Dockerfile
git ls-files finduo_backend/railway.json
git ls-files finduo_backend/app/main.py
```

Todos deben aparecer (no dar error).

### 5. Probar Despliegue Automático

**Después de verificar todo:**

1. Haz un cambio pequeño (ej: agregar un comentario en `app/main.py`)
2. Commit y push:
   ```powershell
   git add finduo_backend/app/main.py
   git commit -m "Test: verificar despliegue automático"
   git push origin main
   ```
3. Ve a Railway → Deployments
4. Debe aparecer un nuevo despliegue automáticamente en 1-2 minutos

## 🚨 Problemas Comunes y Soluciones

### Problema: Railway no detecta cambios

**Solución:**
1. Verifica que "Root Directory" = `finduo_backend`
2. Verifica que "Branch" = `main`
3. Reconecta el repositorio en Railway
4. Verifica el webhook en GitHub

### Problema: Build falla

**Solución:**
1. Verifica los logs en Railway → Deployments
2. Verifica que `Dockerfile` esté en `finduo_backend/`
3. Verifica que `requirements.txt` tenga todas las dependencias
4. Verifica que `start.sh` sea ejecutable

### Problema: Webhook no se activa

**Solución:**
1. Ve a GitHub → Settings → Webhooks
2. Verifica que el webhook de Railway esté activo
3. Si no está, reconecta el repositorio en Railway
4. Verifica permisos de Railway en GitHub:
   - GitHub → Settings → Applications → Authorized OAuth Apps
   - Railway debe tener permisos

## 📝 Nota Final

**La configuración más común que causa problemas:**
- ❌ Root Directory vacío cuando el código está en `finduo_backend/`
- ❌ Branch = `master` cuando el código está en `main`
- ❌ Webhook desactivado o eliminado

**Solución rápida:**
1. Railway → Settings → Source
2. Root Directory: `finduo_backend`
3. Branch: `main`
4. Guardar
5. Redeploy manual
6. Probar con un commit nuevo

