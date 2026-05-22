const botClientService = require('../services/botClient.service');

async function listar(req, res) {
  try {
    const botId = req.params.botId || null;
    const clientes = await botClientService.listarClientes(botId);
    res.json({
      ok: true,
      message: 'Clientes listados correctamente',
      data: clientes,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al listar clientes',
      error: error.message,
    });
  }
}

async function obtenerPorTelefono(req, res) {
  try {
    const { telefono } = req.params;
    const cliente = await botClientService.obtenerClientePorTelefono(telefono);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    res.json({
      ok: true,
      message: 'Cliente encontrado',
      data: cliente,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al obtener cliente',
      error: error.message,
    });
  }
}

async function obtenerPorChatId(req, res) {
  try {
    const { chatid } = req.params;
    const cliente = await botClientService.obtenerClientePorChatId(chatid);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado por chatid',
      });
    }

    res.json({
      ok: true,
      message: 'Cliente encontrado',
      data: cliente,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al obtener cliente por chatid',
      error: error.message,
    });
  }
}

async function buscarOCrear(req, res) {
  try {
    const {
      telefono, nombre, chatid, usuario_whatsapp,
      direccion, ciudad, sector, referencia_direccion,
      interes_principal, producto_servicio_interes,
      categoria_interes, presupuesto_estimado,
      ultimo_mensaje, metadata,
    } = req.body;

    if (!telefono) {
      return res.status(400).json({
        ok: false,
        message: 'El teléfono es obligatorio',
      });
    }

    const bot_id = req.params.botId || null;

    const cliente = await botClientService.buscarOCrearCliente({
      telefono,
      nombre,
      chatid,
      usuario_whatsapp,
      direccion,
      ciudad,
      sector,
      referencia_direccion,
      interes_principal,
      producto_servicio_interes,
      categoria_interes,
      presupuesto_estimado,
      ultimo_mensaje,
      metadata,
      bot_id,
    });

    const esNuevo = cliente.total_mensajes === 1;

    res.status(esNuevo ? 201 : 200).json({
      ok: true,
      message: esNuevo ? 'Cliente creado correctamente' : 'Cliente actualizado correctamente',
      data: cliente,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al procesar cliente',
      error: error.message,
    });
  }
}

async function actualizar(req, res) {
  try {
    const { telefono } = req.params;
    const data = req.body;

    const cliente = await botClientService.actualizarCliente(telefono, data);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    res.json({
      ok: true,
      message: 'Cliente actualizado correctamente',
      data: cliente,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al actualizar cliente',
      error: error.message,
    });
  }
}

async function actualizarEstado(req, res) {
  try {
    const { telefono } = req.params;
    const { estado } = req.body;

    if (!estado) {
      return res.status(400).json({
        ok: false,
        message: 'El estado es obligatorio',
      });
    }

    const cliente = await botClientService.actualizarEstado(telefono, estado);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    res.json({
      ok: true,
      message: 'Estado actualizado correctamente',
      data: cliente,
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al actualizar estado',
      error: error.message,
    });
  }
}

async function pausarBot(req, res) {
  try {
    const { telefono } = req.params;
    const { pausado } = req.body;

    if (typeof pausado !== 'boolean') {
      return res.status(400).json({
        ok: false,
        message: 'El campo "pausado" debe ser booleano',
      });
    }

    const cliente = await botClientService.pausarBot(telefono, pausado);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    res.json({
      ok: true,
      message: pausado ? 'Bot pausado para este cliente' : 'Bot reanudado para este cliente',
      data: {
        telefono: cliente.telefono,
        bot_pausado: cliente.bot_pausado,
        humano_tomo_control: cliente.humano_tomo_control,
      },
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      message: 'Error al pausar/reanudar bot',
      error: error.message,
    });
  }
}

async function eliminar(req, res) {
  try {
    const { telefono } = req.params;

    const cliente = await botClientService.eliminarCliente(telefono);

    if (!cliente) {
      return res.status(404).json({
        ok: false,
        message: 'Cliente no encontrado',
      });
    }

    res.json({
      ok: true,
      message: 'Cliente eliminado correctamente',
    });
  } catch (error) {
    res.status(500).json({
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
  actualizarEstado,
  pausarBot,
  eliminar,
};
