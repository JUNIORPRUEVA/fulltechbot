const prisma = require('../lib/prisma');

async function listarCotizaciones(filtros = {}) {
  const where = {};
  if (filtros.sourceBotId) where.sourceBotId = filtros.sourceBotId;
  if (filtros.estado) where.estado = filtros.estado;
  if (filtros.telefono) where.telefono_cliente = filtros.telefono;
  if (filtros.botId) {
    where.OR = [
      { botId: filtros.botId },
      { sourceBotId: filtros.botId },
    ];
  }

  return prisma.botQuotation.findMany({
    where,
    orderBy: { creado_en: 'desc' },
    include: {
      bot: { select: { id: true, nombre: true, slug: true } },
    },
  });
}

async function obtenerCotizacionPorId(id) {
  return prisma.botQuotation.findUnique({
    where: { id },
    include: {
      bot: { select: { id: true, nombre: true, slug: true } },
    },
  });
}

function generarNumeroCotizacion() {
  const ahora = new Date();
  const yyyy = ahora.getFullYear();
  const mm = String(ahora.getMonth() + 1).padStart(2, '0');
  const dd = String(ahora.getDate()).padStart(2, '0');
  const hh = String(ahora.getHours()).padStart(2, '0');
  const min = String(ahora.getMinutes()).padStart(2, '0');
  const ss = String(ahora.getSeconds()).padStart(2, '0');
  return `COT-${yyyy}${mm}${dd}-${hh}${mm}${ss}`;
}

function parseProductos(productos) {
  if (!productos) return [];
  if (Array.isArray(productos)) return productos;
  if (typeof productos === 'string') {
    try {
      return JSON.parse(productos);
    } catch {
      return [];
    }
  }
  return [];
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
    sourceBotId,
    instanciaWhatsapp,
    origen,
  } = data;

  if (!telefono_cliente) {
    throw new Error('El telefono_cliente es obligatorio');
  }

  const numCot = numero_cotizacion || generarNumeroCotizacion();
  const prod = parseProductos(productos);
  const sub = subtotal ?? 0;
  const desc = descuento ?? 0;
  const tot = total ?? (sub - desc);

  return prisma.botQuotation.create({
    data: {
      numero_cotizacion: numCot,
      telefono_cliente,
      nombre_cliente: nombre_cliente || null,
      direccion_cliente: direccion_cliente || null,
      ciudad: ciudad || null,
      sector: sector || null,
      titulo: titulo || 'Cotización de servicios',
      descripcion_general: descripcion_general || null,
      productos: prod,
      subtotal: sub,
      descuento: desc,
      total: tot,
      moneda: moneda || 'DOP',
      estado: estado || 'pendiente',
      pdf_url: pdf_url || null,
      observaciones: observaciones || null,
      condiciones: condiciones || null,
      valida_hasta: valida_hasta ? new Date(valida_hasta) : null,
      creada_por: creada_por || 'bot',
      botId: botId || null,
      sourceBotId: sourceBotId || botId || null,
      instanciaWhatsapp: instanciaWhatsapp || null,
      origen: origen || null,
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
    instanciaWhatsapp,
    origen,
  } = data;

  const updateData = {};
  if (numero_cotizacion !== undefined) updateData.numero_cotizacion = numero_cotizacion;
  if (telefono_cliente !== undefined) updateData.telefono_cliente = telefono_cliente;
  if (nombre_cliente !== undefined) updateData.nombre_cliente = nombre_cliente;
  if (direccion_cliente !== undefined) updateData.direccion_cliente = direccion_cliente;
  if (ciudad !== undefined) updateData.ciudad = ciudad;
  if (sector !== undefined) updateData.sector = sector;
  if (titulo !== undefined) updateData.titulo = titulo;
  if (descripcion_general !== undefined) updateData.descripcion_general = descripcion_general;
  if (productos !== undefined) updateData.productos = parseProductos(productos);
  if (subtotal !== undefined) updateData.subtotal = subtotal;
  if (descuento !== undefined) updateData.descuento = descuento;
  if (total !== undefined) updateData.total = total;
  else if (subtotal !== undefined || descuento !== undefined) {
    updateData.total = (subtotal ?? existente.subtotal) - (descuento ?? existente.descuento);
  }
  if (moneda !== undefined) updateData.moneda = moneda;
  if (estado !== undefined) updateData.estado = estado;
  if (pdf_url !== undefined) updateData.pdf_url = pdf_url;
  if (observaciones !== undefined) updateData.observaciones = observaciones;
  if (condiciones !== undefined) updateData.condiciones = condiciones;
  if (valida_hasta !== undefined) updateData.valida_hasta = valida_hasta ? new Date(valida_hasta) : null;
  if (creada_por !== undefined) updateData.creada_por = creada_por;
  if (instanciaWhatsapp !== undefined) updateData.instanciaWhatsapp = instanciaWhatsapp;
  if (origen !== undefined) updateData.origen = origen;

  return prisma.botQuotation.update({
    where: { id },
    data: updateData,
  });
}

async function cambiarEstado(id, estado) {
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

  const existente = await prisma.botQuotation.findUnique({
    where: { id },
  });

  if (!existente) {
    return null;
  }

  return prisma.botQuotation.update({
    where: { id },
    data: { estado },
  });
}

async function eliminarCotizacion(id) {
  const existente = await prisma.botQuotation.findUnique({
    where: { id },
  });

  if (!existente) {
    return null;
  }

  return prisma.botQuotation.delete({
    where: { id },
  });
}

module.exports = {
  listarCotizaciones,
  obtenerCotizacionPorId,
  crearCotizacion,
  actualizarCotizacion,
  cambiarEstado,
  eliminarCotizacion,
};
