const prisma = require('../lib/prisma');

class BotService {
  async listar(filtros = {}) {
    const where = {};
    if (filtros.estado) where.estado = filtros.estado;
    if (filtros.search) {
      where.OR = [
        { nombre: { contains: filtros.search, mode: 'insensitive' } },
        { slug: { contains: filtros.search, mode: 'insensitive' } },
      ];
    }
    return prisma.bot.findMany({
      where,
      orderBy: { creadoEn: 'desc' },
    });
  }

  async obtenerPorId(id) {
    const bot = await prisma.bot.findUnique({ where: { id } });
    if (!bot) throw new Error('Bot no encontrado');
    return bot;
  }

  async obtenerPorSlug(slug) {
    const bot = await prisma.bot.findUnique({ where: { slug } });
    if (!bot) throw new Error('Bot no encontrado');
    return bot;
  }

  async crear(data) {
    const { nombre, slug, descripcion, tipoNegocio, promptBase, tono, instrucciones, reglasNegocio, instanciaWhatsapp, telefonoWhatsapp, apiKeyChatGPT } = data;

    if (!nombre || !slug) {
      throw new Error('nombre y slug son obligatorios');
    }

    const existente = await prisma.bot.findUnique({ where: { slug } });
    if (existente) {
      throw new Error('Ya existe un bot con ese slug');
    }

    return prisma.bot.create({
      data: {
        nombre,
        slug,
        descripcion,
        tipoNegocio,
        promptBase,
        tono,
        instrucciones,
        reglasNegocio,
        instanciaWhatsapp,
        telefonoWhatsapp,
        apiKeyChatGPT,
        estado: 'activo',
      },
    });
  }

  async actualizar(id, data) {
    await this.obtenerPorId(id);

    if (data.slug) {
      const existente = await prisma.bot.findUnique({ where: { slug: data.slug } });
      if (existente && existente.id !== id) {
        throw new Error('Ya existe otro bot con ese slug');
      }
    }

    return prisma.bot.update({
      where: { id },
      data,
    });
  }

  async cambiarEstado(id, estado) {
    const estadosPermitidos = ['activo', 'inactivo'];
    if (!estadosPermitidos.includes(estado)) {
      throw new Error('Estado no válido. Use: activo, inactivo');
    }
    await this.obtenerPorId(id);
    return prisma.bot.update({
      where: { id },
      data: { estado },
    });
  }

  async eliminar(id) {
    // Soft-delete: cambiar a inactivo
    await this.obtenerPorId(id);
    return prisma.bot.update({
      where: { id },
      data: { estado: 'inactivo' },
    });
  }
}

module.exports = new BotService();
