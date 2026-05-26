const prisma = require('../lib/prisma');

class FollowupService {
  _serializeScheduledFollowup(row) {
    if (!row) return null;

    const toIso = (value) => {
      if (!value) return null;
      if (value instanceof Date) return value.toISOString();
      if (typeof value?.toISOString === 'function') return value.toISOString();
      return value;
    };

    return {
      id: row.id != null ? row.id.toString() : null,
      telefono_cliente: row.telefono_cliente ?? null,
      bot_id: row.bot_id ?? null,
      instancia_whatsapp: row.instancia_whatsapp ?? null,
      nombre_cliente: row.nombre_cliente ?? null,
      session_key: row.session_key ?? null,
      tipo_seguimiento: row.tipo_seguimiento ?? null,
      motivo: row.motivo ?? null,
      mensaje_cliente: row.mensaje_cliente ?? null,
      ultimo_mensaje_bot: row.ultimo_mensaje_bot ?? null,
      fecha_mencionada: toIso(row.fecha_mencionada),
      fecha_objetivo: toIso(row.fecha_objetivo),
      proximo_seguimiento_at: toIso(row.proximo_seguimiento_at),
      estado: row.estado ?? null,
      nivel: row.nivel != null ? Number(row.nivel) : 0,
      creado_en: toIso(row.creado_en),
      actualizado_en: toIso(row.actualizado_en),
      tipo_followup: row.tipo_followup ?? null,
      cliente_compro:
          row.cliente_compro == null ? null : Boolean(row.cliente_compro),
      fecha_ultima_respuesta_cliente: toIso(
        row.fecha_ultima_respuesta_cliente
      ),
      categoria_seguimiento: row.categoria_seguimiento ?? null,
    };
  }

  // ================================================================
  // BOT_SCHEDULED_FOLLOWUPS (Seguimientos Programados)
  // ================================================================

  async listarScheduled(botId, filtros = {}) {
    const condiciones = ['bsf.bot_id = $1'];
    const params = [botId];
    let paramIndex = 2;

    if (filtros.estado) {
      condiciones.push(`bsf.estado = $${paramIndex++}`);
      params.push(filtros.estado);
    }

    if (filtros.tipo_seguimiento) {
      condiciones.push(`bsf.tipo_seguimiento = $${paramIndex++}`);
      params.push(filtros.tipo_seguimiento);
    }

    if (filtros.nivel) {
      condiciones.push(`bsf.nivel = $${paramIndex++}`);
      params.push(filtros.nivel);
    }

    if (filtros.cliente_compro !== undefined && filtros.cliente_compro !== '') {
      condiciones.push(`bsf.cliente_compro = $${paramIndex++}`);
      params.push(filtros.cliente_compro === 'true' || filtros.cliente_compro === true);
    }

    // Filtros de fecha
    if (filtros.fecha === 'hoy') {
      condiciones.push(`DATE(bsf.proximo_seguimiento_at) = CURRENT_DATE`);
    } else if (filtros.fecha === 'vencidos') {
      condiciones.push(`bsf.proximo_seguimiento_at < NOW() AND bsf.estado = 'pendiente'`);
    } else if (filtros.fecha === 'proximos') {
      condiciones.push(`bsf.proximo_seguimiento_at >= NOW() AND bsf.proximo_seguimiento_at <= NOW() + INTERVAL '7 days'`);
    } else if (filtros.fecha === 'semana') {
      condiciones.push(`bsf.proximo_seguimiento_at >= NOW() AND bsf.proximo_seguimiento_at <= NOW() + INTERVAL '7 days'`);
    }

    // Búsqueda
    if (filtros.search) {
      const searchTerm = `%${filtros.search}%`;
      condiciones.push(`(
        bsf.nombre_cliente ILIKE $${paramIndex} OR
        bsf.telefono_cliente ILIKE $${paramIndex} OR
        bsf.motivo ILIKE $${paramIndex}
      )`);
      params.push(searchTerm);
      paramIndex++;
    }

    const whereClause = condiciones.join(' AND ');

    // Paginación
    const limit = Math.min(Math.max(parseInt(filtros.limit) || 50, 1), 200);
    const offset = Math.max(parseInt(filtros.offset) || 0, 0);

    const countResult = await prisma.$queryRawUnsafe(
      `SELECT COUNT(*) as total FROM bot_scheduled_followups bsf WHERE ${whereClause}`,
      ...params
    );
    const total = Number(countResult[0]?.total || 0);

    const rows = await prisma.$queryRawUnsafe(
      `SELECT bsf.* FROM bot_scheduled_followups bsf WHERE ${whereClause} ORDER BY bsf.proximo_seguimiento_at ASC NULLS LAST LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      ...params,
      limit,
      offset
    );

    return {
      data: rows.map((row) => this._serializeScheduledFollowup(row)),
      pagination: {
        total,
        limit,
        offset,
        hasMore: offset + limit < total,
      },
    };
  }

  async obtenerScheduled(id) {
    const rows = await prisma.$queryRawUnsafe(
      `SELECT * FROM bot_scheduled_followups WHERE id = $1`,
      id
    );
    if (!rows || rows.length === 0) {
      throw new Error('Seguimiento no encontrado');
    }
    return this._serializeScheduledFollowup(rows[0]);
  }

  async actualizarScheduled(id, data) {
    const existente = await this.obtenerScheduled(id);

    const camposPermitidos = [
      'estado', 'nivel', 'motivo', 'proximo_seguimiento_at',
      'tipo_seguimiento', 'fecha_objetivo', 'categoria_seguimiento',
      'cliente_compro', 'ultimo_mensaje_bot', 'mensaje_cliente',
    ];

    const sets = [];
    const params = [];
    let paramIndex = 1;

    for (const campo of camposPermitidos) {
      if (data[campo] !== undefined) {
        sets.push(`${campo} = $${paramIndex++}`);
        params.push(data[campo]);
      }
    }

    if (sets.length === 0) {
      return existente;
    }

    sets.push(`actualizado_en = NOW()`);
    params.push(id);

    await prisma.$executeRawUnsafe(
      `UPDATE bot_scheduled_followups SET ${sets.join(', ')} WHERE id = $${paramIndex}`,
      ...params
    );

    return this.obtenerScheduled(id);
  }

  async finalizarScheduled(id) {
    await this.obtenerScheduled(id);
    await prisma.$executeRawUnsafe(
      `UPDATE bot_scheduled_followups SET estado = 'finalizado', actualizado_en = NOW() WHERE id = $1`,
      id
    );
    return this.obtenerScheduled(id);
  }

  async cancelarScheduled(id) {
    await this.obtenerScheduled(id);
    await prisma.$executeRawUnsafe(
      `UPDATE bot_scheduled_followups SET estado = 'cancelado', actualizado_en = NOW() WHERE id = $1`,
      id
    );
    return this.obtenerScheduled(id);
  }

  async reactivarScheduled(id) {
    await this.obtenerScheduled(id);
    await prisma.$executeRawUnsafe(
      `UPDATE bot_scheduled_followups SET estado = 'pendiente', actualizado_en = NOW() WHERE id = $1`,
      id
    );
    return this.obtenerScheduled(id);
  }

  // ================================================================
  // BOT_FOLLOWUPS (Recuperación de Conversaciones)
  // ================================================================

  async listarRecovery(botId, filtros = {}) {
    const condiciones = ['bf.bot_id = $1'];
    const params = [botId];
    let paramIndex = 2;

    if (filtros.estado) {
      condiciones.push(`bf.estado = $${paramIndex++}`);
      params.push(filtros.estado);
    }

    if (filtros.etapa) {
      condiciones.push(`bf.etapa = $${paramIndex++}`);
      params.push(filtros.etapa);
    }

    if (filtros.nivel) {
      condiciones.push(`bf.nivel = $${paramIndex++}`);
      params.push(filtros.nivel);
    }

    // Filtros de fecha
    if (filtros.fecha === 'hoy') {
      condiciones.push(`DATE(bf.proximo_seguimiento_at) = CURRENT_DATE`);
    } else if (filtros.fecha === 'vencidos') {
      condiciones.push(`bf.proximo_seguimiento_at < NOW() AND bf.estado = 'pendiente'`);
    } else if (filtros.fecha === 'proximos') {
      condiciones.push(`bf.proximo_seguimiento_at >= NOW() AND bf.proximo_seguimiento_at <= NOW() + INTERVAL '7 days'`);
    }

    // Búsqueda
    if (filtros.search) {
      const searchTerm = `%${filtros.search}%`;
      condiciones.push(`(
        bf.nombre_cliente ILIKE $${paramIndex} OR
        bf.telefono_cliente ILIKE $${paramIndex} OR
        bf.motivo_seguimiento ILIKE $${paramIndex}
      )`);
      params.push(searchTerm);
      paramIndex++;
    }

    const whereClause = condiciones.join(' AND ');

    const limit = Math.min(Math.max(parseInt(filtros.limit) || 50, 1), 200);
    const offset = Math.max(parseInt(filtros.offset) || 0, 0);

    const countResult = await prisma.$queryRawUnsafe(
      `SELECT COUNT(*) as total FROM bot_followups bf WHERE ${whereClause}`,
      ...params
    );
    const total = Number(countResult[0]?.total || 0);

    const rows = await prisma.$queryRawUnsafe(
      `SELECT bf.* FROM bot_followups bf WHERE ${whereClause} ORDER BY bf.proximo_seguimiento_at ASC NULLS LAST LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      ...params,
      limit,
      offset
    );

    return {
      data: rows,
      pagination: {
        total,
        limit,
        offset,
        hasMore: offset + limit < total,
      },
    };
  }

  async obtenerRecovery(id) {
    const rows = await prisma.$queryRawUnsafe(
      `SELECT * FROM bot_followups WHERE id = $1`,
      id
    );
    if (!rows || rows.length === 0) {
      throw new Error('Recuperación no encontrada');
    }
    return rows[0];
  }

  async actualizarRecovery(id, data) {
    await this.obtenerRecovery(id);

    const camposPermitidos = [
      'estado', 'nivel', 'motivo_seguimiento', 'etapa',
      'proximo_seguimiento_at', 'ultimo_mensaje_bot', 'ultimo_mensaje_cliente',
    ];

    const sets = [];
    const params = [];
    let paramIndex = 1;

    for (const campo of camposPermitidos) {
      if (data[campo] !== undefined) {
        sets.push(`${campo} = $${paramIndex++}`);
        params.push(data[campo]);
      }
    }

    if (sets.length === 0) {
      return this.obtenerRecovery(id);
    }

    sets.push(`actualizado_en = NOW()`);
    params.push(id);

    await prisma.$executeRawUnsafe(
      `UPDATE bot_followups SET ${sets.join(', ')} WHERE id = $${paramIndex}`,
      ...params
    );

    return this.obtenerRecovery(id);
  }

  async finalizarRecovery(id) {
    await this.obtenerRecovery(id);
    await prisma.$executeRawUnsafe(
      `UPDATE bot_followups SET estado = 'recuperado', actualizado_en = NOW() WHERE id = $1`,
      id
    );
    return this.obtenerRecovery(id);
  }

  async cancelarRecovery(id) {
    await this.obtenerRecovery(id);
    await prisma.$executeRawUnsafe(
      `UPDATE bot_followups SET estado = 'cancelado', actualizado_en = NOW() WHERE id = $1`,
      id
    );
    return this.obtenerRecovery(id);
  }

  async reactivarRecovery(id) {
    await this.obtenerRecovery(id);
    await prisma.$executeRawUnsafe(
      `UPDATE bot_followups SET estado = 'pendiente', actualizado_en = NOW() WHERE id = $1`,
      id
    );
    return this.obtenerRecovery(id);
  }
}

module.exports = new FollowupService();
