const prisma = require('../lib/prisma');

async function listarCotizaciones(botId) {
  return prisma.botQuotation.findMany({
    where: {
      botId,
    },
    orderBy: { creado_en: 'desc' },
  });
}

async function obtenerCotizacionPorId(id, botId) {
  return prisma.botQuotation.findFirst({
    where: { id, botId },
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
    botId,
  } = data;

  if (!telefono_cliente) {
    throw new Error('El telefono_cliente es obligatorio');
  }

  // Generar número de cotización si no viene
  const numeroCotizacion = numero_cotizacion || generarNumeroCotizacion();

  // Procesar productos
  let productosData = [];
  if (productos) {
    if (Array.isArray(productos)) {
      productosData = productos;
    } else if (typeof productos === 'string') {
      try {
        productosData = JSON.parse(productos);
      } catch {
        productosData = [];
      }
    }
  }

  const subtotalNum = subtotal ?? 0;
  const descuentoNum = descuento ?? 0;
  const totalNum = total ?? (subtotalNum - descuentoNum);

  return prisma.botQuotation.create({
    data: {
      numero_cotizacion: numeroCotizacion,
      telefono_cliente,
      nombre_cliente: nombre_cliente ?? null,
      direccion_cliente: direccion_cliente ?? null,
      ciudad: ciudad ?? null,
      sector: sector ?? null,
      titulo: titulo ?? 'Cotización de servicios',
      descripcion_general: descripcion_general ?? null,
      productos: productosData,
      subtotal: subtotalNum,
      descuento: descuentoNum,
      total: totalNum,
      moneda: moneda ?? 'DOP',
      estado: estado ?? 'pendiente',
      pdf_url: pdf_url ?? null,
      observaciones: observaciones ?? null,
      condiciones: condiciones ?? null,
      valida_hasta: valida_hasta ?? null,
      creada_por: creada_por ?? 'bot',
      botId: botId || null,
      creado_en: new Date(),
      actualizado_en: new Date(),
    },
  });
}

async function actualizarCotizacion(id, data, botId) {
  const existente = await prisma.botQuotation.findFirst({
    where: { id, botId },
  });

  if (!existente) {
    return null;
  }

  const updateData = { ...data };
  delete updateData.botId;
  delete updateData.id;
  delete updateData.numero_cotizacion;

  // Procesar productos si vienen
  if (updateData.productos) {
    if (Array.isArray(updateData.productos)) {
      // ya está bien
    } else if (typeof updateData.productos === 'string') {
      try {
        updateData.productos = JSON.parse(updateData.productos);
      } catch {
        updateData.productos = [];
      }
    }
  }

  // Calcular total si no viene pero vienen subtotal/descuento
  if (updateData.total === undefined || updateData.total === null) {
    const sub = updateData.subtotal ?? existente.subtotal;
    const desc = updateData.descuento ?? existente.descuento;
    updateData.total = sub - desc;
  }

  return prisma.botQuotation.update({
    where: { id },
    data: {
      ...updateData,
      actualizado_en: new Date(),
    },
  });
}

async function cambiarEstado(id, estado, botId) {
  const estadosPermitidos = [
    'pendiente',
    'enviada',
    'aprobada',
    'rechazada',
    'vencida',
    'cancelada',
  ];

  if (!estadosPermitidos.includes(estado)) {
    throw new Error(`Estado no válido. Permitidos: ${estadosPermitidos.join(', ')}`);
  }

  const existente = await prisma.botQuotation.findFirst({
    where: { id, botId },
  });

  if (!existente) {
    return null;
  }

  return prisma.botQuotation.update({
    where: { id },
    data: {
      estado,
      actualizado_en: new Date(),
    },
  });
}

async function eliminarCotizacion(id, botId) {
  const existente = await prisma.botQuotation.findFirst({
    where: { id, botId },
  });

  if (!existente) {
    return null;
  }

  const now = new Date();
  return prisma.botQuotation.update({
    where: { id },
    data: {
      deleted_at: now,
      is_deleted: true,
      sync_status: 'pending_delete',
      actualizado_en: now,
    },
  });
}

function generarNumeroCotizacion() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  const h = String(now.getHours()).padStart(2, '0');
  const min = String(now.getMinutes()).padStart(2, '0');
  const s = String(now.getSeconds()).padStart(2, '0');
  return `COT-${y}${m}${d}-${h}${min}${s}`;
}

module.exports = {
  listarCotizaciones,
  obtenerCotizacionPorId,
  crearCotizacion,
  actualizarCotizacion,
  cambiarEstado,
  eliminarCotizacion,
};
