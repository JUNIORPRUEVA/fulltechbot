const botConversationService = require('../services/botConversation.service');

async function listar(req, res) {
  try {
    const botId = req.params.botId || null;
    const conversaciones = await botConversationService.listarConversaciones(botId);
    res.json({
      ok: true,
      message: 'Conversaciones listadas correctamente',
      data: conversaciones,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al listar conversaciones',
      error: error.message,
    });
  }
}

async function obtenerPorSessionId(req, res) {
  try {
    const { sessionId } = req.params;

    const conversaciones = await botConversationService.obtenerPorSessionId(sessionId);

    res.json({
      ok: true,
      message: 'Conversaciones encontradas',
      data: conversaciones,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al obtener conversaciones',
      error: error.message,
    });
  }
}

async function crear(req, res) {
  try {
    const { session_id, message } = req.body;
    const botId = req.params.botId || null;

    if (!session_id) {
      return res.status(400).json({
        ok: false,
        message: 'El session_id es obligatorio',
      });
    }

    if (!message) {
      return res.status(400).json({
        ok: false,
        message: 'El message es obligatorio',
      });
    }

    const conversacion = await botConversationService.crearConversacion({
      session_id,
      message,
      botId,
    });

    res.status(201).json({
      ok: true,
      message: 'Conversación creada correctamente',
      data: conversacion,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al crear conversación',
      error: error.message,
    });
  }
}

async function eliminarPorSessionId(req, res) {
  try {
    const { sessionId } = req.params;

    if (!sessionId) {
      return res.status(400).json({
        ok: false,
        message: 'El sessionId es obligatorio',
      });
    }

    const result = await botConversationService.eliminarPorSessionId(sessionId);

    res.json({
      ok: true,
      message: `Se eliminaron ${result.count} conversaciones`,
      data: { eliminados: result.count },
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al eliminar conversaciones',
      error: error.message,
    });
  }
}

module.exports = {
  listar,
  obtenerPorSessionId,
  crear,
  eliminarPorSessionId,
};
