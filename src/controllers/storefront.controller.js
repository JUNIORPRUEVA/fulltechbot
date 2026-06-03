/**
 * STOREFRONT CONTROLLER
 * 
 * Controlador para la tienda online/PWA.
 * Separa rutas públicas (slug) de rutas admin (botId).
 */

const storefrontService = require('../services/storefront.service');
const { resolveScopedBotId } = require('../services/botScope.service');
const storageService = require('../services/storage.service');

async function getDefaultStore(req, res) {
  try {
    const preferredSlug = req.query?.slug?.toString().trim() || null;
    const result = await storefrontService.getDefaultPublicStore(preferredSlug);

    if (!result.store) {
      return res.status(404).json({
        ok: false,
        message: 'No hay una tienda publica activa disponible',
        diagnostics: result.diagnostics,
      });
    }

    res.json({
      ok: true,
      data: result.store,
      diagnostics: result.diagnostics,
    });
  } catch (error) {
    handleError(res, error, 'Error al resolver tienda publica por defecto');
  }
}

// ============================================
// HELPERS
// ============================================

function handleError(res, error, defaultMessage = 'Error del servidor') {
  console.error(`[STOREFRONT] ${defaultMessage}:`, error.message);
  const statusCode = error.message.includes('vacío') || error.message.includes('configurado') ? 400 : 500;
  res.status(statusCode).json({
    ok: false,
    message: error.message || defaultMessage,
  });
}

// ============================================
// RUTAS PÚBLICAS (por slug)
// ============================================

// ============================================
// CACHE HEADERS HELPERS
// ============================================

/** Para respuestas JSON dinámicas: no cachear nunca */
function setNoCacheHeaders(res) {
  res.set({
    'Cache-Control': 'no-cache, no-store, must-revalidate, private',
    'Pragma': 'no-cache',
    'Expires': '0',
    'Surrogate-Control': 'no-store',
  });
}

/** Para imágenes: cache largo pero con versionado por URL */
function setImageCacheHeaders(res) {
  res.set({
    'Cache-Control': 'public, max-age=31536000, immutable',
    'Expires': new Date(Date.now() + 31536000000).toUTCString(),
  });
}

function construirBaseUrl(req) {
  const forwardedProto = req.headers['x-forwarded-proto'];
  const protocol = forwardedProto || req.protocol || 'https';
  return `${protocol}://${req.get('host')}`;
}

function normalizarMediaUrl(req, value) {
  if (!value || typeof value !== 'string') {
    return value;
  }

  const trimmedValue = value.trim();
  if (!trimmedValue) {
    return null;
  }

  if (/^https?:\/\//i.test(trimmedValue) || /^data:/i.test(trimmedValue)) {
    return trimmedValue;
  }

  const key = storageService.normalizarKeyArchivo(trimmedValue);
  return key ? `${construirBaseUrl(req)}/api/storage/file/${key}` : trimmedValue;
}

function normalizarProducto(req, product) {
  if (!product) {
    return product;
  }

  const gallery = Array.isArray(product.gallery)
    ? product.gallery.map((item) => normalizarMediaUrl(req, item)).filter(Boolean)
    : [];
  const relatedProducts = Array.isArray(product.relatedProducts)
    ? product.relatedProducts.map((item) => normalizarProducto(req, item))
    : undefined;

  return {
    ...product,
    imagen1: normalizarMediaUrl(req, product.imagen1),
    imagen2: normalizarMediaUrl(req, product.imagen2),
    imagen3: normalizarMediaUrl(req, product.imagen3),
    video: normalizarMediaUrl(req, product.video),
    imagen_destacada_url: normalizarMediaUrl(req, product.imagen_destacada_url),
    gallery,
    relatedProducts,
  };
}

function normalizarBanner(req, banner) {
  if (!banner) {
    return banner;
  }

  return {
    ...banner,
    imagen_url: normalizarMediaUrl(req, banner.imagen_url),
  };
}

function normalizarCategoria(req, category) {
  if (!category) {
    return category;
  }

  return {
    ...category,
    imagen: normalizarMediaUrl(req, category.imagen),
  };
}

async function getAdminBotId(req) {
  return resolveScopedBotId(req.params.botId, { createIfMissing: true });
}

async function getConfig(req, res) {
  try {
    const { slug } = req.params;
    setNoCacheHeaders(res);
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({
        ok: false,
        message: 'Tienda no encontrada o inactiva',
      });
    }

    res.json({ ok: true, data: config });
  } catch (error) {
    handleError(res, error, 'Error al obtener configuración');
  }
}

async function getBanners(req, res) {
  try {
    const { slug } = req.params;
    setNoCacheHeaders(res);
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const banners = await storefrontService.getBanners(config.bot_id);
    res.json({ ok: true, data: banners.map((banner) => normalizarBanner(req, banner)) });
  } catch (error) {
    handleError(res, error, 'Error al obtener banners');
  }
}

async function getProducts(req, res) {
  try {
    const { slug } = req.params;
    setNoCacheHeaders(res);
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const { categoria, destacado, search, busqueda, page, limit, sort } = req.query;
    const result = await storefrontService.getStorefrontProducts(config.bot_id, {
      categoria,
      destacado: destacado === 'true',
      search,
      busqueda,
      sort,
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
    });

    res.json({
      ok: true,
      ...result,
      items: Array.isArray(result.items)
        ? result.items.map((item) => normalizarProducto(req, item))
        : [],
    });
  } catch (error) {
    handleError(res, error, 'Error al obtener productos');
  }
}

async function getProductById(req, res) {
  try {
    const { slug, id } = req.params;
    setNoCacheHeaders(res);
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const product = await storefrontService.getStorefrontProductById(config.bot_id, id);

    if (!product) {
      return res.status(404).json({ ok: false, message: 'Producto no encontrado' });
    }

    res.json({ ok: true, data: normalizarProducto(req, product) });
  } catch (error) {
    handleError(res, error, 'Error al obtener producto');
  }
}

async function getCategories(req, res) {
  try {
    const { slug } = req.params;
    setNoCacheHeaders(res);
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const categories = await storefrontService.getStorefrontCategories(config.bot_id);
    res.json({ ok: true, data: categories.map((category) => normalizarCategoria(req, category)) });
  } catch (error) {
    handleError(res, error, 'Error al obtener categorías');
  }
}

// ============================================
// CARRITO (público)
// ============================================

async function createCart(req, res) {
  try {
    const { slug } = req.params;
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const { session_id } = req.body;
    if (!session_id) {
      return res.status(400).json({ ok: false, message: 'session_id es requerido' });
    }

    const cart = await storefrontService.getOrCreateCart(config.bot_id, session_id);
    res.status(201).json({ ok: true, data: cart });
  } catch (error) {
    handleError(res, error, 'Error al crear carrito');
  }
}

async function getCart(req, res) {
  try {
    const { slug, sessionId } = req.params;
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const cart = await storefrontService.getCartBySession(config.bot_id, sessionId);

    if (!cart) {
      return res.status(404).json({ ok: false, message: 'Carrito no encontrado' });
    }

    res.json({ ok: true, data: cart });
  } catch (error) {
    handleError(res, error, 'Error al obtener carrito');
  }
}

async function addCartItem(req, res) {
  try {
    const { slug, sessionId } = req.params;
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const cart = await storefrontService.getCartBySession(config.bot_id, sessionId);
    if (!cart) {
      return res.status(404).json({ ok: false, message: 'Carrito no encontrado' });
    }

    const { producto_id, nombre_producto, cantidad, precio_unitario, imagen_url, metadata } = req.body;
    if (!producto_id || !nombre_producto || !cantidad || !precio_unitario) {
      return res.status(400).json({
        ok: false,
        message: 'producto_id, nombre_producto, cantidad y precio_unitario son requeridos',
      });
    }

    const updatedCart = await storefrontService.addItemToCart(cart.id, {
      producto_id,
      nombre_producto,
      cantidad,
      precio_unitario,
      imagen_url,
      metadata,
    });

    res.json({ ok: true, data: updatedCart });
  } catch (error) {
    handleError(res, error, 'Error al agregar item al carrito');
  }
}

async function updateCartItem(req, res) {
  try {
    const { slug, itemId } = req.params;
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const { cantidad } = req.body;
    if (cantidad === undefined) {
      return res.status(400).json({ ok: false, message: 'cantidad es requerida' });
    }

    const cart = await storefrontService.updateCartItem(itemId, { cantidad });

    if (!cart) {
      return res.status(404).json({ ok: false, message: 'Item no encontrado' });
    }

    res.json({ ok: true, data: cart });
  } catch (error) {
    handleError(res, error, 'Error al actualizar item');
  }
}

async function deleteCartItem(req, res) {
  try {
    const { slug, itemId } = req.params;
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const cart = await storefrontService.deleteCartItem(itemId);

    if (!cart) {
      return res.status(404).json({ ok: false, message: 'Item no encontrado' });
    }

    res.json({ ok: true, data: cart });
  } catch (error) {
    handleError(res, error, 'Error al eliminar item');
  }
}

// ============================================
// CHECKOUT
// ============================================

async function checkout(req, res) {
  try {
    const { slug } = req.params;
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const sessionId = req.body?.session_id || req.query?.session_id;
    if (!sessionId) {
      return res.status(400).json({ ok: false, message: 'session_id es requerido' });
    }

    const result = await storefrontService.checkout(config.bot_id, sessionId, req.body);

    res.status(201).json({
      ok: true,
      message: 'Pedido creado exitosamente',
      data: result,
    });
  } catch (error) {
    handleError(res, error, 'Error al procesar checkout');
  }
}

// ============================================
// WHATSAPP ORDER
// ============================================

async function whatsappOrder(req, res) {
  try {
    const { slug } = req.params;
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const sessionId = req.body?.session_id || req.query?.session_id;
    if (!sessionId) {
      return res.status(400).json({ ok: false, message: 'session_id es requerido' });
    }

    const result = await storefrontService.generateWhatsAppLink(
      config.bot_id,
      sessionId,
      req.body
    );

    res.json({ ok: true, data: result });
  } catch (error) {
    handleError(res, error, 'Error al generar enlace de WhatsApp');
  }
}

// ============================================
// PAYPAL
// ============================================

async function createPaypalOrder(req, res) {
  try {
    const { slug } = req.params;
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const sessionId = req.body?.session_id || req.query?.session_id;
    if (!sessionId) {
      return res.status(400).json({ ok: false, message: 'session_id es requerido' });
    }

    const result = await storefrontService.createPaypalOrder(config.bot_id, sessionId);
    res.json({ ok: true, data: result });
  } catch (error) {
    handleError(res, error, 'Error al crear orden PayPal');
  }
}

async function capturePaypalOrder(req, res) {
  try {
    const { slug } = req.params;
    const config = await storefrontService.getConfigBySlug(slug);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Tienda no encontrada' });
    }

    const { paypal_order_id } = req.body;
    if (!paypal_order_id) {
      return res.status(400).json({ ok: false, message: 'paypal_order_id es requerido' });
    }

    const result = await storefrontService.capturePaypalOrder(config.bot_id, paypal_order_id);
    res.json({ ok: true, data: result });
  } catch (error) {
    handleError(res, error, 'Error al capturar orden PayPal');
  }
}

// ============================================
// RUTAS ADMIN (por botId)
// ============================================

async function getAdminConfig(req, res) {
  try {
    const botId = await getAdminBotId(req);
    const config = await storefrontService.getConfigByBotId(botId);

    if (!config) {
      return res.status(404).json({ ok: false, message: 'Configuración no encontrada' });
    }

    res.json({ ok: true, data: config });
  } catch (error) {
    handleError(res, error, 'Error al obtener configuración');
  }
}

async function updateAdminConfig(req, res) {
  try {
    const botId = await getAdminBotId(req);
    const config = await storefrontService.upsertConfig(botId, req.body);

    res.json({
      ok: true,
      message: 'Configuración guardada exitosamente',
      data: config,
    });
  } catch (error) {
    handleError(res, error, 'Error al guardar configuración');
  }
}

async function getAdminBanners(req, res) {
  try {
    const botId = await getAdminBotId(req);
    const banners = await storefrontService.getBanners(botId, false);
    res.json({ ok: true, data: banners });
  } catch (error) {
    handleError(res, error, 'Error al obtener banners');
  }
}

async function createAdminBanner(req, res) {
  try {
    const botId = await getAdminBotId(req);
    const banner = await storefrontService.createBanner(botId, req.body);
    res.status(201).json({ ok: true, data: banner });
  } catch (error) {
    handleError(res, error, 'Error al crear banner');
  }
}

async function updateAdminBanner(req, res) {
  try {
    const { id } = req.params;
    const banner = await storefrontService.updateBanner(parseInt(id), req.body);

    if (!banner) {
      return res.status(404).json({ ok: false, message: 'Banner no encontrado' });
    }

    res.json({ ok: true, data: banner });
  } catch (error) {
    handleError(res, error, 'Error al actualizar banner');
  }
}

async function deleteAdminBanner(req, res) {
  try {
    const { id } = req.params;
    const banner = await storefrontService.deleteBanner(parseInt(id));

    if (!banner) {
      return res.status(404).json({ ok: false, message: 'Banner no encontrado' });
    }

    res.json({ ok: true, message: 'Banner eliminado exitosamente' });
  } catch (error) {
    handleError(res, error, 'Error al eliminar banner');
  }
}

async function getAdminProductSettings(req, res) {
  try {
    const botId = await getAdminBotId(req);
    const settings = await storefrontService.getProductSettings(botId);
    res.json({ ok: true, data: settings });
  } catch (error) {
    handleError(res, error, 'Error al obtener configuraciones de productos');
  }
}

async function updateAdminProductSetting(req, res) {
  try {
    const botId = await getAdminBotId(req);
    const { productoId } = req.params;
    const setting = await storefrontService.upsertProductSetting(botId, productoId, req.body);
    res.json({ ok: true, data: setting });
  } catch (error) {
    handleError(res, error, 'Error al actualizar configuración de producto');
  }
}

async function getAdminCarts(req, res) {
  try {
    const botId = await getAdminBotId(req);
    const { estado } = req.query;
    const carts = await storefrontService.getCarts(botId, estado || null);
    res.json({ ok: true, data: carts });
  } catch (error) {
    handleError(res, error, 'Error al obtener carritos');
  }
}

async function getAdminPayments(req, res) {
  try {
    const botId = await getAdminBotId(req);
    const payments = await storefrontService.getPayments(botId);
    res.json({ ok: true, data: payments });
  } catch (error) {
    handleError(res, error, 'Error al obtener pagos');
  }
}

async function getAdminDeliveryZones(req, res) {
  try {
    const botId = await getAdminBotId(req);
    const zones = await storefrontService.getDeliveryZones(botId, false);
    res.json({ ok: true, data: zones });
  } catch (error) {
    handleError(res, error, 'Error al obtener zonas de delivery');
  }
}

async function createAdminDeliveryZone(req, res) {
  try {
    const botId = await getAdminBotId(req);
    const zone = await storefrontService.createDeliveryZone(botId, req.body);
    res.status(201).json({ ok: true, data: zone });
  } catch (error) {
    handleError(res, error, 'Error al crear zona de delivery');
  }
}

async function updateAdminDeliveryZone(req, res) {
  try {
    const { id } = req.params;
    const zone = await storefrontService.updateDeliveryZone(parseInt(id), req.body);

    if (!zone) {
      return res.status(404).json({ ok: false, message: 'Zona no encontrada' });
    }

    res.json({ ok: true, data: zone });
  } catch (error) {
    handleError(res, error, 'Error al actualizar zona de delivery');
  }
}

async function deleteAdminDeliveryZone(req, res) {
  try {
    const { id } = req.params;
    const zone = await storefrontService.deleteDeliveryZone(parseInt(id));

    if (!zone) {
      return res.status(404).json({ ok: false, message: 'Zona no encontrada' });
    }

    res.json({ ok: true, message: 'Zona de delivery eliminada exitosamente' });
  } catch (error) {
    handleError(res, error, 'Error al eliminar zona de delivery');
  }
}

// ============================================
// EXPORTS
// ============================================

module.exports = {
  // Públicas
  getDefaultStore,
  getConfig,
  getBanners,
  getProducts,
  getProductById,
  getCategories,

  // Carrito
  createCart,
  getCart,
  addCartItem,
  updateCartItem,
  deleteCartItem,

  // Checkout
  checkout,
  whatsappOrder,

  // PayPal
  createPaypalOrder,
  capturePaypalOrder,

  // Admin - Config
  getAdminConfig,
  updateAdminConfig,

  // Admin - Banners
  getAdminBanners,
  createAdminBanner,
  updateAdminBanner,
  deleteAdminBanner,

  // Admin - Product Settings
  getAdminProductSettings,
  updateAdminProductSetting,

  // Admin - Carts & Payments
  getAdminCarts,
  getAdminPayments,

  // Admin - Delivery Zones
  getAdminDeliveryZones,
  createAdminDeliveryZone,
  updateAdminDeliveryZone,
  deleteAdminDeliveryZone,
};
