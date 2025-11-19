# Guía para Subir el Backend a GitHub y Railway

## Paso 1: Crear Repositorio en GitHub

1. Ve a https://github.com y inicia sesión
2. Click en el botón **"+"** (arriba a la derecha) → **"New repository"**
3. Configura el repositorio:
   - **Repository name**: `finduo-backend` (o el nombre que prefieras)
   - **Description**: "Backend FastAPI para FinDuo - Control de gastos en pareja"
   - **Visibility**: Elige **Private** o **Public**
   - **NO marques** "Initialize this repository with a README" (ya tenemos archivos)
4. Click en **"Create repository"**

## Paso 2: Conectar el Repositorio Local con GitHub

Después de crear el repositorio, GitHub te mostrará instrucciones. Ejecuta estos comandos:

```powershell
cd C:\Users\hp\Desktop\finduo_project\finduo_backend

# Agregar el repositorio remoto (reemplaza TU_USUARIO con tu usuario de GitHub)
git remote add origin https://github.com/TU_USUARIO/finduo-backend.git

# Cambiar la rama principal a 'main' (si GitHub usa 'main' en lugar de 'master')
git branch -M main

# Subir el código
git push -u origin main
```

**Nota**: Si GitHub creó el repositorio con la rama `master` en lugar de `main`, usa:
```powershell
git push -u origin master
```

## Paso 3: Autenticación con GitHub

Si te pide credenciales:
- **Usuario**: Tu usuario de GitHub
- **Contraseña**: Usa un **Personal Access Token** (no tu contraseña normal)
  - Crea uno en: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
  - Permisos necesarios: `repo` (acceso completo a repositorios)

## Paso 4: Conectar GitHub con Railway

1. Ve a https://railway.app e inicia sesión
2. Click en **"New Project"**
3. Selecciona **"Deploy from GitHub repo"**
4. Autoriza Railway para acceder a tu cuenta de GitHub (si es la primera vez)
5. Selecciona el repositorio `finduo-backend`
6. Railway detectará automáticamente el `Dockerfile` y comenzará el despliegue

## Paso 5: Configurar Variables de Entorno en Railway

Una vez que Railway esté desplegando:

1. Ve a tu proyecto en Railway
2. Click en el servicio desplegado
3. Ve a la pestaña **"Variables"**
4. Agrega estas variables:
   - `EMAIL_USER`: Tu correo de Gmail
   - `EMAIL_PASSWORD`: Tu App Password de Gmail (no tu contraseña normal)
   - `DATABASE_URL`: Se configura automáticamente si agregas PostgreSQL

## Paso 6: Agregar Base de Datos PostgreSQL (Recomendado)

1. En tu proyecto Railway, click en **"New"** → **"Database"** → **"Add PostgreSQL"**
2. Railway creará automáticamente la variable `DATABASE_URL`
3. Tu aplicación la usará automáticamente

## Paso 7: Obtener la URL de tu Backend

1. En Railway, ve a tu servicio
2. Click en la pestaña **"Settings"**
3. En **"Domains"**, Railway te dará una URL como: `https://tu-proyecto.up.railway.app`
4. Copia esta URL y actualiza `finduo_flutter/lib/config/api_config.dart` con ella

## Verificar el Despliegue

Visita: `https://tu-proyecto.up.railway.app/health`

Deberías ver: `{"status":"ok"}`

## Comandos Útiles para Futuros Cambios

```powershell
# Después de hacer cambios en el código:
cd C:\Users\hp\Desktop\finduo_project\finduo_backend
git add .
git commit -m "Descripción de los cambios"
git push

# Railway desplegará automáticamente los cambios
```

