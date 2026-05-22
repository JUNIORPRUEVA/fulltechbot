const botCampaignService = require('../services/botCampaign.service');

class BotCampaignController {
  async listar(req, res) {
    try {
      const { botId } = req.params;
      const { active, campaign_status, search } = req.query;
      const campaigns = await botCampaignService.listar(botId, { active, campaign_status, search });
      res.json({ ok: true, data: campaigns });
    } catch (error) {
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async obtenerActivas(req, res) {
    try {
      const { botId } = req.params;
      const campaigns = await botCampaignService.obtenerActivas(botId);
      res.json({ ok: true, data: campaigns });
    } catch (error) {
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async obtenerPorId(req, res) {
    try {
      const campaign = await botCampaignService.obtenerPorId(req.params.campaignId);
      res.json({ ok: true, data: campaign });
    } catch (error) {
      if (error.message === 'Campaña no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async crear(req, res) {
    try {
      const { botId } = req.params;
      const campaign = await botCampaignService.crear({ ...req.body, bot_id: botId });
      res.status(201).json({ ok: true, message: 'Campaña creada exitosamente', data: campaign });
    } catch (error) {
      if (
        error.message.includes('obligatorios') ||
        error.message.includes('obligatorio') ||
        error.code === 'P2002'
      ) {
        return res.status(400).json({
          ok: false,
          message: error.code === 'P2002'
            ? 'Ya existe una campaña con ese código en este bot'
            : error.message,
        });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async actualizar(req, res) {
    try {
      const campaign = await botCampaignService.actualizar(req.params.campaignId, req.body);
      res.json({ ok: true, message: 'Campaña actualizada exitosamente', data: campaign });
    } catch (error) {
      if (error.message === 'Campaña no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async cambiarEstado(req, res) {
    try {
      const { active } = req.body;
      const campaign = await botCampaignService.cambiarEstado(req.params.campaignId, active);
      res.json({
        ok: true,
        message: `Campaña ${active ? 'activada' : 'desactivada'} exitosamente`,
        data: campaign,
      });
    } catch (error) {
      if (error.message === 'Campaña no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async eliminar(req, res) {
    try {
      await botCampaignService.eliminar(req.params.campaignId);
      res.json({ ok: true, message: 'Campaña eliminada exitosamente' });
    } catch (error) {
      if (error.message === 'Campaña no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async duplicar(req, res) {
    try {
      const { campaignId } = req.params;
      const { campaign_code } = req.body;
      const campaign = await botCampaignService.duplicar(campaignId, campaign_code);
      res.status(201).json({ ok: true, message: 'Campaña duplicada exitosamente', data: campaign });
    } catch (error) {
      if (error.message === 'Campaña no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      if (error.code === 'P2002') {
        return res.status(400).json({ ok: false, message: 'Ya existe una campaña con ese código en este bot' });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async detectar(req, res) {
    try {
      const { botId } = req.params;
      const { bot_id, message, conversation_id, customer_id, source_channel } = req.body;
      const resolvedBotId = bot_id || botId;

      if (!resolvedBotId || !message) {
        return res.status(400).json({
          ok: false,
          message: 'bot_id y message son obligatorios',
        });
      }

      const resultado = await botCampaignService.detectCampaignIntent({
        bot_id: resolvedBotId,
        message_text: message,
        conversation_id: conversation_id || '',
        customer_id: customer_id || null,
        source_channel: source_channel || 'whatsapp',
      });

      res.json({ ok: true, data: resultado });
    } catch (error) {
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async obtenerContextoConversacion(req, res) {
    try {
      const { botId, conversationId } = req.params;
      const contexto = await botCampaignService.obtenerContextoConversacion(conversationId, botId || null);
      res.json({ ok: true, data: contexto });
    } catch (error) {
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async obtenerHistorialContexto(req, res) {
    try {
      const { botId, conversationId } = req.params;
      const contextos = await botCampaignService.obtenerHistorialContextoConversacion(conversationId, botId || null);
      res.json({ ok: true, data: contextos });
    } catch (error) {
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async cambiarCampanaManual(req, res) {
    try {
      const { botId, conversationId } = req.params;
      const { campaign_id, customer_id } = req.body;

      if (!campaign_id) {
        return res.status(400).json({ ok: false, message: 'campaign_id es obligatorio' });
      }

      const campaign = await botCampaignService.cambiarCampanaManual(
        botId,
        conversationId,
        campaign_id,
        customer_id,
      );

      res.json({ ok: true, message: 'Campaña cambiada manualmente', data: campaign });
    } catch (error) {
      if (error.message === 'Campaña no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async obtenerDatosAgente(req, res) {
    try {
      const { campaignId } = req.params;
      const datos = await botCampaignService.obtenerDatosParaAgente(campaignId);
      res.json({ ok: true, data: datos });
    } catch (error) {
      if (error.message === 'Campaña no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async prepararAgente(req, res) {
    try {
      const { botId, campaignId } = req.params;
      const { conversation_id, customer_id, customer_message } = req.body;

      if (!customer_message) {
        return res.status(400).json({ ok: false, message: 'customer_message es obligatorio' });
      }

      const payload = await botCampaignService.prepararContextoAgente({
        bot_id: botId,
        campaign_id: campaignId,
        conversation_id: conversation_id || '',
        customer_id: customer_id || null,
        customer_message,
      });

      res.json({ ok: true, data: payload });
    } catch (error) {
      if (error.message === 'Bot no encontrado' || error.message === 'Campaña no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async registrarRespuestaAgente(req, res) {
    try {
      const { botId } = req.params;
      const { context_id, conversation_id, initial_message_sent } = req.body;

      const data = await botCampaignService.registrarRespuestaAgente({
        context_id: context_id || null,
        conversation_id: conversation_id || '',
        bot_id: botId,
        initial_message_sent: Boolean(initial_message_sent),
      });

      res.json({ ok: true, data });
    } catch (error) {
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async generarPrompt(req, res) {
    try {
      const { campaignId } = req.params;
      const { customer_message, bot_data, should_send_initial_message } = req.body;

      if (!customer_message) {
        return res.status(400).json({ ok: false, message: 'customer_message es obligatorio' });
      }

      const campaignData = await botCampaignService.obtenerDatosParaAgente(campaignId);
      const prompt = botCampaignService.generarPromptCampania(
        bot_data || {},
        campaignData,
        customer_message,
        {
          shouldSendInitialMessage: should_send_initial_message !== false,
        },
      );

      res.json({ ok: true, data: { prompt, campaign: campaignData } });
    } catch (error) {
      if (error.message === 'Campaña no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }
}

module.exports = new BotCampaignController();
