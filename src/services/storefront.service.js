/**
 * STOREFRONT SERVICE
 * 
 * Capa storefront para vender productos online usando tablas reales:
 * - catalogo = productos reales
 * - bot_clients = clientes reales
 * - bot_orders = pedidos reales
 * 
 * NO duplica productos, clientes ni pedidos.
 * NO usa prisma migrate.
 * Usa SQL directo con Prisma.
 */

const prisma = require('../lib/prisma');
const orderService = require('./order.service');
const botClientService = require('./botClient.service');

// ============================================
// HELPERS
// ============================================

function serializeBigInt(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'bigint') return Number(value);
  return value;
}

function serializeRow(row) {
  if (!row) return null;
  const obj = {};
  for (const [key, val] of Object.entries(row)) {
    obj[key] = serializeBigInt(val);
  }
  return obj;
}

function serializeRows(rows) {
  return rows.map(serializeRow);
}

// ============================================
// STOREFRONT CONFIG
// ============================================

async function getConfigBySlug(slug) {
  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_config WHERE slug = $1 AND activo = true LIMIT 1`,
    slug
  );
  return rows[0] ? serializeRow(rows[0]) : null;
}

async function getConfigByBotId(botId) {
  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_config WHERE bot_id = $1 LIMIT 1`,
    botId
  );
  return rows[0] ? serializeRow(rows[0]) : null;
}

async function upsertConfig(botId, data) {
  const existente = await getConfigByBotId(botId);

  if (existente) {
    const assignments = [];
    const values = [];
    const allowedFields = [
      'slug', 'nombre_tienda', 'descripcion', 'logo_url',
      'color_principal', 'color_secundario', 'whatsapp_numero',
      'telefono_contacto', 'direccion', 'horario',
      'mensaje_principal', 'mensaje_secundario', 'activo',
      'permitir_paypal', 'permitir_whatsapp', 'permitir_retiro_tienda',
      'permitir_delivery',
    ];

    for (const field of allowedFields) {
      if (data[field] !== undefined) {
        values.push(data[field]);
        assignments.push(`${field} = $${values.length}`);
      }
    }

    if (assignments.length === 0) return existente;

    values.push(botId);
    assignments.push(`actualizado_en = NOW()`);

    await prisma.$executeRawUnsafe(
      `UPDATE storefront_config SET ${assignments.join(', ')} WHERE bot_id = $${values.length}`,
      ...values
    );

    return getConfigByBotId(botId);
  }

  // Crear nueva
  const fields = [
    'bot_id', 'slug', 'nombre_tienda', 'descripcion', 'logo_url',
    'color_principal', 'color_secundario', 'whatsapp_numero',
    'telefono_contacto', 'direccion', 'horario',
    'mensaje_principal', 'mensaje_secundario', 'activo',
    'permitir_paypal', 'permitir_whatsapp', 'permitir_retiro_tienda',
    'permitir_delivery',
  ];

  const values = [
    botId,
    data.slug || `tienda-${botId}`,
    data.nombre_tienda || 'Mi Tienda',
    data.descripcion || null,
    data.logo_url || null,
    data.color_principal || '#0F172A',
    data.color_secundario || '#2563EB',
    data.whatsapp_numero || null,
    data.telefono_contacto || null,
    data.direccion || null,
    data.horario || null,
    data.mensaje_principal || null,
    data.mensaje_secundario || null,
    data.activo !== undefined ? data.activo : true,
    data.permitir_paypal || false,
    data.permitir_whatsapp !== undefined ? data.permitir_whatsapp : true,
    data.permitir_retiro_tienda !== undefined ? data.permitir_retiro_tienda : true,
    data.permitir_delivery || false,
  ];

  const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');

  await prisma.$executeRawUnsafe(
    `INSERT INTO storefront_config (${fields.join(', ')}) VALUES (${placeholders})`,
    ...values
  );

  return getConfigByBotId(botId);
}

// ============================================
// BANNERS
// ============================================

async function getBanners(botId, soloActivos = true) {
  const whereActivo = soloActivos ? 'AND activo = true' : '';
  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_banners WHERE bot_id = $1 ${whereActivo} ORDER BY orden ASC, creado_en DESC`,
    botId
  );
  return serializeRows(rows);
}

async function createBanner(botId, data) {
  const fields = [
    'bot_id', 'titulo', 'subtitulo', 'imagen_url', 'link_url',
    'boton_texto', 'orden', 'activo', 'fecha_inicio', 'fecha_fin',
  ];
  const values = [
    botId,
    data.titulo,
    data.subtitulo || null,
    data.imagen_url || null,
    data.link_url || null,
    data.boton_texto || null,
    data.orden || 0,
    data.activo !== undefined ? data.activo : true,
    data.fecha_inicio || null,
    data.fecha_fin || null,
  ];
  const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');

  await prisma.$executeRawUnsafe(
    `INSERT INTO storefront_banners (${fields.join(', ')}) VALUES (${placeholders})`,
    ...values
  );

  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_banners WHERE bot_id = $1 ORDER BY creado_en DESC LIMIT 1`,
    botId
  );
  return rows[0] ? serializeRow(rows[0]) : null;
}

async function updateBanner(id, data) {
  const assignments = [];
  const values = [];
  const allowedFields = [
    'titulo', 'subtitulo', 'imagen_url', 'link_url', 'boton_texto',
    'orden', 'activo', 'fecha_inicio', 'fecha_fin',
  ];

  for (const field of allowedFields) {
    if (data[field] !== undefined) {
      values.push(data[field]);
      assignments.push(`${field} = $${values.length}`);
    }
  }

  if (assignments.length === 0) return getBannerById(id);

  values.push(id);
  assignments.push(`actualizado_en = NOW()`);

  await prisma.$executeRawUnsafe(
    `UPDATE storefront_banners SET ${assignments.join(', ')} WHERE id = $${values.length}`,
    ...values
  );

  return getBannerById(id);
}

async function deleteBanner(id) {
  const existente = await getBannerById(id);
  if (!existente) return null;
  await prisma.$executeRawUnsafe(`DELETE FROM storefront_banners WHERE id = $1`, id);
  return existente;
}

async function getBannerById(id) {
  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_banners WHERE id = $1 LIMIT 1`,
    id
  );
  return rows[0] ? serializeRow(rows[0]) : null;
}

// ============================================
// PRODUCT SETTINGS (storefront)
// ============================================

async function getProductSettings(botId, productoId = null) {
  if (productoId) {
    const rows = await prisma.$queryRawUnsafe(
      `SELECT * FROM storefront_product_settings WHERE bot_id = $1 AND producto_id = $2 LIMIT 1`,
      botId, productoId
    );
    return rows[0] ? serializeRow(rows[0]) : null;
  }

  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_product_settings WHERE bot_id = $1 ORDER BY orden ASC, creado_en DESC`,
    botId
  );
  return serializeRows(rows);
}

async function upsertProductSetting(botId, productoId, data) {
  const existente = await getProductSettings(botId, productoId);

  if (existente) {
    const assignments = [];
    const values = [];
    const allowedFields = [
      'visible_en_tienda', 'destacado', 'orden', 'etiqueta',
      'precio_oferta_web', 'descripcion_web', 'imagen_destacada_url',
      'permitir_compra_online', 'permitir_whatsapp', 'requiere_instalacion', 'activo',
    ];

    for (const field of allowedFields) {
      if (data[field] !== undefined) {
        values.push(data[field]);
        assignments.push(`${field} = $${values.length}`);
      }
    }

    if (assignments.length === 0) return existente;

    values.push(botId, productoId);
    assignments.push(`actualizado_en = NOW()`);

    await prisma.$executeRawUnsafe(
      `UPDATE storefront_product_settings SET ${assignments.join(', ')} WHERE bot_id = $${values.length - 1} AND producto_id = $${values.length}`,
      ...values
    );

    return getProductSettings(botId, productoId);
  }

  // Crear nuevo
  const fields = [
    'bot_id', 'producto_id', 'visible_en_tienda', 'destacado', 'orden',
    'etiqueta', 'precio_oferta_web', 'descripcion_web', 'imagen_destacada_url',
    'permitir_compra_online', 'permitir_whatsapp', 'requiere_instalacion', 'activo',
  ];
  const values = [
    botId,
    productoId,
    data.visible_en_tienda || false,
    data.destacado || false,
    data.orden || 0,
    data.etiqueta || null,
    data.precio_oferta_web || null,
    data.descripcion_web || null,
    data.imagen_destacada_url || null,
    data.permitir_compra_online !== undefined ? data.permitir_compra_online : true,
    data.permitir_whatsapp !== undefined ? data.permitir_whatsapp : true,
    data.requiere_instalacion || false,
    data.activo !== undefined ? data.activo : true,
  ];
  const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');

  await prisma.$executeRawUnsafe(
    `INSERT INTO storefront_product_settings (${fields.join(', ')}) VALUES (${placeholders})`,
    ...values
  );

  return getProductSettings(botId, productoId);
}

// ============================================
// PRODUCTOS PÚBLICOS (desde catalogo + settings)
// ============================================

async function getStorefrontProducts(botId, options = {}) {
  const {
    categoria,
    destacado,
    busqueda,
    page = 1,
    limit = 20,
  } = options;

  const offset = (page - 1) * limit;
  const conditions = [
    `c.estado = 'activo'`,
    `ps.visible_en_tienda = true`,
    `ps.activo = true`,
    `c.bot_id = $1`,
  ];
  const params = [botId];
  let paramIndex = 2;

  if (categoria) {
    params.push(categoria);
    conditions.push(`c.categoria = $${paramIndex++}`);
  }

  if (destacado) {
    conditions.push(`ps.destacado = true`);
  }

  if (busqueda) {
    params.push(`%${busqueda}%`);
    conditions.push(`(c.titulo ILIKE $${paramIndex} OR c.descripcion ILIKE $${paramIndex} OR c.palabras_clave ILIKE $${paramIndex})`);
    paramIndex++;
  }

  const whereClause = conditions.join(' AND ');

  // Count
  const countRows = await prisma.$queryRawUnsafe(
    `SELECT COUNT(*) as total FROM catalogo c
     INNER JOIN storefront_product_settings ps ON c.id::text = ps.producto_id AND ps.bot_id = $1
     WHERE ${whereClause}`,
    ...params
  );
  const total = Number(countRows[0]?.total || 0);

  // Data
  params.push(limit, offset);
  const rows = await prisma.$queryRawUnsafe(
    `SELECT
       c.id, c.titulo, c.categoria, c.descripcion, c.informacion,
       c.precio, c.precio_minimo, c.precio_oferta, c.stock,
       c.imagen1, c.imagen2, c.imagen3, c.video,
       c.palabras_clave, c.estado, c.tipo_producto, c.incluye,
       c.permite_adicionales, c.es_cotizable, c.orden,
       c.cantidad_base, c.unidad_adicional_nombre, c.precio_adicional,
       c.instalacion_incluida, c.reglas_calculo,
       ps.id as setting_id, ps.visible_en_tienda, ps.destacado,
       ps.etiqueta, ps.precio_oferta_web, ps.descripcion_web,
       ps.imagen_destacada_url, ps.permitir_compra_online,
       ps.permitir_whatsapp, ps.requiere_instalacion
     FROM catalogo c
     INNER JOIN storefront_product_settings ps ON c.id::text = ps.producto_id AND ps.bot_id = $1
     WHERE ${whereClause}
     ORDER BY ps.orden ASC, c.creado_en DESC
     LIMIT $${paramIndex++} OFFSET $${paramIndex}`,
    ...params
  );

  return {
    products: serializeRows(rows),
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
  };
}

async function getStorefrontProductById(botId, productId) {
  const rows = await prisma.$queryRawUnsafe(
    `SELECT
       c.id, c.titulo, c.categoria, c.descripcion, c.informacion,
       c.precio, c.precio_minimo, c.precio_oferta, c.stock,
       c.imagen1, c.imagen2, c.imagen3, c.video,
       c.palabras_clave, c.estado, c.tipo_producto, c.incluye,
       c.permite_adicionales, c.es_cotizable, c.orden,
       c.cantidad_base, c.unidad_adicional_nombre, c.precio_adicional,
       c.precio_minimo_adicional, c.permite_calculo_adicional,
       c.ciudad_base, c.cargo_fuera_ciudad, c.aplica_cargo_fuera_ciudad,
       c.instalacion_incluida, c.reglas_calculo,
       ps.id as setting_id, ps.visible_en_tienda, ps.destacado,
       ps.etiqueta, ps.precio_oferta_web, ps.descripcion_web,
       ps.imagen_destacada_url, ps.permitir_compra_online,
       ps.permitir_whatsapp, ps.requiere_instalacion
     FROM catalogo c
     INNER JOIN storefront_product_settings ps ON c.id::text = ps.producto_id AND ps.bot_id = $1
     WHERE c.id = $2 AND c.estado = 'activo' AND ps.visible_en_tienda = true AND ps.activo = true
     LIMIT 1`,
    botId, productId
  );
  return rows[0] ? serializeRow(rows[0]) : null;
}

async function getStorefrontCategories(botId) {
  const rows = await prisma.$queryRawUnsafe(
    `SELECT DISTINCT c.categoria, COUNT(*) as total
     FROM catalogo c
     INNER JOIN storefront_product_settings ps ON c.id::text = ps.producto_id AND ps.bot_id = $1
     WHERE c.estado = 'activo' AND ps.visible_en_tienda = true AND ps.activo = true
     GROUP BY c.categoria
     ORDER BY c.categoria ASC`,
    botId
  );
  return serializeRows(rows);
}

// ============================================
// CARRITO
// ============================================

async function getOrCreateCart(botId, sessionId) {
  let rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_carts WHERE bot_id = $1 AND session_id = $2 AND estado = 'activo' LIMIT 1`,
    botId, sessionId
  );

  if (rows.length === 0) {
    await prisma.$executeRawUnsafe(
      `INSERT INTO storefront_carts (bot_id, session_id) VALUES ($1, $2)`,
      botId, sessionId
    );
    rows = await prisma.$queryRawUnsafe(
      `SELECT * FROM storefront_carts WHERE bot_id = $1 AND session_id = $2 LIMIT 1`,
      botId, sessionId
    );
  }

  return rows[0] ? serializeRow(rows[0]) : null;
}

async function getCartWithItems(cartId) {
  const cartRows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_carts WHERE id = $1 LIMIT 1`,
    cartId
  );
  if (cartRows.length === 0) return null;

  const cart = serializeRow(cartRows[0]);
  const items = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_cart_items WHERE cart_id = $1 ORDER BY creado_en ASC`,
    cartId
  );
  cart.items = serializeRows(items);
  return cart;
}

async function getCartBySession(botId, sessionId) {
  const cartRows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_carts WHERE bot_id = $1 AND session_id = $2 AND estado = 'activo' LIMIT 1`,
    botId, sessionId
  );
  if (cartRows.length === 0) return null;

  const cart = serializeRow(cartRows[0]);
  const items = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_cart_items WHERE cart_id = $1 ORDER BY creado_en ASC`,
    cart.id
  );
  cart.items = serializeRows(items);
  return cart;
}

async function addItemToCart(cartId, data) {
  const { producto_id, nombre_producto, cantidad, precio_unitario, imagen_url, metadata } = data;
  const subtotal = Number(cantidad) * Number(precio_unitario);

  // Verificar si ya existe el producto en el carrito
  const existing = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_cart_items WHERE cart_id = $1 AND producto_id = $2 LIMIT 1`,
    cartId, producto_id
  );

  if (existing.length > 0) {
    // Actualizar cantidad
    const item = existing[0];
    const newCantidad = Number(item.cantidad) + Number(cantidad);
    const newSubtotal = newCantidad * Number(precio_unitario);

    await prisma.$executeRawUnsafe(
      `UPDATE storefront_cart_items SET cantidad = $1, subtotal = $2, actualizado_en = NOW() WHERE id = $3`,
      newCantidad, newSubtotal, item.id
    );
  } else {
    await prisma.$executeRawUnsafe(
      `INSERT INTO storefront_cart_items (cart_id, producto_id, nombre_producto, cantidad, precio_unitario, subtotal, imagen_url, metadata)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      cartId, producto_id, nombre_producto, cantidad, precio_unitario, subtotal, imagen_url || null, metadata ? JSON.stringify(metadata) : null
    );
  }

  await recalculateCart(cartId);
  return getCartWithItems(cartId);
}

async function updateCartItem(itemId, data) {
  const { cantidad } = data;

  const itemRows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_cart_items WHERE id = $1 LIMIT 1`,
    itemId
  );
  if (itemRows.length === 0) return null;

  const item = itemRows[0];
  const newCantidad = cantidad !== undefined ? Number(cantidad) : Number(item.cantidad);
  const newSubtotal = newCantidad * Number(item.precio_unitario);

  await prisma.$executeRawUnsafe(
    `UPDATE storefront_cart_items SET cantidad = $1, subtotal = $2, actualizado_en = NOW() WHERE id = $3`,
    newCantidad, newSubtotal, itemId
  );

  await recalculateCart(Number(item.cart_id));
  return getCartWithItems(Number(item.cart_id));
}

async function deleteCartItem(itemId) {
  const itemRows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_cart_items WHERE id = $1 LIMIT 1`,
    itemId
  );
  if (itemRows.length === 0) return null;

  const cartId = Number(itemRows[0].cart_id);
  await prisma.$executeRawUnsafe(`DELETE FROM storefront_cart_items WHERE id = $1`, itemId);
  await recalculateCart(cartId);
  return getCartWithItems(cartId);
}

async function recalculateCart(cartId) {
  const rows = await prisma.$queryRawUnsafe(
    `SELECT COALESCE(SUM(subtotal), 0) as subtotal FROM storefront_cart_items WHERE cart_id = $1`,
    cartId
  );
  const subtotal = Number(rows[0]?.subtotal || 0);

  await prisma.$executeRawUnsafe(
    `UPDATE storefront_carts SET subtotal = $1, total = $1, actualizado_en = NOW() WHERE id = $2`,
    subtotal, cartId
  );
}

// ============================================
// CHECKOUT
// ============================================

async function checkout(botId, sessionId, data) {
  const {
    telefono_cliente,
    nombre_cliente,
    direccion,
    ciudad,
    sector,
    metodo_entrega = 'retiro_tienda',
    metodo_pago = 'whatsapp',
    notas,
  } = data;

  // 1. Obtener carrito
  const cart = await getCartBySession(botId, sessionId);
  if (!cart || !cart.items || cart.items.length === 0) {
    throw new Error('El carrito está vacío');
  }

  // 2. Buscar o crear cliente en bot_clients
  const clienteData = {
    telefono: telefono_cliente,
    nombre: nombre_cliente || null,
    direccion: direccion || null,
    ciudad: ciudad || null,
    sector: sector || null,
    origen: 'tienda_online',
    botId: botId,
  };

  const cliente = await botClientService.buscarOCrearCliente(clienteData);

  // 3. Preparar resumen del pedido
  const productosResumen = cart.items.map(item =>
    `${item.nombre_producto} x${item.cantidad} = $${item.subtotal}`
  ).join('\n');

  const resumenPedido = [
    `🛒 Pedido desde Tienda Online`,
    ``,
    `Productos:`,
    productosResumen,
    ``,
    `Subtotal: $${cart.subtotal}`,
    `Total: $${cart.total}`,
    ``,
    `📦 Método de entrega: ${metodo_entrega}`,
    `💳 Método de pago: ${metodo_pago}`,
    direccion ? `📍 Dirección: ${direccion}` : '',
    ciudad ? `🏙️ Ciudad: ${ciudad}` : '',
    sector ? `📍 Sector: ${sector}` : '',
    notas ? `📝 Notas: ${notas}` : '',
  ].filter(Boolean).join('\n');

  // 4. Determinar estado según método de pago
  let estadoPedido = 'pendiente';
  if (metodo_pago === 'paypal') {
    estadoPedido = 'pendiente_pago';
  }

  // 5. Crear pedido en bot_orders
  const orden = await orderService.crearOrden({
    telefonoCliente: telefono_cliente,
    nombreCliente: nombre_cliente || null,
    productoServicio: cart.items.map(i => i.nombre_producto).join(', '),
    tipoServicio: 'producto',
    direccion: direccion || null,
    estadoPedido: estadoPedido,
    resumenPedido: resumenPedido,
    botId: botId,
    origen: 'tienda_online',
    metadata: {
      storefront: true,
      session_id: sessionId,
      cart_id: cart.id,
      metodo_entrega,
      metodo_pago,
      items: cart.items.map(i => ({
        producto_id: i.producto_id,
        nombre: i.nombre_producto,
        cantidad: i.cantidad,
        precio_unitario: i.precio_unitario,
        subtotal: i.subtotal,
      })),
      total: cart.total,
      notas,
    },
  });

  // 6. Marcar carrito como completado
  await prisma.$executeRawUnsafe(
    `UPDATE storefront_carts SET estado = 'completado', telefono_cliente = $1, nombre_cliente = $2, actualizado_en = NOW() WHERE id = $3`,
    telefono_cliente, nombre_cliente || null, cart.id
  );

  return {
    orden,
    cliente,
    cart: await getCartWithItems(cart.id),
  };
}

// ============================================
// WHATSAPP ORDER
// ============================================

async function generateWhatsAppLink(botId, sessionId, data) {
  const cart = await getCartBySession(botId, sessionId);
  if (!cart || !cart.items || cart.items.length === 0) {
    throw new Error('El carrito está vacío');
  }

  const config = await getConfigByBotId(botId);
  const whatsappNumber = config?.whatsapp_numero || data.whatsapp_numero;

  if (!whatsappNumber) {
    throw new Error('No hay número de WhatsApp configurado');
  }

  const {
    nombre_cliente = '',
    telefono_cliente = '',
    direccion = '',
    ciudad = '',
    sector = '',
    metodo_entrega = 'retiro_tienda',
    notas = '',
  } = data;

  const productosTexto = cart.items.map(item =>
    `• ${item.nombre_producto} x${item.cantidad} = $${item.subtotal}`
  ).join('\n');

  const mensaje = [
    `🛒 *Nuevo Pedido - Tienda Online*`,
    ``,
    `👤 *Cliente:* ${nombre_cliente}`,
    `📱 *Teléfono:* ${telefono_cliente}`,
    ``,
    `*Productos:*`,
    productosTexto,
    ``,
    `💰 *Total: $${cart.total}*`,
    ``,
    `📦 *Entrega:* ${metodo_entrega}`,
    direccion ? `📍 *Dirección:* ${direccion}` : '',
    ciudad ? `🏙️ *Ciudad:* ${ciudad}` : '',
    sector ? `📍 *Sector:* ${sector}` : '',
    notas ? `📝 *Notas:* ${notas}` : '',
  ].filter(Boolean).join('\n');

  const numeroLimpio = whatsappNumber.replace(/[^\d]/g, '');
  const url = `https://wa.me/${numeroLimpio}?text=${encodeURIComponent(mensaje)}`;

  return { url, mensaje, numero: numeroLimpio };
}

// ============================================
// PAYPAL
// ============================================

function isPaypalConfigured() {
  return !!(process.env.PAYPAL_CLIENT_ID && process.env.PAYPAL_CLIENT_SECRET);
}

async function createPaypalOrder(botId, sessionId) {
  if (!isPaypalConfigured()) {
    throw new Error('PayPal no está configurado todavía.');
  }

  const cart = await getCartBySession(botId, sessionId);
  if (!cart || !cart.items || cart.items.length === 0) {
    throw new Error('El carrito está vacío');
  }

  // Aquí se integraría con PayPal SDK
  // Por ahora devolvemos estructura preparada
  return {
    message: 'PayPal listo para integrar',
    cart_id: cart.id,
    total: cart.total,
    items: cart.items,
  };
}

async function capturePaypalOrder(botId, paypalOrderId) {
  if (!isPaypalConfigured()) {
    throw new Error('PayPal no está configurado todavía.');
  }

  // Aquí se integraría la captura de PayPal
  return {
    message: 'Captura de PayPal lista para integrar',
    paypal_order_id: paypalOrderId,
  };
}

// ============================================
// DELIVERY ZONES
// ============================================

async function getDeliveryZones(botId, soloDisponibles = true) {
  const whereDisponible = soloDisponibles ? 'AND disponible = true' : '';
  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_delivery_zones WHERE bot_id = $1 ${whereDisponible} ORDER BY nombre_zona ASC`,
    botId
  );
  return serializeRows(rows);
}

async function createDeliveryZone(botId, data) {
  const fields = [
    'bot_id', 'nombre_zona', 'ciudad', 'sector',
    'costo_delivery', 'disponible', 'tiempo_estimado',
  ];
  const values = [
    botId,
    data.nombre_zona,
    data.ciudad || null,
    data.sector || null,
    data.costo_delivery || 0,
    data.disponible !== undefined ? data.disponible : true,
    data.tiempo_estimado || null,
  ];
  const placeholders = values.map((_, i) => `$${i + 1}`).join(', ');

  await prisma.$executeRawUnsafe(
    `INSERT INTO storefront_delivery_zones (${fields.join(', ')}) VALUES (${placeholders})`,
    ...values
  );

  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_delivery_zones WHERE bot_id = $1 ORDER BY creado_en DESC LIMIT 1`,
    botId
  );
  return rows[0] ? serializeRow(rows[0]) : null;
}

async function updateDeliveryZone(id, data) {
  const assignments = [];
  const values = [];
  const allowedFields = [
    'nombre_zona', 'ciudad', 'sector', 'costo_delivery',
    'disponible', 'tiempo_estimado',
  ];

  for (const field of allowedFields) {
    if (data[field] !== undefined) {
      values.push(data[field]);
      assignments.push(`${field} = $${values.length}`);
    }
  }

  if (assignments.length === 0) return getDeliveryZoneById(id);

  values.push(id);
  assignments.push(`actualizado_en = NOW()`);

  await prisma.$executeRawUnsafe(
    `UPDATE storefront_delivery_zones SET ${assignments.join(', ')} WHERE id = $${values.length}`,
    ...values
  );

  return getDeliveryZoneById(id);
}

async function deleteDeliveryZone(id) {
  const existente = await getDeliveryZoneById(id);
  if (!existente) return null;
  await prisma.$executeRawUnsafe(`DELETE FROM storefront_delivery_zones WHERE id = $1`, id);
  return existente;
}

async function getDeliveryZoneById(id) {
  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_delivery_zones WHERE id = $1 LIMIT 1`,
    id
  );
  return rows[0] ? serializeRow(rows[0]) : null;
}

// ============================================
// PAYMENTS (admin)
// ============================================

async function getPayments(botId) {
  const rows = await prisma.$queryRawUnsafe(
    `SELECT * FROM storefront_payments WHERE bot_id = $1 ORDER BY creado_en DESC`,
    botId
  );
  return serializeRows(rows);
}

async function getCarts(botId, estado = null) {
  let sql = `SELECT * FROM storefront_carts WHERE bot_id = $1`;
  const params = [botId];

  if (estado) {
    params.push(estado);
    sql += ` AND estado = $2`;
  }

  sql += ` ORDER BY actualizado_en DESC`;

  const rows = await prisma.$queryRawUnsafe(sql, ...params);
  const carts = serializeRows(rows);

  // Cargar items para cada carrito
  for (const cart of carts) {
    const items = await prisma.$queryRawUnsafe(
      `SELECT * FROM storefront_cart_items WHERE cart_id = $1 ORDER BY creado_en ASC`,
      cart.id
    );
    cart.items = serializeRows(items);
  }

  return carts;
}

// ============================================
// EXPORTS
// ============================================

module.exports = {
  // Config
  getConfigBySlug,
  getConfigByBotId,
  upsertConfig,

  // Banners
  getBanners,
  createBanner,
  updateBanner,
  deleteBanner,
  getBannerById,

  // Product Settings
  getProductSettings,
  upsertProductSetting,

  // Productos públicos
  getStorefrontProducts,
  getStorefrontProductById,
  getStorefrontCategories,

  // Carrito
  getOrCreateCart,
  getCartWithItems,
  getCartBySession,
  addItemToCart,
  updateCartItem,
  deleteCartItem,

  // Checkout
  checkout,

  // WhatsApp
  generateWhatsAppLink,

  // PayPal
  isPaypalConfigured,
  createPaypalOrder,
  capturePaypalOrder,

  // Delivery Zones
  getDeliveryZones,
  createDeliveryZone,
  updateDeliveryZone,
  deleteDeliveryZone,
  getDeliveryZoneById,

  // Admin
  getPayments,
  getCarts,
};
