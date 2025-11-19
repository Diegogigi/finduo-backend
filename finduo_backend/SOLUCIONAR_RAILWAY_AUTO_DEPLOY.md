# 🔧 Solucionar Despliegue Automático en Railway

## Problema
Railway no se actualiza automáticamente cuando haces `git push` a GitHub.

## Soluciones

### 1. Verificar que Railway esté conectado al repositorio correcto

1. Ve a **https://railway.app**
2. Selecciona tu proyecto
3. Click en el **servicio** (tu backend)
4. Ve a la pestaña **"Settings"**
5. Busca la sección **"Source"** o **"Repository"**
6. Verifica que esté conectado a:
   - **Repositorio**: `Diegogigi/finduo-backend` (con D mayúscula)
   - **Rama**: `main` (no `master`)

### 2. Verificar la rama que Railway está monitoreando

Si Railway está monitoreando `master` pero ahora estás usando `main`:

**Opción A: Cambiar Railway para que monitoree `main`**
1. En Railway, ve a **Settings** del servicio
2. Busca **"Branch"** o **"Source Branch"**
3. Cambia de `master` a `main`
4. Guarda los cambios

**Opción B: Cambiar tu repositorio local a `master`**
```powershell
git branch -M master
git push -u origin master
```

### 3. Reconectar el repositorio en Railway

Si el repositorio cambió de nombre o usuario:

1. En Railway, ve a **Settings** del servicio
2. Busca **"Disconnect Repository"** o **"Change Source"**
3. Click en **"Connect Repository"** o **"Change Source"**
4. Selecciona: `Diegogigi/finduo-backend`
5. Selecciona la rama: `main`
6. Guarda los cambios

### 4. Verificar los webhooks de GitHub

1. Ve a tu repositorio en GitHub: https://github.com/Diegogigi/finduo-backend
2. Click en **"Settings"** (del repositorio)
3. Ve a **"Webhooks"** en el menú lateral
4. Verifica que haya un webhook de Railway
5. Si no existe, Railway lo creará automáticamente cuando reconectes el repositorio

### 5. Forzar un nuevo despliegue

Después de verificar la configuración:

1. En Railway, ve a tu servicio
2. Click en **"Deployments"** o **"Deploys"**
3. Click en **"Redeploy"** o **"Deploy"** para forzar un despliegue manual
4. Esto también puede reactivar el webhook

### 6. Verificar que el código esté en la rama correcta

```powershell
# Verificar rama actual
git branch

# Si no estás en main, cambiar a main
git checkout main

# Verificar que los cambios estén en GitHub
git log origin/main -5
```

## Verificación Final

Después de aplicar las soluciones:

1. Haz un cambio pequeño en el código
2. Haz commit y push:
   ```powershell
   git add .
   git commit -m "Test: verificar despliegue automático"
   git push
   ```
3. Ve a Railway y verifica que aparezca un nuevo despliegue automáticamente

## Problemas Comunes

### Railway muestra "No deployments"
- Verifica que el repositorio esté conectado correctamente
- Asegúrate de que la rama `main` tenga commits

### El webhook no se activa
- Verifica los permisos de Railway en GitHub
- Ve a GitHub → Settings → Applications → Authorized OAuth Apps
- Asegúrate de que Railway tenga permisos

### Railway está conectado pero no despliega
- Verifica los logs en Railway (pestaña "Deployments")
- Revisa si hay errores en el build
- Verifica que el `Dockerfile` esté en la raíz del repositorio

