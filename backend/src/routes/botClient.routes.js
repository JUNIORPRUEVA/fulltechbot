const express = require('express');
const botClientController = require('../controllers/botClient.controller');

const router = express.Router();

// GET /api/bot/clients - Listar todos los clientes
router.get('/', botClientController.listar);

// GET /api/bot/clients/by-phone/:telefono - Buscar por teléfono
router.get('/by-phone/:telefono', botClientController.obtenerPorTelefono);

// GET /api/bot/clients/by-chatid/:chatid - Buscar por chatid
router.get('/by-chatid/:chatid', botClientController.obtenerPorChatId);

// POST /api/bot/clients - Crear o actualizar cliente (upsert)
router.post('/', botClientController.buscarOCrear);

// PUT /api/bot/clients/:telefono - Actualizar cliente
router.put('/:telefono', botClientController.actualizar);

// PATCH /api/bot/clients/:telefono/status - Actualizar estado
router.patch('/:telefono/status', botClientController.actualizarEstado);

// PATCH /api/bot/clients/:telefono/pause-bot - Pausar/reanudar bot
router.patch('/:telefono/pause-bot', botClientController.pausarBot);

// DELETE /api/bot/clients/:telefono - Eliminar cliente
router.delete('/:telefono', botClientController.eliminar);

module.exports = router;
