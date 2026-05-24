const botClientService = require('../services/botClient.service');

async function listar(req, res) {
  try {
    const { botId } = req.params;

    console.log('[CLIENTES] Listar clientes - botId:', botId);

    if (!botId) {
      return res.status(400).json({
        ok: false,
        message: 'botId requerido',
      });
    }

    const clientes = await botClientService.listarClientes(botId);

    console.log('[CLIENTES] Total devueltos:', Array.isArray(clientes) ? clientes.length : 0);

    return res.json({
      ok: true,
      data: clientes,
    });
  } catch (error) {
    console.error('Error al listar clientes:', error);

    return res.status(500).json({
      ok: false,
      message: 'Error al listar clientes',
      error: error.message,
    });
  }
}

async function obtenerPorTelefono(req, res) {
  try {
    const { botId, telefono } = req.params;

    console.log('[CLIENTES] Obtener por teléfono:', {
      botId,
      telefono,
    });

    if (!botId || !telefono) {
      return res.status(400).json({
        ok: false,
        message: 'botId y telefono son requeridos',
      });
    }

    const cliente = await botClientService.obtenerClientePorTelefono(telefono, botId);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    return res.json({
      ok: true,
      data: cliente,
    });
  } catch (error) {
    console.error('Error al obtener cliente:', error);

    return res.status(500).json({
      ok: false,
      message: 'Error al obtener cliente',
      error: error.message,
    });
  }
}

async function obtenerPorChatId(req, res) {
  try {
    const { botId } = req.params;
    const chatId = req.params.chatId || req.params.chatid;

    console.log('[CLIENTES] Obtener por chatId:', {
      botId,
      chatId,
    });

    if (!botId || !chatId) {
      return res.status(400).json({
        ok: false,
        message: 'botId y chatId son requeridos',
      });
    }

    const cliente = await botClientService.obtenerClientePorChatId(chatId, botId);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    return res.json({
      ok: true,
      data: cliente,
    });
  } catch (error) {
    console.error('Error al obtener cliente por chatId:', error);

    return res.status(500).json({
      ok: false,
      message: 'Error al obtener cliente',
      error: error.message,
    });
  }
}

async function buscarOCrear(req, res) {
  try {
    const { botId } = req.params;

    console.log('[CLIENTES] Buscar o crear cliente - botId:', botId);

    if (!botId) {
      return res.status(400).json({
        ok: false,
        message: 'botId requerido',
      });
    }

    const data = {
      ...req.body,
      botId,
    };

    const cliente = await botClientService.buscarOCrearCliente(data);

    return res.status(201).json({
      ok: true,
      data: cliente,
    });
  } catch (error) {
    console.error('Error al crear/actualizar cliente:', error);

    return res.status(500).json({
      ok: false,
      message: 'Error al crear/actualizar cliente',
      error: error.message,
    });
  }
}

async function actualizar(req, res) {
  try {
    const { botId, telefono } = req.params;

    console.log('[CLIENTES] Actualizar cliente:', {
      botId,
      telefono,
    });

    if (!botId || !telefono) {
      return res.status(400).json({
        ok: false,
        message: 'botId y telefono son requeridos',
      });
    }

    const cliente = await botClientService.actualizarCliente(telefono, req.body, botId);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    return res.json({
      ok: true,
      data: cliente,
    });
  } catch (error) {
    console.error('Error al actualizar cliente:', error);

    return res.status(500).json({
      ok: false,
      message: 'Error al actualizar cliente',
      error: error.message,
    });
  }
}

/**
 * PATCH /api/bots/:botId/clients/:telefono/assign-bot
 * Asigna un botId a un cliente existente.
 */
async function assignBot(req, res) {
  try {
    const { botId, telefono } = req.params;

    console.log('[CLIENTES] Asignar botId:', {
      botId,
      telefono,
    });

    if (!botId || !telefono) {
      return res.status(400).json({
        ok: false,
        message: 'botId y telefono son requeridos',
      });
    }

    const cliente = await botClientService.asignarBotId(telefono, botId);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    return res.json({
      ok: true,
      data: cliente,
    });
  } catch (error) {
    console.error('Error al asignar botId:', error);

    return res.status(500).json({
      ok: false,
      message: 'Error al asignar botId',
      error: error.message,
    });
  }
}

async function actualizarEstado(req, res) {
  try {
    const { botId, telefono } = req.params;
    const { estado } = req.body;

    console.log('[CLIENTES] Actualizar estado:', {
      botId,
      telefono,
      estado,
    });

    if (!telefono || !estado) {
      return res.status(400).json({
        ok: false,
        message: 'telefono y estado son requeridos',
      });
    }

    const cliente = await botClientService.actualizarEstado(telefono, estado, botId);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    return res.json({
      ok: true,
      data: cliente,
    });
  } catch (error) {
    console.error('Error al actualizar estado:', error);

    return res.status(500).json({
      ok: false,
      message: 'Error al actualizar estado',
      error: error.message,
    });
  }
}

async function pausarBot(req, res) {
  try {
    const { botId, telefono } = req.params;
    const { pausado } = req.body;

    console.log('[CLIENTES] Pausar/Reanudar bot:', {
      botId,
      telefono,
      pausado,
    });

    if (!telefono) {
      return res.status(400).json({
        ok: false,
        message: 'telefono requerido',
      });
    }

    const cliente = await botClientService.pausarBot(telefono, pausado, botId);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    return res.json({
      ok: true,
      data: cliente,
    });
  } catch (error) {
    console.error('Error al pausar/reanudar bot:', error);

    return res.status(500).json({
      ok: false,
      message: 'Error al pausar/reanudar bot',
      error: error.message,
    });
  }
}

/**
 * DELETE /api/bots/:botId/clients/:telefono
 * Elimina un cliente y sus datos relacionados.
 */
async function eliminar(req, res) {
  try {
    const { botId, telefono } = req.params;

    console.log('[CLIENTES] Eliminar cliente:', {
      botId,
      telefono,
    });

    if (!botId || !telefono) {
      return res.status(400).json({
        ok: false,
        message: 'botId y telefono son requeridos',
      });
    }

    const existente = await botClientService.obtenerClientePorTelefono(telefono, botId);

    if (!existente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    const clienteEliminado = await botClientService.eliminarCliente(telefono, botId);

    console.log('[AUDITORÍA] Cliente eliminado:', {
      telefono: clienteEliminado?.telefono || existente.telefono,
      nombre: clienteEliminado?.nombre || existente.nombre,
      botId,
      usuario: req.userRole || 'desconocido',
      fecha: new Date().toISOString(),
    });

    return res.json({
      ok: true,
      message: `Cliente ${existente.nombre || existente.telefono} eliminado correctamente.`,
      data: {
        telefono: clienteEliminado?.telefono || existente.telefono,
        nombre: clienteEliminado?.nombre || existente.nombre,
      },
    });
  } catch (error) {
    console.error('Error al eliminar cliente:', error);

    return res.status(500).json({
      ok: false,
      message: 'Error al eliminar cliente',
      error: error.message,
    });
  }
}

module.exports = {
  listar,
  obtenerPorTelefono,
  obtenerPorChatId,
  buscarOCrear,
  actualizar,
  assignBot,
  actualizarEstado,
  pausarBot,
  eliminar,
};