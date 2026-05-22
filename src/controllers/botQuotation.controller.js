const botQuotationService = require('../services/botQuotation.service');

async function listar(req, res) {
  try {
    const botId = req.params.botId || null;
    const cotizaciones = await botQuotationService.listarCotizaciones(botId);
    res.json({
      ok: true,
      message: 'Cotizaciones listadas correctamente',
      data: cotizaciones,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al listar cotizaciones',
      error: error.message,
    });
  }
}

async function obtenerPorId(req, res) {
  try {
    const { id } = req.params;

    const cotizacion = await botQuotationService.obtenerCotizacionPorId(id);

    if (!cotizacion) {
      return res.status(404).json({
        ok: false,
        message: 'Cotización no encontrada',
      });
    }

    res.json({
      ok: true,
      message: 'Cotización encontrada',
      data: cotizacion,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al obtener cotización',
      error: error.message,
    });
  }
}

async function crear(req, res) {
  try {
    const data = req.body;
    const bot_id = req.params.botId || null;

    if (!data.numero_cotizacion) {
      return res.status(400).json({
        ok: false,
        message: 'El numero_cotizacion es obligatorio',
      });
    }

    if (!data.telefono_cliente) {
      return res.status(400).json({
        ok: false,
        message: 'El telefono_cliente es obligatorio',
      });
    }

    const cotizacion = await botQuotationService.crearCotizacion({
      ...data,
      bot_id,
    });

    res.status(201).json({
      ok: true,
      message: 'Cotización creada correctamente',
      data: cotizacion,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al crear cotización',
      error: error.message,
    });
  }
}

async function actualizar(req, res) {
  try {
    const { id } = req.params;
    const data = req.body;

    const cotizacion = await botQuotationService.actualizarCotizacion(id, data);

    if (!cotizacion) {
      return res.status(404).json({
        ok: false,
        message: 'Cotización no encontrada',
      });
    }

    res.json({
      ok: true,
      message: 'Cotización actualizada correctamente',
      data: cotizacion,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al actualizar cotización',
      error: error.message,
    });
  }
}

module.exports = {
  listar,
  obtenerPorId,
  crear,
  actualizar,
};
