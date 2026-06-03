-- FULLTECH SRL
-- Corrige URLs heredadas del backend viejo en catalogo/storefront.
--
-- Uso recomendado:
-- 1. Haz backup de la base.
-- 2. Ejecuta primero los SELECT de verificacion.
-- 3. Ejecuta el bloque BEGIN ... COMMIT.
-- 4. Vuelve a correr los SELECT finales para confirmar.

-- ============================================
-- PARAMETROS
-- ============================================
-- Backend viejo:
--   https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host
--
-- Backend nuevo:
--   https://ai-business-platform-fulltechbot-backend.onqyr1.easypanel.host

-- ============================================
-- PREVIEW: CUANTAS URLS VIEJAS HAY
-- ============================================
SELECT 'catalogo.imagen1' AS campo, COUNT(*) AS total
FROM catalogo
WHERE imagen1 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
UNION ALL
SELECT 'catalogo.imagen2', COUNT(*)
FROM catalogo
WHERE imagen2 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
UNION ALL
SELECT 'catalogo.imagen3', COUNT(*)
FROM catalogo
WHERE imagen3 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
UNION ALL
SELECT 'catalogo.video', COUNT(*)
FROM catalogo
WHERE video LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
UNION ALL
SELECT 'storefront_product_settings.imagen_destacada_url', COUNT(*)
FROM storefront_product_settings
WHERE imagen_destacada_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
UNION ALL
SELECT 'storefront_banners.imagen_url', COUNT(*)
FROM storefront_banners
WHERE imagen_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
UNION ALL
SELECT 'storefront_config.logo_url', COUNT(*)
FROM storefront_config
WHERE logo_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
UNION ALL
SELECT 'storefront_cart_items.imagen_url', COUNT(*)
FROM storefront_cart_items
WHERE imagen_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%';

-- ============================================
-- MUESTRAS RAPIDAS
-- ============================================
SELECT id, titulo, imagen1, imagen2, imagen3, video
FROM catalogo
WHERE imagen1 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
   OR imagen2 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
   OR imagen3 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
   OR video   LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
LIMIT 20;

SELECT id, imagen_url
FROM storefront_banners
WHERE imagen_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
LIMIT 20;

-- ============================================
-- FIX AUTOMATICO
-- ============================================
BEGIN;

-- Catalogo: imagenes y videos que ya usan /api/storage/file/...
UPDATE catalogo
SET imagen1 = REPLACE(
  imagen1,
  'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host',
  'https://ai-business-platform-fulltechbot-backend.onqyr1.easypanel.host'
)
WHERE imagen1 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%';

UPDATE catalogo
SET imagen2 = REPLACE(
  imagen2,
  'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host',
  'https://ai-business-platform-fulltechbot-backend.onqyr1.easypanel.host'
)
WHERE imagen2 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%';

UPDATE catalogo
SET imagen3 = REPLACE(
  imagen3,
  'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host',
  'https://ai-business-platform-fulltechbot-backend.onqyr1.easypanel.host'
)
WHERE imagen3 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%';

UPDATE catalogo
SET video = REPLACE(
  video,
  'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host',
  'https://ai-business-platform-fulltechbot-backend.onqyr1.easypanel.host'
)
WHERE video LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%';

-- Storefront product settings
UPDATE storefront_product_settings
SET imagen_destacada_url = REPLACE(
  imagen_destacada_url,
  'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host',
  'https://ai-business-platform-fulltechbot-backend.onqyr1.easypanel.host'
)
WHERE imagen_destacada_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%';

-- Storefront config logo
UPDATE storefront_config
SET logo_url = REPLACE(
  logo_url,
  'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host',
  'https://ai-business-platform-fulltechbot-backend.onqyr1.easypanel.host'
)
WHERE logo_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%';

-- Carrito: imagen que ya se guardo en pedidos/carritos
UPDATE storefront_cart_items
SET imagen_url = REPLACE(
  imagen_url,
  'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host',
  'https://ai-business-platform-fulltechbot-backend.onqyr1.easypanel.host'
)
WHERE imagen_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%';

-- Banners:
-- Muchos banners viejos quedaron como /storefront/banners/... en vez de /api/storage/file/...
-- Los convertimos al formato que si entiende el backend nuevo.
UPDATE storefront_banners
SET imagen_url = REPLACE(
  imagen_url,
  'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/storefront/banners/',
  'https://ai-business-platform-fulltechbot-backend.onqyr1.easypanel.host/api/storage/file/storefront/banners/'
)
WHERE imagen_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/storefront/banners/%';

-- Si algun banner ya estaba en /api/storage/file/... solo cambia el host.
UPDATE storefront_banners
SET imagen_url = REPLACE(
  imagen_url,
  'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host',
  'https://ai-business-platform-fulltechbot-backend.onqyr1.easypanel.host'
)
WHERE imagen_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%';

COMMIT;

-- ============================================
-- VERIFICACION FINAL
-- ============================================
SELECT 'catalogo_restante' AS chequeo, COUNT(*) AS total
FROM catalogo
WHERE imagen1 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
   OR imagen2 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
   OR imagen3 LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
   OR video   LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
UNION ALL
SELECT 'storefront_product_settings_restante', COUNT(*)
FROM storefront_product_settings
WHERE imagen_destacada_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
UNION ALL
SELECT 'storefront_banners_restante', COUNT(*)
FROM storefront_banners
WHERE imagen_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
UNION ALL
SELECT 'storefront_config_restante', COUNT(*)
FROM storefront_config
WHERE logo_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%'
UNION ALL
SELECT 'storefront_cart_items_restante', COUNT(*)
FROM storefront_cart_items
WHERE imagen_url LIKE 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host/%';
