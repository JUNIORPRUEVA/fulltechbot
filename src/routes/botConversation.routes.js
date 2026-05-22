const express = require('express');
const botConversationController = require('../controllers/botConversation.controller');
const { verificarPermisoEliminar } = require('../middleware/auth.middleware');

const router = express.Router({ mergeParams: true });

router.get('/', botConversationController.listar);
router.get('/:sessionId', botConversationController.obtenerPorSessionId);
router.post('/', botConversationController.crear);
router.delete('/:sessionId', verificarPermisoEliminar, botConversationController.eliminarPorSessionId);

module.exports = router;
