const followupService = require('../services/followup.service');

class FollowupController {
  // ================================================================
  // SCHEDULED FOLLOWUPS
  // ================================================================

  async listarScheduled(req, res) {
    try {
      const { botId } = req.params;
      const { estado, tipo_seguimiento, nivel, cliente_compro, fecha, search, limit, offset } = req.query;

      const result = await followupService.listarScheduled(botId, {
        estado, tipo_seguimiento, nivel, cliente_compro, fecha, search, limit, offset,
      });

      res.json({ ok: true, ...result });
    } catch (error) {
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async obtenerScheduled(req, res) {
    try {
      const followup = await followupService.obtenerScheduled(req.params.id);
      res.json({ ok: true, data: followup });
    } catch (error) {
      if (error.message === 'Seguimiento no encontrado') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async actualizarScheduled(req, res) {
    try {
      const followup = await followupService.actualizarScheduled(req.params.id, req.body);
      res.json({ ok: true, message: 'Seguimiento actualizado', data: followup });
    } catch (error) {
      if (error.message === 'Seguimiento no encontrado') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async finalizarScheduled(req, res) {
    try {
      const followup = await followupService.finalizarScheduled(req.params.id);
      res.json({ ok: true, message: 'Seguimiento finalizado', data: followup });
    } catch (error) {
      if (error.message === 'Seguimiento no encontrado') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async cancelarScheduled(req, res) {
    try {
      const followup = await followupService.cancelarScheduled(req.params.id);
      res.json({ ok: true, message: 'Seguimiento cancelado', data: followup });
    } catch (error) {
      if (error.message === 'Seguimiento no encontrado') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async reactivarScheduled(req, res) {
    try {
      const followup = await followupService.reactivarScheduled(req.params.id);
      res.json({ ok: true, message: 'Seguimiento reactivado', data: followup });
    } catch (error) {
      if (error.message === 'Seguimiento no encontrado') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  // ================================================================
  // RECOVERY FOLLOWUPS
  // ================================================================

  async listarRecovery(req, res) {
    try {
      const { botId } = req.params;
      const { estado, etapa, nivel, fecha, search, limit, offset } = req.query;

      const result = await followupService.listarRecovery(botId, {
        estado, etapa, nivel, fecha, search, limit, offset,
      });

      res.json({ ok: true, ...result });
    } catch (error) {
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async obtenerRecovery(req, res) {
    try {
      const followup = await followupService.obtenerRecovery(req.params.id);
      res.json({ ok: true, data: followup });
    } catch (error) {
      if (error.message === 'Recuperación no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async actualizarRecovery(req, res) {
    try {
      const followup = await followupService.actualizarRecovery(req.params.id, req.body);
      res.json({ ok: true, message: 'Recuperación actualizada', data: followup });
    } catch (error) {
      if (error.message === 'Recuperación no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async finalizarRecovery(req, res) {
    try {
      const followup = await followupService.finalizarRecovery(req.params.id);
      res.json({ ok: true, message: 'Recuperación finalizada', data: followup });
    } catch (error) {
      if (error.message === 'Recuperación no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async cancelarRecovery(req, res) {
    try {
      const followup = await followupService.cancelarRecovery(req.params.id);
      res.json({ ok: true, message: 'Recuperación cancelada', data: followup });
    } catch (error) {
      if (error.message === 'Recuperación no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }

  async reactivarRecovery(req, res) {
    try {
      const followup = await followupService.reactivarRecovery(req.params.id);
      res.json({ ok: true, message: 'Recuperación reactivada', data: followup });
    } catch (error) {
      if (error.message === 'Recuperación no encontrada') {
        return res.status(404).json({ ok: false, message: error.message });
      }
      res.status(500).json({ ok: false, message: error.message });
    }
  }
}

module.exports = new FollowupController();
