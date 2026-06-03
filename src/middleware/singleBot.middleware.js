const { isSingleBotMode, resolveScopedBotId } = require('../services/botScope.service');

async function normalizeBotParam(req, res, next) {
  try {
    if (!isSingleBotMode() || !req.params?.botId) {
      return next();
    }

    req.params.botId = await resolveScopedBotId(req.params.botId, {
      createIfMissing: true,
    });

    return next();
  } catch (error) {
    return res.status(500).json({
      ok: false,
      message: error.message || 'No se pudo resolver el bot principal',
    });
  }
}

module.exports = {
  normalizeBotParam,
};
