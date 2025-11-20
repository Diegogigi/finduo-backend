-- ============================================
-- VERIFICAR ESTRUCTURA DE LA TABLA users
-- Ejecutar esto para verificar que todo esté correcto
-- ============================================

-- Ver todas las columnas de la tabla users
SELECT 
    column_name AS "Nombre de Columna",
    data_type AS "Tipo de Dato",
    is_nullable AS "Puede ser NULL",
    column_default AS "Valor por Defecto"
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- ============================================
-- ESTRUCTURA ESPERADA:
-- ============================================
-- id             | integer   | NO  | nextval('users_id_seq'::regclass)
-- email          | text      | NO  | NULL
-- name           | text      | YES | NULL
-- password_hash  | text      | YES | NULL          ← Debe existir
-- created_at     | text      | YES | CURRENT_TIMESTAMP  ← Debe existir (como TEXT está bien)
-- ============================================

-- ============================================
-- VERIFICAR QUE LOS CAMPOS EXISTAN:
-- ============================================

-- Verificar password_hash
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'password_hash'
        ) THEN '✓ Campo password_hash existe'
        ELSE '✗ Campo password_hash NO existe'
    END AS estado;

-- Verificar created_at
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'users' AND column_name = 'created_at'
        ) THEN '✓ Campo created_at existe'
        ELSE '✗ Campo created_at NO existe'
    END AS estado;

-- ============================================
-- ACTUALIZAR created_at PARA USUARIOS EXISTENTES (si es necesario)
-- ============================================
-- Si tienes usuarios existentes sin fecha, ejecuta esto:
UPDATE users 
SET created_at = TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS') 
WHERE created_at IS NULL OR created_at = '';

-- ============================================
-- NOTA SOBRE created_at COMO TEXT:
-- ============================================
-- Si created_at es de tipo TEXT, está bien. El código Python
-- puede trabajar con strings de fecha. SQLAlchemy convertirá
-- automáticamente cuando sea necesario.
-- ============================================

