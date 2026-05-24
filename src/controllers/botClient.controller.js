const botClientService = require('../services/botClient.service');

async function listar(req, res) {
  try {
    const { botId } = req.params;
    const clientes = await botClientService.listarClientes(botId);
    res.json({ ok: true, data: clientes });
  } catch (error) {
    console.error('Error al listar clientes:', error);
    res.status(500).json({ ok: false, message: 'Error al listar clientes', error: error.message });
  }
}

async function obtenerPorTelefono(req, res) {
  try {
    const { botId } = req.params;
    const { telefono } = req.params;
    const cliente = await botClientService.obtenerClientePorTelefono(telefono, botId);
    if (!cliente) {
      return res.status(404).json({ ok: false, message: 'Cliente no encontrado' });
    }
    res.json({ ok: true, data: cliente });
  } catch (error) {
    console.error('Error al obtener cliente:', error);
    res.status(500).json({ ok: false, message: 'Error al obtener cliente', error: error.message });
  }
}

async function obtenerPorChatId(req, res) {
  try {
    const { botId } = req.params;
    const { chatid } = req.params;
    const cliente = await botClientService.obtenerClientePorChatId(chatid, botId);
    if (!cliente) {
      return res.status(404).json({ ok: false, message: 'Cliente no encontrado' });
    }
    res.json({ ok: true, data: cliente });
  } catch (error) {
    console.error('Error al obtener cliente por chatid:', error);
    res.status(500).json({ ok: false, message: 'Error al obtener cliente', error: error.message });
  }
}

async function buscarOCrear(req, res) {
  try {
    const { botId } = req.params;
    const data = { ...req.body, botId };
    const cliente = await botClientService.buscarOCrearCliente(data);
    res.status(201).json({ ok: true, data: cliente });
  } catch (error) {
    console.error('Error al crear/actualizar cliente:', error);
    res.status(500).json({ ok: false, message: 'Error al crear/actualizar cliente', error: error.message });
  }
}

async function actualizar(req, res) {
  try {
    const { botId } = req.params;
    const { telefono } = req.params;
    const cliente = await botClientService.actualizarCliente(telefono, req.body, botId);
    if (!cliente) {
      return res.status(404).json({ ok: false, message: 'Cliente no encontrado' });
    }
    res.json({ ok: true, data: cliente });
  } catch (error) {
    console.error('Error al actualizar cliente:', error);
    res.status(500).json({ ok: false, message: 'Error al actualizar cliente', error: error.message });
  }
}

/**
 * PATCH /api/bots/:botId/clients/:telefono/assign-bot
 * Asigna un botId a un cliente existente (para corregir clientes sin botId)
 */
async function assignBot(req, res) {
  try {
    const { botId } = req.params;
    const { telefono } = req.params;
    const cliente = await botClientService.asignarBotId(telefono, botId);
    if (!cliente) {
      return res.status(404).json({ ok: false, message: 'Cliente no encontrado' });
    }
    res.json({ ok: true, data: cliente });
  } catch (error) {
    console.error('Error al asignar botId:', error);
    res.status(500).json({ ok: false, message: 'Error al asignar botId', error: error.message });
  }
}

async function actualizarEstado(req, res) {
  try {
    const { telefono } = req.params;
    const { estado } = req.body;
    const cliente = await botClientService.actualizarEstado(telefono, estado);
    if (!cliente) {
      return res.status(404).json({ ok: false, message: 'Cliente no encontrado' });
    }
    res.json({ ok: true, data: cliente });
  } catch (error) {
    console.error('Error al actualizar estado:', error);
    res.status(500).json({ ok: false, message: 'Error al actualizar estado', error: error.message });
  }
}

async function pausarBot(req, res) {
  try {
    const { telefono } = req.params;
    const { pausado } = req.body;
    const cliente = await botClientService.pausarBot(telefono, pausado);
    if (!cliente) {
      return res.status(404).json({ ok: false, message: 'Cliente no encontrado' });
    }
    res.json({ ok: true, data: cliente });
  } catch (error) {
    console.error('Error al pausar/reanudar bot:', error);
    res.status(500).json({ ok: false, message: 'Error al pausar/reanudar bot', error: error.message });
  }
}

/**
 * DELETE /api/bots/:botId/clients/:telefono
 * Elimina un cliente y todos sus datos relacionados.
 * Solo accesible para admin/owner (middleware verifica permiso).
 */
async function eliminar(req, res) {
  try {
    const { botId } = req.params;
    const { telefono } = req.params;

    // Verificar que el cliente existe
    const existente = await botClientService.obtenerClientePorTelefono(telefono, botId);
    if (!existente) {
      return res.status(404).json({ ok: false, message: 'Cliente no encontrado' });
    }

    // Eliminar en transacción (servicio maneja todas las dependencias)
    const clienteEliminado = await botClientService.eliminarCliente(telefono, botId);

    console.log(`[AUDITORÍA] Cliente eliminado por ${req.userRole || 'desconocido'}:`, {
      telefono: clienteEliminado.telefono,
      nombre: clienteEliminado.nombre,
      fecha: new Date().toISOString(),
    });

    res.json({
      ok: true,
      message: `Cliente ${existente.nombre || existente.telefono} y todos sus datos relacionados han sido eliminados permanentemente.`,
      data: {
        telefono: clienteEliminado.telefono,
        nombre: clienteEliminado.nombre,
      },
    });
  } catch (error) {
    console.error('Error al eliminar cliente:', error);
    res.status(500).json({ ok: false, message: 'Error al eliminar cliente', error: error.message });
  }
}

module.exports = {
  listar,
  obtenerPorTelefono,
  obtenerPorChatId,
  buscarOCrear,
  actualizar,
  actualizarEstado,
  pausarBot,
  eliminar,
};
