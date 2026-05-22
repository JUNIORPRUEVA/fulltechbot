const botQuotationService = require('../services/botQuotation.service');

async function listar(req, res) {
  try {
    const { botId } = req.params;
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
    const { botId, id } = req.params;
    const cotizacion = await botQuotationService.obtenerCotizacionPorId(id, botId);

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
    const { botId } = req.params;
    const data = req.body;

    // Aceptar tanto snake_case como camelCase
    const telefono = data.telefono_cliente || data.telefonoCliente;

    if (!telefono) {
      return res.status(400).json({
        ok: false,
        message: 'El telefono_cliente es obligatorio',
      });
    }

    const normalizedData = {
      numero_cotizacion: data.numero_cotizacion || data.numeroCotizacion || null,
      telefono_cliente: telefono,
      nombre_cliente: data.nombre_cliente || data.nombreCliente || null,
      direccion_cliente: data.direccion_cliente || data.direccionCliente || null,
      ciudad: data.ciudad || null,
      sector: data.sector || null,
      titulo: data.titulo || data.titulo || 'Cotización de servicios',
      descripcion_general: data.descripcion_general || data.descripcionGeneral || null,
      productos: data.productos ?? [],
      subtotal: data.subtotal ?? 0,
      descuento: data.descuento ?? 0,
      total: data.total ?? null,
      moneda: data.moneda || 'DOP',
      estado: data.estado || 'pendiente',
      pdf_url: data.pdf_url || data.pdfUrl || null,
      observaciones: data.observaciones || null,
      condiciones: data.condiciones || null,
      valida_hasta: data.valida_hasta || data.validaHasta || null,
      creada_por: data.creada_por || data.creadaPor || 'bot',
      botId,
    };

    const cotizacion = await botQuotationService.crearCotizacion(normalizedData);

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
    const { botId, id } = req.params;
    const data = req.body;

    const cotizacion = await botQuotationService.actualizarCotizacion(id, data, botId);

    if (!cotizacion) {
      return res.status(404).json({
        ok: false,
        message: 'Cotización no encontrada o no pertenece a este bot',
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

async function cambiarEstado(req, res) {
  try {
    const { botId, id } = req.params;
    const { estado } = req.body;

    if (!estado) {
      return res.status(400).json({
        ok: false,
        message: 'El campo estado es obligatorio',
      });
    }

    const cotizacion = await botQuotationService.cambiarEstado(id, estado, botId);

    if (!cotizacion) {
      return res.status(404).json({
        ok: false,
        message: 'Cotización no encontrada o no pertenece a este bot',
      });
    }

    res.json({
      ok: true,
      message: `Estado actualizado a "${estado}" correctamente`,
      data: cotizacion,
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      message: error.message,
    });
  }
}

async function eliminar(req, res) {
  try {
    const { botId, id } = req.params;
    const cotizacion = await botQuotationService.eliminarCotizacion(id, botId);

    if (!cotizacion) {
      return res.status(404).json({
        ok: false,
        message: 'Cotización no encontrada o no pertenece a este bot',
      });
    }

    res.json({
      ok: true,
      message: 'Cotización eliminada correctamente',
      data: cotizacion,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al eliminar cotización',
      error: error.message,
    });
  }
}

module.exports = {
  listar,
  obtenerPorId,
  crear,
  actualizar,
  cambiarEstado,
  eliminar,
};
