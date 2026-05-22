const prisma = require('../lib/prisma');

async function listarClientes(botId = null) {
  const where = {};
  if (botId) where.botId = botId;

  return prisma.botClient.findMany({
    where,
    orderBy: { ultima_interaccion_at: 'desc' },
  });
}

async function obtenerClientePorTelefono(telefono) {
  return prisma.botClient.findUnique({
    where: { telefono },
  });
}

async function obtenerClientePorChatId(chatid) {
  return prisma.botClient.findFirst({
    where: { chatid },
  });
}

async function buscarOCrearCliente(data) {
  const { telefono, chatid, botId } = data;

  if (!telefono) {
    throw new Error('El telefono es obligatorio');
  }

  let existente = await prisma.botClient.findUnique({
    where: { telefono },
  });

  if (!existente && chatid) {
    existente = await prisma.botClient.findFirst({
      where: { chatid },
    });
  }

  if (existente) {
    const updateData = {
      nombre: data.nombre ?? existente.nombre,
      chatid: data.chatid ?? existente.chatid,
      usuario_whatsapp: data.usuario_whatsapp ?? existente.usuario_whatsapp,
      direccion: data.direccion ?? existente.direccion,
      ciudad: data.ciudad ?? existente.ciudad,
      sector: data.sector ?? existente.sector,
      referencia_direccion: data.referencia_direccion ?? existente.referencia_direccion,
      interes_principal: data.interes_principal ?? existente.interes_principal,
      producto_servicio_interes: data.producto_servicio_interes ?? existente.producto_servicio_interes,
      categoria_interes: data.categoria_interes ?? existente.categoria_interes,
      presupuesto_estimado: data.presupuesto_estimado ?? existente.presupuesto_estimado,
      ultimo_mensaje: data.ultimo_mensaje ?? existente.ultimo_mensaje,
      total_mensajes: { increment: 1 },
      ultima_interaccion_at: new Date(),
      dias_sin_responder: 0,
      actualizado_en: new Date(),
    };

    if (data.metadata) {
      const existingMetadata = typeof existente.metadata === 'object' ? existente.metadata : {};
      updateData.metadata = { ...existingMetadata, ...data.metadata };
    }

    return prisma.botClient.update({
      where: { telefono: existente.telefono },
      data: updateData,
    });
  }

  return prisma.botClient.create({
    data: {
      telefono,
      chatid: data.chatid ?? null,
      nombre: data.nombre ?? null,
      usuario_whatsapp: data.usuario_whatsapp ?? null,
      direccion: data.direccion ?? null,
      ciudad: data.ciudad ?? null,
      sector: data.sector ?? null,
      referencia_direccion: data.referencia_direccion ?? null,
      interes_principal: data.interes_principal ?? null,
      producto_servicio_interes: data.producto_servicio_interes ?? null,
      categoria_interes: data.categoria_interes ?? null,
      presupuesto_estimado: data.presupuesto_estimado ?? null,
      estado_cliente: 'prospecto',
      etapa: 'inicio',
      total_mensajes: 1,
      ultima_interaccion_at: new Date(),
      requiere_seguimiento: true,
      bot_pausado: false,
      humano_tomo_control: false,
      metadata: data.metadata ?? {},
      botId: botId || null,
      creado_en: new Date(),
      actualizado_en: new Date(),
    },
  });
}

async function actualizarCliente(telefono, data) {
  const existente = await prisma.botClient.findUnique({
    where: { telefono },
  });

  if (!existente) {
    return null;
  }

  const { telefono: _, ...updateData } = data;

  return prisma.botClient.update({
    where: { telefono },
    data: {
      ...updateData,
      actualizado_en: new Date(),
    },
  });
}

async function actualizarEstado(telefono, estado) {
  const existente = await prisma.botClient.findUnique({
    where: { telefono },
  });

  if (!existente) {
    return null;
  }

  return prisma.botClient.update({
    where: { telefono },
    data: {
      estado_cliente: estado,
      actualizado_en: new Date(),
    },
  });
}

async function pausarBot(telefono, pausado) {
  const existente = await prisma.botClient.findUnique({
    where: { telefono },
  });

  if (!existente) {
    return null;
  }

  return prisma.botClient.update({
    where: { telefono },
    data: {
      bot_pausado: pausado,
      actualizado_en: new Date(),
    },
  });
}

async function eliminarCliente(telefono) {
  const existente = await prisma.botClient.findUnique({
    where: { telefono },
  });

  if (!existente) {
    return null;
  }

  return prisma.botClient.delete({
    where: { telefono },
  });
}

module.exports = {
  listarClientes,
  obtenerClientePorTelefono,
  obtenerClientePorChatId,
  buscarOCrearCliente,
  actualizarCliente,
  actualizarEstado,
  pausarBot,
  eliminarCliente,
};
