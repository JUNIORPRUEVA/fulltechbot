const prisma = require('../lib/prisma');

async function listarConversaciones() {
  return prisma.botConversation.findMany({
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
  const { session_id, message } = data;

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
      created_at: new Date(),
    },
  });
}

module.exports = {
  listarConversaciones,
  obtenerPorSessionId,
  crearConversacion,
};
