-- ============================================
-- AJUSTAR CAMPO created_at EN LA TABLA users
-- Si created_at es TEXT, asegurar que tenga el default correcto
-- ============================================

-- Verificar el tipo actual de created_at
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'created_at';

-- ============================================
-- Si created_at es TEXT y no tiene default, agregarlo:
-- ============================================

-- Opción 1: Si created_at es TEXT, actualizar el default
-- (PostgreSQL puede tener problemas con CURRENT_TIMESTAMP en TEXT, usar función)
DO $$ 
BEGIN
    -- Verificar si created_at es TEXT y no tiene default
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'created_at' 
        AND data_type = 'text'
        AND (column_default IS NULL OR column_default = '')
    ) THEN
        -- Cambiar el default para usar una función que devuelva texto
        ALTER TABLE users 
        ALTER COLUMN created_at 
        SET DEFAULT TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS');
        
        RAISE NOTICE 'Default actualizado para created_at (TEXT)';
    ELSE
        RAISE NOTICE 'created_at ya tiene un default o no es TEXT';
    END IF;
END $$;

-- ============================================
-- ACTUALIZAR USUARIOS EXISTENTES SIN FECHA:
-- ============================================
UPDATE users 
SET created_at = TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS') 
WHERE created_at IS NULL OR created_at = '';

-- ============================================
-- VERIFICAR RESULTADO FINAL:
-- ============================================
SELECT 
    column_name AS "Columna",
    data_type AS "Tipo",
    is_nullable AS "Nullable",
    column_default AS "Default"
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('password_hash', 'created_at')
ORDER BY column_name;

-- ============================================
-- NOTA IMPORTANTE:
-- ============================================
-- Si created_at es TEXT, el código Python (SQLAlchemy) puede trabajar con él
-- siempre que el formato sea ISO 8601: 'YYYY-MM-DD HH24:MI:SS'
-- SQLAlchemy convertirá automáticamente entre TEXT y DateTime cuando sea necesario.
-- ============================================

