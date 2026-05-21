const express = require('express');
const botQuotationController = require('../controllers/botQuotation.controller');

const router = express.Router();

router.get('/', botQuotationController.listar);
router.get('/:id', botQuotationController.obtenerPorId);
router.post('/', botQuotationController.crear);
router.put('/:id', botQuotationController.actualizar);

module.exports = router;
