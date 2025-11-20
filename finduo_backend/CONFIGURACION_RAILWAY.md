# 🔧 Configuración Correcta de Railway

## ⚠️ Problema Identificado

El repositorio tiene archivos duplicados:
- En la **raíz**: `Dockerfile`, `railway.json`, `requirements.txt`, `start.sh`
- En **finduo_backend/**: `Dockerfile`, `railway.json`, `requirements.txt`, `start.sh`

Railway necesita saber **exactamente** dónde está el código del backend.

## ✅ Solución: Configurar Railway para usar `finduo_backend/`

### Opción 1: Configurar Railway para usar el subdirectorio (RECOMENDADO)

1. Ve a **https://railway.app**
2. Selecciona tu proyecto
3. Click en el **servicio** (tu backend)
4. Ve a la pestaña **"Settings"**
5. Busca la sección **"Source"** o **"Repository"**
6. Verifica o configura:
   - **Repositorio**: `Diegogigi/finduo-backend`
   - **Rama**: `main`
   - **Root Directory**: `finduo_backend` ⚠️ **ESTO ES CRÍTICO**
7. Guarda los cambios

### Opción 2: Verificar que Railway esté usando la raíz correctamente

Si Railway está configurado para usar la **raíz del repositorio**, entonces:
- Los archivos en la raíz deben ser los correctos
- El código debe estar en `app/` (no en `finduo_backend/app/`)

## 🔍 Verificación Paso a Paso

### 1. Verificar configuración en Railway

1. Ve a Railway → Tu Proyecto → Tu Servicio → **Settings**
2. Verifica:
   - ✅ **Repository**: `Diegogigi/finduo-backend`
   - ✅ **Branch**: `main`
   - ✅ **Root Directory**: `finduo_backend` (o vacío si usa la raíz)

### 2. Verificar estructura del código

Si **Root Directory** = `finduo_backend`:
- ✅ Debe existir: `finduo_backend/Dockerfile`
- ✅ Debe existir: `finduo_backend/railway.json`
- ✅ Debe existir: `finduo_backend/app/main.py`
- ✅ Debe existir: `finduo_backend/requirements.txt`

Si **Root Directory** = vacío (raíz):
- ✅ Debe existir: `Dockerfile` (en la raíz)
- ✅ Debe existir: `railway.json` (en la raíz)
- ✅ Debe existir: `app/main.py` (en la raíz)
- ✅ Debe existir: `requirements.txt` (en la raíz)

### 3. Verificar webhook de GitHub

1. Ve a: https://github.com/Diegogigi/finduo-backend/settings/hooks
2. Debe haber un webhook de Railway activo
3. Si no existe, Railway lo creará cuando reconectes el repositorio

### 4. Verificar que el Dockerfile sea correcto

El Dockerfile debe:
- ✅ Estar en el directorio que Railway está monitoreando
- ✅ Copiar `requirements.txt`
- ✅ Copiar el código (`app/`)
- ✅ Ejecutar `start.sh`

## 🚀 Forzar Re-despliegue

Después de verificar la configuración:

1. En Railway → Tu Servicio → **Deployments**
2. Click en **"Redeploy"** o **"Deploy Latest"**
3. Esto debería activar el webhook y futuros despliegues automáticos

## 📝 Notas Importantes

- Railway detecta cambios automáticamente cuando hay un `git push` a la rama monitoreada
- El webhook de GitHub debe estar activo
- La configuración de **Root Directory** es crítica para que Railway encuentre el código
- Si cambias la configuración, haz un **Redeploy** manual la primera vez

