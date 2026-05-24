class BotOrderModel {
  final String id;
  final String? botId;
  final String? sourceBotId;
  final String telefonoCliente;
  final String? nombreCliente;
  final String? productoServicio;
  final String? tipoServicio;
  final String? direccion;
  final String? fechaDeseada;
  final String? estadoPedido;
  final String? resumenPedido;
  final String? instanciaWhatsapp;
  final String? origen;
  final Map<String, dynamic> metadata;
  final String? ubicacionGpsUrl;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  BotOrderModel({
    required this.id,
    this.botId,
    this.sourceBotId,
    required this.telefonoCliente,
    this.nombreCliente,
    this.productoServicio,
    this.tipoServicio,
    this.direccion,
    this.fechaDeseada,
    this.estadoPedido,
    this.resumenPedido,
    this.instanciaWhatsapp,
    this.origen,
    this.metadata = const {},
    this.ubicacionGpsUrl,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory BotOrderModel.fromJson(Map<String, dynamic> json) {
    return BotOrderModel(
      id: json['id'] ?? '',
      botId: json['bot_id'] ?? json['botId'],
      sourceBotId: json['source_bot_id'] ?? json['sourceBotId'],
      telefonoCliente:
          json['telefono_cliente'] ?? json['telefonoCliente'] ?? '',
      nombreCliente: json['nombre_cliente'] ?? json['nombreCliente'],
      productoServicio: json['producto_servicio'] ?? json['productoServicio'],
      tipoServicio: json['tipo_servicio'] ?? json['tipoServicio'] ?? 'otro',
      direccion: json['direccion'],
      fechaDeseada: json['fecha_deseada'] ?? json['fechaDeseada'],
      estadoPedido:
          json['estado_pedido'] ?? json['estadoPedido'] ?? 'pendiente',
      resumenPedido: json['resumen_pedido'] ?? json['resumenPedido'],
      instanciaWhatsapp:
          json['instancia_whatsapp'] ?? json['instanciaWhatsapp'],
      origen: json['origen'],
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : {},
      ubicacionGpsUrl: json['ubicacion_gps_url'] ?? json['ubicacionGpsUrl'],
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'])
          : (json['creadoEn'] != null
                ? DateTime.tryParse(json['creadoEn'])
                : null),
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.tryParse(json['actualizado_en'])
          : (json['actualizadoEn'] != null
                ? DateTime.tryParse(json['actualizadoEn'])
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'telefono_cliente': telefonoCliente,
      'nombre_cliente': nombreCliente,
      'producto_servicio': productoServicio,
      'tipo_servicio': tipoServicio,
      'direccion': direccion,
      'fecha_deseada': fechaDeseada,
      'estado_pedido': estadoPedido,
      'resumen_pedido': resumenPedido,
      'source_bot_id': sourceBotId,
      'instancia_whatsapp': instanciaWhatsapp,
      'origen': origen,
      'metadata': metadata,
      'ubicacion_gps_url': ubicacionGpsUrl,
    };
  }

  BotOrderModel copyWith({
    String? id,
    String? botId,
    String? sourceBotId,
    String? telefonoCliente,
    String? nombreCliente,
    String? productoServicio,
    String? tipoServicio,
    String? direccion,
    String? fechaDeseada,
    String? estadoPedido,
    String? resumenPedido,
    String? instanciaWhatsapp,
    String? origen,
    Map<String, dynamic>? metadata,
    String? ubicacionGpsUrl,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return BotOrderModel(
      id: id ?? this.id,
      botId: botId ?? this.botId,
      sourceBotId: sourceBotId ?? this.sourceBotId,
      telefonoCliente: telefonoCliente ?? this.telefonoCliente,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      productoServicio: productoServicio ?? this.productoServicio,
      tipoServicio: tipoServicio ?? this.tipoServicio,
      direccion: direccion ?? this.direccion,
      fechaDeseada: fechaDeseada ?? this.fechaDeseada,
      estadoPedido: estadoPedido ?? this.estadoPedido,
      resumenPedido: resumenPedido ?? this.resumenPedido,
      instanciaWhatsapp: instanciaWhatsapp ?? this.instanciaWhatsapp,
      origen: origen ?? this.origen,
      metadata: metadata ?? this.metadata,
      ubicacionGpsUrl: ubicacionGpsUrl ?? this.ubicacionGpsUrl,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
