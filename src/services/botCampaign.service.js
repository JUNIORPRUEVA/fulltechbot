const prisma = require('../lib/prisma');

class BotCampaignService {
  normalizeText(text = '') {
    return text
      .toString()
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9\s]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  normalizeList(values) {
    if (!Array.isArray(values)) return [];
    return values
      .map((value) => this.normalizeText(value))
      .filter(Boolean);
  }

  async listar(botId, filtros = {}) {
    const where = { 
      bot_id: botId,
    };

    if (filtros.active !== undefined) {
      where.active = filtros.active === true || filtros.active === 'true';
    }

    if (filtros.search) {
      where.OR = [
        { campaign_name: { contains: filtros.search, mode: 'insensitive' } },
        { campaign_code: { contains: filtros.search, mode: 'insensitive' } },
        { campaign_context: { contains: filtros.search, mode: 'insensitive' } },
      ];
    }

    return prisma.botCampaign.findMany({
      where,
      orderBy: [{ created_at: 'desc' }],
    });
  }

  async obtenerPorId(id) {
    const campaign = await prisma.botCampaign.findUnique({ where: { id } });
    if (!campaign) {
      throw new Error('Campaña no encontrada');
    }
    return campaign;
  }

  async obtenerActivas(botId) {
    return prisma.botCampaign.findMany({
      where: {
        bot_id: botId,
        active: true,
      },
      orderBy: [{ created_at: 'desc' }],
    });
  }

  async crear(data) {
    const payload = this._sanitizeCampaignPayload(data, true);
    return prisma.botCampaign.create({ data: payload });
  }

  async actualizar(id, data) {
    await this.obtenerPorId(id);
    const payload = this._sanitizeCampaignPayload(data, false);

    if (Object.keys(payload).length === 0) {
      throw new Error('No hay campos para actualizar');
    }

    return prisma.botCampaign.update({
      where: { id },
      data: payload,
    });
  }

  async cambiarEstado(id, active) {
    await this.obtenerPorId(id);
    return prisma.botCampaign.update({
      where: { id },
      data: { active: Boolean(active) },
    });
  }

  async eliminar(id) {
    await this.obtenerPorId(id);
    const now = new Date();
    await prisma.botCampaign.update({
      where: { id },
      data: {
        deleted_at: now,
        is_deleted: true,
        sync_status: 'pending_delete',
      },
    });
    return { message: 'Campaña eliminada exitosamente' };
  }

  async duplicar(id, nuevoCodigo) {
    const original = await this.obtenerPorId(id);
    return prisma.botCampaign.create({
      data: {
        bot_id: original.bot_id,
        campaign_code: nuevoCodigo || `${original.campaign_code}_copia`,
        campaign_name: `${original.campaign_name} (copia)`,
        keywords: original.keywords || [],
        trigger_phrases: original.trigger_phrases || [],
        initial_message: original.initial_message,
        campaign_context: original.campaign_context,
        media_urls: original.media_urls || [],
        active: false,
      },
    });
  }

  async detectCampaignIntent({
    bot_id,
    message_text,
    conversation_id,
    customer_id,
    source_channel = 'whatsapp',
  }) {
    const emptyResult = {
      detected: false,
      route: 'GENERAL',
      campaign: null,
      matched_keyword: null,
      matched_trigger_phrase: null,
      confidence: 0,
      should_respond: true,
      customer_paused: false,
    };

    if (!bot_id || !message_text) {
      return emptyResult;
    }

    const [campaigns, pausedState] = await Promise.all([
      this.obtenerActivas(bot_id),
      this._isCustomerPaused(bot_id, customer_id, conversation_id),
    ]);

    if (campaigns.length === 0) {
      return {
        ...emptyResult,
        should_respond: !pausedState,
        customer_paused: pausedState,
      };
    }

    const normalizedMessage = this.normalizeText(message_text);
    const candidates = campaigns
      .map((campaign) => this._scoreCampaignMatch(campaign, normalizedMessage))
      .filter((candidate) => candidate.detectable);

    if (candidates.length === 0) {
      return {
        ...emptyResult,
        should_respond: !pausedState,
        customer_paused: pausedState,
      };
    }

    candidates.sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      return (b.matchedKeyword?.length || 0) - (a.matchedKeyword?.length || 0);
    });

    const winner = candidates[0];

    const context = await this._guardarContextoDetectado({
      bot_id,
      conversation_id,
      customer_id,
      campaign_id: winner.campaign.id,
      campaign_code: winner.campaign.campaign_code,
      campaign_name: winner.campaign.campaign_name,
      matched_keyword: winner.matchedKeyword,
      matched_trigger_phrase: winner.matchedTriggerPhrase,
      customer_message: message_text,
      detection_confidence: winner.score,
      source_channel,
      status: 'detectada',
    });

    return {
      detected: true,
      route: 'CAMPAIGN',
      campaign: {
        id: winner.campaign.id,
        bot_id: winner.campaign.bot_id,
        campaign_code: winner.campaign.campaign_code,
        campaign_name: winner.campaign.campaign_name,
        keywords: winner.campaign.keywords,
        trigger_phrases: winner.campaign.trigger_phrases,
        initial_message: winner.campaign.initial_message,
        campaign_context: winner.campaign.campaign_context,
        media_urls: winner.campaign.media_urls,
        active: winner.campaign.active,
      },
      matched_keyword: winner.matchedKeyword,
      matched_trigger_phrase: winner.matchedTriggerPhrase,
      confidence: winner.score,
      context_id: context?.id || null,
      should_respond: !pausedState,
      customer_paused: pausedState,
    };
  }

  async obtenerContextoConversacion(conversationId, botId = null) {
    return prisma.conversationCampaignContext.findFirst({
      where: {
        conversation_id: conversationId,
        ...(botId ? { bot_id: botId } : {}),
      },
      include: { campaign: true },
      orderBy: { created_at: 'desc' },
    });
  }

  async obtenerHistorialContextoConversacion(conversationId, botId = null) {
    return prisma.conversationCampaignContext.findMany({
      where: {
        conversation_id: conversationId,
        ...(botId ? { bot_id: botId } : {}),
      },
      include: { campaign: true },
      orderBy: { created_at: 'desc' },
    });
  }

  async cambiarCampanaManual(botId, conversationId, campaignId, customerId) {
    const campaign = await this.obtenerPorId(campaignId);
    const existingContext = await this.obtenerContextoConversacion(conversationId, botId);

    if (existingContext) {
      return prisma.conversationCampaignContext.update({
        where: { id: existingContext.id },
        data: {
          customer_id: customerId || existingContext.customer_id,
          campaign_id: campaign.id,
          campaign_code: campaign.campaign_code,
          campaign_name: campaign.campaign_name,
          status: 'manual',
          updated_at: new Date(),
        },
        include: { campaign: true },
      });
    }

    return this._guardarContextoDetectado({
      bot_id: botId,
      conversation_id: conversationId,
      customer_id: customerId,
      campaign_id: campaign.id,
      campaign_code: campaign.campaign_code,
      campaign_name: campaign.campaign_name,
      matched_keyword: null,
      matched_trigger_phrase: null,
      customer_message: null,
      detection_confidence: 1,
      source_channel: 'crm',
      status: 'manual',
    });
  }

  async obtenerDatosParaAgente(campaignId) {
    const campaign = await this.obtenerPorId(campaignId);
    return {
      bot_id: campaign.bot_id,
      campaign_code: campaign.campaign_code,
      campaign_name: campaign.campaign_name,
      keywords: campaign.keywords || [],
      trigger_phrases: campaign.trigger_phrases || [],
      initial_message: campaign.initial_message,
      campaign_context: campaign.campaign_context,
      media_urls: campaign.media_urls || [],
      active: campaign.active,
    };
  }

  async prepararContextoAgente({
    bot_id,
    campaign_id,
    conversation_id,
    customer_id,
    customer_message,
  }) {
    const [bot, latestContext, customer, campaignData] = await Promise.all([
      prisma.bot.findUnique({ where: { id: bot_id } }),
      conversation_id ? this.obtenerContextoConversacion(conversation_id, bot_id) : null,
      this._findCustomer(bot_id, customer_id, conversation_id),
      this.obtenerDatosParaAgente(campaign_id),
    ]);

    if (!bot) {
      throw new Error('Bot no encontrado');
    }

    const shouldSendInitialMessage = !latestContext?.initial_message_sent_at;

    return {
      agent_name: 'AGENTE_CAMPAÑA',
      route: 'CAMPAIGN',
      should_respond: !customer?.bot_pausado,
      should_send_initial_message: shouldSendInitialMessage,
      customer_paused: Boolean(customer?.bot_pausado),
      bot: {
        id: bot.id,
        nombre: bot.nombre,
        slug: bot.slug,
        tipoNegocio: bot.tipoNegocio,
      },
      customer: customer
        ? {
            telefono: customer.telefono,
            nombre: customer.nombre,
            chatid: customer.chatid,
            bot_pausado: customer.bot_pausado,
            humano_tomo_control: customer.humano_tomo_control,
          }
        : null,
      conversation_context: latestContext,
      campaign: campaignData,
      prompt: this.generarPromptCampania(bot, campaignData, customer_message, {
        shouldSendInitialMessage,
      }),
    };
  }

  async registrarRespuestaAgente({
    context_id,
    conversation_id,
    bot_id,
    initial_message_sent = false,
  }) {
    let context = null;

    if (context_id) {
      context = await prisma.conversationCampaignContext.findUnique({
        where: { id: context_id },
      });
    }

    if (!context && conversation_id) {
      context = await this.obtenerContextoConversacion(conversation_id, bot_id);
    }

    if (!context) return null;

    return prisma.conversationCampaignContext.update({
      where: { id: context.id },
      data: {
        status: initial_message_sent ? 'respuesta_inicial_enviada' : 'respuesta_enviada',
        initial_message_sent_at: initial_message_sent
          ? context.initial_message_sent_at || new Date()
          : context.initial_message_sent_at,
        last_response_at: new Date(),
        updated_at: new Date(),
      },
    });
  }

  generarPromptCampania(botData, campaignData, customerMessage, options = {}) {
    const shouldSendInitialMessage = options.shouldSendInitialMessage !== false;

    return `
Eres ${botData.nombre || 'Asesor'}, asesor de ventas de ${botData.tipoNegocio || botData.nombre || 'la empresa'}.

MENSAJE DEL CLIENTE:
${customerMessage}

CAMPAÑA DETECTADA:
${campaignData.campaign_name}

MENSAJE INICIAL CONFIGURADO:
${campaignData.initial_message || 'No hay mensaje inicial configurado.'}

CONTEXTO DE LA CAMPAÑA:
${campaignData.campaign_context || 'No hay contexto adicional.'}

RECURSOS MULTIMEDIA:
${this._stringifyField(campaignData.media_urls)}

ESTADO DE LA PRIMERA RESPUESTA:
${shouldSendInitialMessage ? 'Es la primera respuesta de campaña en esta conversación.' : 'Ya se envió la primera respuesta de campaña anteriormente. No la repitas textual.'}

INSTRUCCIONES:
1. Responde como vendedor humano profesional.
2. No digas que eres una IA.
3. No respondas de forma genérica.
4. No preguntes "¿cómo puedo ayudarte?" si ya sabes la campaña.
5. Usa el mensaje inicial configurado como base solo si esta es la primera respuesta.
6. No inventes precios, garantías, descuentos ni condiciones fuera del contexto.
7. Si falta información, haz una sola pregunta útil para avanzar la venta.
8. Mantén la respuesta corta, clara y persuasiva.
9. Usa tono dominicano profesional, sin exagerar emojis.
10. Cierra con una pregunta de avance.
`.trim();
  }

  _scoreCampaignMatch(campaign, normalizedMessage) {
    const triggerPhrases = this.normalizeList(campaign.trigger_phrases);
    const keywords = Array.from(new Set([
      ...this.normalizeList(campaign.keywords),
      this.normalizeText(campaign.campaign_name),
    ])).filter(Boolean);

    let matchedTriggerPhrase = null;
    let matchedKeyword = null;

    for (const phrase of triggerPhrases.sort((a, b) => b.length - a.length)) {
      if (normalizedMessage.includes(phrase)) {
        matchedTriggerPhrase = phrase;
        break;
      }
    }

    for (const keyword of keywords.sort((a, b) => b.length - a.length)) {
      if (normalizedMessage.includes(keyword)) {
        matchedKeyword = keyword;
        break;
      }
    }

    if (!matchedKeyword) {
      return {
        campaign,
        detectable: false,
        score: 0,
        matchedKeyword: null,
        matchedTriggerPhrase,
      };
    }

    let score = 0.7;
    if (matchedKeyword.split(' ').length >= 2) score += 0.1;
    if (matchedTriggerPhrase) score += 0.15;
    score = Number(Math.min(score, 0.99).toFixed(2));

    return {
      campaign,
      detectable: matchedTriggerPhrase ? score >= 0.75 : score >= 0.8,
      score,
      matchedKeyword,
      matchedTriggerPhrase,
    };
  }

  async _guardarContextoDetectado(data) {
    return prisma.conversationCampaignContext.create({
      data,
      include: { campaign: true },
    });
  }

  async _isCustomerPaused(botId, customerId, conversationId) {
    const customer = await this._findCustomer(botId, customerId, conversationId);
    return Boolean(customer?.bot_pausado);
  }

  async _findCustomer(botId, customerId, conversationId) {
    const or = [];

    if (customerId) {
      or.push({ telefono: customerId });
      or.push({ chatid: customerId });
    }

    if (conversationId) {
      or.push({ telefono: conversationId });
      or.push({ chatid: conversationId });
    }

    if (or.length === 0) return null;

    return prisma.botClient.findFirst({
      where: {
        botId,
        OR: or,
      },
    });
  }

  _sanitizeCampaignPayload(data, requireRequiredFields = false) {
    if (requireRequiredFields) {
      if (!data.bot_id || !data.campaign_code || !data.campaign_name) {
        throw new Error('bot_id, campaign_code y campaign_name son obligatorios');
      }
    }

    const payload = {};

    if (data.bot_id !== undefined) payload.bot_id = data.bot_id;
    if (data.campaign_code !== undefined) payload.campaign_code = data.campaign_code;
    if (data.campaign_name !== undefined) payload.campaign_name = data.campaign_name;
    if (data.keywords !== undefined) payload.keywords = Array.isArray(data.keywords) ? data.keywords : [];
    if (data.trigger_phrases !== undefined) {
      payload.trigger_phrases = Array.isArray(data.trigger_phrases) ? data.trigger_phrases : [];
    }
    if (data.initial_message !== undefined) payload.initial_message = data.initial_message ?? null;
    if (data.campaign_context !== undefined) payload.campaign_context = data.campaign_context ?? null;
    if (data.media_urls !== undefined) payload.media_urls = Array.isArray(data.media_urls) ? data.media_urls : [];
    if (data.active !== undefined) payload.active = Boolean(data.active);

    if (requireRequiredFields) {
      payload.keywords ??= [];
      payload.trigger_phrases ??= [];
      payload.media_urls ??= [];
      payload.active ??= true;
    }

    return payload;
  }

  _stringifyField(value) {
    if (value === null || value === undefined) return 'No especificado';
    if (typeof value === 'string') return value;
    if (Array.isArray(value)) return value.length ? value.join('\n') : 'No especificado';
    return JSON.stringify(value, null, 2);
  }
}

module.exports = new BotCampaignService();
