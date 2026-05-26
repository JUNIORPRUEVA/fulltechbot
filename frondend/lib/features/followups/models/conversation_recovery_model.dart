class ConversationRecoveryModel {
  final String id;
  final String? botId;
  final String? instanciaWhatsapp;
  final String? telefonoCliente;
  final String? nombreCliente;
  final String? motivoSeguimiento;
  final String? etapa;
  final String? ultimoMensajeBot;
  final String? ultimoMensajeCliente;
  final String? estado;
  final String? nivel;
  final DateTime? proximoSeguimientoAt;
  final DateTime? ultimoSeguimientoAt;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  ConversationRecoveryModel({
    required this.id,
    this.botId,
    this.instanciaWhatsapp,
    this.telefonoCliente,
    this.nombreCliente,
    this.motivoSeguimiento,
    this.etapa,
    this.ultimoMensajeBot,
    this.ultimoMensajeCliente,
    this.estado,
    this.nivel,
    this.proximoSeguimientoAt,
    this.ultimoSeguimientoAt,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory ConversationRecoveryModel.fromJson(Map<String, dynamic> json) {
    return ConversationRecoveryModel(
      id: json['id']?.toString() ?? '',
      botId: json['bot_id']?.toString(),
      instanciaWhatsapp: json['instancia_whatsapp']?.toString(),
      telefonoCliente: json['telefono_cliente']?.toString(),
      nombreCliente: json['nombre_cliente']?.toString(),
      motivoSeguimiento: json['motivo_seguimiento']?.toString(),
      etapa: json['etapa']?.toString(),
      ultimoMensajeBot: json['ultimo_mensaje_bot']?.toString(),
      ultimoMensajeCliente: json['ultimo_mensaje_cliente']?.toString(),
      estado: json['estado']?.toString(),
      nivel: json['nivel']?.toString(),
      proximoSeguimientoAt: _parseDate(json['proximo_seguimiento_at']),
      ultimoSeguimientoAt: _parseDate(json['ultimo_seguimiento_at']),
      creadoEn: _parseDate(json['creado_en']),
      actualizadoEn: _parseDate(json['actualizado_en']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (botId != null) 'bot_id': botId,
      if (instanciaWhatsapp != null) 'instancia_whatsapp': instanciaWhatsapp,
      if (telefonoCliente != null) 'telefono_cliente': telefonoCliente,
      if (nombreCliente != null) 'nombre_cliente': nombreCliente,
      if (motivoSeguimiento != null) 'motivo_seguimiento': motivoSeguimiento,
      if (etapa != null) 'etapa': etapa,
      if (ultimoMensajeBot != null) 'ultimo_mensaje_bot': ultimoMensajeBot,
      if (ultimoMensajeCliente != null) 'ultimo_mensaje_cliente': ultimoMensajeCliente,
      if (estado != null) 'estado': estado,
      if (nivel != null) 'nivel': nivel,
      if (proximoSeguimientoAt != null) 'proximo_seguimiento_at': proximoSeguimientoAt!.toIso8601String(),
      if (ultimoSeguimientoAt != null) 'ultimo_seguimiento_at': ultimoSeguimientoAt!.toIso8601String(),
    };
  }

  /// Prioridad según atraso
  String get prioridad {
    if (proximoSeguimientoAt == null) return 'bajo';
    if (estado != 'pendiente') return 'bajo';

    final now = DateTime.now();
    final diff = now.difference(proximoSeguimientoAt!);

    if (diff.isNegative) return 'bajo'; // No vencido
    if (diff.inHours < 24) return 'medio'; // Vencido menos de 24h
    return 'alto'; // Vencido más de 24h
  }

  bool get estaVencido {
    if (proximoSeguimientoAt == null) return false;
    return proximoSeguimientoAt!.isBefore(DateTime.now()) && estado == 'pendiente';
  }

  bool get esFinalizado => estado == 'finalizado' || estado == 'recuperado';
  bool get esCancelado => estado == 'cancelado';
  bool get esPendiente => estado == 'pendiente';

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
