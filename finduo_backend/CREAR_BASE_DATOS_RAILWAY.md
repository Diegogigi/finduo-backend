# 🗄️ Crear Base de Datos PostgreSQL en Railway

Esta guía te mostrará cómo crear una base de datos PostgreSQL en Railway para FinDuo.

## 📋 Pasos para Crear la Base de Datos

### 1. Ir a Railway Dashboard

1. Ve a [https://railway.app](https://railway.app)
2. Inicia sesión con tu cuenta
3. Selecciona tu proyecto **finduo-backend**

### 2. Crear un Nuevo Servicio de PostgreSQL

1. En tu proyecto, haz clic en el botón **"+ New"** (arriba a la derecha)
2. Selecciona **"Database"** → **"Add PostgreSQL"**
3. Railway creará automáticamente un servicio de PostgreSQL

### 3. Obtener la URL de Conexión

1. Haz clic en el servicio de PostgreSQL que acabas de crear
2. Ve a la pestaña **"Variables"**
3. Busca la variable **`DATABASE_URL`** (Railway la crea automáticamente)
4. Copia el valor completo de `DATABASE_URL`
   - Se ve algo como: `postgresql://postgres:password@host:port/railway`

### 4. Configurar la Variable de Entorno en el Backend

1. Ve a tu servicio de backend (finduo-backend)
2. Haz clic en **"Variables"**
3. Busca o crea la variable **`DATABASE_URL`**
4. Pega el valor que copiaste del servicio de PostgreSQL
5. Guarda los cambios

**Nota:** Si ya existe una variable `DATABASE_URL`, reemplázala con la nueva.

### 5. Verificar que las Tablas se Crean Automáticamente

El backend usa SQLAlchemy con `Base.metadata.create_all(bind=engine)`, lo que significa que:

- ✅ Las tablas se crearán automáticamente cuando el backend inicie
- ✅ No necesitas ejecutar el archivo SQL manualmente
- ✅ Las tablas se crearán con la estructura definida en `app/models.py`

### 6. Verificar las Tablas Creadas (Opcional)

Si quieres verificar que las tablas se crearon correctamente:

1. En Railway, ve a tu servicio de PostgreSQL
2. Haz clic en la pestaña **"Query"**
3. Ejecuta esta consulta:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```

Deberías ver estas tablas:
- `users`
- `duo_rooms`
- `duo_memberships`
- `transactions`

## 🔍 Estructura de las Tablas

### 1. **users**
   - Almacena información de usuarios
   - Campos: `id`, `email`, `name`, `password_hash`, `created_at`

### 2. **duo_rooms**
   - Representa una "sala" o "pareja"
   - Campos: `id`, `name`, `invite_code`, `created_at`

### 3. **duo_memberships**
   - Relación entre usuarios y parejas
   - Campos: `id`, `user_id`, `room_id`, `role`, `status`, `created_at`
   - Un usuario puede tener su cuenta individual O estar en una pareja

### 4. **transactions**
   - Almacena ingresos y gastos
   - Campos: `id`, `user_id`, `duo_room_id`, `type`, `description`, `amount`, `currency`, `date_time`
   - Si `duo_room_id` es NULL, es una transacción individual
   - Si `duo_room_id` tiene valor, es una transacción compartida

## 🎯 Sistema de Parejas (DUO)

### Caso 1: Usuario Individual
- Un usuario se registra y puede crear transacciones individuales
- No tiene ningún registro en `duo_memberships`
- Sus transacciones tienen `duo_room_id = NULL`

### Caso 2: Usuario Invita a Pareja
1. El usuario crea un `duo_room` (sala de pareja)
2. Se crea un `duo_membership` con `role = 'owner'` y `status = 'active'`
3. Se genera un código de invitación único (`invite_code`)
4. El usuario comparte el código con su pareja

### Caso 3: Pareja Se Une
1. La pareja usa el código de invitación
2. Se crea un `duo_membership` con `role = 'partner'` y `status = 'active'`
3. Ambos usuarios pueden crear transacciones compartidas
4. Las transacciones compartidas tienen `duo_room_id` con el ID de la sala

## ✅ Verificación Final

Después de configurar todo:

1. ✅ El servicio de PostgreSQL está creado
2. ✅ La variable `DATABASE_URL` está configurada en el backend
3. ✅ El backend está desplegado y corriendo
4. ✅ Las tablas se crearon automáticamente (puedes verificarlo con la consulta SQL)

## 🚨 Troubleshooting

### Problema: "No se pueden crear las tablas"
- **Solución:** Verifica que `DATABASE_URL` esté configurada correctamente en el backend
- Revisa los logs del backend en Railway para ver errores específicos

### Problema: "Error de conexión a la base de datos"
- **Solución:** Verifica que la URL de conexión sea correcta
- Asegúrate de que el servicio de PostgreSQL esté activo (verde) en Railway

### Problema: "Tablas no existen"
- **Solución:** Las tablas se crean automáticamente al iniciar el backend
- Si no se crearon, revisa los logs del backend
- Puedes ejecutar manualmente el archivo `database_schema.sql` si es necesario

## 📝 Notas Importantes

- **PostgreSQL es la opción recomendada** porque:
  - Ya está configurado en el código
  - Es más robusto para aplicaciones en producción
  - Railway lo soporta nativamente

- **No uses MySQL** a menos que modifiques el código:
  - El código actual está optimizado para PostgreSQL
  - MySQL requiere cambios en el código y en SQLAlchemy

- **El archivo `database_schema.sql`** es principalmente para documentación
  - Las tablas se crean automáticamente mediante SQLAlchemy
  - Puedes usarlo como referencia o para crear las tablas manualmente si es necesario

