const prisma = require('../lib/prisma');

async function listarOrdenes(filtros = {}) {
  const where = {};
  if (filtros.sourceBotId) where.sourceBotId = filtros.sourceBotId;
  if (filtros.estado) where.estadoPedido = filtros.estado;
  if (filtros.telefono) where.telefonoCliente = filtros.telefono;
  if (filtros.botId) where.botId = filtros.botId;

  return prisma.botOrder.findMany({
    where,
    orderBy: { creadoEn: 'desc' },
    include: {
      bot: { select: { id: true, nombre: true, slug: true } },
    },
  });
}

async function obtenerOrdenPorId(id) {
  return prisma.botOrder.findUnique({
    where: { id },
    include: {
      bot: { select: { id: true, nombre: true, slug: true } },
    },
  });
}

async function crearOrden(data) {
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
    sourceBotId,
    instanciaWhatsapp,
    origen,
    metadata,
  } = data;

  if (!telefonoCliente) {
    throw new Error('El telefono_cliente es obligatorio');
  }

  return prisma.botOrder.create({
    data: {
      telefonoCliente,
      nombreCliente: nombreCliente ?? null,
      productoServicio: productoServicio ?? null,
      tipoServicio: tipoServicio ?? 'otro',
      direccion: direccion ?? null,
      fechaDeseada: fechaDeseada ?? null,
      estadoPedido: estadoPedido ?? 'pendiente',
      resumenPedido: resumenPedido ?? null,
      botId: botId || null,
      sourceBotId: sourceBotId || botId || null,
      instanciaWhatsapp: instanciaWhatsapp || null,
      origen: origen || null,
      metadata: metadata || {},
    },
  });
}

async function actualizarOrden(id, data) {
  const existente = await prisma.botOrder.findUnique({
    where: { id },
  });

  if (!existente) {
    return null;
  }

  const {
    telefonoCliente,
    nombreCliente,
    productoServicio,
    tipoServicio,
    direccion,
    fechaDeseada,
    estadoPedido,
    resumenPedido,
    instanciaWhatsapp,
    origen,
    metadata,
  } = data;

  return prisma.botOrder.update({
    where: { id },
    data: {
      ...(telefonoCliente !== undefined && { telefonoCliente }),
      ...(nombreCliente !== undefined && { nombreCliente }),
      ...(productoServicio !== undefined && { productoServicio }),
      ...(tipoServicio !== undefined && { tipoServicio }),
      ...(direccion !== undefined && { direccion }),
      ...(fechaDeseada !== undefined && { fechaDeseada }),
      ...(estadoPedido !== undefined && { estadoPedido }),
      ...(resumenPedido !== undefined && { resumenPedido }),
      ...(instanciaWhatsapp !== undefined && { instanciaWhatsapp }),
      ...(origen !== undefined && { origen }),
      ...(metadata !== undefined && { metadata }),
    },
  });
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
    throw new Error(`Estado no válido. Permitidos: ${estadosPermitidos.join(', ')}`);
  }

  const existente = await prisma.botOrder.findUnique({
    where: { id },
  });

  if (!existente) {
    return null;
  }

  return prisma.botOrder.update({
    where: { id },
    data: { estadoPedido: estado },
  });
}

async function eliminarOrden(id) {
  const existente = await prisma.botOrder.findUnique({
    where: { id },
  });

  if (!existente) {
    return null;
  }

  return prisma.botOrder.delete({
    where: { id },
  });
}

module.exports = {
  listarOrdenes,
  obtenerOrdenPorId,
  crearOrden,
  actualizarOrden,
  cambiarEstado,
  eliminarOrden,
};
