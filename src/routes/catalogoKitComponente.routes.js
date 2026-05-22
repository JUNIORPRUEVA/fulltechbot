const express = require('express');
const router = express.Router();
const controller = require('../controllers/catalogoKitComponente.controller');

// GET /api/catalogo/:kitId/componentes - Listar componentes de un kit
router.get('/:kitId/componentes', controller.listarComponentes);

// GET /api/catalogo/:kitId/detalle - Obtener detalle completo del kit
router.get('/:kitId/detalle', controller.obtenerDetalle);

// POST /api/catalogo/:kitId/componentes - Agregar componente al kit
router.post('/:kitId/componentes', controller.agregarComponente);

// PUT /api/catalogo/:kitId/componentes/:id - Actualizar componente del kit
router.put('/:kitId/componentes/:id', controller.actualizarComponente);

// DELETE /api/catalogo/:kitId/componentes/:id - Eliminar componente del kit
router.delete('/:kitId/componentes/:id', controller.eliminarComponente);

// GET /api/catalogo/buscar-componentes - Buscar productos disponibles para componente
router.get('/buscar-componentes', controller.buscarProductos);

module.exports = router;
