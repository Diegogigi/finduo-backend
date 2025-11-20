# 🔄 Migrar Tabla users en Railway

Esta guía te ayudará a actualizar la tabla `users` existente en Railway para que coincida con el esquema correcto.

## 📋 Problema Identificado

La tabla `users` en Railway tiene:
- ❌ `identificación` (debería ser `id`)
- ❌ `correo electrónico` (debería ser `email`)
- ❌ `nombre` (debería ser `name`)
- ❌ Falta `password_hash` (necesario para autenticación)
- ❌ Falta `created_at` (timestamp de creación)

## ✅ Solución

### Opción 1: Ejecutar Script SQL Manualmente (Recomendado)

1. **Ve a Railway Dashboard**
   - Accede a [Railway Dashboard](https://railway.app)
   - Selecciona tu proyecto
   - Haz clic en el servicio de **PostgreSQL**

2. **Abre la Consola SQL**
   - Haz clic en la pestaña **"Query"** o **"SQL"**
   - O busca la opción para ejecutar queries SQL

3. **Copia y Ejecuta el Script**
   - Abre el archivo `migrate_users_table.sql`
   - Copia TODO el contenido
   - Pégalo en la consola SQL de Railway
   - Ejecuta el script

4. **Verifica el Resultado**
   - Ejecuta esta consulta para verificar:
   ```sql
   SELECT column_name, data_type, is_nullable 
   FROM information_schema.columns 
   WHERE table_name = 'users'
   ORDER BY ordinal_position;
   ```

   **Deberías ver:**
   - `id` (integer, not null)
   - `email` (varchar, not null, unique)
   - `name` (varchar, nullable)
   - `password_hash` (varchar, nullable)
   - `created_at` (timestamp, nullable, default CURRENT_TIMESTAMP)

### Opción 2: Eliminar y Recrear la Tabla (⚠️ SOLO si no tienes datos importantes)

**⚠️ ADVERTENCIA: Esto eliminará todos los usuarios existentes**

```sql
-- ⚠️ SOLO EJECUTA ESTO SI NO TIENES DATOS IMPORTANTES
DROP TABLE IF EXISTS users CASCADE;

-- Recrear la tabla con la estructura correcta
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR UNIQUE NOT NULL,
    name VARCHAR NOT NULL,
    password_hash VARCHAR,  -- Nullable para compatibilidad
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_id ON users(id);
```

### Opción 3: Las Tablas se Recrearán Automáticamente (Si no hay datos importantes)

Si la tabla se creó incorrectamente y **no tienes datos importantes**:

1. **Elimina la tabla manualmente en Railway:**
   ```sql
   DROP TABLE IF EXISTS users CASCADE;
   ```

2. **Reinicia el backend en Railway:**
   - Ve a tu servicio de backend
   - Haz clic en **"Redeploy"**
   - Las tablas se recrearán automáticamente con la estructura correcta

3. **Verifica que se hayan creado correctamente**

## 🔍 Verificar que la Migración Funcionó

### 1. Verificar Estructura de la Tabla

```sql
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;
```

**Resultado esperado:**
```
column_name    | data_type | is_nullable | column_default
---------------|-----------|-------------|----------------
id             | integer   | NO          | nextval('users_id_seq'::regclass)
email          | character varying | NO | NULL
name           | character varying | YES | NULL
password_hash  | character varying | YES | NULL
created_at     | timestamp without time zone | YES | CURRENT_TIMESTAMP
```

### 2. Verificar Índices

```sql
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'users';
```

**Deberías ver:**
- `idx_users_email`
- `idx_users_id`
- `users_pkey` (clave primaria)

### 3. Verificar Restricciones

```sql
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'users';
```

**Deberías ver:**
- `users_pkey` (PRIMARY KEY)
- `users_email_key` (UNIQUE)

## 🚨 Troubleshooting

### Error: "column already exists"
- **Solución:** El script detecta columnas existentes y no intenta crearlas de nuevo
- Es seguro ejecutar el script múltiples veces

### Error: "cannot rename column because it does not exist"
- **Solución:** Las columnas ya tienen los nombres correctos
- El script verifica antes de renombrar

### Error: "relation does not exist"
- **Solución:** La tabla no existe. El backend la creará automáticamente al iniciar
- O crea la tabla manualmente usando `database_schema.sql`

### Las columnas siguen teniendo nombres en español
- **Solución:** Ejecuta manualmente los comandos de renombrado:
  ```sql
  ALTER TABLE users RENAME COLUMN "identificación" TO id;
  ALTER TABLE users RENAME COLUMN "correo electrónico" TO email;
  ALTER TABLE users RENAME COLUMN nombre TO name;
  ```

## ✅ Después de la Migración

1. ✅ Verifica que la tabla tenga la estructura correcta
2. ✅ Verifica que los índices estén creados
3. ✅ Prueba crear un usuario nuevo desde la app móvil
4. ✅ Verifica que el login funcione correctamente

## 📝 Notas Importantes

- **El script es idempotente:** Puedes ejecutarlo múltiples veces sin problemas
- **No elimina datos:** Los usuarios existentes se conservan
- **Agrega campos faltantes:** Los campos nuevos se agregan sin afectar datos existentes
- **Renombra columnas:** Si las columnas tienen nombres en español, se renombran correctamente

## 🔗 Archivos Relacionados

- `database_schema.sql` - Esquema completo de la base de datos
- `migrate_users_table.sql` - Script de migración para la tabla users
- `app/models.py` - Modelos de SQLAlchemy

