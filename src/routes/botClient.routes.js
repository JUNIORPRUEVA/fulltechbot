const express = require('express');
const botClientController = require('../controllers/botClient.controller');
const { verificarPermisoEliminar } = require('../middleware/auth.middleware');

const router = express.Router({ mergeParams: true });

// GET /api/bots/:botId/clients - Listar todos los clientes
router.get('/', botClientController.listar);

// GET /api/bots/:botId/clients/by-phone/:telefono - Buscar por teléfono
router.get('/by-phone/:telefono', botClientController.obtenerPorTelefono);

// GET /api/bots/:botId/clients/by-chatid/:chatid - Buscar por chatid
router.get('/by-chatid/:chatid', botClientController.obtenerPorChatId);

// POST /api/bots/:botId/clients - Crear o actualizar cliente (upsert)
router.post('/', botClientController.buscarOCrear);

// PUT /api/bots/:botId/clients/:telefono - Actualizar cliente
router.put('/:telefono', botClientController.actualizar);

// PATCH /api/bots/:botId/clients/:telefono/status - Actualizar estado
router.patch('/:telefono/status', botClientController.actualizarEstado);

// PATCH /api/bots/:botId/clients/:telefono/pause-bot - Pausar/reanudar bot
router.patch('/:telefono/pause-bot', botClientController.pausarBot);

// DELETE /api/bots/:botId/clients/:telefono - Eliminar cliente (solo admin/owner)
router.delete('/:telefono', verificarPermisoEliminar, botClientController.eliminar);

module.exports = router;
