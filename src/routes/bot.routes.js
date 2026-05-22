const express = require('express');
const router = express.Router();
const botController = require('../controllers/bot.controller');

// GET /api/bots
router.get('/', botController.listar);

// GET /api/bots/slug/:slug (debe ir antes de /:id para evitar conflicto)
router.get('/slug/:slug', botController.obtenerPorSlug);

// GET /api/bots/:id
router.get('/:id', botController.obtenerPorId);

// POST /api/bots
router.post('/', botController.crear);

// PUT /api/bots/:id
router.put('/:id', botController.actualizar);

// PATCH /api/bots/:id/status
router.patch('/:id/status', botController.cambiarEstado);

// DELETE /api/bots/:id
router.delete('/:id', botController.eliminar);

module.exports = router;
