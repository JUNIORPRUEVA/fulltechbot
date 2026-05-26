class ScheduledFollowupModel {
  final String id;
  final String? telefonoCliente;
  final String? botId;
  final String? instanciaWhatsapp;
  final String? nombreCliente;
  final String? sessionKey;
  final String? tipoSeguimiento;
  final String? motivo;
  final String? mensajeCliente;
  final String? ultimoMensajeBot;
  final DateTime? fechaMencionada;
  final DateTime? fechaObjetivo;
  final DateTime? proximoSeguimientoAt;
  final String? estado;
  final String? nivel;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;
  final String? tipoFollowup;
  final bool? clienteCompro;
  final DateTime? fechaUltimaRespuestaCliente;
  final String? categoriaSeguimiento;

  ScheduledFollowupModel({
    required this.id,
    this.telefonoCliente,
    this.botId,
    this.instanciaWhatsapp,
    this.nombreCliente,
    this.sessionKey,
    this.tipoSeguimiento,
    this.motivo,
    this.mensajeCliente,
    this.ultimoMensajeBot,
    this.fechaMencionada,
    this.fechaObjetivo,
    this.proximoSeguimientoAt,
    this.estado,
    this.nivel,
    this.creadoEn,
    this.actualizadoEn,
    this.tipoFollowup,
    this.clienteCompro,
    this.fechaUltimaRespuestaCliente,
    this.categoriaSeguimiento,
  });

  factory ScheduledFollowupModel.fromJson(Map<String, dynamic> json) {
    return ScheduledFollowupModel(
      id: json['id']?.toString() ?? '',
      telefonoCliente: json['telefono_cliente']?.toString(),
      botId: json['bot_id']?.toString(),
      instanciaWhatsapp: json['instancia_whatsapp']?.toString(),
      nombreCliente: json['nombre_cliente']?.toString(),
      sessionKey: json['session_key']?.toString(),
      tipoSeguimiento: json['tipo_seguimiento']?.toString(),
      motivo: json['motivo']?.toString(),
      mensajeCliente: json['mensaje_cliente']?.toString(),
      ultimoMensajeBot: json['ultimo_mensaje_bot']?.toString(),
      fechaMencionada: _parseDate(json['fecha_mencionada']),
      fechaObjetivo: _parseDate(json['fecha_objetivo']),
      proximoSeguimientoAt: _parseDate(json['proximo_seguimiento_at']),
      estado: json['estado']?.toString(),
      nivel: json['nivel']?.toString(),
      creadoEn: _parseDate(json['creado_en']),
      actualizadoEn: _parseDate(json['actualizado_en']),
      tipoFollowup: json['tipo_followup']?.toString(),
      clienteCompro: json['cliente_compro'] is bool
          ? json['cliente_compro']
          : json['cliente_compro']?.toString() == 'true',
      fechaUltimaRespuestaCliente: _parseDate(json['fecha_ultima_respuesta_cliente']),
      categoriaSeguimiento: json['categoria_seguimiento']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (telefonoCliente != null) 'telefono_cliente': telefonoCliente,
      if (botId != null) 'bot_id': botId,
      if (instanciaWhatsapp != null) 'instancia_whatsapp': instanciaWhatsapp,
      if (nombreCliente != null) 'nombre_cliente': nombreCliente,
      if (sessionKey != null) 'session_key': sessionKey,
      if (tipoSeguimiento != null) 'tipo_seguimiento': tipoSeguimiento,
      if (motivo != null) 'motivo': motivo,
      if (mensajeCliente != null) 'mensaje_cliente': mensajeCliente,
      if (ultimoMensajeBot != null) 'ultimo_mensaje_bot': ultimoMensajeBot,
      if (fechaMencionada != null) 'fecha_mencionada': fechaMencionada!.toIso8601String(),
      if (fechaObjetivo != null) 'fecha_objetivo': fechaObjetivo!.toIso8601String(),
      if (proximoSeguimientoAt != null) 'proximo_seguimiento_at': proximoSeguimientoAt!.toIso8601String(),
      if (estado != null) 'estado': estado,
      if (nivel != null) 'nivel': nivel,
      if (tipoFollowup != null) 'tipo_followup': tipoFollowup,
      if (clienteCompro != null) 'cliente_compro': clienteCompro,
      if (categoriaSeguimiento != null) 'categoria_seguimiento': categoriaSeguimiento,
    };
  }

  bool get estaVencido {
    if (proximoSeguimientoAt == null) return false;
    return proximoSeguimientoAt!.isBefore(DateTime.now()) && estado == 'pendiente';
  }

  bool get esFinalizado => estado == 'finalizado';
  bool get esCancelado => estado == 'cancelado';
  bool get esPendiente => estado == 'pendiente';

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
