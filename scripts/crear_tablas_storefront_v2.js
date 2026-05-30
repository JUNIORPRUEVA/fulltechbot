require('dotenv/config');
const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');

const adapter = new PrismaPg(process.env.DATABASE_URL);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('📦 Creando tablas storefront (v2)...');

  // Crear cada tabla individualmente con CREATE TABLE IF NOT EXISTS
  const statements = [
    // 1. Configuración de la tienda
    `CREATE TABLE IF NOT EXISTS storefront_config (
      id BIGSERIAL PRIMARY KEY,
      bot_id TEXT NOT NULL,
      slug TEXT NOT NULL UNIQUE,
      nombre_tienda TEXT NOT NULL,
      descripcion TEXT,
      logo_url TEXT,
      color_principal TEXT DEFAULT '#0F172A',
      color_secundario TEXT DEFAULT '#2563EB',
      whatsapp_numero TEXT,
      telefono_contacto TEXT,
      direccion TEXT,
      horario TEXT,
      mensaje_principal TEXT,
      mensaje_secundario TEXT,
      activo BOOLEAN DEFAULT true,
      permitir_paypal BOOLEAN DEFAULT false,
      permitir_whatsapp BOOLEAN DEFAULT true,
      permitir_retiro_tienda BOOLEAN DEFAULT true,
      permitir_delivery BOOLEAN DEFAULT false,
      creado_en TIMESTAMPTZ DEFAULT NOW(),
      actualizado_en TIMESTAMPTZ DEFAULT NOW()
    )`,
    
    // 2. Banners
    `CREATE TABLE IF NOT EXISTS storefront_banners (
      id BIGSERIAL PRIMARY KEY,
      bot_id TEXT NOT NULL,
      titulo TEXT NOT NULL,
      subtitulo TEXT,
      imagen_url TEXT,
      link_url TEXT,
      boton_texto TEXT,
      orden INTEGER DEFAULT 0,
      activo BOOLEAN DEFAULT true,
      fecha_inicio TIMESTAMPTZ,
      fecha_fin TIMESTAMPTZ,
      creado_en TIMESTAMPTZ DEFAULT NOW(),
      actualizado_en TIMESTAMPTZ DEFAULT NOW()
    )`,
    
    // 3. Product settings
    `CREATE TABLE IF NOT EXISTS storefront_product_settings (
      id BIGSERIAL PRIMARY KEY,
      bot_id TEXT NOT NULL,
      producto_id TEXT NOT NULL,
      visible_en_tienda BOOLEAN DEFAULT false,
      destacado BOOLEAN DEFAULT false,
      orden INTEGER DEFAULT 0,
      etiqueta TEXT,
      precio_oferta_web NUMERIC(12,2),
      descripcion_web TEXT,
      imagen_destacada_url TEXT,
      permitir_compra_online BOOLEAN DEFAULT true,
      permitir_whatsapp BOOLEAN DEFAULT true,
      requiere_instalacion BOOLEAN DEFAULT false,
      activo BOOLEAN DEFAULT true,
      creado_en TIMESTAMPTZ DEFAULT NOW(),
      actualizado_en TIMESTAMPTZ DEFAULT NOW(),
      UNIQUE (bot_id, producto_id)
    )`,
    
    // 4. Carts
    `CREATE TABLE IF NOT EXISTS storefront_carts (
      id BIGSERIAL PRIMARY KEY,
      bot_id TEXT NOT NULL,
      session_id TEXT NOT NULL,
      telefono_cliente TEXT,
      nombre_cliente TEXT,
      estado TEXT DEFAULT 'activo',
      subtotal NUMERIC(12,2) DEFAULT 0,
      total NUMERIC(12,2) DEFAULT 0,
      creado_en TIMESTAMPTZ DEFAULT NOW(),
      actualizado_en TIMESTAMPTZ DEFAULT NOW(),
      UNIQUE (bot_id, session_id)
    )`,
    
    // 5. Cart items
    `CREATE TABLE IF NOT EXISTS storefront_cart_items (
      id BIGSERIAL PRIMARY KEY,
      cart_id BIGINT NOT NULL REFERENCES storefront_carts(id) ON DELETE CASCADE,
      producto_id TEXT NOT NULL,
      nombre_producto TEXT NOT NULL,
      cantidad INTEGER DEFAULT 1,
      precio_unitario NUMERIC(12,2) NOT NULL,
      subtotal NUMERIC(12,2) NOT NULL,
      imagen_url TEXT,
      metadata JSONB,
      creado_en TIMESTAMPTZ DEFAULT NOW(),
      actualizado_en TIMESTAMPTZ DEFAULT NOW()
    )`,
    
    // 6. Payments
    `CREATE TABLE IF NOT EXISTS storefront_payments (
      id BIGSERIAL PRIMARY KEY,
      bot_id TEXT NOT NULL,
      pedido_id TEXT,
      cart_id BIGINT,
      metodo_pago TEXT DEFAULT 'paypal',
      paypal_order_id TEXT,
      paypal_capture_id TEXT,
      estado TEXT DEFAULT 'creado',
      moneda TEXT DEFAULT 'USD',
      monto NUMERIC(12,2) NOT NULL,
      raw_response JSONB,
      creado_en TIMESTAMPTZ DEFAULT NOW(),
      actualizado_en TIMESTAMPTZ DEFAULT NOW()
    )`,
    
    // 7. Delivery zones
    `CREATE TABLE IF NOT EXISTS storefront_delivery_zones (
      id BIGSERIAL PRIMARY KEY,
      bot_id TEXT NOT NULL,
      nombre_zona TEXT NOT NULL,
      ciudad TEXT,
      sector TEXT,
      costo_delivery NUMERIC(12,2) DEFAULT 0,
      disponible BOOLEAN DEFAULT true,
      tiempo_estimado TEXT,
      creado_en TIMESTAMPTZ DEFAULT NOW(),
      actualizado_en TIMESTAMPTZ DEFAULT NOW()
    )`,
  ];

  for (const stmt of statements) {
    try {
      await prisma.$queryRawUnsafe(stmt);
      console.log(`✅ Tabla creada: ${stmt.match(/CREATE TABLE IF NOT EXISTS (\w+)/)?.[1] || 'desconocida'}`);
    } catch (err) {
      if (err.message?.includes('ya existe')) {
        console.log(`ℹ️  Ya existe (omitido)`);
      } else {
        console.error(`❌ Error: ${err.message?.substring(0, 150)}`);
      }
    }
  }

  // Crear índices
  const indices = [
    `CREATE INDEX IF NOT EXISTS idx_storefront_config_bot_id ON storefront_config(bot_id)`,
    `CREATE INDEX IF NOT EXISTS idx_storefront_banners_bot_id ON storefront_banners(bot_id)`,
    `CREATE INDEX IF NOT EXISTS idx_storefront_product_settings_bot_id ON storefront_product_settings(bot_id)`,
    `CREATE INDEX IF NOT EXISTS idx_storefront_product_settings_producto_id ON storefront_product_settings(producto_id)`,
    `CREATE INDEX IF NOT EXISTS idx_storefront_carts_bot_id ON storefront_carts(bot_id)`,
    `CREATE INDEX IF NOT EXISTS idx_storefront_cart_items_cart_id ON storefront_cart_items(cart_id)`,
    `CREATE INDEX IF NOT EXISTS idx_storefront_payments_bot_id ON storefront_payments(bot_id)`,
    `CREATE INDEX IF NOT EXISTS idx_storefront_delivery_zones_bot_id ON storefront_delivery_zones(bot_id)`,
  ];

  for (const idx of indices) {
    try {
      await prisma.$queryRawUnsafe(idx);
      console.log(`✅ Índice creado`);
    } catch (err) {
      console.error(`❌ Error índice: ${err.message?.substring(0, 100)}`);
    }
  }

  console.log('✅ Tablas storefront creadas/verificadas.');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
