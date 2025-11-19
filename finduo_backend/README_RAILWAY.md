# Desplegar en Railway

## Pasos para desplegar el backend en Railway:

1. **Crear cuenta en Railway** (si no tienes una):
   - Ve a https://railway.app
   - Regístrate con GitHub

2. **Crear nuevo proyecto**:
   - Click en "New Project"
   - Selecciona "Deploy from GitHub repo"
   - Conecta tu repositorio y selecciona la carpeta `finduo_backend`

3. **Configurar variables de entorno**:
   En Railway, ve a tu servicio → Variables y agrega:
   - `EMAIL_USER`: Tu correo de Gmail
   - `EMAIL_PASSWORD`: Tu App Password de Gmail (no tu contraseña normal)
   - `DATABASE_URL`: Se configura automáticamente si agregas un servicio PostgreSQL

4. **Agregar base de datos PostgreSQL** (opcional pero recomendado):
   - En tu proyecto Railway, click en "New" → "Database" → "Add PostgreSQL"
   - Railway configurará automáticamente la variable `DATABASE_URL`

5. **Desplegar**:
   - Railway detectará automáticamente el `Dockerfile` y desplegará tu aplicación
   - Una vez desplegado, obtendrás una URL como: `https://tu-proyecto.up.railway.app`

6. **Probar**:
   - Visita: `https://tu-proyecto.up.railway.app/health`
   - Deberías ver: `{"status":"ok"}`

## Notas importantes:

- El `Dockerfile` ya está configurado para Railway
- El `railway.json` contiene la configuración de despliegue
- La aplicación usará PostgreSQL si `DATABASE_URL` está configurada, sino usará SQLite (no recomendado en producción)
- Asegúrate de configurar las variables de entorno antes del primer despliegue

