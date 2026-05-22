const botConversationService = require('../services/botConversation.service');

async function listar(req, res) {
  try {
    const { botId } = req.params;
    const conversaciones = await botConversationService.listarConversaciones(botId);
    res.json({ ok: true, data: conversaciones });
  } catch (error) {
    console.error('Error al listar conversaciones:', error);
    res.status(500).json({ ok: false, message: 'Error al listar conversaciones', error: error.message });
  }
}

async function obtenerPorSessionId(req, res) {
  try {
    const { sessionId } = req.params;
    const conversaciones = await botConversationService.obtenerPorSessionId(sessionId);
    res.json({ ok: true, data: conversaciones });
  } catch (error) {
    console.error('Error al obtener conversaciones:', error);
    res.status(500).json({ ok: false, message: 'Error al obtener conversaciones', error: error.message });
  }
}

async function crear(req, res) {
  try {
    const { botId } = req.params;
    const data = { ...req.body, botId };
    const conversacion = await botConversationService.crearConversacion(data);
    res.status(201).json({ ok: true, data: conversacion });
  } catch (error) {
    console.error('Error al crear conversación:', error);
    res.status(500).json({ ok: false, message: 'Error al crear conversación', error: error.message });
  }
}

/**
 * DELETE /api/bots/:botId/conversations/:sessionId
 * Elimina todas las conversaciones de un sessionId.
 * Solo accesible para admin/owner (middleware verifica permiso).
 */
async function eliminarPorSessionId(req, res) {
  try {
    const { sessionId } = req.params;

    if (!sessionId) {
      return res.status(400).json({ ok: false, message: 'El sessionId es obligatorio' });
    }

    // Verificar que existen conversaciones para ese sessionId
    const existentes = await botConversationService.obtenerPorSessionId(sessionId);
    if (!existentes || existentes.length === 0) {
      return res.status(404).json({ ok: false, message: 'No se encontraron conversaciones para este sessionId' });
    }

    // Eliminar en transacción
    const resultado = await botConversationService.eliminarPorSessionId(sessionId);

    console.log(`[AUDITORÍA] Conversaciones eliminadas por ${req.userRole || 'desconocido'}:`, {
      sessionId,
      cantidad: resultado.count,
      fecha: new Date().toISOString(),
    });

    res.json({
      ok: true,
      message: `${resultado.count} conversación(es) eliminada(s) permanentemente.`,
      data: {
        sessionId,
        eliminadas: resultado.count,
      },
    });
  } catch (error) {
    console.error('Error al eliminar conversaciones:', error);
    res.status(500).json({ ok: false, message: 'Error al eliminar conversaciones', error: error.message });
  }
}

module.exports = {
  listar,
  obtenerPorSessionId,
  crear,
  eliminarPorSessionId,
};
