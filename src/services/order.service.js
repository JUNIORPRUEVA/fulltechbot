const prisma = require('../lib/prisma');
const { shouldAutoAssignSingleBot } = require('./botScope.service');

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

function normalizeOrderRow(row, index = 0) {
  const fallbackId =
    row._row_id ||
    row.id ||
    `${row.telefono_cliente || 'sin-telefono'}-${row.creado_en || index}`;

  return {
    id: String(fallbackId),
    bot_id: row.bot_id ?? null,
    telefono_cliente: row.telefono_cliente ?? '',
    nombre_cliente: row.nombre_cliente ?? null,
    producto_servicio: row.producto_servicio ?? null,
    tipo_servicio: row.tipo_servicio ?? 'otro',
    direccion: row.direccion ?? null,
    fecha_deseada: row.fecha_deseada ?? null,
    estado_pedido: row.estado_pedido ?? 'pendiente',
    resumen_pedido: row.resumen_pedido ?? null,
    creado_en: row.creado_en ?? null,
    actualizado_en: row.actualizado_en ?? null,
  };
}

function buildListQuery({ telefono, estado, botId }, columns) {
  const conditions = [];
  const values = [];

  if (telefono) {
    values.push(telefono);
    conditions.push(`telefono_cliente = $${values.length}`);
  }

  if (estado) {
    values.push(estado);
    conditions.push(`estado_pedido = $${values.length}`);
  }

  if (botId && columns.has('bot_id')) {
    values.push(botId);
    conditions.push(`bot_id = $${values.length}`);
  }

  const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
  const orderByClause = columns.has('creado_en')
    ? 'ORDER BY creado_en DESC NULLS LAST'
    : '';
  const idSelect = columns.has('id') ? 'id::text AS _row_id,' : 'ctid::text AS _row_id,';

  return {
    sql: `
      SELECT
        ${idSelect}
        telefono_cliente,
        nombre_cliente,
        producto_servicio,
        tipo_servicio,
        direccion,
        fecha_deseada,
        estado_pedido,
        resumen_pedido,
        creado_en,
        actualizado_en
        ${columns.has('bot_id') ? ', bot_id' : ''}
      FROM bot_orders
      ${whereClause}
      ${orderByClause}
    `,
    values,
  };
}

async function listarOrdenes(filtros = {}) {
  const columns = await getBotOrdersColumns();
  const { botId } = filtros;

  if (botId && columns.has('bot_id') && (await shouldAutoAssignSingleBot(botId))) {
    await prisma.$executeRawUnsafe(
      `
      UPDATE bot_orders
      SET bot_id = $1
      WHERE bot_id IS NULL
      `,
      botId
    );
  }

  const { sql, values } = buildListQuery(filtros, columns);
  const rows = await prisma.$queryRawUnsafe(sql, ...values);
  return rows.map(normalizeOrderRow);
}

async function obtenerOrdenPorId(id) {
  const columns = await getBotOrdersColumns();
  const idCondition = columns.has('id') ? 'id::text = $1' : 'ctid::text = $1';
  const idSelect = columns.has('id') ? 'id::text AS _row_id,' : 'ctid::text AS _row_id,';

  const rows = await prisma.$queryRawUnsafe(`
    SELECT
      ${idSelect}
      telefono_cliente,
      nombre_cliente,
      producto_servicio,
      tipo_servicio,
      direccion,
      fecha_deseada,
      estado_pedido,
      resumen_pedido,
      creado_en,
      actualizado_en
      ${columns.has('bot_id') ? ', bot_id' : ''}
    FROM bot_orders
    WHERE ${idCondition}
    LIMIT 1
  `, id);

  return rows[0] ? normalizeOrderRow(rows[0]) : null;
}

async function crearOrden(data) {
  const columns = await getBotOrdersColumns();
  const {
    telefonoCliente,
    nombreCliente,
    productoServicio,
    tipoServicio,
    direccion,
    fechaDeseada,
    estadoPedido,
    resumenPedido,
    botId,
  } = data;

  if (!telefonoCliente) {
    throw new Error('El telefono_cliente es obligatorio');
  }

  const insertColumns = [
    'telefono_cliente',
    'nombre_cliente',
    'producto_servicio',
    'tipo_servicio',
    'direccion',
    'fecha_deseada',
    'estado_pedido',
    'resumen_pedido',
  ];

  const values = [
    telefonoCliente,
    nombreCliente ?? null,
    productoServicio ?? null,
    tipoServicio ?? 'otro',
    direccion ?? null,
    fechaDeseada ?? null,
    estadoPedido ?? 'pendiente',
    resumenPedido ?? null,
  ];

  if (botId && columns.has('bot_id')) {
    insertColumns.push('bot_id');
    values.push(botId);
  }

  const placeholders = values.map((_, index) => `$${index + 1}`).join(', ');
  const idSelect = columns.has('id') ? 'id::text AS _row_id,' : 'ctid::text AS _row_id,';

  const rows = await prisma.$queryRawUnsafe(`
    INSERT INTO bot_orders (${insertColumns.join(', ')})
    VALUES (${placeholders})
    RETURNING
      ${idSelect}
      telefono_cliente,
      nombre_cliente,
      producto_servicio,
      tipo_servicio,
      direccion,
      fecha_deseada,
      estado_pedido,
      resumen_pedido,
      creado_en,
      actualizado_en
      ${columns.has('bot_id') ? ', bot_id' : ''}
  `, ...values);

  return normalizeOrderRow(rows[0]);
}

async function actualizarOrden(id, data) {
  const columns = await getBotOrdersColumns();
  const existente = await obtenerOrdenPorId(id);

  if (!existente) {
    return null;
  }

  const fieldMap = {
    telefonoCliente: 'telefono_cliente',
    nombreCliente: 'nombre_cliente',
    productoServicio: 'producto_servicio',
    tipoServicio: 'tipo_servicio',
    direccion: 'direccion',
    fechaDeseada: 'fecha_deseada',
    estadoPedido: 'estado_pedido',
    resumenPedido: 'resumen_pedido',
  };

  const assignments = [];
  const values = [];

  for (const [key, column] of Object.entries(fieldMap)) {
    if (data[key] !== undefined) {
      values.push(data[key]);
      assignments.push(`${column} = $${values.length}`);
    }
  }

  if (!assignments.length) {
    return existente;
  }

  const idCondition = columns.has('id')
    ? `id::text = $${values.length + 1}`
    : `ctid::text = $${values.length + 1}`;

  values.push(id);

  const idSelect = columns.has('id') ? 'id::text AS _row_id,' : 'ctid::text AS _row_id,';
  const rows = await prisma.$queryRawUnsafe(`
    UPDATE bot_orders
    SET ${assignments.join(', ')}
    WHERE ${idCondition}
    RETURNING
      ${idSelect}
      telefono_cliente,
      nombre_cliente,
      producto_servicio,
      tipo_servicio,
      direccion,
      fecha_deseada,
      estado_pedido,
      resumen_pedido,
      creado_en,
      actualizado_en
      ${columns.has('bot_id') ? ', bot_id' : ''}
  `, ...values);

  return rows[0] ? normalizeOrderRow(rows[0]) : null;
}

async function cambiarEstado(id, estado) {
  const estadosPermitidos = [
    'pendiente',
    'cotizado',
    'reservado',
    'confirmado',
    'completado',
    'cancelado',
  ];

  if (!estadosPermitidos.includes(estado)) {
    throw new Error(`Estado no valido. Permitidos: ${estadosPermitidos.join(', ')}`);
  }

  return actualizarOrden(id, { estadoPedido: estado });
}

/**
 * Elimina físicamente una orden.
 * El modelo BotOrder NO tiene deleted_at/is_deleted/sync_status,
 * por lo tanto se usa delete físico.
 */
async function eliminarOrden(id) {
  const columns = await getBotOrdersColumns();
  const existente = await obtenerOrdenPorId(id);

  if (!existente) {
    return null;
  }

  const idCondition = columns.has('id') ? 'id::text = $1' : 'ctid::text = $1';
  
  // Delete físico: la tabla bot_orders NO tiene campos de soft delete
  await prisma.$executeRawUnsafe(`
    DELETE FROM bot_orders 
    WHERE ${idCondition}
  `, id);

  return existente;
}

module.exports = {
  listarOrdenes,
  obtenerOrdenPorId,
  crearOrden,
  actualizarOrden,
  cambiarEstado,
  eliminarOrden,
};
