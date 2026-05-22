const orderService = require('../services/order.service');

async function listar(req, res) {
  try {
    const { sourceBotId, estado, telefono, botId } = req.query;
    const filtros = {};
    if (sourceBotId) filtros.sourceBotId = sourceBotId;
    if (estado) filtros.estado = estado;
    if (telefono) filtros.telefono = telefono;
    if (botId) filtros.botId = botId;

    const ordenes = await orderService.listarOrdenes(filtros);
    res.json({ ok: true, data: ordenes, total: ordenes.length });
  } catch (error) {
    console.error('Error al listar órdenes:', error);
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function obtener(req, res) {
  try {
    const { id } = req.params;
    const orden = await orderService.obtenerOrdenPorId(id);

    if (!orden) {
      return res.status(404).json({ ok: false, message: 'Orden no encontrada' });
    }

    res.json({ ok: true, data: orden });
  } catch (error) {
    console.error('Error al obtener orden:', error);
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function crear(req, res) {
  try {
    const data = { ...req.body };
    const orden = await orderService.crearOrden(data);
    res.status(201).json({ ok: true, message: 'Orden creada exitosamente', data: orden });
  } catch (error) {
    console.error('Error al crear orden:', error);
    res.status(400).json({ ok: false, message: error.message });
  }
}

async function actualizar(req, res) {
  try {
    const { id } = req.params;
    const orden = await orderService.actualizarOrden(id, req.body);

    if (!orden) {
      return res.status(404).json({ ok: false, message: 'Orden no encontrada' });
    }

    res.json({ ok: true, message: 'Orden actualizada exitosamente', data: orden });
  } catch (error) {
    console.error('Error al actualizar orden:', error);
    res.status(400).json({ ok: false, message: error.message });
  }
}

async function cambiarEstado(req, res) {
  try {
    const { id } = req.params;
    const { estado } = req.body;

    if (!estado) {
      return res.status(400).json({ ok: false, message: 'El campo estado es obligatorio' });
    }

    const orden = await orderService.cambiarEstado(id, estado);

    if (!orden) {
      return res.status(404).json({ ok: false, message: 'Orden no encontrada' });
    }

    res.json({ ok: true, message: 'Estado actualizado exitosamente', data: orden });
  } catch (error) {
    console.error('Error al cambiar estado:', error);
    res.status(400).json({ ok: false, message: error.message });
  }
}

async function eliminar(req, res) {
  try {
    const { id } = req.params;
    const orden = await orderService.eliminarOrden(id);

    if (!orden) {
      return res.status(404).json({ ok: false, message: 'Orden no encontrada' });
    }

    res.json({ ok: true, message: 'Orden eliminada exitosamente' });
  } catch (error) {
    console.error('Error al eliminar orden:', error);
    res.status(500).json({ ok: false, message: error.message });
  }
}

module.exports = {
  listar,
  obtener,
  crear,
  actualizar,
  cambiarEstado,
  eliminar,
};
