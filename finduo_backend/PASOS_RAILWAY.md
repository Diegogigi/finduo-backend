# 🚂 Pasos para Desplegar en Railway

## ✅ Estado Actual
- ✅ Código subido a GitHub: https://github.com/Diegogigi/finduo-backend
- ✅ Repositorio configurado correctamente

## 📋 Pasos para Railway

### Paso 1: Crear Proyecto en Railway

1. Ve a **https://railway.app**
2. Inicia sesión con tu cuenta (puedes usar GitHub para autenticarte)
3. Click en **"New Project"**
4. Selecciona **"Deploy from GitHub repo"**
5. Si es la primera vez, autoriza Railway para acceder a tu cuenta de GitHub
6. Selecciona el repositorio: **`Diegogigi/finduo-backend`**
7. Railway detectará automáticamente el `Dockerfile` y comenzará el despliegue

### Paso 2: Configurar Variables de Entorno

Una vez que Railway esté desplegando:

1. En tu proyecto Railway, click en el **servicio desplegado**
2. Ve a la pestaña **"Variables"**
3. Click en **"New Variable"** y agrega:

   **Variable 1:**
   - **Name**: `EMAIL_USER`
   - **Value**: Tu correo de Gmail (ej: `tu_correo@gmail.com`)

   **Variable 2:**
   - **Name**: `EMAIL_PASSWORD`
   - **Value**: Tu App Password de Gmail
     - ⚠️ **NO uses tu contraseña normal**
     - Cómo obtener App Password:
       1. Ve a tu cuenta de Google: https://myaccount.google.com
       2. Seguridad → Verificación en 2 pasos (debe estar activada)
       3. Contraseñas de aplicaciones → Selecciona "Correo" y "Otro (personalizado)"
       4. Nombre: "FinDuo"
       5. Copia la contraseña generada (16 caracteres)

### Paso 3: Agregar Base de Datos PostgreSQL (Recomendado)

1. En tu proyecto Railway, click en **"New"**
2. Selecciona **"Database"** → **"Add PostgreSQL"**
3. Railway creará automáticamente la variable `DATABASE_URL`
4. Tu aplicación la usará automáticamente (ya está configurada en `database.py`)

### Paso 4: Obtener la URL de tu Backend

1. En Railway, ve a tu servicio
2. Click en la pestaña **"Settings"**
3. En la sección **"Domains"**, Railway te dará una URL como:
   ```
   https://finduo-backend-production-xxxx.up.railway.app
   ```
4. **Copia esta URL** - la necesitarás para la app Flutter

### Paso 5: Verificar el Despliegue

1. Visita la URL que Railway te dio
2. Agrega `/health` al final:
   ```
   https://tu-url.up.railway.app/health
   ```
3. Deberías ver: `{"status":"ok"}`

### Paso 6: Actualizar la App Flutter

1. Abre: `finduo_flutter/lib/config/api_config.dart`
2. Reemplaza la URL con la de Railway:
   ```dart
   static const String baseUrl = 'https://tu-url.up.railway.app';
   ```
3. Guarda el archivo

---

## 🔄 Despliegues Automáticos

Railway desplegará automáticamente cada vez que hagas `git push` a GitHub.

Para hacer cambios:
```powershell
cd C:\Users\hp\Desktop\finduo_project\finduo_backend
git add .
git commit -m "Descripción de los cambios"
git push
```

Railway detectará los cambios y desplegará automáticamente.

---

## 🐛 Solución de Problemas

### El despliegue falla:
- Verifica que el `Dockerfile` esté en la raíz del repositorio
- Revisa los logs en Railway (pestaña "Deployments")

### La app no se conecta al backend:
- Verifica que la URL en `api_config.dart` sea correcta
- Asegúrate de usar `https://` (no `http://`)
- Verifica que el backend esté desplegado (pestaña "Deployments" en Railway)

### Error de base de datos:
- Asegúrate de haber agregado PostgreSQL en Railway
- Verifica que la variable `DATABASE_URL` esté configurada automáticamente

---

## 📝 Notas Importantes

- Railway ofrece un plan gratuito con límites
- La URL puede cambiar si eliminas y recreas el servicio
- Las variables de entorno son sensibles - no las compartas públicamente
- El backend usará PostgreSQL automáticamente si `DATABASE_URL` está configurada

