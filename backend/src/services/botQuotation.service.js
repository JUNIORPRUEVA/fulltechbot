const prisma = require('../lib/prisma');

async function listarCotizaciones() {
  return prisma.botQuotation.findMany({
    orderBy: { creado_en: 'desc' },
  });
}

async function obtenerCotizacionPorId(id) {
  return prisma.botQuotation.findUnique({
    where: { id },
  });
}

async function crearCotizacion(data) {
  const {
    numero_cotizacion,
    telefono_cliente,
    nombre_cliente,
    direccion_cliente,
    ciudad,
    sector,
    titulo,
    descripcion_general,
    productos,
    subtotal,
    descuento,
    total,
    moneda,
    estado,
    pdf_url,
    observaciones,
    condiciones,
    valida_hasta,
    creada_por,
  } = data;

  if (!numero_cotizacion) {
    throw new Error('El numero_cotizacion es obligatorio');
  }

  if (!telefono_cliente) {
    throw new Error('El telefono_cliente es obligatorio');
  }

  return prisma.botQuotation.create({
    data: {
      numero_cotizacion,
      telefono_cliente,
      nombre_cliente: nombre_cliente ?? null,
      direccion_cliente: direccion_cliente ?? null,
      ciudad: ciudad ?? null,
      sector: sector ?? null,
      titulo: titulo ?? 'Cotización de servicios',
      descripcion_general: descripcion_general ?? null,
      productos: productos ?? [],
      subtotal: subtotal ?? 0,
      descuento: descuento ?? 0,
      total: total ?? 0,
      moneda: moneda ?? 'DOP',
      estado: estado ?? 'pendiente',
      pdf_url: pdf_url ?? null,
      observaciones: observaciones ?? null,
      condiciones: condiciones ?? null,
      valida_hasta: valida_hasta ?? null,
      creada_por: creada_por ?? 'bot',
      creado_en: new Date(),
      actualizado_en: new Date(),
    },
  });
}

async function actualizarCotizacion(id, data) {
  const existente = await prisma.botQuotation.findUnique({
    where: { id },
  });

  if (!existente) {
    return null;
  }

  return prisma.botQuotation.update({
    where: { id },
    data: {
      ...data,
      actualizado_en: new Date(),
    },
  });
}

module.exports = {
  listarCotizaciones,
  obtenerCotizacionPorId,
  crearCotizacion,
  actualizarCotizacion,
};
