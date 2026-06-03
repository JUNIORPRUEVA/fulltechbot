require('dotenv').config();

const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');

const adapter = new PrismaPg(process.env.DATABASE_URL);
const prisma = new PrismaClient({ adapter });

const PRIMARY_BOT_SLUG = (process.env.PRIMARY_BOT_SLUG || 'fulltech').trim().toLowerCase();
const PRIMARY_BOT_NAME = (process.env.PRIMARY_BOT_NAME || 'FULLTECH SRL').trim();
const BOT_ALIASES = Array.from(
  new Set(['fulltech', 'fulltech-srl', 'fulltech-seguridad', PRIMARY_BOT_SLUG])
);

async function ensurePrimaryBot() {
  let bot = await prisma.bot.findFirst({
    where: {
      slug: {
        in: BOT_ALIASES,
      },
    },
    orderBy: { actualizadoEn: 'desc' },
  });

  if (!bot) {
    bot = await prisma.bot.findFirst({
      orderBy: { actualizadoEn: 'desc' },
    });
  }

  if (!bot) {
    bot = await prisma.bot.create({
      data: {
        nombre: PRIMARY_BOT_NAME,
        slug: PRIMARY_BOT_SLUG,
        descripcion: 'Bot principal unificado de FULLTECH SRL',
        tipoNegocio: 'fulltech',
        estado: 'activo',
      },
    });
    return bot;
  }

  return prisma.bot.update({
    where: { id: bot.id },
    data: {
      nombre: PRIMARY_BOT_NAME,
      slug: PRIMARY_BOT_SLUG,
      estado: 'activo',
    },
  });
}

async function run() {
  const primaryBot = await ensurePrimaryBot();
  const primaryBotId = primaryBot.id;

  const otherBots = await prisma.bot.findMany({
    where: {
      id: { not: primaryBotId },
    },
  });
  const otherBotIds = otherBots.map((bot) => bot.id);

  console.log('PRIMARY_BOT:', primaryBotId, primaryBot.slug, primaryBot.nombre);
  console.log('OTHER_BOTS:', otherBotIds.length);

  await prisma.$executeRawUnsafe(
    'UPDATE catalogo SET bot_id = $1 WHERE bot_id IS NULL OR bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE bot_clients SET bot_id = $1 WHERE bot_id IS NULL OR bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE bot_conversations SET bot_id = $1 WHERE bot_id IS NULL OR bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE bot_quotations SET bot_id = $1 WHERE bot_id IS NULL OR bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE bot_orders SET bot_id = $1 WHERE bot_id IS NULL OR bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE storefront_config SET bot_id = $1 WHERE bot_id IS NULL OR bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(`
    DELETE FROM storefront_config a
    USING storefront_config b
    WHERE a.id < b.id
      AND a.bot_id = b.bot_id
  `);

  await prisma.$executeRawUnsafe(
    'UPDATE storefront_config SET slug = $1, nombre_tienda = COALESCE(nombre_tienda, $2) WHERE bot_id = $3',
    PRIMARY_BOT_SLUG,
    PRIMARY_BOT_NAME,
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE storefront_banners SET bot_id = $1 WHERE bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    `DELETE FROM storefront_product_settings a
     USING storefront_product_settings b
     WHERE a.id < b.id
       AND a.producto_id = b.producto_id
       AND (a.bot_id = ANY($1::text[]) OR a.bot_id = $2)
       AND (b.bot_id = ANY($1::text[]) OR b.bot_id = $2)`,
    otherBotIds,
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE storefront_product_settings SET bot_id = $1 WHERE bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    `DELETE FROM storefront_carts a
     USING storefront_carts b
     WHERE a.id < b.id
       AND a.session_id = b.session_id
       AND a.estado = b.estado
       AND (a.bot_id = ANY($1::text[]) OR a.bot_id = $2)
       AND (b.bot_id = ANY($1::text[]) OR b.bot_id = $2)`,
    otherBotIds,
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE storefront_carts SET bot_id = $1 WHERE bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE storefront_payments SET bot_id = $1 WHERE bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE storefront_delivery_zones SET bot_id = $1 WHERE bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    `DELETE FROM bot_campaigns a
     USING bot_campaigns b
     WHERE a.id::text < b.id::text
       AND a.campaign_code = b.campaign_code
       AND (a.bot_id = ANY($1::text[]) OR a.bot_id = $2)
       AND (b.bot_id = ANY($1::text[]) OR b.bot_id = $2)`,
    otherBotIds,
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE bot_campaigns SET bot_id = $1 WHERE bot_id <> $1',
    primaryBotId
  );

  await prisma.$executeRawUnsafe(
    'UPDATE conversation_campaign_context SET bot_id = $1 WHERE bot_id <> $1',
    primaryBotId
  );

  if (otherBotIds.length > 0) {
    await prisma.$executeRawUnsafe(
      'DELETE FROM bots WHERE id = ANY($1::text[])',
      otherBotIds
    );
  }

  console.log('Single-bot consolidation completed successfully.');
}

run()
  .catch((error) => {
    console.error('CONSOLIDATION_ERROR:', error.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
