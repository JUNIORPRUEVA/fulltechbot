const express = require('express');
const router = express.Router();
const orderController = require('../controllers/order.controller');

// GET /api/orders
router.get('/', orderController.listar);

// GET /api/orders/:id
router.get('/:id', orderController.obtener);

// POST /api/orders
router.post('/', orderController.crear);

// PUT /api/orders/:id
router.put('/:id', orderController.actualizar);

// PATCH /api/orders/:id/status
router.patch('/:id/status', orderController.cambiarEstado);

// DELETE /api/orders/:id
router.delete('/:id', orderController.eliminar);

module.exports = router;
