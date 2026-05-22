const quotationService = require('../services/quotation.service');

async function listar(req, res) {
  try {
    const { sourceBotId, estado, telefono, botId } = req.query;
    const filtros = {};
    if (sourceBotId) filtros.sourceBotId = sourceBotId;
    if (estado) filtros.estado = estado;
    if (telefono) filtros.telefono = telefono;
    if (botId) filtros.botId = botId;

    const cotizaciones = await quotationService.listarCotizaciones(filtros);
    res.json({ ok: true, data: cotizaciones, total: cotizaciones.length });
  } catch (error) {
    console.error('Error al listar cotizaciones:', error);
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function obtener(req, res) {
  try {
    const { id } = req.params;
    const cotizacion = await quotationService.obtenerCotizacionPorId(id);

    if (!cotizacion) {
      return res.status(404).json({ ok: false, message: 'Cotización no encontrada' });
    }

    res.json({ ok: true, data: cotizacion });
  } catch (error) {
    console.error('Error al obtener cotización:', error);
    res.status(500).json({ ok: false, message: error.message });
  }
}

async function crear(req, res) {
  try {
    const data = { ...req.body };
    const cotizacion = await quotationService.crearCotizacion(data);
    res.status(201).json({ ok: true, message: 'Cotización creada exitosamente', data: cotizacion });
  } catch (error) {
    console.error('Error al crear cotización:', error);
    res.status(400).json({ ok: false, message: error.message });
  }
}

async function actualizar(req, res) {
  try {
    const { id } = req.params;
    const cotizacion = await quotationService.actualizarCotizacion(id, req.body);

    if (!cotizacion) {
      return res.status(404).json({ ok: false, message: 'Cotización no encontrada' });
    }

    res.json({ ok: true, message: 'Cotización actualizada exitosamente', data: cotizacion });
  } catch (error) {
    console.error('Error al actualizar cotización:', error);
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

    const cotizacion = await quotationService.cambiarEstado(id, estado);

    if (!cotizacion) {
      return res.status(404).json({ ok: false, message: 'Cotización no encontrada' });
    }

    res.json({ ok: true, message: 'Estado actualizado exitosamente', data: cotizacion });
  } catch (error) {
    console.error('Error al cambiar estado:', error);
    res.status(400).json({ ok: false, message: error.message });
  }
}

async function eliminar(req, res) {
  try {
    const { id } = req.params;
    const cotizacion = await quotationService.eliminarCotizacion(id);

    if (!cotizacion) {
      return res.status(404).json({ ok: false, message: 'Cotización no encontrada' });
    }

    res.json({ ok: true, message: 'Cotización eliminada exitosamente' });
  } catch (error) {
    console.error('Error al eliminar cotización:', error);
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
