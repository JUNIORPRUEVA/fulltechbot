const express = require('express');
const botQuotationController = require('../controllers/botQuotation.controller');

const router = express.Router({ mergeParams: true });

router.get('/', botQuotationController.listar);
router.get('/:id', botQuotationController.obtenerPorId);
router.post('/', botQuotationController.crear);
router.put('/:id', botQuotationController.actualizar);
router.patch('/:id/status', botQuotationController.cambiarEstado);
router.delete('/:id', botQuotationController.eliminar);

module.exports = router;
