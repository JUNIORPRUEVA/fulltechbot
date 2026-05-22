const express = require('express');
const router = express.Router();
const quotationController = require('../controllers/quotation.controller');

// GET /api/quotations
router.get('/', quotationController.listar);

// GET /api/quotations/:id
router.get('/:id', quotationController.obtener);

// POST /api/quotations
router.post('/', quotationController.crear);

// PUT /api/quotations/:id
router.put('/:id', quotationController.actualizar);

// PATCH /api/quotations/:id/status
router.patch('/:id/status', quotationController.cambiarEstado);

// DELETE /api/quotations/:id
router.delete('/:id', quotationController.eliminar);

module.exports = router;
