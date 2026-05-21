const botConversationService = require('../services/botConversation.service');

async function listar(req, res) {
  try {
    const conversaciones = await botConversationService.listarConversaciones();
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

module.exports = {
  listar,
  obtenerPorSessionId,
  crear,
};
