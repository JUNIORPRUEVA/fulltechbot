const botService = require('../services/bot.service');

class BotController {
  async listar(req, res) {
    try {
      const { estado, search } = req.query;
      const bots = await botService.listar({ estado, search });
      res.json({ ok: true, data: bots });
    } catch (error) {
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async obtenerPorId(req, res) {
    try {
      const bot = await botService.obtenerPorId(req.params.id);
      res.json({ ok: true, data: bot });
    } catch (error) {
      if (error.message === 'Bot no encontrado') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async obtenerPorSlug(req, res) {
    try {
      const bot = await botService.obtenerPorSlug(req.params.slug);
      res.json({ ok: true, data: bot });
    } catch (error) {
      if (error.message === 'Bot no encontrado') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async crear(req, res) {
    try {
      const bot = await botService.crear(req.body);
      res.status(201).json({ ok: true, message: 'Bot creado exitosamente', data: bot });
    } catch (error) {
      if (error.message.includes('obligatorio') || error.message.includes('Ya existe')) {
        return res.status(400).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async actualizar(req, res) {
    try {
      const bot = await botService.actualizar(req.params.id, req.body);
      res.json({ ok: true, message: 'Bot actualizado exitosamente', data: bot });
    } catch (error) {
      if (error.message === 'Bot no encontrado') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      if (error.message.includes('Ya existe')) {
        return res.status(400).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async cambiarEstado(req, res) {
    try {
      const { estado } = req.body;
      const bot = await botService.cambiarEstado(req.params.id, estado);
      res.json({ ok: true, message: `Bot ${estado === 'activo' ? 'activado' : 'inactivado'} exitosamente`, data: bot });
    } catch (error) {
      if (error.message === 'Bot no encontrado') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      if (error.message.includes('no válido')) {
        return res.status(400).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async eliminar(req, res) {
    try {
      await botService.eliminar(req.params.id);
      res.json({ ok: true, message: 'Bot desactivado (soft-delete)' });
    } catch (error) {
      if (error.message === 'Bot no encontrado') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }
}

module.exports = new BotController();
