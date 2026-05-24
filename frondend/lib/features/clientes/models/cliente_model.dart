class ClienteModel {
  final String telefono;
  final String? chatid;
  final String? nombre;
  final String? botId;
  final String? sourceBotId;
  final String? ultimaInstanciaWhatsapp;
  final String? origen;
  final String? preferenciaRespuesta;
  final String? usuarioWhatsapp;
  final String? direccion;
  final String? ciudad;
  final String? sector;
  final String? referenciaDireccion;
  final String? interesPrincipal;
  final String? productoServicioInteres;
  final String? categoriaInteres;
  final double? presupuestoEstimado;
  final String? fechaInteres;
  final String estadoCliente;
  final String etapa;
  final String? fechaReserva;
  final String? motivoReserva;
  final String? ultimoMensaje;
  final DateTime? ultimaInteraccionAt;
  final int diasSinResponder;
  final int totalMensajes;
  final String? resumenConversacion;
  final String? preferenciasCliente;
  final String? datosImportantes;
  final String? notasInternas;
  final String satisfaccion;
  final String? comentarioSatisfaccion;
  final DateTime? ultimaCompraAt;
  final String? productosComprados;
  final bool requiereSeguimiento;
  final DateTime? proximoSeguimientoAt;
  final String? motivoSeguimiento;
  final int cantidadSeguimientos;
  final DateTime? ultimoSeguimientoAt;
  final bool botPausado;
  final bool humanoTomoControl;
  final Map<String, dynamic> metadata;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  ClienteModel({
    required this.telefono,
    this.chatid,
    this.nombre,
    this.botId,
    this.sourceBotId,
    this.ultimaInstanciaWhatsapp,
    this.origen,
    this.preferenciaRespuesta,
    this.usuarioWhatsapp,
    this.direccion,
    this.ciudad,
    this.sector,
    this.referenciaDireccion,
    this.interesPrincipal,
    this.productoServicioInteres,
    this.categoriaInteres,
    this.presupuestoEstimado,
    this.fechaInteres,
    this.estadoCliente = 'prospecto',
    this.etapa = 'inicio',
    this.fechaReserva,
    this.motivoReserva,
    this.ultimoMensaje,
    this.ultimaInteraccionAt,
    this.diasSinResponder = 0,
    this.totalMensajes = 0,
    this.resumenConversacion,
    this.preferenciasCliente,
    this.datosImportantes,
    this.notasInternas,
    this.satisfaccion = 'no_evaluada',
    this.comentarioSatisfaccion,
    this.ultimaCompraAt,
    this.productosComprados,
    this.requiereSeguimiento = true,
    this.proximoSeguimientoAt,
    this.motivoSeguimiento,
    this.cantidadSeguimientos = 0,
    this.ultimoSeguimientoAt,
    this.botPausado = false,
    this.humanoTomoControl = false,
    this.metadata = const {},
    this.creadoEn,
    this.actualizadoEn,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      telefono: json['telefono']?.toString() ?? '',
      chatid: json['chatid']?.toString(),
      nombre: json['nombre']?.toString(),
      botId: json['bot_id']?.toString() ?? json['botId']?.toString(),
      sourceBotId:
          json['source_bot_id']?.toString() ?? json['sourceBotId']?.toString(),
      ultimaInstanciaWhatsapp:
          json['ultima_instancia_whatsapp']?.toString() ??
          json['ultimaInstanciaWhatsapp']?.toString(),
      origen: json['origen']?.toString(),
      preferenciaRespuesta:
          json['preferencia_respuesta']?.toString() ??
          json['preferenciaRespuesta']?.toString(),
      usuarioWhatsapp: json['usuario_whatsapp']?.toString(),
      direccion: json['direccion']?.toString(),
      ciudad: json['ciudad']?.toString(),
      sector: json['sector']?.toString(),
      referenciaDireccion: json['referencia_direccion']?.toString(),
      interesPrincipal: json['interes_principal']?.toString(),
      productoServicioInteres: json['producto_servicio_interes']?.toString(),
      categoriaInteres: json['categoria_interes']?.toString(),
      presupuestoEstimado: _toDouble(json['presupuesto_estimado']),
      fechaInteres: json['fecha_interes']?.toString(),
      estadoCliente: json['estado_cliente']?.toString() ?? 'prospecto',
      etapa: json['etapa']?.toString() ?? 'inicio',
      fechaReserva: json['fecha_reserva']?.toString(),
      motivoReserva: json['motivo_reserva']?.toString(),
      ultimoMensaje: json['ultimo_mensaje']?.toString(),
      ultimaInteraccionAt: _toDateTime(json['ultima_interaccion_at']),
      diasSinResponder: _toInt(json['dias_sin_responder']),
      totalMensajes: _toInt(json['total_mensajes']),
      resumenConversacion: json['resumen_conversacion']?.toString(),
      preferenciasCliente: json['preferencias_cliente']?.toString(),
      datosImportantes: json['datos_importantes']?.toString(),
      notasInternas: json['notas_internas']?.toString(),
      satisfaccion: json['satisfaccion']?.toString() ?? 'no_evaluada',
      comentarioSatisfaccion: json['comentario_satisfaccion']?.toString(),
      ultimaCompraAt: _toDateTime(json['ultima_compra_at']),
      productosComprados: json['productos_comprados']?.toString(),
      requiereSeguimiento: json['requiere_seguimiento'] ?? true,
      proximoSeguimientoAt: _toDateTime(json['proximo_seguimiento_at']),
      motivoSeguimiento: json['motivo_seguimiento']?.toString(),
      cantidadSeguimientos: _toInt(json['cantidad_seguimientos']),
      ultimoSeguimientoAt: _toDateTime(json['ultimo_seguimiento_at']),
      botPausado: json['bot_pausado'] ?? false,
      humanoTomoControl: json['humano_tomo_control'] ?? false,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : {},
      creadoEn: _toDateTime(json['creado_en']),
      actualizadoEn: _toDateTime(json['actualizado_en']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'telefono': telefono,
      'chatid': chatid,
      'nombre': nombre,
      'source_bot_id': sourceBotId,
      'ultima_instancia_whatsapp': ultimaInstanciaWhatsapp,
      'origen': origen,
      'preferencia_respuesta': preferenciaRespuesta,
      'usuario_whatsapp': usuarioWhatsapp,
      'direccion': direccion,
      'ciudad': ciudad,
      'sector': sector,
      'referencia_direccion': referenciaDireccion,
      'interes_principal': interesPrincipal,
      'producto_servicio_interes': productoServicioInteres,
      'categoria_interes': categoriaInteres,
      'presupuesto_estimado': presupuestoEstimado,
      'fecha_interes': fechaInteres,
      'estado_cliente': estadoCliente,
      'etapa': etapa,
      'fecha_reserva': fechaReserva,
      'motivo_reserva': motivoReserva,
      'ultimo_mensaje': ultimoMensaje,
      'resumen_conversacion': resumenConversacion,
      'preferencias_cliente': preferenciasCliente,
      'datos_importantes': datosImportantes,
      'notas_internas': notasInternas,
      'satisfaccion': satisfaccion,
      'comentario_satisfaccion': comentarioSatisfaccion,
      'productos_comprados': productosComprados,
      'requiere_seguimiento': requiereSeguimiento,
      'proximo_seguimiento_at': proximoSeguimientoAt?.toIso8601String(),
      'motivo_seguimiento': motivoSeguimiento,
      'bot_pausado': botPausado,
      'humano_tomo_control': humanoTomoControl,
      'metadata': metadata,
    };
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
