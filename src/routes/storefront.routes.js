/**
 * STOREFRONT ROUTES
 * 
 * Rutas públicas (por slug) y admin (por botId) para la tienda online/PWA.
 */

const express = require('express');
const router = express.Router();
const controller = require('../controllers/storefront.controller');

// ============================================
// RUTAS PÚBLICAS (por slug)
// ============================================

// Configuración de la tienda
router.get('/public/default', controller.getDefaultStore);
router.get('/:slug/config', controller.getConfig);

// Banners activos
router.get('/:slug/banners', controller.getBanners);

// Productos con paginación y filtros
router.get('/:slug/products', controller.getProducts);

// Producto individual
router.get('/:slug/products/:id', controller.getProductById);

// Categorías
router.get('/:slug/categories', controller.getCategories);

// ============================================
// CARRITO (público)
// ============================================

// Crear/obtener carrito
router.post('/:slug/cart', controller.createCart);

// Obtener carrito por sessionId
router.get('/:slug/cart/:sessionId', controller.getCart);

// Agregar item al carrito
router.post('/:slug/cart/:sessionId/items', controller.addCartItem);

// Actualizar item del carrito
router.put('/:slug/cart/:sessionId/items/:itemId', controller.updateCartItem);

// Eliminar item del carrito
router.delete('/:slug/cart/:sessionId/items/:itemId', controller.deleteCartItem);

// ============================================
// CHECKOUT
// ============================================

// Procesar checkout (crea pedido en bot_orders y cliente en bot_clients)
router.post('/:slug/checkout', controller.checkout);

// Generar link de WhatsApp con resumen del pedido
router.post('/:slug/whatsapp-order', controller.whatsappOrder);

// ============================================
// PAYPAL
// ============================================

// Crear orden PayPal
router.post('/:slug/paypal/create-order', controller.createPaypalOrder);

// Capturar orden PayPal
router.post('/:slug/paypal/capture-order', controller.capturePaypalOrder);

// ============================================
// RUTAS ADMIN (por botId)
// ============================================

// Configuración
router.get('/admin/:botId/config', controller.getAdminConfig);
router.put('/admin/:botId/config', controller.updateAdminConfig);

// Banners
router.get('/admin/:botId/banners', controller.getAdminBanners);
router.post('/admin/:botId/banners', controller.createAdminBanner);
router.put('/admin/:botId/banners/:id', controller.updateAdminBanner);
router.delete('/admin/:botId/banners/:id', controller.deleteAdminBanner);

// Product Settings
router.get('/admin/:botId/product-settings', controller.getAdminProductSettings);
router.put('/admin/:botId/product-settings/:productoId', controller.updateAdminProductSetting);

// Carritos
router.get('/admin/:botId/carts', controller.getAdminCarts);

// Pagos
router.get('/admin/:botId/payments', controller.getAdminPayments);

// Zonas de delivery
router.get('/admin/:botId/delivery-zones', controller.getAdminDeliveryZones);
router.post('/admin/:botId/delivery-zones', controller.createAdminDeliveryZone);
router.put('/admin/:botId/delivery-zones/:id', controller.updateAdminDeliveryZone);
router.delete('/admin/:botId/delivery-zones/:id', controller.deleteAdminDeliveryZone);

module.exports = router;
