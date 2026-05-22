const express = require('express');
const botConversationController = require('../controllers/botConversation.controller');

const router = express.Router({ mergeParams: true });

router.get('/', botConversationController.listar);
router.get('/:sessionId', botConversationController.obtenerPorSessionId);
router.post('/', botConversationController.crear);
router.delete('/:sessionId', botConversationController.eliminarPorSessionId);

module.exports = router;
