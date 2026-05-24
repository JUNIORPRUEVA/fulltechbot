const prisma = require('../lib/prisma');

function normalizarTelefono(telefono) {
  if (!telefono) return '';
  return String(telefono).replace(/[^\d]/g, '');
}

function generarVariantesTelefono(telefono) {
  const limpio = normalizarTelefono(telefono);
  const variantes = new Set();

  if (telefono) variantes.add(String(telefono));
  if (limpio) variantes.add(limpio);

  if (limpio.length === 10) {
    variantes.add(`1${limpio}`);
    variantes.add(`+1${limpio}`);
  }

  if (limpio.length === 11 && limpio.startsWith('1')) {
    variantes.add(limpio.substring(1));
    variantes.add(`+${limpio}`);
  }

  if (limpio.startsWith('1') && limpio.length > 10) {
    variantes.add(limpio);
    variantes.add(`+${limpio}`);
  }

  return Array.from(variantes).filter(Boolean);
}

function limpiarDataCliente(data = {}) {
  const dataLimpia = { ...data };

  // Campos que no deben actualizarse directamente.
  delete dataLimpia.id;
  delete dataLimpia.telefono;
  delete dataLimpia.botId;
  delete dataLimpia.bot_id;
  delete dataLimpia.createdAt;
  delete dataLimpia.updatedAt;
  delete dataLimpia.creado_en;
  delete dataLimpia.actualizado_en;

  // Campos que NO existen en tu modelo actual de BotClient.
  delete dataLimpia.is_deleted;
  delete dataLimpia.deleted_at;
  delete dataLimpia.deletedAt;
  delete dataLimpia.sync_status;

  return dataLimpia;
}

async function listarClientes(botId = null) {
  console.log('[BOT CLIENT SERVICE] listarClientes botId:', botId);

  const where = {};

  if (botId) {
    where.botId = botId;
  }

  const totalGeneral = await prisma.botClient.count();
  const totalDelBot = await prisma.botClient.count({ where });

  console.log('[BOT CLIENT SERVICE] Total clientes en DB:', totalGeneral);
  console.log('[BOT CLIENT SERVICE] Total clientes del bot:', totalDelBot);

  return prisma.botClient.findMany({
    where,
    orderBy: [
      { ultima_interaccion_at: 'desc' },
      { actualizado_en: 'desc' },
    ],
  });
}

async function obtenerClientePorTelefono(telefono, botId = null) {
  const variantes = generarVariantesTelefono(telefono);

  console.log('[BOT CLIENT SERVICE] obtenerClientePorTelefono:', {
    telefono,
    variantes,
    botId,
  });

  return prisma.botClient.findFirst({
    where: {
      telefono: {
        in: variantes,
      },
      ...(botId ? { botId } : {}),
    },
    orderBy: {
      actualizado_en: 'desc',
    },
  });
}

async function obtenerClientePorChatId(chatid, botId = null) {
  if (!chatid) return null;

  return prisma.botClient.findFirst({
    where: {
      chatid,
      ...(botId ? { botId } : {}),
    },
    orderBy: {
      actualizado_en: 'desc',
    },
  });
}

async function buscarOCrearCliente(data) {
  const { telefono, chatid, botId } = data;

  if (!telefono) {
    throw new Error('El telefono es obligatorio');
  }

  let existente = await obtenerClientePorTelefono(telefono, botId);

  if (!existente && chatid) {
    existente = await obtenerClientePorChatId(chatid, botId);
  }

  if (existente) {
    const updateData = {
      nombre: data.nombre ?? existente.nombre,
      chatid: data.chatid ?? existente.chatid,
      usuario_whatsapp: data.usuario_whatsapp ?? existente.usuario_whatsapp,
      direccion: data.direccion ?? existente.direccion,
      ciudad: data.ciudad ?? existente.ciudad,
      sector: data.sector ?? existente.sector,
      referencia_direccion:
        data.referencia_direccion ?? existente.referencia_direccion,
      interes_principal: data.interes_principal ?? existente.interes_principal,
      producto_servicio_interes:
        data.producto_servicio_interes ?? existente.producto_servicio_interes,
      categoria_interes:
        data.categoria_interes ?? existente.categoria_interes,
      presupuesto_estimado:
        data.presupuesto_estimado ?? existente.presupuesto_estimado,
      ultimo_mensaje: data.ultimo_mensaje ?? existente.ultimo_mensaje,
      total_mensajes: {
        increment: 1,
      },
      ultima_interaccion_at: new Date(),
      dias_sin_responder: 0,
      botId: botId || existente.botId,
      actualizado_en: new Date(),
    };

    if (data.metadata) {
      const existingMetadata =
        typeof existente.metadata === 'object' && existente.metadata !== null
          ? existente.metadata
          : {};

      updateData.metadata = {
        ...existingMetadata,
        ...data.metadata,
      };
    }

    return prisma.botClient.update({
      where: {
        telefono: existente.telefono,
      },
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
      estado_cliente: data.estado_cliente ?? 'prospecto',
      etapa: data.etapa ?? 'inicio',
      total_mensajes: data.total_mensajes ?? 1,
      ultima_interaccion_at: new Date(),
      requiere_seguimiento: data.requiere_seguimiento ?? true,
      bot_pausado: data.bot_pausado ?? false,
      humano_tomo_control: data.humano_tomo_control ?? false,
      metadata: data.metadata ?? {},
      botId: botId || null,
      creado_en: new Date(),
      actualizado_en: new Date(),
    },
  });
}

async function actualizarCliente(telefono, data, botId = null) {
  const existente = await obtenerClientePorTelefono(telefono, botId);

  if (!existente) {
    return null;
  }

  const updateData = limpiarDataCliente(data);

  return prisma.botClient.update({
    where: {
      telefono: existente.telefono,
    },
    data: {
      ...updateData,
      actualizado_en: new Date(),
    },
  });
}

async function asignarBotId(telefono, botId) {
  const variantes = generarVariantesTelefono(telefono);

  console.log('[BOT CLIENT SERVICE] asignarBotId:', {
    telefono,
    variantes,
    botId,
  });

  const existente = await prisma.botClient.findFirst({
    where: {
      telefono: {
        in: variantes,
      },
    },
    orderBy: {
      actualizado_en: 'desc',
    },
  });

  if (!existente) {
    return null;
  }

  return prisma.botClient.update({
    where: {
      telefono: existente.telefono,
    },
    data: {
      botId,
      actualizado_en: new Date(),
    },
  });
}

async function actualizarEstado(telefono, estado, botId = null) {
  const existente = await obtenerClientePorTelefono(telefono, botId);

  if (!existente) {
    return null;
  }

  return prisma.botClient.update({
    where: {
      telefono: existente.telefono,
    },
    data: {
      estado_cliente: estado,
      actualizado_en: new Date(),
    },
  });
}

async function pausarBot(telefono, pausado, botId = null) {
  const existente = await obtenerClientePorTelefono(telefono, botId);

  if (!existente) {
    return null;
  }

  return prisma.botClient.update({
    where: {
      telefono: existente.telefono,
    },
    data: {
      bot_pausado: Boolean(pausado),
      actualizado_en: new Date(),
    },
  });
}

async function ejecutarDeleteSeguro(tx, sql, ...params) {
  try {
    await tx.$executeRawUnsafe(sql, ...params);
  } catch (error) {
    console.log('[eliminarCliente] Delete relacionado ignorado:', error.message);
  }
}

/**
 * Elimina un cliente y sus datos relacionados.
 *
 * IMPORTANTE:
 * Esta versión usa DELETE físico porque tu modelo actual de BotClient
 * NO tiene deleted_at, is_deleted ni sync_status.
 */
async function eliminarCliente(telefono, botId = null) {
  const existente = await obtenerClientePorTelefono(telefono, botId);

  if (!existente) {
    return null;
  }

  const telefonoReal = existente.telefono;
  const variantesTelefono = generarVariantesTelefono(telefonoReal);

  const sessionIds = new Set();
  sessionIds.add(telefonoReal);

  for (const variante of variantesTelefono) {
    sessionIds.add(variante);
  }

  if (existente.chatid && existente.chatid !== telefonoReal) {
    sessionIds.add(existente.chatid);
  }

  const sessionIdsArray = Array.from(sessionIds).filter(Boolean);

  console.log('[BOT CLIENT SERVICE] eliminarCliente:', {
    telefonoSolicitado: telefono,
    telefonoReal,
    variantesTelefono,
    sessionIdsArray,
    botId,
  });

  return prisma.$transaction(async (tx) => {
    // 1. Contextos de campañas relacionados.
    await ejecutarDeleteSeguro(
      tx,
      `
      DELETE FROM conversation_campaign_context
      WHERE customer_id = ANY($1::text[])
         OR conversation_id = ANY($2::text[])
      `,
      variantesTelefono,
      sessionIdsArray
    );

    // 2. Conversaciones del bot.
    await ejecutarDeleteSeguro(
      tx,
      `
      DELETE FROM bot_conversations
      WHERE session_id = ANY($1::text[])
      `,
      sessionIdsArray
    );

    // 3. Cotizaciones del bot.
    await ejecutarDeleteSeguro(
      tx,
      `
      DELETE FROM bot_quotations
      WHERE telefono_cliente = ANY($1::text[])
      `,
      variantesTelefono
    );

    // 4. Órdenes del bot.
    await ejecutarDeleteSeguro(
      tx,
      `
      DELETE FROM bot_orders
      WHERE telefono_cliente = ANY($1::text[])
      `,
      variantesTelefono
    );

    // 5. Cliente principal.
    const clienteEliminado = await tx.botClient.delete({
      where: {
        telefono: telefonoReal,
      },
    });

    return clienteEliminado;
  });
}

module.exports = {
  listarClientes,
  obtenerClientePorTelefono,
  obtenerClientePorChatId,
  buscarOCrearCliente,
  actualizarCliente,
  asignarBotId,
  actualizarEstado,
  pausarBot,
  eliminarCliente,
};