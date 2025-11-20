-- ============================================
-- Script de Migración para Tabla users
-- ============================================
-- Este script actualiza la tabla users existente en Railway
-- para que coincida con el esquema correcto
-- ============================================

-- Paso 1: Verificar la estructura actual de la tabla
-- Ejecuta esto primero para ver qué columnas tiene actualmente:
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'users';

-- Paso 2: Agregar el campo password_hash si no existe
-- (Este campo es nullable porque puede haber usuarios existentes sin contraseña)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'password_hash'
    ) THEN
        ALTER TABLE users ADD COLUMN password_hash VARCHAR;
        RAISE NOTICE 'Campo password_hash agregado a la tabla users';
    ELSE
        RAISE NOTICE 'El campo password_hash ya existe';
    END IF;
END $$;

-- Paso 3: Agregar el campo created_at si no existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
        -- Actualizar registros existentes con la fecha actual
        UPDATE users SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL;
        RAISE NOTICE 'Campo created_at agregado a la tabla users';
    ELSE
        RAISE NOTICE 'El campo created_at ya existe';
    END IF;
END $$;

-- Paso 4: Verificar que los nombres de las columnas sean correctos
-- Si las columnas tienen nombres en español, renómbralas
-- (Esto solo es necesario si las columnas tienen nombres en español)

-- Si la columna se llama "identificación" en lugar de "id"
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'identificación'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'id'
    ) THEN
        ALTER TABLE users RENAME COLUMN "identificación" TO id;
        RAISE NOTICE 'Columna "identificación" renombrada a "id"';
    END IF;
END $$;

-- Si la columna se llama "correo electrónico" en lugar de "email"
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'correo electrónico'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'email'
    ) THEN
        ALTER TABLE users RENAME COLUMN "correo electrónico" TO email;
        RAISE NOTICE 'Columna "correo electrónico" renombrada a "email"';
    END IF;
END $$;

-- Si la columna se llama "nombre" en lugar de "name"
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'nombre'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'name'
    ) THEN
        ALTER TABLE users RENAME COLUMN nombre TO name;
        RAISE NOTICE 'Columna "nombre" renombrada a "name"';
    END IF;
END $$;

-- Paso 5: Verificar índices
-- Crear índice en email si no existe
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_id ON users(id);

-- Paso 6: Verificar restricciones
-- Asegurar que email sea UNIQUE y NOT NULL
DO $$ 
BEGIN
    -- Agregar restricción UNIQUE a email si no existe
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'users_email_key'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_email_key UNIQUE (email);
        RAISE NOTICE 'Restricción UNIQUE agregada a email';
    END IF;
    
    -- Asegurar que email no sea NULL
    ALTER TABLE users ALTER COLUMN email SET NOT NULL;
    RAISE NOTICE 'Restricción NOT NULL agregada a email';
END $$;

-- Paso 7: Verificar la estructura final
-- Ejecuta esto después para verificar que todo esté correcto:
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns 
-- WHERE table_name = 'users'
-- ORDER BY ordinal_position;

-- ============================================
-- NOTAS:
-- ============================================
-- 1. Este script es seguro de ejecutar múltiples veces (idempotente)
-- 2. No elimina datos existentes
-- 3. Agrega campos faltantes sin afectar datos existentes
-- 4. Renombra columnas si tienen nombres en español
-- ============================================

