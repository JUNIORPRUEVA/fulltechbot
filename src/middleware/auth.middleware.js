/**
 * Middleware de autorización para operaciones de eliminación.
 * 
 * Roles permitidos para eliminar:
 * - admin
 * - owner (dueño)
 * - superadmin (si existe)
 * 
 * Cualquier otro rol (vendedor, técnico, usuario normal) NO puede eliminar.
 * 
 * IMPORTANTE: Como el sistema actual no tiene un sistema de autenticación completo,
 * este middleware verifica un header opcional 'X-User-Role' que debe ser enviado
 * desde el frontend. Si no se envía, se asume rol 'user' (sin permisos de eliminación).
 * 
 * Cuando se implemente autenticación real, este middleware debe actualizarse
 * para leer el rol desde el token JWT o sesión.
 */

const ROLES_PERMITIDOS = ['admin', 'owner', 'superadmin'];

/**
 * Middleware que verifica si el usuario tiene permisos para eliminar.
 * @param {Object} req - Request de Express
 * @param {Object} res - Response de Express
 * @param {Function} next - Next function
 */
function verificarPermisoEliminar(req, res, next) {
  const userRole = (req.headers['x-user-role'] || 'user').toLowerCase();

  if (!ROLES_PERMITIDOS.includes(userRole)) {
    return res.status(403).json({
      ok: false,
      message: 'No tienes permisos para realizar esta acción. Solo administradores y dueños pueden eliminar registros.',
    });
  }

  // Adjuntar el rol al request para uso posterior
  req.userRole = userRole;
  next();
}

/**
 * Middleware que verifica si el usuario tiene permisos de administración
 * (para operaciones sensibles como cambiar estado, pausar bot, etc.)
 */
function verificarPermisoAdmin(req, res, next) {
  const userRole = (req.headers['x-user-role'] || 'user').toLowerCase();

  if (!ROLES_PERMITIDOS.includes(userRole)) {
    return res.status(403).json({
      ok: false,
      message: 'No tienes permisos para realizar esta acción.',
    });
  }

  req.userRole = userRole;
  next();
}

module.exports = {
  verificarPermisoEliminar,
  verificarPermisoAdmin,
  ROLES_PERMITIDOS,
};
