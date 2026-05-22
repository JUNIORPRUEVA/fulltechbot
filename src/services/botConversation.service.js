const prisma = require('../lib/prisma');

async function listarConversaciones(botId = null) {
  const where = {};
  if (botId) where.botId = botId;
  return prisma.botConversation.findMany({
    where,
    orderBy: { created_at: 'desc' },
  });
}

async function obtenerPorSessionId(sessionId, botId = null) {
  return prisma.botConversation.findMany({
    where: {
      session_id: sessionId,
      ...(botId ? { botId } : {}),
    },
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

/**
 * Elimina todas las conversaciones de un sessionId en una transacción.
 * También limpia datos relacionados si es necesario.
 */
async function eliminarPorSessionId(sessionId, botId = null) {
  if (!sessionId) {
    throw new Error('El sessionId es obligatorio');
  }

  return prisma.$transaction(async (tx) => {
    // Eliminar todas las conversaciones con ese session_id
    const deleted = await tx.botConversation.deleteMany({
      where: {
        session_id: sessionId,
        ...(botId ? { botId } : {}),
      },
    });

    return deleted;
  });
}

module.exports = {
  listarConversaciones,
  obtenerPorSessionId,
  crearConversacion,
  eliminarPorSessionId,
};
