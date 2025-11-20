# 📝 Guía: Agregar Campos Faltantes a la Tabla users Manualmente

Esta guía te muestra cómo agregar los campos faltantes (`password_hash` y `created_at`) a la tabla `users` en Railway de forma manual y sencilla.

## 🎯 Campos que Faltan

Tu tabla `users` actualmente tiene:
- ✅ `id` (o "identificación")
- ✅ `email` (o "correo electrónico")
- ✅ `name` (o "nombre")
- ❌ `password_hash` ← **Falta este**
- ❌ `created_at` ← **Falta este**

## 📋 Pasos para Agregar los Campos Manualmente

### Paso 1: Ir a Railway PostgreSQL

1. Ve a [Railway Dashboard](https://railway.app)
2. Selecciona tu proyecto
3. Haz clic en el servicio de **PostgreSQL** (la base de datos)

### Paso 2: Abrir la Consola SQL

1. En el servicio de PostgreSQL, busca la pestaña:
   - **"Query"** o
   - **"SQL"** o
   - **"Console"** o
   - **"Data"** → **"Query"**
2. Deberías ver un editor de texto donde puedes escribir SQL

### Paso 3: Ejecutar los Comandos SQL

Copia y pega **cada comando uno por uno** y ejecútalo:

#### **Comando 1: Agregar campo password_hash**

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR;
```

**¿Qué hace?**
- Agrega la columna `password_hash` de tipo VARCHAR
- `IF NOT EXISTS` evita errores si la columna ya existe
- Es nullable (puede ser NULL) porque hay usuarios existentes sin contraseña

**Resultado esperado:**
```
Query OK, 0 rows affected
```

#### **Comando 2: Agregar campo created_at**

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
```

**¿Qué hace?**
- Agrega la columna `created_at` de tipo TIMESTAMP
- `DEFAULT CURRENT_TIMESTAMP` establece la fecha actual por defecto para nuevos usuarios

**Resultado esperado:**
```
Query OK, 0 rows affected
```

#### **Comando 3: Actualizar usuarios existentes con fecha actual**

```sql
UPDATE users SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL;
```

**¿Qué hace?**
- Asigna la fecha actual a todos los usuarios existentes que no tengan fecha de creación

**Resultado esperado:**
```
Query OK, X rows affected (donde X es el número de usuarios existentes)
```

### Paso 4: Verificar que los Campos se Agregaron

Ejecuta este comando para ver todas las columnas de la tabla:

```sql
SELECT 
    column_name AS "Nombre de Columna",
    data_type AS "Tipo de Dato",
    is_nullable AS "Puede ser NULL",
    column_default AS "Valor por Defecto"
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;
```

**Resultado esperado:**
```
Nombre de Columna | Tipo de Dato | Puede ser NULL | Valor por Defecto
------------------|--------------|----------------|-------------------
id                | integer      | NO             | nextval(...)
email             | varchar      | NO             | NULL
name              | varchar      | YES            | NULL
password_hash     | varchar      | YES            | NULL          ← NUEVO
created_at        | timestamp    | YES            | CURRENT_TIMESTAMP ← NUEVO
```

## ✅ Verificación Final

Después de ejecutar los comandos, verifica que:

1. ✅ El campo `password_hash` existe
2. ✅ El campo `created_at` existe
3. ✅ Los usuarios existentes tienen fecha de creación
4. ✅ La estructura de la tabla es correcta

## 🔄 Opcional: Renombrar Columnas en Español (si es necesario)

Si tus columnas tienen nombres en español, ejecuta estos comandos para renombrarlas:

### Renombrar "identificación" a "id"

```sql
ALTER TABLE users RENAME COLUMN "identificación" TO id;
```

### Renombrar "correo electrónico" a "email"

```sql
ALTER TABLE users RENAME COLUMN "correo electrónico" TO email;
```

### Renombrar "nombre" a "name"

```sql
ALTER TABLE users RENAME COLUMN nombre TO name;
```

**Nota:** Solo ejecuta estos comandos si tus columnas tienen esos nombres exactos en español.

## 📝 Resumen de Comandos (Todo en Uno)

Si quieres ejecutar todo de una vez, copia y pega esto:

```sql
-- Agregar password_hash
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR;

-- Agregar created_at
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Actualizar usuarios existentes
UPDATE users SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL;

-- Verificar estructura
SELECT 
    column_name AS "Nombre de Columna",
    data_type AS "Tipo de Dato",
    is_nullable AS "Puede ser NULL",
    column_default AS "Valor por Defecto"
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;
```

## 🚨 Solución de Problemas

### Error: "column already exists"
- **Solución:** El campo ya existe, no necesitas agregarlo. Continúa con el siguiente.

### Error: "column does not exist"
- **Solución:** Verifica que estés escribiendo el nombre de la tabla correctamente: `users` (en minúsculas)

### Error: "permission denied"
- **Solución:** Asegúrate de tener permisos de administrador en la base de datos de Railway

### No veo la pestaña "Query" o "SQL"
- **Solución:** 
  - En Railway, algunos servicios de PostgreSQL tienen la consola SQL en diferentes lugares
  - Busca: "Data" → "Query", "SQL Editor", "Database", o "Console"
  - O usa una herramienta externa como pgAdmin o DBeaver

## ✅ Después de Agregar los Campos

1. ✅ La tabla `users` ahora tiene todos los campos necesarios
2. ✅ Puedes registrar nuevos usuarios con contraseña
3. ✅ Los usuarios existentes pueden actualizar su contraseña
4. ✅ El sistema de autenticación funcionará correctamente

## 🔗 Archivo de Referencia

Si prefieres usar un script más completo, usa el archivo:
- `migrate_users_table.sql` - Script completo con verificaciones

