const express = require('express');
const botConversationController = require('../controllers/botConversation.controller');

const router = express.Router();

router.get('/', botConversationController.listar);
router.get('/:sessionId', botConversationController.obtenerPorSessionId);
router.post('/', botConversationController.crear);

module.exports = router;
