require('dotenv/config');
const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');

const adapter = new PrismaPg(process.env.DATABASE_URL);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('🌱 Sembrando datos storefront...');

  // Obtener el bot
  const bot = await prisma.bot.findUnique({ where: { slug: 'fulltech-seguridad' } });
  if (!bot) {
    console.error('❌ Bot no encontrado');
    return;
  }
  console.log(`✅ Bot: ${bot.nombre} (${bot.id})`);

  // 1. Crear/actualizar config storefront
  const configExists = await prisma.$queryRawUnsafe(
    `SELECT id FROM storefront_config WHERE bot_id = $1 LIMIT 1`,
    bot.id
  );

  if (configExists.length === 0) {
    await prisma.$queryRawUnsafe(
      `INSERT INTO storefront_config (bot_id, slug, nombre_tienda, descripcion, color_principal, color_secundario, whatsapp_numero, mensaje_principal, mensaje_secundario, activo)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, true)`,
      bot.id,
      'fulltech-seguridad',
      'FULLTECH',
      'Soluciones en seguridad y tecnología',
      '#0F172A',
      '#2563EB',
      '18295551234',
      'Protege tu hogar y negocio con FULLTECH',
      'Cámaras, alarmas y sistemas de seguridad profesional'
    );
    console.log('✅ Config storefront creada');
  } else {
    console.log('ℹ️  Config storefront ya existe');
  }

  // 2. Obtener productos del catálogo
  const productos = await prisma.catalogo.findMany({
    where: { botId: bot.id, estado: 'activo' },
  });
  console.log(`✅ ${productos.length} productos encontrados`);

  // 3. Crear product settings para cada producto
  for (const prod of productos) {
    const exists = await prisma.$queryRawUnsafe(
      `SELECT id FROM storefront_product_settings WHERE bot_id = $1 AND producto_id = $2 LIMIT 1`,
      bot.id, prod.id
    );

    if (exists.length === 0) {
      await prisma.$queryRawUnsafe(
        `INSERT INTO storefront_product_settings (bot_id, producto_id, visible_en_tienda, destacado, orden, activo, permitir_compra_online, permitir_whatsapp)
         VALUES ($1, $2, true, $3, $4, true, true, true)`,
        bot.id,
        prod.id,
        prod.titulo === 'Kit Cámaras 4CH Full HD' ? true : false,
        prod.orden || 0
      );
      console.log(`✅ Product setting creado: ${prod.titulo}`);
    } else {
      console.log(`ℹ️  Product setting ya existe: ${prod.titulo}`);
    }
  }

  // 4. Crear banners de ejemplo
  const bannersExist = await prisma.$queryRawUnsafe(
    `SELECT id FROM storefront_banners WHERE bot_id = $1 LIMIT 1`,
    bot.id
  );

  if (bannersExist.length === 0) {
    await prisma.$queryRawUnsafe(
      `INSERT INTO storefront_banners (bot_id, titulo, subtitulo, boton_texto, link_url, orden, activo)
       VALUES ($1, $2, $3, $4, $5, 1, true)`,
      bot.id,
      'Protege tu hogar con FULLTECH',
      'Cámaras de seguridad profesionales con instalación incluida en Higüey',
      'Ver productos',
      '/productos'
    );
    console.log('✅ Banner creado');
  }

  console.log('🌱 Seed storefront completado.');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
