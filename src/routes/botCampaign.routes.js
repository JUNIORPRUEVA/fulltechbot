const express = require('express');
const botCampaignController = require('../controllers/botCampaign.controller');

const router = express.Router({ mergeParams: true });

router.get('/', botCampaignController.listar);
router.get('/active', botCampaignController.obtenerActivas);
router.post('/', botCampaignController.crear);
router.post('/detect', botCampaignController.detectar);

router.get('/:campaignId', botCampaignController.obtenerPorId);
router.patch('/:campaignId', botCampaignController.actualizar);
router.put('/:campaignId', botCampaignController.actualizar);
router.patch('/:campaignId/status', botCampaignController.cambiarEstado);
router.delete('/:campaignId', botCampaignController.eliminar);
router.post('/:campaignId/duplicate', botCampaignController.duplicar);
router.get('/:campaignId/agent-data', botCampaignController.obtenerDatosAgente);
router.post('/:campaignId/generate-prompt', botCampaignController.generarPrompt);
router.post('/:campaignId/prepare-agent', botCampaignController.prepararAgente);
router.post('/agent/response-tracking', botCampaignController.registrarRespuestaAgente);

module.exports = router;
