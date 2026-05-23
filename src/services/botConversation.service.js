const prisma = require('../lib/prisma');

async function listarConversaciones(botId = null) {
  const where = {
    deleted_at: null,
    is_deleted: false,
  };
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
 * Elimina (soft delete) todas las conversaciones de un sessionId.
 * Marca como eliminado para propagar a otros dispositivos vía sync.
 */
async function eliminarPorSessionId(sessionId, botId = null) {
  if (!sessionId) {
    throw new Error('El sessionId es obligatorio');
  }

  const now = new Date();

  return prisma.botConversation.updateMany({
    where: {
      session_id: sessionId,
      ...(botId ? { botId } : {}),
    },
    data: {
      deleted_at: now,
      is_deleted: true,
      sync_status: 'pending_delete',
    },
  });
}

module.exports = {
  listarConversaciones,
  obtenerPorSessionId,
  crearConversacion,
  eliminarPorSessionId,
};
