/**
 * AUTH ROUTES
 * 
 * Rutas de autenticación.
 */

const express = require('express');
const router = express.Router();
const controller = require('../controllers/auth.controller');
const { authMiddleware } = require('../services/auth.service');

// Iniciar sesión
router.post('/login', controller.login);

// Verificar token
router.post('/verificar', controller.verificarToken);

// Obtener perfil (requiere autenticación)
router.get('/perfil', authMiddleware, controller.getPerfil);

module.exports = router;
