const prisma = require('../lib/prisma');
const {
  PRIMARY_BOT_NAME,
  PRIMARY_BOT_SLUG,
  getPrimaryBot,
  isPrimaryBotSlug,
  isSingleBotMode,
} = require('./botScope.service');

class BotService {
  async listar(filtros = {}) {
    if (isSingleBotMode()) {
      const bot = await getPrimaryBot({ createIfMissing: true });
      return bot ? [bot] : [];
    }

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
    if (isSingleBotMode()) {
      const bot = await getPrimaryBot({ createIfMissing: true });
      if (!bot) throw new Error('Bot no encontrado');
      return bot;
    }

    const bot = await prisma.bot.findUnique({ where: { id } });
    if (!bot) throw new Error('Bot no encontrado');
    return bot;
  }

  async obtenerPorSlug(slug) {
    if (isSingleBotMode()) {
      const bot = await getPrimaryBot({ createIfMissing: true });
      if (!bot) throw new Error('Bot no encontrado');

      if (!slug || isPrimaryBotSlug(slug) || slug === bot.slug) {
        return bot;
      }

      return bot;
    }

    const bot = await prisma.bot.findUnique({ where: { slug } });
    if (!bot) throw new Error('Bot no encontrado');
    return bot;
  }

  async crear(data) {
    if (isSingleBotMode()) {
      const existente = await getPrimaryBot();

      if (existente) {
        return prisma.bot.update({
          where: { id: existente.id },
          data: {
            nombre: data.nombre || existente.nombre || PRIMARY_BOT_NAME,
            slug: PRIMARY_BOT_SLUG,
            descripcion: data.descripcion ?? existente.descripcion,
            tipoNegocio: data.tipoNegocio ?? existente.tipoNegocio,
            promptBase: data.promptBase ?? existente.promptBase,
            tono: data.tono ?? existente.tono,
            instrucciones: data.instrucciones ?? existente.instrucciones,
            reglasNegocio: data.reglasNegocio ?? existente.reglasNegocio,
            instanciaWhatsapp: data.instanciaWhatsapp ?? existente.instanciaWhatsapp,
            telefonoWhatsapp: data.telefonoWhatsapp ?? existente.telefonoWhatsapp,
            apiKeyChatGPT: data.apiKeyChatGPT ?? existente.apiKeyChatGPT,
            estado: 'activo',
          },
        });
      }

      return prisma.bot.create({
        data: {
          nombre: data.nombre || PRIMARY_BOT_NAME,
          slug: PRIMARY_BOT_SLUG,
          descripcion: data.descripcion ?? 'Bot principal unificado de FULLTECH SRL',
          tipoNegocio: data.tipoNegocio ?? 'fulltech',
          promptBase: data.promptBase,
          tono: data.tono,
          instrucciones: data.instrucciones,
          reglasNegocio: data.reglasNegocio,
          instanciaWhatsapp: data.instanciaWhatsapp,
          telefonoWhatsapp: data.telefonoWhatsapp,
          apiKeyChatGPT: data.apiKeyChatGPT,
          estado: 'activo',
        },
      });
    }

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
    const target = await this.obtenerPorId(id);

    if (!isSingleBotMode() && data.slug) {
      const existente = await prisma.bot.findUnique({ where: { slug: data.slug } });
      if (existente && existente.id !== id) {
        throw new Error('Ya existe otro bot con ese slug');
      }
    }

    const updatePayload = {
      ...data,
    };

    if (isSingleBotMode()) {
      updatePayload.slug = PRIMARY_BOT_SLUG;
      updatePayload.nombre = data.nombre || target.nombre || PRIMARY_BOT_NAME;
    }

    return prisma.bot.update({
      where: { id: target.id },
      data: updatePayload,
    });
  }

  async cambiarEstado(id, estado) {
    const estadosPermitidos = ['activo', 'inactivo'];
    if (!estadosPermitidos.includes(estado)) {
      throw new Error('Estado no valido. Use: activo, inactivo');
    }

    const target = await this.obtenerPorId(id);

    return prisma.bot.update({
      where: { id: target.id },
      data: { estado },
    });
  }

  async eliminar(id) {
    if (isSingleBotMode()) {
      throw new Error('No se puede eliminar el bot principal en modo single-bot');
    }

    await this.obtenerPorId(id);
    return prisma.bot.update({
      where: { id },
      data: { estado: 'inactivo' },
    });
  }
}

module.exports = new BotService();
