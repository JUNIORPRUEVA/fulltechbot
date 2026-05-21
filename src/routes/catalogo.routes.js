const express = require('express');
const catalogoController = require('../controllers/catalogo.controller');

const router = express.Router();

router.get('/', catalogoController.listar);
router.get('/activos', catalogoController.listarActivos);
router.get('/:id', catalogoController.obtenerPorId);

router.post('/', catalogoController.crear);

router.put('/:id', catalogoController.actualizar);
router.patch('/:id/estado', catalogoController.cambiarEstado);

router.delete('/:id', catalogoController.eliminar);

module.exports = router;