/**
 * AUTH SERVICE
 * 
 * Servicio de autenticación con JWT.
 * Usa la tabla 'usuarios' creada directamente en PostgreSQL.
 */

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');

const JWT_SECRET = process.env.JWT_SECRET || 'fulltech-bot-jwt-secret-2026';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';

/**
 * Iniciar sesión
 * @param {string} email
 * @param {string} password
 * @returns {Object} { token, usuario }
 */
async function login(email, password) {
  // Buscar usuario por email
  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM usuarios WHERE email = $1 AND activo = true LIMIT 1`,
    email.toLowerCase().trim()
  );

  if (!rows || rows.length === 0) {
    throw new Error('Credenciales inválidas');
  }

  const usuario = rows[0];

  // Verificar contraseña
  const passwordValido = await bcrypt.compare(password, usuario.password_hash);
  if (!passwordValido) {
    throw new Error('Credenciales inválidas');
  }

  // Actualizar último acceso
  await prisma.$executeRawUnsafe(
    `UPDATE usuarios SET ultimo_acceso = NOW() WHERE id = $1`,
    usuario.id
  );

  // Generar token JWT
  const token = jwt.sign(
    {
      id: usuario.id,
      email: usuario.email,
      nombre: usuario.nombre,
      rol: usuario.rol,
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );

  return {
    token,
    usuario: {
      id: usuario.id,
      nombre: usuario.nombre,
      email: usuario.email,
      rol: usuario.rol,
    },
  };
}

/**
 * Verificar token JWT
 * @param {string} token
 * @returns {Object|null} payload del token o null
 */
function verificarToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
}

/**
 * Middleware de Express para proteger rutas
 */
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      ok: false,
      message: 'Token de autenticación requerido',
    });
  }

  const token = authHeader.split(' ')[1];
  const payload = verificarToken(token);

  if (!payload) {
    return res.status(401).json({
      ok: false,
      message: 'Token inválido o expirado',
    });
  }

  req.usuario = payload;
  next();
}

/**
 * Middleware para verificar rol de administrador
 */
function adminMiddleware(req, res, next) {
  if (!req.usuario || req.usuario.rol !== 'admin') {
    return res.status(403).json({
      ok: false,
      message: 'Se requieren permisos de administrador',
    });
  }
  next();
}

/**
 * Obtener perfil del usuario actual
 */
async function getPerfil(usuarioId) {
  const rows = await prisma.$queryRawUnsafe(
    `SELECT id, nombre, email, rol, activo, ultimo_acceso, creado_en, actualizado_en
     FROM usuarios WHERE id = $1 LIMIT 1`,
    usuarioId
  );
  return rows[0] || null;
}

module.exports = {
  login,
  verificarToken,
  authMiddleware,
  adminMiddleware,
  getPerfil,
};
