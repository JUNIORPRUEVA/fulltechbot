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

function filtroNoEliminado() {
  return {
    deleted_at: null,
  };
}

async function listarClientes(botId = null) {
  console.log('[BOT CLIENT SERVICE] listarClientes botId:', botId);

  const where = {
    ...filtroNoEliminado(),
  };

  if (botId) {
    where.botId = botId;
  }

  const totalGeneral = await prisma.botClient.count();

  const totalDelBot = await prisma.botClient.count({
    where,
  });

  console.log('[BOT CLIENT SERVICE] Total clientes en DB:', totalGeneral);
  console.log('[BOT CLIENT SERVICE] Total clientes visibles:', totalDelBot);

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

  const where = {
    telefono: {
      in: variantes,
    },
    ...filtroNoEliminado(),
    ...(botId ? { botId } : {}),
  };

  return prisma.botClient.findFirst({
    where,
    orderBy: {
      actualizado_en: 'desc',
    },
  });
}

async function obtenerClientePorChatId(chatid, botId = null) {
  return prisma.botClient.findFirst({
    where: {
      chatid,
      ...filtroNoEliminado(),
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
      referencia_direccion: data.referencia_direccion ?? existente.referencia_direccion,
      interes_principal: data.interes_principal ?? existente.interes_principal,
      producto_servicio_interes:
        data.producto_servicio_interes ?? existente.producto_servicio_interes,
      categoria_interes: data.categoria_interes ?? existente.categoria_interes,
      presupuesto_estimado: data.presupuesto_estimado ?? existente.presupuesto_estimado,
      ultimo_mensaje: data.ultimo_mensaje ?? existente.ultimo_mensaje,
      total_mensajes: { increment: 1 },
      ultima_interaccion_at: new Date(),
      dias_sin_responder: 0,
      botId: botId || existente.botId,
      is_deleted: false,
      deleted_at: null,
      sync_status: 'pending_update',
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
      estado_cliente: 'prospecto',
      etapa: 'inicio',
      total_mensajes: 1,
      ultima_interaccion_at: new Date(),
      requiere_seguimiento: true,
      bot_pausado: false,
      humano_tomo_control: false,
      metadata: data.metadata ?? {},
      botId: botId || null,
      is_deleted: false,
      deleted_at: null,
      sync_status: 'pending_create',
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

  const { telefono: telefonoIgnorado, botId: botIdIgnorado, ...updateData } = data;

  return prisma.botClient.update({
    where: {
      telefono: existente.telefono,
    },
    data: {
      ...updateData,
      sync_status: 'pending_update',
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
      ...filtroNoEliminado(),
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
      sync_status: 'pending_update',
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
      sync_status: 'pending_update',
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
      sync_status: 'pending_update',
      actualizado_en: new Date(),
    },
  });
}

/**
 * Elimina un cliente y todos sus datos relacionados usando SOFT DELETE.
 * No borra físico. Marca como eliminado para que no vuelva a aparecer.
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
  const now = new Date();

  console.log('[BOT CLIENT SERVICE] eliminarCliente:', {
    telefonoSolicitado: telefono,
    telefonoReal,
    variantesTelefono,
    sessionIdsArray,
    botId,
  });

  return prisma.$transaction(async (tx) => {
    // 1. Conversaciones del bot
    try {
      await tx.botConversation.updateMany({
        where: {
          session_id: {
            in: sessionIdsArray,
          },
          ...(botId ? { botId } : {}),
        },
        data: {
          deleted_at: now,
          is_deleted: true,
          sync_status: 'pending_delete',
        },
      });
    } catch (e) {
      console.log('[eliminarCliente] No se pudieron marcar conversaciones:', e.message);
    }

    // 2. Cotizaciones del bot
    try {
      await tx.botQuotation.updateMany({
        where: {
          telefono_cliente: {
            in: variantesTelefono,
          },
          ...(botId ? { botId } : {}),
        },
        data: {
          deleted_at: now,
          is_deleted: true,
          sync_status: 'pending_delete',
          actualizado_en: now,
        },
      });
    } catch (e) {
      console.log('[eliminarCliente] No se pudieron marcar cotizaciones del bot:', e.message);
    }

    // 3. Órdenes del bot
    try {
      const botOrdersColumns = await getBotOrdersColumns();
      const canFilterByBot = botId && botOrdersColumns.has('bot_id');

      if (canFilterByBot) {
        await tx.$executeRawUnsafe(
          `
          UPDATE bot_orders
          SET deleted_at = $1,
              is_deleted = true,
              sync_status = 'pending_delete'
          WHERE telefono_cliente = ANY($2::text[])
            AND bot_id = $3
          `,
          now,
          variantesTelefono,
          botId
        );
      } else {
        await tx.$executeRawUnsafe(
          `
          UPDATE bot_orders
          SET deleted_at = $1,
              is_deleted = true,
              sync_status = 'pending_delete'
          WHERE telefono_cliente = ANY($2::text[])
          `,
          now,
          variantesTelefono
        );
      }
    } catch (e) {
      console.log('[eliminarCliente] No se pudieron marcar órdenes del bot:', e.message);
    }

    // 4. Cotizaciones globales
    try {
      await tx.$executeRawUnsafe(
        `
        UPDATE quotations
        SET deleted_at = $1,
            is_deleted = true,
            sync_status = 'pending_delete'
        WHERE telefono_cliente = ANY($2::text[])
        `,
        now,
        variantesTelefono
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla quotations no encontrada o sin columnas esperadas.');
    }

    // 5. Órdenes globales
    try {
      await tx.$executeRawUnsafe(
        `
        UPDATE orders
        SET deleted_at = $1,
            is_deleted = true,
            sync_status = 'pending_delete'
        WHERE telefono_cliente = ANY($2::text[])
        `,
        now,
        variantesTelefono
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla orders no encontrada o sin columnas esperadas.');
    }

    // 6. Memorias
    try {
      await tx.$executeRawUnsafe(
        `
        UPDATE bot_memories
        SET deleted_at = $1,
            is_deleted = true,
            sync_status = 'pending_delete'
        WHERE telefono_cliente = ANY($2::text[])
           OR session_id = ANY($3::text[])
        `,
        now,
        variantesTelefono,
        sessionIdsArray
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla bot_memories no encontrada o sin columnas esperadas.');
    }

    // 7. Historial
    try {
      await tx.$executeRawUnsafe(
        `
        UPDATE bot_history
        SET deleted_at = $1,
            is_deleted = true,
            sync_status = 'pending_delete'
        WHERE telefono_cliente = ANY($2::text[])
           OR session_id = ANY($3::text[])
        `,
        now,
        variantesTelefono,
        sessionIdsArray
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla bot_history no encontrada o sin columnas esperadas.');
    }

    // 8. Multimedia
    try {
      await tx.$executeRawUnsafe(
        `
        UPDATE bot_media
        SET deleted_at = $1,
            is_deleted = true,
            sync_status = 'pending_delete'
        WHERE telefono_cliente = ANY($2::text[])
           OR session_id = ANY($3::text[])
        `,
        now,
        variantesTelefono,
        sessionIdsArray
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla bot_media no encontrada o sin columnas esperadas.');
    }

    // 9. Auditoría
    try {
      await tx.$executeRawUnsafe(
        `
        UPDATE audit_logs
        SET deleted_at = $1,
            is_deleted = true,
            sync_status = 'pending_delete'
        WHERE referencia_id = ANY($2::text[])
        `,
        now,
        sessionIdsArray
      );
    } catch (e) {
      console.log('[eliminarCliente] Tabla audit_logs no encontrada o sin columnas esperadas.');
    }

    // 10. Cliente principal
    const clienteEliminado = await tx.botClient.update({
      where: {
        telefono: telefonoReal,
      },
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
  asignarBotId,
  actualizarEstado,
  pausarBot,
  eliminarCliente,
};