-- ============================================
-- AGREGAR CAMPOS FALTANTES A LA TABLA users
-- Ejecutar esto en Railway PostgreSQL
-- ============================================

-- ============================================
-- PASO 1: Agregar campo password_hash
-- ============================================
-- Este campo almacena el hash de la contraseña del usuario
-- Es nullable porque puede haber usuarios existentes sin contraseña
-- En PostgreSQL, TEXT es equivalente a VARCHAR
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Verificar que se agregó correctamente
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'users' AND column_name = 'password_hash';

-- ============================================
-- PASO 2: Agregar campo created_at
-- ============================================
-- Este campo almacena la fecha y hora de creación del usuario
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT CURRENT_TIMESTAMP;

-- Actualizar usuarios existentes con la fecha actual
UPDATE users SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL;

-- Verificar que se agregó correctamente
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns 
-- WHERE table_name = 'users' AND column_name = 'created_at';

-- ============================================
-- PASO 3: Renombrar columnas en español (si es necesario)
-- ============================================

-- Renombrar "identificación" a "id" (si existe)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'identificación'
    ) THEN
        ALTER TABLE users RENAME COLUMN "identificación" TO id;
        RAISE NOTICE 'Columna "identificación" renombrada a "id"';
    END IF;
END $$;

-- Renombrar "correo electrónico" a "email" (si existe)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'correo electrónico'
    ) THEN
        ALTER TABLE users RENAME COLUMN "correo electrónico" TO email;
        RAISE NOTICE 'Columna "correo electrónico" renombrada a "email"';
    END IF;
END $$;

-- Renombrar "nombre" a "name" (si existe)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'nombre'
    ) THEN
        ALTER TABLE users RENAME COLUMN nombre TO name;
        RAISE NOTICE 'Columna "nombre" renombrada a "name"';
    END IF;
END $$;

-- ============================================
-- PASO 4: Verificar estructura final
-- ============================================
-- Ejecuta esto para ver todas las columnas de la tabla users:
SELECT 
    column_name AS "Nombre de Columna",
    data_type AS "Tipo de Dato",
    is_nullable AS "Puede ser NULL",
    column_default AS "Valor por Defecto"
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- ============================================
-- ESTRUCTURA ESPERADA DESPUÉS DE EJECUTAR:
-- ============================================
-- id             | integer   | NO  | nextval('users_id_seq'::regclass)
-- email          | varchar   | NO  | NULL
-- name           | varchar   | YES | NULL
-- password_hash  | varchar   | YES | NULL         ← NUEVO
-- created_at     | timestamp | YES | CURRENT_TIMESTAMP  ← NUEVO
-- ============================================

