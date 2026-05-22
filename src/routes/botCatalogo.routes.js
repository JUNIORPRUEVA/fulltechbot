const express = require('express');
const router = express.Router({ mergeParams: true });
const catalogoController = require('../controllers/catalogo.controller');

// GET /api/bots/:botId/catalogo
router.get('/', catalogoController.listar);

// GET /api/bots/:botId/catalogo/activos
router.get('/activos', catalogoController.listarActivos);

// GET /api/bots/:botId/catalogo/:id
router.get('/:id', catalogoController.obtenerPorId);

// POST /api/bots/:botId/catalogo
router.post('/', catalogoController.crear);

// PUT /api/bots/:botId/catalogo/:id
router.put('/:id', catalogoController.actualizar);

// PATCH /api/bots/:botId/catalogo/:id/estado
router.patch('/:id/estado', catalogoController.cambiarEstado);

// DELETE /api/bots/:botId/catalogo/:id
router.delete('/:id', catalogoController.eliminar);

module.exports = router;
