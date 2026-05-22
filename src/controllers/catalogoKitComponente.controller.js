const kitComponenteService = require('../services/catalogoKitComponente.service');

function normalizarMediaUrl(req, value) {
  if (!value || typeof value !== 'string') return value;
  const trimmed = value.trim();
  if (!trimmed) return null;
  if (/^https?:\/\//i.test(trimmed)) return trimmed;
  return trimmed;
}

function normalizarComponente(req, comp) {
  if (!comp) return comp;
  return {
    ...comp,
    imagen1: normalizarMediaUrl(req, comp.imagen1),
    imagen2: normalizarMediaUrl(req, comp.imagen2),
    imagen3: normalizarMediaUrl(req, comp.imagen3),
    video: normalizarMediaUrl(req, comp.video),
  };
}

async function listarComponentes(req, res) {
  try {
    const { kitId } = req.params;
    const componentes = await kitComponenteService.obtenerComponentesKit(kitId);
    res.json({
      ok: true,
      data: componentes.map(c => normalizarComponente(req, c)),
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al listar componentes del kit',
      error: error.message,
    });
  }
}

async function obtenerDetalle(req, res) {
  try {
    const { kitId } = req.params;
    const detalle = await kitComponenteService.obtenerDetalleKit(kitId);

    if (!detalle) {
      return res.status(404).json({ ok: false, message: 'Kit no encontrado' });
    }

    res.json({
      ok: true,
      data: {
        kit: detalle.kit,
        componentesIncluidos: detalle.componentesIncluidos.map(c => normalizarComponente(req, c)),
        extrasOpcionales: detalle.extrasOpcionales.map(c => normalizarComponente(req, c)),
      },
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al obtener detalle del kit',
      error: error.message,
    });
  }
}

async function agregarComponente(req, res) {
  try {
    const { kitId } = req.params;
    const data = req.body;

    if (!data.componente_id) {
      return res.status(400).json({ ok: false, message: 'componente_id es obligatorio' });
    }

    const componente = await kitComponenteService.agregarComponenteKit(kitId, data);

    res.status(201).json({
      ok: true,
      message: 'Componente agregado al kit correctamente',
      data: normalizarComponente(req, componente),
    });
  } catch (error) {
    const status = error.message.includes('no encontrado') ? 404
      : error.message.includes('ya está agregado') || error.message.includes('mismo bot') || error.message.includes('sí mismo') || error.message.includes('debe ser mayor') ? 400
      : 500;
    res.status(status).json({
      ok: false,
      message: error.message,
    });
  }
}

async function actualizarComponente(req, res) {
  try {
    const { kitId, id } = req.params;
    const data = req.body;

    const componente = await kitComponenteService.actualizarComponenteKit(kitId, id, data);

    if (!componente) {
      return res.status(404).json({ ok: false, message: 'Relación no encontrada' });
    }

    res.json({
      ok: true,
      message: 'Componente actualizado correctamente',
      data: normalizarComponente(req, componente),
    });
  } catch (error) {
    const status = error.message.includes('debe ser mayor') ? 400 : 500;
    res.status(status).json({
      ok: false,
      message: error.message,
    });
  }
}

async function eliminarComponente(req, res) {
  try {
    const { kitId, id } = req.params;
    const eliminado = await kitComponenteService.eliminarComponenteKit(kitId, id);

    if (!eliminado) {
      return res.status(404).json({ ok: false, message: 'Relación no encontrada' });
    }

    res.json({
      ok: true,
      message: 'Componente eliminado del kit correctamente',
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al eliminar componente del kit',
      error: error.message,
    });
  }
}

async function buscarProductos(req, res) {
  try {
    const { botId } = req.query;
    const { query } = req.query;
    const { excludeKitId } = req.query;

    if (!botId) {
      return res.status(400).json({ ok: false, message: 'botId es obligatorio' });
    }

    const productos = await kitComponenteService.buscarProductosParaComponente({
      botId,
      query: query || null,
      excludeKitId: excludeKitId || null,
    });

    res.json({
      ok: true,
      data: productos,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al buscar productos',
      error: error.message,
    });
  }
}

module.exports = {
  listarComponentes,
  obtenerDetalle,
  agregarComponente,
  actualizarComponente,
  eliminarComponente,
  buscarProductos,
};
