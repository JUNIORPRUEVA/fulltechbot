-- ============================================
-- TABLA DE USUARIOS PARA AUTENTICACIÓN
-- ============================================
-- Ejecutar este script en la base de datos PostgreSQL
-- ============================================

CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    rol VARCHAR(50) NOT NULL DEFAULT 'admin',
    activo BOOLEAN NOT NULL DEFAULT true,
    ultimo_acceso TIMESTAMP,
    creado_en TIMESTAMP NOT NULL DEFAULT NOW(),
    actualizado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ============================================
-- USUARIO ADMIN POR DEFECTO
-- ============================================
-- Email: admin@fulltech.com
-- Contraseña: Admin123!
-- La contraseña está hasheada con bcrypt
-- ============================================

INSERT INTO usuarios (nombre, email, password_hash, rol)
VALUES (
    'Administrador FULLTECH',
    'admin@fulltech.com',
    '$2b$10$8K1p/a0dL1LXMIgoEDFrwOfMQkfAjkMBcGmF0xP5y0n0C0X9X7XKq',
    'admin'
) ON CONFLICT (email) DO NOTHING;

-- ============================================
-- ÍNDICES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(rol);
CREATE INDEX IF NOT EXISTS idx_usuarios_activo ON usuarios(activo);
