# 🔐 Variables de Entorno Requeridas en Railway

## 📋 Variables Obligatorias

### 1. `EMAIL_USER`

- **Descripción**: Tu dirección de correo electrónico de Gmail
- **Ejemplo**: `tu_correo@gmail.com`
- **Uso**: Se usa para conectarse a Gmail vía IMAP y leer los correos del banco
- **⚠️ Importante**: Debe ser el mismo correo donde recibes los correos del banco

### 2. `EMAIL_PASSWORD`

- **Descripción**: App Password de Gmail (NO tu contraseña normal)
- **Ejemplo**: `abcd efgh ijkl mnop` (16 caracteres sin espacios)
- **Uso**: Se usa para autenticarse en Gmail vía IMAP
- **⚠️ CRÍTICO**:
  - **NO uses tu contraseña normal de Gmail**
  - Debes crear una "App Password" específica
  - Cómo obtenerla:
    1. Ve a: https://myaccount.google.com
    2. Seguridad → Verificación en 2 pasos (debe estar activada)
    3. Contraseñas de aplicaciones → Selecciona "Correo" y "Otro (personalizado)"
    4. Nombre: "FinDuo" o "Railway"
    5. Copia la contraseña generada (16 caracteres)

### 3. `DATABASE_URL`

- **Descripción**: URL de conexión a la base de datos PostgreSQL
- **Ejemplo**: `postgresql://user:password@host:port/dbname`
- **Uso**: Se usa para conectarse a la base de datos
- **⚠️ Importante**:
  - Si agregas PostgreSQL en Railway, esta variable se configura **automáticamente**
  - No necesitas crearla manualmente si usas PostgreSQL de Railway
  - Si no está configurada, usará SQLite local (no recomendado en producción)

## 📝 Variables Opcionales

### 4. `SECRET_KEY` ⚠️ **RECOMENDADA** (Para autenticación JWT)

- **Descripción**: Clave secreta para firmar tokens JWT
- **Ejemplo**: `mi-clave-secreta-super-segura-123456`
- **Uso**: Se usa para generar y verificar tokens JWT en el sistema de autenticación
- **⚠️ Importante**:
  - Si no está configurada, usa el valor por defecto (no recomendado para producción)
  - Debe ser una cadena aleatoria y segura
  - Puedes usar cualquier string largo y aleatorio
- **Cómo configurarla**: Railway → Servicio backend → Variables → Agregar `SECRET_KEY`

### 5. `PORT` (Automática en Railway)

- **Descripción**: Puerto donde corre la aplicación
- **Ejemplo**: `8080`
- **Uso**: Railway la inyecta automáticamente
- **⚠️ No necesitas configurarla manualmente**

## 🔍 Cómo Verificar Variables en Railway

1. Ve a **https://railway.app**
2. Selecciona tu proyecto
3. Click en el servicio **`finduo-backend`**
4. Ve a la pestaña **"Variables"**
5. Verifica que estén configuradas:
   - ✅ `DATABASE_URL` (OBLIGATORIA - debe estar configurada con la URL del PostgreSQL)
   - ✅ `SECRET_KEY` (Recomendada - para autenticación JWT)
   - ⚠️ `EMAIL_USER` (Solo si usas sincronización de correos)
   - ⚠️ `EMAIL_PASSWORD` (Solo si usas sincronización de correos)

## ✅ Checklist de Configuración

- [ ] `DATABASE_URL` configurada con la URL del PostgreSQL (OBLIGATORIA)
- [ ] `SECRET_KEY` configurada (Recomendada para producción)
- [ ] `EMAIL_USER` configurada con tu correo de Gmail (Solo si usas correos)
- [ ] `EMAIL_PASSWORD` configurada con App Password de Gmail (Solo si usas correos)
- [ ] Verificación en 2 pasos activada en Gmail (Solo si usas correos)
- [ ] App Password creada en Gmail (Solo si usas correos)

## 🚨 Problemas Comunes

### Error: "EMAIL_USER y EMAIL_PASSWORD deben estar configuradas"

- **Solución**: Verifica que ambas variables estén en Railway → Variables

### Error: "Authentication failed" o "Login failed"

- **Solución**:
  - Verifica que `EMAIL_PASSWORD` sea una App Password (no tu contraseña normal)
  - Verifica que la verificación en 2 pasos esté activada
  - Crea una nueva App Password si es necesario

### Error: "No se encontraron correos"

- **Solución**:
  - Verifica que `EMAIL_USER` sea el correo donde recibes los correos del banco
  - Verifica que los correos estén en el INBOX (no en otras carpetas)
  - Revisa los logs en Railway para ver qué está pasando

### Error de conexión a base de datos

- **Solución**:
  - Si usas PostgreSQL, agrega el servicio PostgreSQL en Railway
  - Railway configurará `DATABASE_URL` automáticamente
  - Si no, verifica que la URL sea correcta

## 📝 Notas Importantes

1. **Seguridad**:

   - Nunca compartas tus variables de entorno públicamente
   - Las App Passwords son más seguras que usar tu contraseña normal
   - Railway encripta las variables de entorno

2. **Actualización**:

   - Si cambias tu contraseña de Gmail, necesitas crear una nueva App Password
   - Actualiza `EMAIL_PASSWORD` en Railway con la nueva App Password

3. **Múltiples Entornos**:
   - Puedes tener diferentes variables para desarrollo y producción
   - Railway permite configurar variables por servicio
