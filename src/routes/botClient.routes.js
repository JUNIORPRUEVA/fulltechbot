const express = require('express');
const botClientController = require('../controllers/botClient.controller');
const { verificarPermisoEliminar } = require('../middleware/auth.middleware');

const router = express.Router({ mergeParams: true });

// GET /api/bots/:botId/clients
// Listar todos los clientes del bot
router.get('/', botClientController.listar);

// GET /api/bots/:botId/clients/by-phone/:telefono
// Buscar cliente por teléfono
router.get('/by-phone/:telefono', botClientController.obtenerPorTelefono);

// GET /api/bots/:botId/clients/by-chatid/:chatid
// Buscar cliente por chatId
router.get('/by-chatid/:chatid', botClientController.obtenerPorChatId);

// POST /api/bots/:botId/clients
// Crear o actualizar cliente
router.post('/', botClientController.buscarOCrear);

// PATCH /api/bots/:botId/clients/:telefono/assign-bot
// Asignar botId a cliente existente
router.patch('/:telefono/assign-bot', botClientController.assignBot);

// PATCH /api/bots/:botId/clients/:telefono/status
// Actualizar estado del cliente
router.patch('/:telefono/status', botClientController.actualizarEstado);

// PATCH /api/bots/:botId/clients/:telefono/pause-bot
// Pausar o reanudar bot para ese cliente
router.patch('/:telefono/pause-bot', botClientController.pausarBot);

// PUT /api/bots/:botId/clients/:telefono
// Actualizar cliente
router.put('/:telefono', botClientController.actualizar);

// DELETE /api/bots/:botId/clients/:telefono
// Eliminar cliente
router.delete('/:telefono', verificarPermisoEliminar, botClientController.eliminar);

module.exports = router;