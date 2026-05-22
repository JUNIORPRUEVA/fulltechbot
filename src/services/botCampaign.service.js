const prisma = require('../lib/prisma');

const DEFAULT_TRIGGER_PHRASES = [
  'quiero mas informacion',
  'mas informacion',
  'me interesa',
  'precio',
  'quiero precio',
  'necesito informacion',
  'informacion',
  'cotizacion',
  'cuanto cuesta',
  'quiero saber',
  'quisiera saber',
  'me gustaria saber',
  'dame informacion',
  'quiero contratar',
  'quiero comprar',
  'me puedes cotizar',
  'me puede cotizar',
  'a cuanto',
  'precio de',
  'precio del',
];

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
    const where = { bot_id: botId };

    if (filtros.active !== undefined) {
      where.active = filtros.active === true || filtros.active === 'true';
    }

    if (filtros.campaign_status) {
      where.campaign_status = filtros.campaign_status;
    }

    if (filtros.search) {
      where.OR = [
        { campaign_name: { contains: filtros.search, mode: 'insensitive' } },
        { campaign_code: { contains: filtros.search, mode: 'insensitive' } },
        { product_name: { contains: filtros.search, mode: 'insensitive' } },
      ];
    }

    return prisma.botCampaign.findMany({
      where,
      orderBy: [
        { priority: 'desc' },
        { created_at: 'desc' },
      ],
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
        campaign_status: 'activa',
      },
      orderBy: [
        { priority: 'desc' },
        { created_at: 'desc' },
      ],
    });
  }

  async crear(data) {
    const payload = this._sanitizeCampaignPayload(data, { requireRequiredFields: true });

    return prisma.botCampaign.create({
      data: payload,
    });
  }

  async actualizar(id, data) {
    await this.obtenerPorId(id);
    const payload = this._sanitizeCampaignPayload(data, { partial: true });

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
    await prisma.botCampaign.delete({ where: { id } });
    return { message: 'Campaña eliminada exitosamente' };
  }

  async duplicar(id, nuevoCodigo) {
    const original = await this.obtenerPorId(id);

    return prisma.botCampaign.create({
      data: {
        ...this._sanitizeCampaignPayload({
          ...original,
          campaign_code: nuevoCodigo || `${original.campaign_code}_copia`,
          campaign_name: `${original.campaign_name} (copia)`,
          active: false,
        }, { requireRequiredFields: true }),
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
      if ((b.campaign.priority || 0) !== (a.campaign.priority || 0)) {
        return (b.campaign.priority || 0) - (a.campaign.priority || 0);
      }
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
        campaign_code: winner.campaign.campaign_code,
        campaign_name: winner.campaign.campaign_name,
        product_name: winner.campaign.product_name,
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
      include: {
        campaign: true,
      },
      orderBy: { created_at: 'desc' },
    });
  }

  async obtenerHistorialContextoConversacion(conversationId, botId = null) {
    return prisma.conversationCampaignContext.findMany({
      where: {
        conversation_id: conversationId,
        ...(botId ? { bot_id: botId } : {}),
      },
      include: {
        campaign: true,
      },
      orderBy: { created_at: 'desc' },
    });
  }

  async actualizarEstadoContexto(id, status) {
    return prisma.conversationCampaignContext.update({
      where: { id },
      data: {
        status,
        updated_at: new Date(),
      },
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
        include: {
          campaign: true,
        },
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
      campaign_name: campaign.campaign_name,
      campaign_code: campaign.campaign_code,
      product_name: campaign.product_name,
      product_id: campaign.product_id,
      normal_price: campaign.normal_price,
      offer_price: campaign.offer_price,
      currency: campaign.currency,
      initial_message: campaign.initial_message,
      agent_context: campaign.agent_context,
      sales_instructions: campaign.sales_instructions,
      negotiation_rules: campaign.negotiation_rules,
      objection_handling: campaign.objection_handling,
      closing_questions: campaign.closing_questions,
      extra_camera_price: campaign.extra_camera_price,
      minimum_extra_camera_price: campaign.minimum_extra_camera_price,
      location_rules: campaign.location_rules,
      warranty_info: campaign.warranty_info,
      installation_info: campaign.installation_info,
      media_urls: campaign.media_urls,
      crm_initial_status: campaign.crm_initial_status,
      crm_tag: campaign.crm_tag,
      priority: campaign.priority,
    };
  }

  async prepararContextoAgente({
    bot_id,
    campaign_id,
    conversation_id,
    customer_id,
    customer_message,
  }) {
    const [bot, campaign, latestContext, customer] = await Promise.all([
      prisma.bot.findUnique({ where: { id: bot_id } }),
      this.obtenerPorId(campaign_id),
      conversation_id ? this.obtenerContextoConversacion(conversation_id, bot_id) : null,
      this._findCustomer(bot_id, customer_id, conversation_id),
    ]);

    if (!bot) {
      throw new Error('Bot no encontrado');
    }

    const shouldSendInitialMessage = !latestContext?.initial_message_sent_at;
    const shouldRespond = !customer?.bot_pausado;

    const campaignData = await this.obtenerDatosParaAgente(campaign_id);
    const prompt = this.generarPromptCampania(bot, campaignData, customer_message, {
      shouldSendInitialMessage,
      customer,
    });

    return {
      agent_name: 'AGENTE_CAMPAÑA',
      route: 'CAMPAIGN',
      should_respond: shouldRespond,
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
      prompt,
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

    if (!context) {
      return null;
    }

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

Estás atendiendo a un cliente que escribió desde una campaña publicitaria o mensaje prellenado.

MENSAJE DEL CLIENTE:
${customerMessage}

CAMPAÑA DETECTADA:
${campaignData.campaign_name}

PRODUCTO RELACIONADO:
${campaignData.product_name || 'No especificado'}

PRECIO NORMAL:
${campaignData.normal_price || 0} ${campaignData.currency || 'DOP'}

PRECIO OFERTA:
${campaignData.offer_price || 0} ${campaignData.currency || 'DOP'}

MENSAJE INICIAL CONFIGURADO:
${campaignData.initial_message || 'No hay mensaje inicial configurado.'}

CONTEXTO DE LA CAMPAÑA:
${campaignData.agent_context || 'No hay contexto adicional.'}

INSTRUCCIONES DE VENTA:
${campaignData.sales_instructions || 'No hay instrucciones específicas.'}

REGLAS DE NEGOCIACIÓN:
${this._stringifyField(campaignData.negotiation_rules)}

GARANTÍA:
${campaignData.warranty_info || 'No especificada'}

INSTALACIÓN:
${campaignData.installation_info || 'No especificada'}

REGLAS DE UBICACIÓN:
${this._stringifyField(campaignData.location_rules)}

OBJECIONES FRECUENTES:
${this._stringifyField(campaignData.objection_handling)}

PREGUNTAS DE CIERRE:
${this._stringifyField(campaignData.closing_questions)}

ESTADO DE LA PRIMERA RESPUESTA:
${shouldSendInitialMessage ? 'Es la primera respuesta de campaña en esta conversación.' : 'Ya se envió la primera respuesta de campaña anteriormente. No la repitas textual.'}

INSTRUCCIONES:
1. Responde como vendedor humano profesional.
2. No digas que eres una IA.
3. No respondas de forma genérica.
4. No preguntes "¿cómo puedo ayudarte?" si ya sabes la campaña.
5. Usa el mensaje inicial configurado como base solo si esta es la primera respuesta.
6. No inventes precios, descuentos, garantías ni condiciones.
7. Si falta información, haz una sola pregunta útil para avanzar la venta.
8. Mantén la respuesta corta, clara y persuasiva.
9. Usa tono dominicano profesional, sin exagerar emojis.
10. Cierra con una pregunta de avance.
`.trim();
  }

  _scoreCampaignMatch(campaign, normalizedMessage) {
    const triggerPhrases = Array.from(new Set([
      ...DEFAULT_TRIGGER_PHRASES,
      ...this.normalizeList(campaign.trigger_phrases),
    ]));

    const rawKeywords = Array.isArray(campaign.keywords) ? campaign.keywords : [];
    const fallbackKeywords = [
      campaign.campaign_name,
      campaign.product_name,
    ].filter(Boolean);

    const keywords = Array.from(new Set([
      ...this.normalizeList(rawKeywords),
      ...this.normalizeList(fallbackKeywords),
    ])).filter((keyword) => keyword.length >= 3);

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

    const keywordTokenCount = matchedKeyword.split(' ').filter(Boolean).length;
    const keywordLengthRatio = Math.min(matchedKeyword.length / Math.max(normalizedMessage.length, 1), 0.45);

    let score = 0.45 + keywordLengthRatio;

    if (keywordTokenCount >= 2) {
      score += 0.12;
    }

    if (matchedTriggerPhrase) {
      score += 0.25;
    } else if (keywordTokenCount >= 3 || matchedKeyword.length >= 14) {
      score += 0.08;
    }

    score += Math.min((campaign.priority || 0) * 0.01, 0.08);
    score = Number(Math.min(score, 0.99).toFixed(2));

    const detectable = matchedTriggerPhrase ? score >= 0.55 : score >= 0.68;

    return {
      campaign,
      detectable,
      score,
      matchedKeyword,
      matchedTriggerPhrase,
    };
  }

  async _guardarContextoDetectado(data) {
    return prisma.conversationCampaignContext.create({
      data: {
        bot_id: data.bot_id,
        conversation_id: data.conversation_id || '',
        customer_id: data.customer_id || null,
        campaign_id: data.campaign_id || null,
        campaign_code: data.campaign_code || null,
        campaign_name: data.campaign_name || null,
        matched_keyword: data.matched_keyword || null,
        matched_trigger_phrase: data.matched_trigger_phrase || null,
        customer_message: data.customer_message || null,
        detection_confidence: data.detection_confidence || 0,
        source_channel: data.source_channel || 'whatsapp',
        status: data.status || 'detectada',
      },
      include: {
        campaign: true,
      },
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

  _sanitizeCampaignPayload(data, options = {}) {
    const requireRequiredFields = options.requireRequiredFields === true;
    const partial = options.partial === true;
    const payload = {};

    const assign = (key, value) => {
      if (value !== undefined) {
        payload[key] = value;
      }
    };

    if (requireRequiredFields) {
      if (!data.bot_id || !data.campaign_code || !data.campaign_name) {
        throw new Error('bot_id, campaign_code y campaign_name son obligatorios');
      }
    }

    assign('bot_id', partial ? undefined : data.bot_id);
    assign('campaign_code', data.campaign_code);
    assign('campaign_name', data.campaign_name);
    assign('campaign_description', data.campaign_description ?? null);
    assign('product_name', data.product_name ?? null);
    assign('product_id', data.product_id ?? null);
    assign('normal_price', data.normal_price !== undefined ? Number(data.normal_price) : undefined);
    assign('offer_price', data.offer_price !== undefined ? Number(data.offer_price) : undefined);
    assign('currency', data.currency);
    assign('campaign_status', data.campaign_status);
    assign('trigger_phrases', Array.isArray(data.trigger_phrases) ? data.trigger_phrases : data.trigger_phrases === undefined ? undefined : []);
    assign('keywords', Array.isArray(data.keywords) ? data.keywords : data.keywords === undefined ? undefined : []);
    assign('initial_message', data.initial_message ?? null);
    assign('agent_context', data.agent_context ?? null);
    assign('sales_instructions', data.sales_instructions ?? null);
    assign('negotiation_rules', this._normalizeJsonInput(data.negotiation_rules, {}));
    assign('objection_handling', this._normalizeJsonInput(data.objection_handling, []));
    assign('closing_questions', this._normalizeJsonInput(data.closing_questions, []));
    assign('extra_camera_price', data.extra_camera_price !== undefined ? Number(data.extra_camera_price) : undefined);
    assign('minimum_extra_camera_price', data.minimum_extra_camera_price !== undefined ? Number(data.minimum_extra_camera_price) : undefined);
    assign('location_rules', this._normalizeJsonInput(data.location_rules, {}));
    assign('warranty_info', data.warranty_info ?? null);
    assign('installation_info', data.installation_info ?? null);
    assign('media_urls', this._normalizeJsonInput(data.media_urls, []));
    assign('crm_initial_status', data.crm_initial_status);
    assign('crm_tag', data.crm_tag ?? null);
    assign('priority', data.priority !== undefined ? Number(data.priority) : undefined);
    assign('active', data.active !== undefined ? Boolean(data.active) : undefined);

    if (!partial) {
      payload.normal_price ??= 0;
      payload.offer_price ??= 0;
      payload.currency ??= 'DOP';
      payload.campaign_status ??= 'activa';
      payload.trigger_phrases ??= [];
      payload.keywords ??= [];
      payload.negotiation_rules ??= {};
      payload.objection_handling ??= [];
      payload.closing_questions ??= [];
      payload.extra_camera_price ??= 0;
      payload.minimum_extra_camera_price ??= 0;
      payload.location_rules ??= {};
      payload.media_urls ??= [];
      payload.crm_initial_status ??= 'Nuevo interesado';
      payload.priority ??= 0;
      payload.active ??= true;
    }

    return payload;
  }

  _normalizeJsonInput(value, fallback) {
    if (value === undefined) return undefined;
    if (value === null) return fallback;
    if (typeof value === 'string') {
      try {
        return JSON.parse(value);
      } catch {
        return fallback;
      }
    }
    return value;
  }

  _stringifyField(value) {
    if (value === null || value === undefined) return 'No especificado';
    if (typeof value === 'string') return value;
    if (Array.isArray(value)) {
      return value.length > 0 ? value.join('\n') : 'No especificado';
    }
    return JSON.stringify(value, null, 2);
  }
}

module.exports = new BotCampaignService();
