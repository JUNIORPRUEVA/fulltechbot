const express = require('express');
const botOrderController = require('../controllers/botOrder.controller');

const router = express.Router({ mergeParams: true });

router.get('/', botOrderController.listar);
router.get('/:id', botOrderController.obtenerPorId);
router.post('/', botOrderController.crear);
router.put('/:id', botOrderController.actualizar);
router.patch('/:id/status', botOrderController.cambiarEstado);
router.delete('/:id', botOrderController.eliminar);

module.exports = router;
