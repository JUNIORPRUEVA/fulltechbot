/**
 * AUTH CONTROLLER
 *
 * Controlador de autenticacion.
 */

const authService = require('../services/auth.service');

/**
 * POST /api/auth/login
 * Iniciar sesion
 */
async function login(req, res) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        ok: false,
        message: 'Email y contrasena son requeridos',
      });
    }

    const result = await authService.login(email, password);

    return res.json({
      ok: true,
      message: 'Inicio de sesion exitoso',
      data: result,
    });
  } catch (error) {
    if (
      error.message === 'Credenciales invalidas' ||
      error.message === 'Credenciales invÃ¡lidas'
    ) {
      return res.status(401).json({
        ok: false,
        message: 'Credenciales invalidas',
      });
    }

    console.error('[AUTH] Error en login:', error);
    return res.status(500).json({
      ok: false,
      message: 'Error interno del servidor',
    });
  }
}

/**
 * GET /api/auth/perfil
 * Obtener perfil del usuario autenticado
 */
async function getPerfil(req, res) {
  try {
    const perfil = await authService.getPerfil(req.usuario.id);

    if (!perfil) {
      return res.status(404).json({
        ok: false,
        message: 'Usuario no encontrado',
      });
    }

    return res.json({
      ok: true,
      data: perfil,
    });
  } catch (error) {
    console.error('[AUTH] Error en perfil:', error);
    return res.status(500).json({
      ok: false,
      message: 'Error interno del servidor',
    });
  }
}

/**
 * POST /api/auth/verificar
 * Verificar si un token es valido
 */
async function verificarToken(req, res) {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        ok: false,
        message: 'Token requerido',
      });
    }

    const payload = authService.verificarToken(token);

    if (!payload) {
      return res.json({
        ok: false,
        message: 'Token invalido o expirado',
        valido: false,
      });
    }

    return res.json({
      ok: true,
      valido: true,
      data: {
        id: payload.id,
        email: payload.email,
        nombre: payload.nombre,
        rol: payload.rol,
      },
    });
  } catch (error) {
    console.error('[AUTH] Error en verificar:', error);
    return res.status(500).json({
      ok: false,
      message: 'Error interno del servidor',
    });
  }
}

module.exports = {
  login,
  getPerfil,
  verificarToken,
};
