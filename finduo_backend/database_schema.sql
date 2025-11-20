-- ============================================
-- FinDuo Database Schema
-- PostgreSQL Database Schema
-- ============================================
-- Este archivo contiene todas las tablas necesarias para la aplicación FinDuo
-- Las tablas se crean automáticamente mediante SQLAlchemy, pero este archivo
-- sirve como documentación y puede usarse para crear las tablas manualmente
-- ============================================

-- ============================================
-- TABLA: users
-- Descripción: Almacena información de los usuarios
-- Relaciones: 
--   - Una relación uno a muchos con transactions
--   - Una relación uno a muchos con duo_memberships
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR UNIQUE NOT NULL,
    name VARCHAR NOT NULL,
    password_hash VARCHAR,  -- Nullable para compatibilidad con usuarios existentes
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para optimizar búsquedas
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_id ON users(id);

-- ============================================
-- TABLA: duo_rooms
-- Descripción: Representa una "sala" o "pareja" de usuarios
-- Cada pareja tiene un código de invitación único
-- ============================================
CREATE TABLE IF NOT EXISTS duo_rooms (
    id SERIAL PRIMARY KEY,
    name VARCHAR DEFAULT 'FinDuo',
    invite_code VARCHAR UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para optimizar búsquedas
CREATE INDEX IF NOT EXISTS idx_duo_rooms_invite_code ON duo_rooms(invite_code);
CREATE INDEX IF NOT EXISTS idx_duo_rooms_id ON duo_rooms(id);

-- ============================================
-- TABLA: duo_memberships
-- Descripción: Relación entre usuarios y duo_rooms (parejas)
-- Cada usuario puede pertenecer a máximo una pareja activa
-- Roles: 'owner' (dueño) o 'partner' (pareja)
-- Estados: 'pending' (pendiente) o 'active' (activo)
-- ============================================
CREATE TABLE IF NOT EXISTS duo_memberships (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    room_id INTEGER NOT NULL REFERENCES duo_rooms(id) ON DELETE CASCADE,
    role VARCHAR NOT NULL DEFAULT 'partner',  -- 'owner' o 'partner'
    status VARCHAR NOT NULL DEFAULT 'pending',  -- 'pending' o 'active'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Un usuario solo puede tener una membresía activa por room
    UNIQUE(user_id, room_id)
);

-- Índices para optimizar búsquedas
CREATE INDEX IF NOT EXISTS idx_duo_memberships_user_id ON duo_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_duo_memberships_room_id ON duo_memberships(room_id);
CREATE INDEX IF NOT EXISTS idx_duo_memberships_status ON duo_memberships(status);

-- ============================================
-- TABLA: transactions
-- Descripción: Almacena todas las transacciones (ingresos y gastos)
-- Puede pertenecer a un usuario individual o a una pareja (duo_room)
-- Tipos: 'purchase', 'income', 'transfer_in', 'transfer_out'
-- ============================================
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    duo_room_id INTEGER REFERENCES duo_rooms(id) ON DELETE SET NULL,
    type VARCHAR NOT NULL,  -- 'purchase', 'income', 'transfer_in', 'transfer_out'
    description VARCHAR NOT NULL,
    amount INTEGER NOT NULL,  -- Monto en centavos (CLP)
    currency VARCHAR DEFAULT 'CLP',
    date_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para optimizar búsquedas y filtros
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_duo_room_id ON transactions(duo_room_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_date_time ON transactions(date_time DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, date_time DESC);

-- ============================================
-- COMENTARIOS SOBRE EL DISEÑO
-- ============================================
-- 
-- 1. AUTENTICACIÓN:
--    - La tabla users almacena email y password_hash
--    - password_hash es nullable para permitir migración de usuarios existentes
--    - Se puede agregar email_verified BOOLEAN DEFAULT FALSE en el futuro
--
-- 2. SISTEMA DE PAREJAS (DUO):
--    - Un usuario puede tener su cuenta individual (sin duo_membership)
--    - Un usuario puede invitar a una pareja creando un duo_room
--    - El creador del duo_room tiene role='owner'
--    - El invitado tiene role='partner'
--    - Cada duo_room puede tener máximo 2 miembros
--
-- 3. TRANSACCIONES:
--    - Si duo_room_id es NULL, la transacción es individual
--    - Si duo_room_id tiene valor, la transacción es compartida en pareja
--    - Todas las transacciones tienen un user_id (quien la creó)
--    - El amount se almacena en centavos para evitar problemas de decimales
--
-- 4. INTEGRIDAD REFERENCIAL:
--    - ON DELETE CASCADE: Si se elimina un usuario, se eliminan sus transacciones y membresías
--    - ON DELETE SET NULL: Si se elimina un duo_room, las transacciones se vuelven individuales
--
-- ============================================
-- CONSULTAS ÚTILES
-- ============================================
--
-- Ver todos los usuarios:
-- SELECT id, email, name, created_at FROM users;
--
-- Ver todas las parejas activas:
-- SELECT dr.id, dr.invite_code, u1.name as owner, u2.name as partner
-- FROM duo_rooms dr
-- JOIN duo_memberships dm1 ON dr.id = dm1.room_id AND dm1.role = 'owner'
-- JOIN users u1 ON dm1.user_id = u1.id
-- LEFT JOIN duo_memberships dm2 ON dr.id = dm2.room_id AND dm2.role = 'partner'
-- LEFT JOIN users u2 ON dm2.user_id = u2.id
-- WHERE dm1.status = 'active';
--
-- Ver transacciones de un usuario:
-- SELECT * FROM transactions WHERE user_id = ? ORDER BY date_time DESC;
--
-- Ver transacciones compartidas de una pareja:
-- SELECT * FROM transactions WHERE duo_room_id = ? ORDER BY date_time DESC;
--
-- ============================================

