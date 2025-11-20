-- ============================================
-- AGREGAR CAMPOS FALTANTES A LA TABLA users
-- Versión para Railway PostgreSQL
-- Usa tipos comunes: TEXT y timestamp
-- ============================================

-- PASO 1: Agregar campo password_hash (TEXT)
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- PASO 2: Agregar campo created_at (timestamp)
-- timestamp es el tipo más común en PostgreSQL
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at timestamp DEFAULT CURRENT_TIMESTAMP;

-- PASO 3: Actualizar usuarios existentes con fecha actual
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

-- ============================================
-- ALTERNATIVAS SI TIMESTAMP NO FUNCIONA:
-- ============================================

-- Opción 1: Usar DATE (solo fecha, sin hora)
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at DATE DEFAULT CURRENT_DATE;

-- Opción 2: Usar BIGINT (guardar como número Unix timestamp)
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW());

-- Opción 3: Usar texto (guardar como string ISO 8601)
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TEXT DEFAULT TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS');

