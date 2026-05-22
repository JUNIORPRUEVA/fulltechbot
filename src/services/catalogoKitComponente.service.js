const prisma = require('../lib/prisma');

/**
 * Obtener todos los componentes de un kit
 */
async function obtenerComponentesKit(kitId) {
  const relaciones = await prisma.$queryRawUnsafe(`
    SELECT
      r.id,
      r.kit_id,
      r.componente_id,
      r.cantidad,
      r.incluido,
      r.es_opcional,
      r.nota,
      r.orden,
      r.creado_en,
      r.actualizado_en,
      c.titulo,
      c.categoria,
      c.tipo_producto,
      c.descripcion,
      c.informacion,
      c.precio,
      c.precio_minimo,
      c.precio_oferta,
      c.stock,
      c.imagen1,
      c.imagen2,
      c.imagen3,
      c.video
    FROM catalogo_kit_componentes r
    JOIN catalogo c ON c.id = r.componente_id
    WHERE r.kit_id = $1
    ORDER BY r.orden ASC, c.titulo ASC
  `, kitId);

  return (relaciones || []).map(normalizarRelacion);
}

/**
 * Obtener detalle completo del kit (kit + componentes incluidos + extras opcionales)
 */
async function obtenerDetalleKit(kitId) {
  const kit = await prisma.catalogo.findUnique({ where: { id: kitId } });
  if (!kit) return null;

  const relaciones = await obtenerComponentesKit(kitId);

  return {
    kit,
    componentesIncluidos: relaciones.filter(r => r.incluido && !r.esOpcional),
    extrasOpcionales: relaciones.filter(r => r.esOpcional),
  };
}

/**
 * Agregar un componente a un kit
 */
async function agregarComponenteKit(kitId, data) {
  // Validar que el kit existe
  const kit = await prisma.catalogo.findUnique({ where: { id: kitId } });
  if (!kit) throw new Error('Kit no encontrado');

  // Validar que el componente existe
  const componente = await prisma.catalogo.findUnique({ where: { id: data.componente_id } });
  if (!componente) throw new Error('Componente no encontrado');

  // Validar que pertenecen al mismo bot
  if (kit.botId !== componente.botId) {
    throw new Error('El componente no pertenece al mismo bot del kit');
  }

  // No permitir agregar el kit como componente de sí mismo
  if (data.componente_id === kitId) {
    throw new Error('No puedes agregar el kit como componente de sí mismo');
  }

  // Validar que no exista duplicado
  const existente = await prisma.$queryRawUnsafe(`
    SELECT id FROM catalogo_kit_componentes
    WHERE kit_id = $1 AND componente_id = $2
    LIMIT 1
  `, kitId, data.componente_id);

  if (existente && existente.length > 0) {
    throw new Error('Este componente ya está agregado al kit. Actualiza la cantidad en lugar de agregarlo de nuevo.');
  }

  const cantidad = data.cantidad !== undefined && data.cantidad !== '' ? Number(data.cantidad) : 1;
  if (cantidad <= 0) throw new Error('La cantidad debe ser mayor que 0');

  const result = await prisma.$executeRawUnsafe(`
    INSERT INTO catalogo_kit_componentes (kit_id, componente_id, cantidad, incluido, es_opcional, nota, orden)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING id
  `, kitId, data.componente_id, cantidad,
    data.incluido !== undefined ? Boolean(data.incluido) : true,
    data.es_opcional !== undefined ? Boolean(data.es_opcional) : false,
    data.nota || null,
    data.orden !== undefined ? Number(data.orden) : 0
  );

  // Obtener la relación recién creada
  const relaciones = await obtenerComponentesKit(kitId);
  return relaciones.find(r => r.componenteId === data.componente_id) || null;
}

/**
 * Actualizar un componente del kit
 */
async function actualizarComponenteKit(kitId, relacionId, data) {
  const updateFields = [];
  const values = [];
  let paramIndex = 1;

  if (data.cantidad !== undefined) {
    const cantidad = Number(data.cantidad);
    if (cantidad <= 0) throw new Error('La cantidad debe ser mayor que 0');
    updateFields.push(`cantidad = $${paramIndex++}`);
    values.push(cantidad);
  }
  if (data.incluido !== undefined) {
    updateFields.push(`incluido = $${paramIndex++}`);
    values.push(Boolean(data.incluido));
  }
  if (data.es_opcional !== undefined) {
    updateFields.push(`es_opcional = $${paramIndex++}`);
    values.push(Boolean(data.es_opcional));
  }
  if (data.nota !== undefined) {
    updateFields.push(`nota = $${paramIndex++}`);
    values.push(data.nota || null);
  }
  if (data.orden !== undefined) {
    updateFields.push(`orden = $${paramIndex++}`);
    values.push(Number(data.orden));
  }

  if (updateFields.length === 0) {
    throw new Error('No hay campos para actualizar');
  }

  updateFields.push(`actualizado_en = CURRENT_TIMESTAMP`);

  values.push(relacionId);
  values.push(kitId);

  await prisma.$executeRawUnsafe(`
    UPDATE catalogo_kit_componentes
    SET ${updateFields.join(', ')}
    WHERE id = $${paramIndex++} AND kit_id = $${paramIndex}
  `, ...values);

  // Obtener la relación actualizada
  const relaciones = await obtenerComponentesKit(kitId);
  return relaciones.find(r => r.id === relacionId) || null;
}

/**
 * Eliminar un componente del kit
 */
async function eliminarComponenteKit(kitId, relacionId) {
  const result = await prisma.$executeRawUnsafe(`
    DELETE FROM catalogo_kit_componentes
    WHERE id = $1 AND kit_id = $2
  `, relacionId, kitId);

  return result > 0;
}

/**
 * Buscar productos disponibles para agregar como componente
 */
async function buscarProductosParaComponente({ botId, query, excludeKitId }) {
  let sql = `
    SELECT * FROM catalogo
    WHERE bot_id = $1
      AND tipo_producto IN ('componente', 'accesorio', 'repuesto', 'servicio', 'extra', 'producto')
  `;
  const params = [botId];
  let paramIndex = 2;

  if (excludeKitId) {
    sql += ` AND id != $${paramIndex++}`;
    params.push(excludeKitId);
  }

  if (query && query.trim()) {
    sql += ` AND (
      titulo ILIKE $${paramIndex}
      OR categoria ILIKE $${paramIndex}
      OR palabras_clave ILIKE $${paramIndex}
    )`;
    params.push(`%${query.trim()}%`);
    paramIndex++;
  }

  sql += ` ORDER BY orden ASC, titulo ASC LIMIT 50`;

  return prisma.$queryRawUnsafe(sql, ...params);
}

function normalizarRelacion(r) {
  return {
    id: r.id,
    kitId: r.kit_id,
    componenteId: r.componente_id,
    cantidad: Number(r.cantidad),
    incluido: Boolean(r.incluido),
    esOpcional: Boolean(r.es_opcional),
    nota: r.nota,
    orden: Number(r.orden),
    creadoEn: r.creado_en,
    actualizadoEn: r.actualizado_en,
    // Datos del componente
    titulo: r.titulo,
    categoria: r.categoria,
    tipoProducto: r.tipo_producto,
    descripcion: r.descripcion,
    informacion: r.informacion,
    precio: r.precio ? Number(r.precio) : 0,
    precioMinimo: r.precio_minimo ? Number(r.precio_minimo) : null,
    precioOferta: r.precio_oferta ? Number(r.precio_oferta) : null,
    stock: r.stock ? Number(r.stock) : 0,
    imagen1: r.imagen1,
    imagen2: r.imagen2,
    imagen3: r.imagen3,
    video: r.video,
  };
}

module.exports = {
  obtenerComponentesKit,
  obtenerDetalleKit,
  agregarComponenteKit,
  actualizarComponenteKit,
  eliminarComponenteKit,
  buscarProductosParaComponente,
};
