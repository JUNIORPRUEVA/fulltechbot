const express = require('express');
const botCampaignController = require('../controllers/botCampaign.controller');

const router = express.Router({ mergeParams: true });

router.get('/conversations/:conversationId/campaign-context', botCampaignController.obtenerContextoConversacion);
router.get('/conversations/:conversationId/campaign-context/history', botCampaignController.obtenerHistorialContexto);
router.post('/bots/:botId/conversations/:conversationId/change-campaign', botCampaignController.cambiarCampanaManual);

module.exports = router;
