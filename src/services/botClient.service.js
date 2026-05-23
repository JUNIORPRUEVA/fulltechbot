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
  const where = {
    deleted_at: null,
    is_deleted: false,
  };
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
 * Elimina un cliente y TODOS sus datos relacionados usando SOFT DELETE.
 * 
 * En lugar de borrar físicamente, marca todos los registros como eliminados
 * para que la eliminación se propague a otros dispositivos vía sync.
 * 
 * ORDEN DE ELIMINACIÓN (de dependencias a principal):
 * 1. Conversaciones (bot_conversations) por session_id
 * 2. Cotizaciones del bot (bot_quotations) por telefono_cliente
 * 3. Órdenes del bot (bot_orders) por telefono_cliente
 * 4. Cotizaciones globales (quotations) por telefono_cliente
 * 5. Órdenes globales (orders) por telefono_cliente
 * 6. Cliente (bot_clients)
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

  const now = new Date();

  return prisma.$transaction(async (tx) => {
    // 1. Soft delete conversaciones del bot por session_id
    if (sessionIds.length > 0) {
      await tx.botConversation.updateMany({
        where: {
          session_id: { in: sessionIds },
          ...(botId ? { botId } : {}),
        },
        data: {
          deleted_at: now,
          is_deleted: true,
          sync_status: 'pending_delete',
        },
      });
    }

    // 2. Soft delete cotizaciones del bot asociadas al cliente
    await tx.botQuotation.updateMany({
      where: {
        telefono_cliente: telefono,
        ...(botId ? { botId } : {}),
      },
      data: {
        deleted_at: now,
        is_deleted: true,
        sync_status: 'pending_delete',
        actualizado_en: now,
      },
    });

    // 3. Soft delete órdenes del bot asociadas al cliente
    try {
      const botOrdersColumns = await getBotOrdersColumns();
      const canFilterByBot = botId && botOrdersColumns.has('bot_id');

      if (canFilterByBot) {
        await tx.$executeRawUnsafe(
          `UPDATE bot_orders SET deleted_at = $1, is_deleted = true, sync_status = 'pending_delete' WHERE telefono_cliente = $2 AND bot_id = $3`,
          now, telefono, botId
        );
      } else {
        await tx.$executeRawUnsafe(
          `UPDATE bot_orders SET deleted_at = $1, is_deleted = true, sync_status = 'pending_delete' WHERE telefono_cliente = $2`,
          now, telefono
        );
      }
    } catch (e) {
      console.log('[eliminarCliente] No se pudieron marcar órdenes del bot, ignorando.', e.message);
    }

    // 4. Soft delete cotizaciones globales si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `UPDATE quotations SET deleted_at = $1, is_deleted = true, sync_status = 'pending_delete' WHERE telefono_cliente = $2`,
        now, telefono
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla quotations no encontrada, ignorando.');
    }

    // 5. Soft delete órdenes globales si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `UPDATE orders SET deleted_at = $1, is_deleted = true, sync_status = 'pending_delete' WHERE telefono_cliente = $2`,
        now, telefono
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla orders no encontrada, ignorando.');
    }

    // 6. Soft delete memorias del bot si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `UPDATE bot_memories SET deleted_at = $1, is_deleted = true, sync_status = 'pending_delete' WHERE telefono_cliente = $2 OR session_id = ANY($3)`,
        now, telefono, sessionIds
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla bot_memories no encontrada, ignorando.');
    }

    // 7. Soft delete historial del bot si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `UPDATE bot_history SET deleted_at = $1, is_deleted = true, sync_status = 'pending_delete' WHERE telefono_cliente = $2 OR session_id = ANY($3)`,
        now, telefono, sessionIds
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla bot_history no encontrada, ignorando.');
    }

    // 8. Soft delete archivos multimedia relacionados si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `UPDATE bot_media SET deleted_at = $1, is_deleted = true, sync_status = 'pending_delete' WHERE telefono_cliente = $2 OR session_id = ANY($3)`,
        now, telefono, sessionIds
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla bot_media no encontrada, ignorando.');
    }

    // 9. Soft delete logs de auditoría si la tabla existe
    try {
      await tx.$executeRawUnsafe(
        `UPDATE audit_logs SET deleted_at = $1, is_deleted = true, sync_status = 'pending_delete' WHERE referencia_id = $2 OR referencia_id = ANY($3)`,
        now, telefono, sessionIds
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla audit_logs no encontrada, ignorando.');
    }

    // 10. Finalmente soft delete del cliente
    const clienteEliminado = await tx.botClient.update({
      where: { telefono },
      data: {
        deleted_at: now,
        is_deleted: true,
        sync_status: 'pending_delete',
        actualizado_en: now,
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
  actualizarEstado,
  pausarBot,
  eliminarCliente,
};
