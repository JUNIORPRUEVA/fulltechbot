const prisma = require('../lib/prisma');

async function listarOrdenes(botId) {
  return prisma.botOrder.findMany({
    where: { botId },
    orderBy: { creadoEn: 'desc' },
  });
}

async function obtenerOrdenPorId(id, botId) {
  return prisma.botOrder.findFirst({
    where: { id, botId },
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
    },
  });
}

async function actualizarOrden(id, data, botId) {
  const existente = await prisma.botOrder.findFirst({
    where: { id, botId },
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
    },
  });
}

async function cambiarEstado(id, estado, botId) {
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

  const existente = await prisma.botOrder.findFirst({
    where: { id, botId },
  });

  if (!existente) {
    return null;
  }

  return prisma.botOrder.update({
    where: { id },
    data: { estadoPedido: estado },
  });
}

async function eliminarOrden(id, botId) {
  const existente = await prisma.botOrder.findFirst({
    where: { id, botId },
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
