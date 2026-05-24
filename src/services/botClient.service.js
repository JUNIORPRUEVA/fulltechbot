const prisma = require('../lib/prisma');
const { claimUnassignedRecords } = require('./botScope.service');

let botClientsColumnsPromise;

async function getBotClientsColumns() {
  if (!botClientsColumnsPromise) {
    botClientsColumnsPromise = prisma.$queryRawUnsafe(`
      SELECT column_name
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'bot_clients'
    `).then((rows) => new Set(rows.map((row) => row.column_name)));
  }

  return botClientsColumnsPromise;
}

function textSelect(columns, columnName) {
  return columns.has(columnName)
    ? `${columnName},`
    : `NULL::text AS ${columnName},`;
}

function intSelect(columns, columnName, fallback = '0') {
  return columns.has(columnName)
    ? `${columnName},`
    : `${fallback}::integer AS ${columnName},`;
}

function boolSelect(columns, columnName, fallback = 'false') {
  return columns.has(columnName)
    ? `${columnName},`
    : `${fallback}::boolean AS ${columnName},`;
}

function timestamptzSelect(columns, columnName) {
  return columns.has(columnName)
    ? `${columnName},`
    : `NULL::timestamptz AS ${columnName},`;
}

function floatSelect(columns, columnName) {
  return columns.has(columnName)
    ? `${columnName},`
    : `NULL::double precision AS ${columnName},`;
}

function jsonSelect(columns, columnName) {
  return columns.has(columnName)
    ? `${columnName},`
    : `'{}'::jsonb AS ${columnName},`;
}

function buildClientSelect(columns) {
  return `
    telefono,
    ${textSelect(columns, 'chatid')}
    ${textSelect(columns, 'nombre')}
    ${textSelect(columns, 'usuario_whatsapp')}
    ${textSelect(columns, 'direccion')}
    ${textSelect(columns, 'ciudad')}
    ${textSelect(columns, 'sector')}
    ${textSelect(columns, 'referencia_direccion')}
    ${textSelect(columns, 'interes_principal')}
    ${textSelect(columns, 'producto_servicio_interes')}
    ${textSelect(columns, 'categoria_interes')}
    ${floatSelect(columns, 'presupuesto_estimado')}
    ${timestamptzSelect(columns, 'fecha_interes')}
    ${textSelect(columns, 'estado_cliente')}
    ${textSelect(columns, 'etapa')}
    ${timestamptzSelect(columns, 'fecha_reserva')}
    ${textSelect(columns, 'motivo_reserva')}
    ${textSelect(columns, 'ultimo_mensaje')}
    ${timestamptzSelect(columns, 'ultima_interaccion_at')}
    ${intSelect(columns, 'dias_sin_responder')}
    ${intSelect(columns, 'total_mensajes', '1')}
    ${textSelect(columns, 'resumen_conversacion')}
    ${textSelect(columns, 'preferencias_cliente')}
    ${textSelect(columns, 'datos_importantes')}
    ${textSelect(columns, 'notas_internas')}
    ${textSelect(columns, 'satisfaccion')}
    ${textSelect(columns, 'comentario_satisfaccion')}
    ${timestamptzSelect(columns, 'ultima_compra_at')}
    ${textSelect(columns, 'productos_comprados')}
    ${boolSelect(columns, 'requiere_seguimiento', 'true')}
    ${timestamptzSelect(columns, 'proximo_seguimiento_at')}
    ${textSelect(columns, 'motivo_seguimiento')}
    ${intSelect(columns, 'cantidad_seguimientos')}
    ${timestamptzSelect(columns, 'ultimo_seguimiento_at')}
    ${boolSelect(columns, 'bot_pausado', 'false')}
    ${boolSelect(columns, 'humano_tomo_control', 'false')}
    ${jsonSelect(columns, 'metadata')}
    ${textSelect(columns, 'source_bot_id')}
    ${textSelect(columns, 'ultima_instancia_whatsapp')}
    ${textSelect(columns, 'origen')}
    ${textSelect(columns, 'preferencia_respuesta')}
    ${timestamptzSelect(columns, 'creado_en')}
    ${timestamptzSelect(columns, 'actualizado_en')}
    ${textSelect(columns, 'bot_id')}
    ${textSelect(columns, 'ultima_instancia_whatsapp')}
    ${textSelect(columns, 'origen')}
    ${textSelect(columns, 'preferencia_respuesta')}
    ${textSelect(columns, 'source_bot_id')}
    NULL::text AS id
  `;
}

function normalizeClientRow(row) {
  return {
    ...row,
    metadata:
      row.metadata && typeof row.metadata === 'object' ? row.metadata : {},
  };
}

async function queryClients(whereSql = '', params = [], orderSql = '') {
  const columns = await getBotClientsColumns();
  const rows = await prisma.$queryRawUnsafe(
    `
    SELECT
      ${buildClientSelect(columns)}
    FROM bot_clients
    ${whereSql}
    ${orderSql}
    `,
    ...params
  );

  return rows.map(normalizeClientRow);
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

  await claimUnassignedRecords(prisma.botClient, botId);

  const params = [];
  let whereSql = '';

  if (botId) {
    params.push(botId);
    whereSql = `WHERE bot_id = $${params.length}`;
  }

  return queryClients(
    whereSql,
    params,
    'ORDER BY ultima_interaccion_at DESC NULLS LAST, actualizado_en DESC NULLS LAST'
  );
}

async function obtenerClientePorTelefono(telefono, botId = null) {
  const variantes = generarVariantesTelefono(telefono);

  await claimUnassignedRecords(prisma.botClient, botId);

  console.log('[BOT CLIENT SERVICE] obtenerClientePorTelefono:', {
    telefono,
    variantes,
    botId,
  });

  const params = [variantes];
  let whereSql = 'WHERE telefono = ANY($1::text[])';

  if (botId) {
    params.push(botId);
    whereSql += ` AND bot_id = $${params.length}`;
  }

  const rows = await queryClients(
    whereSql,
    params,
    'ORDER BY actualizado_en DESC NULLS LAST LIMIT 1'
  );

  return rows[0] || null;
}

async function obtenerClientePorChatId(chatid, botId = null) {
  if (!chatid) return null;

  await claimUnassignedRecords(prisma.botClient, botId);

  const params = [chatid];
  let whereSql = 'WHERE chatid = $1';

  if (botId) {
    params.push(botId);
    whereSql += ` AND bot_id = $${params.length}`;
  }

  const rows = await queryClients(
    whereSql,
    params,
    'ORDER BY actualizado_en DESC NULLS LAST LIMIT 1'
  );

  return rows[0] || null;
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
      source_bot_id: data.source_bot_id ?? existente.source_bot_id,
      ultima_instancia_whatsapp:
        data.ultima_instancia_whatsapp ?? existente.ultima_instancia_whatsapp,
      origen: data.origen ?? existente.origen,
      preferencia_respuesta:
        data.preferencia_respuesta ?? existente.preferencia_respuesta,
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
      source_bot_id: data.source_bot_id ?? null,
      ultima_instancia_whatsapp: data.ultima_instancia_whatsapp ?? null,
      origen: data.origen ?? null,
      preferencia_respuesta: data.preferencia_respuesta ?? 'auto',
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

async function ejecutarDeleteSeguro(sql, ...params) {
  try {
    await prisma.$executeRawUnsafe(sql, ...params);
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

  // IMPORTANTE:
  // No usamos prisma.$transaction aquí porque si un DELETE relacionado falla,
  // PostgreSQL aborta la transacción completa.
  // Estos deletes son limpieza auxiliar. Si alguno falla, se ignora y seguimos.
  await ejecutarDeleteSeguro(
    `
    DELETE FROM conversation_campaign_context
    WHERE customer_id = ANY($1::text[])
       OR conversation_id = ANY($2::text[])
    `,
    variantesTelefono,
    sessionIdsArray
  );

  await ejecutarDeleteSeguro(
    `
    DELETE FROM bot_conversations
    WHERE session_id = ANY($1::text[])
    `,
    sessionIdsArray
  );

  await ejecutarDeleteSeguro(
    `
    DELETE FROM bot_quotations
    WHERE telefono_cliente = ANY($1::text[])
    `,
    variantesTelefono
  );

  await ejecutarDeleteSeguro(
    `
    DELETE FROM bot_orders
    WHERE telefono_cliente = ANY($1::text[])
    `,
    variantesTelefono
  );

  // Cliente principal.
  // Este sí debe fallar si no puede eliminarse, porque es el objetivo real.
  const clienteEliminado = await prisma.botClient.delete({
    where: {
      telefono: telefonoReal,
    },
  });

  return clienteEliminado;
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
