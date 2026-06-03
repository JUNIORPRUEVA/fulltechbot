/**
 * AUTH SERVICE
 *
 * Servicio de autenticacion con JWT.
 * Compatible con tablas `usuarios` antiguas y nuevas.
 */

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');

const JWT_SECRET = process.env.JWT_SECRET || 'fulltech-bot-jwt-secret-2026';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';

/**
 * Iniciar sesion
 * @param {string} email
 * @param {string} password
 * @returns {Object} { token, usuario }
 */
async function login(email, password) {
  const rows = await prisma.$queryRawUnsafe(
    'SELECT * FROM usuarios WHERE email = $1 LIMIT 1',
    email.toLowerCase().trim()
  );

  if (!rows || rows.length === 0) {
    throw new Error('Credenciales invalidas');
  }

  const usuario = rows[0];
  const activo = usuario.activo ?? true;
  const passwordHash = usuario.password_hash ?? usuario.password ?? null;

  if (!activo || !passwordHash) {
    throw new Error('Credenciales invalidas');
  }

  const passwordValido = await bcrypt.compare(password, passwordHash);
  if (!passwordValido) {
    throw new Error('Credenciales invalidas');
  }

  if (Object.prototype.hasOwnProperty.call(usuario, 'ultimo_acceso')) {
    await prisma.$executeRawUnsafe(
      'UPDATE usuarios SET ultimo_acceso = NOW() WHERE id = $1',
      usuario.id
    );
  }

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
 * @returns {Object|null}
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
      message: 'Token de autenticacion requerido',
    });
  }

  const token = authHeader.split(' ')[1];
  const payload = verificarToken(token);

  if (!payload) {
    return res.status(401).json({
      ok: false,
      message: 'Token invalido o expirado',
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
    'SELECT * FROM usuarios WHERE id = $1 LIMIT 1',
    usuarioId
  );

  if (!rows[0]) {
    return null;
  }

  const usuario = rows[0];
  return {
    id: usuario.id,
    nombre: usuario.nombre,
    email: usuario.email,
    rol: usuario.rol,
    activo: usuario.activo ?? true,
    ultimo_acceso: usuario.ultimo_acceso ?? null,
    creado_en: usuario.creado_en ?? usuario.created_at ?? null,
    actualizado_en: usuario.actualizado_en ?? usuario.updated_at ?? null,
  };
}

module.exports = {
  login,
  verificarToken,
  authMiddleware,
  adminMiddleware,
  getPerfil,
};
