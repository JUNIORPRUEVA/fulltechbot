const express = require('express');
const followupController = require('../controllers/followup.controller');

const router = express.Router({ mergeParams: true });

// ================================================================
// SCHEDULED FOLLOWUPS - /api/bots/:botId/followups/scheduled
// ================================================================
router.get('/scheduled', followupController.listarScheduled);
router.get('/scheduled/:id', followupController.obtenerScheduled);
router.patch('/scheduled/:id', followupController.actualizarScheduled);
router.post('/scheduled/:id/finalize', followupController.finalizarScheduled);
router.post('/scheduled/:id/cancel', followupController.cancelarScheduled);
router.post('/scheduled/:id/reactivate', followupController.reactivarScheduled);

// ================================================================
// RECOVERY FOLLOWUPS - /api/bots/:botId/followups/recovery
// ================================================================
router.get('/recovery', followupController.listarRecovery);
router.get('/recovery/:id', followupController.obtenerRecovery);
router.patch('/recovery/:id', followupController.actualizarRecovery);
router.post('/recovery/:id/finalize', followupController.finalizarRecovery);
router.post('/recovery/:id/cancel', followupController.cancelarRecovery);
router.post('/recovery/:id/reactivate', followupController.reactivarRecovery);

module.exports = router;
