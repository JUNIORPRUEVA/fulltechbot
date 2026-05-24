const prisma = require('../lib/prisma');

async function shouldAutoAssignSingleBot(botId) {
  if (!botId) return false;

  const totalBots = await prisma.bot.count();
  return totalBots === 1;
}

async function claimUnassignedRecords(model, botId, botField = 'botId') {
  if (!(await shouldAutoAssignSingleBot(botId))) {
    return false;
  }

  await model.updateMany({
    where: {
      [botField]: null,
    },
    data: {
      [botField]: botId,
    },
  });

  return true;
}

module.exports = {
  shouldAutoAssignSingleBot,
  claimUnassignedRecords,
};
