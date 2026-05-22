const prisma = require('../lib/prisma');

async function listarCatalogo(botId = null) {
  const where = {};
  if (botId) where.botId = botId;
  return prisma.catalogo.findMany({
    where,
    orderBy: {
      creadoEn: 'desc',
    },
  });
}

async function listarCatalogoActivo(botId = null) {
  const where = {
    estado: 'activo',
  };
  if (botId) where.botId = botId;
  return prisma.catalogo.findMany({
    where,
    orderBy: {
      creadoEn: 'desc',
    },
  });
}

async function obtenerProductoPorId(id) {
  return prisma.catalogo.findUnique({
    where: { id },
  });
}

async function crearProducto(data) {
  return prisma.catalogo.create({
    data: {
      titulo: data.titulo,
      categoria: data.categoria,
      descripcion: data.descripcion || null,
      informacion: data.informacion || null,

      precio: Number(data.precio),
      precioMinimo:
        data.precioMinimo !== undefined && data.precioMinimo !== ''
          ? Number(data.precioMinimo)
          : null,
      precioOferta:
        data.precioOferta !== undefined && data.precioOferta !== ''
          ? Number(data.precioOferta)
          : null,
      stock:
        data.stock !== undefined && data.stock !== ''
          ? Number(data.stock)
          : 0,

      imagen1: data.imagen1 || null,
      imagen2: data.imagen2 || null,
      imagen3: data.imagen3 || null,
      video: data.video || null,

      palabrasClave: data.palabrasClave || null,
      reglasNegociacion: data.reglasNegociacion || null,
      estado: data.estado || 'activo',
      botId: data.botId || null,
    },
  });
}

async function actualizarProducto(id, data) {
  return prisma.catalogo.update({
    where: { id },
    data: {
      titulo: data.titulo,
      categoria: data.categoria,
      descripcion: data.descripcion || null,
      informacion: data.informacion || null,

      precio: Number(data.precio),
      precioMinimo:
        data.precioMinimo !== undefined && data.precioMinimo !== ''
          ? Number(data.precioMinimo)
          : null,
      precioOferta:
        data.precioOferta !== undefined && data.precioOferta !== ''
          ? Number(data.precioOferta)
          : null,
      stock:
        data.stock !== undefined && data.stock !== ''
          ? Number(data.stock)
          : 0,

      imagen1: data.imagen1 || null,
      imagen2: data.imagen2 || null,
      imagen3: data.imagen3 || null,
      video: data.video || null,

      palabrasClave: data.palabrasClave || null,
      reglasNegociacion: data.reglasNegociacion || null,
      estado: data.estado || 'activo',
      botId: data.botId !== undefined ? data.botId : undefined,
    },
  });
}

async function cambiarEstadoProducto(id, estado) {
  return prisma.catalogo.update({
    where: { id },
    data: { estado },
  });
}

async function eliminarProducto(id) {
  return prisma.catalogo.delete({
    where: { id },
  });
}

module.exports = {
  listarCatalogo,
  listarCatalogoActivo,
  obtenerProductoPorId,
  crearProducto,
  actualizarProducto,
  cambiarEstadoProducto,
  eliminarProducto,
};
