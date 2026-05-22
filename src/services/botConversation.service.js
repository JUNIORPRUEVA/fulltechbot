const prisma = require('../lib/prisma');

async function listarConversaciones(botId = null) {
  const where = {};
  if (botId) where.botId = botId;
  return prisma.botConversation.findMany({
    where,
    orderBy: { created_at: 'desc' },
  });
}

async function obtenerPorSessionId(sessionId) {
  return prisma.botConversation.findMany({
    where: { session_id: sessionId },
    orderBy: { created_at: 'asc' },
  });
}

async function crearConversacion(data) {
  const { session_id, message, botId } = data;

  if (!session_id) {
    throw new Error('El session_id es obligatorio');
  }

  if (!message) {
    throw new Error('El message es obligatorio');
  }

  return prisma.botConversation.create({
    data: {
      session_id,
      message: typeof message === 'string' ? JSON.parse(message) : message,
      botId: botId || null,
      created_at: new Date(),
    },
  });
}

async function eliminarPorSessionId(sessionId) {
  const deleted = await prisma.botConversation.deleteMany({
    where: { session_id: sessionId },
  });
  return deleted;
}

module.exports = {
  listarConversaciones,
  obtenerPorSessionId,
  crearConversacion,
  eliminarPorSessionId,
};
