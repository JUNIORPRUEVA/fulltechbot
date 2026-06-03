const prisma = require('../lib/prisma');

const SINGLE_BOT_MODE = process.env.SINGLE_BOT_MODE !== 'false';
const PRIMARY_BOT_SLUG = (process.env.PRIMARY_BOT_SLUG || 'fulltech').trim().toLowerCase();
const PRIMARY_BOT_NAME = (process.env.PRIMARY_BOT_NAME || 'FULLTECH SRL').trim();
const PRIMARY_BOT_ALIASES = Array.from(
  new Set(
    [
      PRIMARY_BOT_SLUG,
      'fulltech',
      'fulltech-srl',
      'fulltech-seguridad',
      process.env.DEFAULT_STOREFRONT_SLUG,
    ]
      .filter(Boolean)
      .map((value) => value.trim().toLowerCase())
  )
);

function isSingleBotMode() {
  return SINGLE_BOT_MODE;
}

function isPrimaryBotSlug(slug) {
  if (!slug) return false;
  return PRIMARY_BOT_ALIASES.includes(String(slug).trim().toLowerCase());
}

async function getPrimaryBot({ createIfMissing = false } = {}) {
  let bot = await prisma.bot.findFirst({
    where: {
      slug: {
        in: PRIMARY_BOT_ALIASES,
      },
    },
    orderBy: { actualizadoEn: 'desc' },
  });

  if (!bot) {
    bot = await prisma.bot.findFirst({
      orderBy: [
        { estado: 'asc' },
        { actualizadoEn: 'desc' },
      ],
    });
  }

  if (!bot && createIfMissing) {
    bot = await prisma.bot.create({
      data: {
        nombre: PRIMARY_BOT_NAME,
        slug: PRIMARY_BOT_SLUG,
        descripcion: 'Bot principal unificado de FULLTECH SRL',
        tipoNegocio: 'fulltech',
        estado: 'activo',
      },
    });
  }

  return bot || null;
}

async function getPrimaryBotId({ createIfMissing = false } = {}) {
  const bot = await getPrimaryBot({ createIfMissing });
  return bot?.id || null;
}

async function resolveScopedBotId(requestedBotId = null, options = {}) {
  if (!isSingleBotMode()) {
    return requestedBotId;
  }

  const primaryBotId = await getPrimaryBotId(options);
  return primaryBotId || requestedBotId;
}

async function shouldAutoAssignSingleBot(botId) {
  if (!isSingleBotMode()) return false;

  const primaryBotId = await getPrimaryBotId();
  if (!primaryBotId) return false;

  return !botId || botId === primaryBotId;
}

async function claimUnassignedRecords(model, botId, botField = 'botId') {
  const resolvedBotId = await resolveScopedBotId(botId);

  if (!(await shouldAutoAssignSingleBot(resolvedBotId)) || !resolvedBotId) {
    return false;
  }

  await model.updateMany({
    where: {
      [botField]: null,
    },
    data: {
      [botField]: resolvedBotId,
    },
  });

  return true;
}

module.exports = {
  PRIMARY_BOT_ALIASES,
  PRIMARY_BOT_NAME,
  PRIMARY_BOT_SLUG,
  claimUnassignedRecords,
  getPrimaryBot,
  getPrimaryBotId,
  isPrimaryBotSlug,
  isSingleBotMode,
  resolveScopedBotId,
  shouldAutoAssignSingleBot,
};
