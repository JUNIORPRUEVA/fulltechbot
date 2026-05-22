const prisma = require('../lib/prisma');

let botOrdersColumnsPromise;

async function getBotOrdersColumns() {
  if (!botOrdersColumnsPromise) {
    botOrdersColumnsPromise = prisma.$queryRawUnsafe(`
      SELECT column_name
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'bot_orders'
    `).then((rows) => new Set(rows.map((row) => row.column_name)));
  }

  return botOrdersColumnsPromise;
}

async function listarClientes(botId = null) {
  const where = {};
  if (botId) where.botId = botId;

  return prisma.botClient.findMany({
    where,
    orderBy: { ultima_interaccion_at: 'desc' },
  });
}

async function obtenerClientePorTelefono(telefono, botId = null) {
  if (botId) {
    return prisma.botClient.findFirst({
      where: { telefono, botId },
    });
  }

  return prisma.botClient.findUnique({
    where: { telefono },
  });
}

async function obtenerClientePorChatId(chatid, botId = null) {
  return prisma.botClient.findFirst({
    where: {
      chatid,
      ...(botId ? { botId } : {}),
    },
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

async function actualizarCliente(telefono, data, botId = null) {
  const existente = await obtenerClientePorTelefono(telefono, botId);

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
  const existente = await obtenerClientePorTelefono(telefono);

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
  const existente = await obtenerClientePorTelefono(telefono);

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

/**
 * Elimina un cliente y TODOS sus datos relacionados en una transacción.
 * 
 * ORDEN DE ELIMINACIÓN (de dependencias a principal):
 * 1. Conversaciones (bot_conversations) por session_id (chatid o telefono)
 * 2. Cotizaciones del bot (bot_quotations) por telefono_cliente
 * 3. Órdenes del bot (bot_orders) por telefono_cliente
 * 4. Cotizaciones globales (quotations) por telefono_cliente - si existe la tabla
 * 5. Órdenes globales (orders) por telefono_cliente - si existe la tabla
 * 6. Cliente (bot_clients)
 * 
 * NOTA: Si en el futuro se agregan tablas como:
 *   - bot_memories (memorias del bot)
 *   - bot_history (historial del bot)
 *   - bot_media (archivos multimedia)
 *   - audit_logs (logs de auditoría)
 * Se deben agregar aquí en el orden correcto.
 */
async function eliminarCliente(telefono, botId = null) {
  const existente = await obtenerClientePorTelefono(telefono, botId);

  if (!existente) {
    return null;
  }

  // Determinar sessionIds a eliminar (chatid y/o telefono)
  const sessionIds = [telefono];
  if (existente.chatid && existente.chatid !== telefono) {
    sessionIds.push(existente.chatid);
  }

  return prisma.$transaction(async (tx) => {
    // 1. Eliminar conversaciones del bot por session_id
    if (sessionIds.length > 0) {
      await tx.botConversation.deleteMany({
        where: {
          session_id: { in: sessionIds },
          ...(botId ? { botId } : {}),
        },
      });
    }

    // 2. Eliminar cotizaciones del bot asociadas al cliente
    await tx.botQuotation.deleteMany({
      where: {
        telefono_cliente: telefono,
        ...(botId ? { botId } : {}),
      },
    });

    // 3. Eliminar órdenes del bot asociadas al cliente
    try {
      const botOrdersColumns = await getBotOrdersColumns();
      const canFilterByBot = botId && botOrdersColumns.has('bot_id');

      if (canFilterByBot) {
        await tx.$executeRawUnsafe(
          `DELETE FROM bot_orders WHERE telefono_cliente = $1 AND bot_id = $2`,
          telefono,
          botId
        );
      } else {
        await tx.$executeRawUnsafe(
          `DELETE FROM bot_orders WHERE telefono_cliente = $1`,
          telefono
        );
      }
    } catch (e) {
      console.log('[eliminarCliente] No se pudieron eliminar órdenes del bot, ignorando.', e.message);
    }

    // 4. Intentar eliminar cotizaciones globales si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `DELETE FROM quotations WHERE telefono_cliente = $1`,
        telefono
      );
    } catch (e) {
      // La tabla puede no existir, ignorar error
      console.log('[eliminarCliente] Tabla quotations no encontrada, ignorando.');
    }

    // 5. Intentar eliminar órdenes globales si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `DELETE FROM orders WHERE telefono_cliente = $1`,
        telefono
      );
    } catch (e) {
      // La tabla puede no existir, ignorar error
      console.log('[eliminarCliente] Tabla orders no encontrada, ignorando.');
    }

    // 6. Intentar eliminar memorias del bot si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `DELETE FROM bot_memories WHERE telefono_cliente = $1 OR session_id = ANY($2)`,
        telefono, sessionIds
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla bot_memories no encontrada, ignorando.');
    }

    // 7. Intentar eliminar historial del bot si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `DELETE FROM bot_history WHERE telefono_cliente = $1 OR session_id = ANY($2)`,
        telefono, sessionIds
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla bot_history no encontrada, ignorando.');
    }

    // 8. Intentar eliminar archivos multimedia relacionados si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `DELETE FROM bot_media WHERE telefono_cliente = $1 OR session_id = ANY($2)`,
        telefono, sessionIds
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla bot_media no encontrada, ignorando.');
    }

    // 9. Intentar eliminar logs de auditoría si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `DELETE FROM audit_logs WHERE referencia_id = $1 OR referencia_id = ANY($2)`,
        telefono, sessionIds
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla audit_logs no encontrada, ignorando.');
    }

    // 10. Finalmente eliminar el cliente
    const clienteEliminado = await tx.botClient.delete({
      where: { telefono },
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
  actualizarEstado,
  pausarBot,
  eliminarCliente,
};
