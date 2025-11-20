-- ============================================
-- AGREGAR CAMPOS FALTANTES A LA TABLA users
-- Versión Simple - Usar TEXT en lugar de VARCHAR
-- ============================================

-- PASO 1: Agregar campo password_hash
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- PASO 2: Agregar campo created_at
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- PASO 3: Actualizar usuarios existentes
UPDATE users SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL;

-- PASO 4: Verificar estructura final
SELECT 
    column_name AS "Nombre de Columna",
    data_type AS "Tipo de Dato",
    is_nullable AS "Puede ser NULL",
    column_default AS "Valor por Defecto"
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

