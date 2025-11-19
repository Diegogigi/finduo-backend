# Instrucciones para Subir a GitHub (Usuario: diegogigi)

## ✅ Estado Actual

- ✅ Repositorio Git inicializado
- ✅ Commit inicial realizado
- ✅ Rama: `master`
- ✅ Usuario GitHub: `diegogigi`

## 📋 Pasos para Subir a GitHub

### Paso 1: Crear el Repositorio en GitHub

1. Ve a: **https://github.com/new**
2. Configuración:
   - **Repository name**: `finduo-backend`
   - **Description**: "Backend FastAPI para FinDuo"
   - **Visibility**: Elige Private o Public
   - ⚠️ **NO marques** "Add a README file"
   - ⚠️ **NO marques** "Add .gitignore"
   - ⚠️ **NO marques** "Choose a license"
3. Click en **"Create repository"**

### Paso 2: Subir el Código

**Opción A: Usar el script automático**

```powershell
cd C:\Users\hp\Desktop\finduo_project\finduo_backend
.\subir_github.ps1
```

**Opción B: Comandos manuales**

```powershell
cd C:\Users\hp\Desktop\finduo_project\finduo_backend

# Agregar el remote de GitHub
git remote add origin https://github.com/diegogigi/finduo-backend.git

# Subir el código
git push -u origin master
```

### Paso 3: Autenticación

Si GitHub te pide credenciales:

- **Usuario**: `diegogigi`
- **Contraseña**: Usa un **Personal Access Token** (NO tu contraseña normal)

**Cómo crear un Personal Access Token:**

1. Ve a: https://github.com/settings/tokens
2. Click en **"Generate new token"** → **"Generate new token (classic)"**
3. Configuración:
   - **Note**: "Railway Deployment"
   - **Expiration**: Elige una duración (90 días recomendado)
   - **Scopes**: Marca `repo` (acceso completo a repositorios)
4. Click en **"Generate token"**
5. **Copia el token** (solo se muestra una vez)
6. Úsalo como contraseña cuando Git te la pida

### Paso 4: Verificar

Visita: **https://github.com/diegogigi/finduo-backend**

Deberías ver todos tus archivos allí.

---

## 🚂 Después: Conectar con Railway

Una vez que el código esté en GitHub:

1. Ve a **https://railway.app** e inicia sesión
2. Click en **"New Project"**
3. Selecciona **"Deploy from GitHub repo"**
4. Autoriza Railway para acceder a GitHub (si es la primera vez)
5. Selecciona el repositorio **`diegogigi/finduo-backend`**
6. Railway detectará automáticamente el `Dockerfile` y comenzará el despliegue

### Configurar Variables en Railway:

1. En tu proyecto Railway, ve a **Variables**
2. Agrega:
   - `EMAIL_USER`: Tu correo de Gmail
   - `EMAIL_PASSWORD`: Tu App Password de Gmail
3. (Opcional) Agrega PostgreSQL: **New** → **Database** → **Add PostgreSQL**

### Obtener la URL:

1. En Railway, ve a **Settings** → **Domains**
2. Copia la URL (ej: `https://finduo-backend.up.railway.app`)
3. Actualiza `finduo_flutter/lib/config/api_config.dart` con esa URL

---

## 🔄 Para Futuros Cambios

```powershell
cd C:\Users\hp\Desktop\finduo_project\finduo_backend
git add .
git commit -m "Descripción de los cambios"
git push
```

Railway desplegará automáticamente los cambios.
