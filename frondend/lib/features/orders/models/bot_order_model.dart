class BotOrderModel {
  final String id;
  final String? botId;
  final String telefonoCliente;
  final String? nombreCliente;
  final String? productoServicio;
  final String? tipoServicio;
  final String? direccion;
  final String? fechaDeseada;
  final String? estadoPedido;
  final String? resumenPedido;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  BotOrderModel({
    required this.id,
    this.botId,
    required this.telefonoCliente,
    this.nombreCliente,
    this.productoServicio,
    this.tipoServicio,
    this.direccion,
    this.fechaDeseada,
    this.estadoPedido,
    this.resumenPedido,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory BotOrderModel.fromJson(Map<String, dynamic> json) {
    return BotOrderModel(
      id: json['id'] ?? '',
      botId: json['bot_id'] ?? json['botId'],
      telefonoCliente: json['telefono_cliente'] ?? json['telefonoCliente'] ?? '',
      nombreCliente: json['nombre_cliente'] ?? json['nombreCliente'],
      productoServicio: json['producto_servicio'] ?? json['productoServicio'],
      tipoServicio: json['tipo_servicio'] ?? json['tipoServicio'] ?? 'otro',
      direccion: json['direccion'],
      fechaDeseada: json['fecha_deseada'] ?? json['fechaDeseada'],
      estadoPedido: json['estado_pedido'] ?? json['estadoPedido'] ?? 'pendiente',
      resumenPedido: json['resumen_pedido'] ?? json['resumenPedido'],
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'])
          : (json['creadoEn'] != null ? DateTime.tryParse(json['creadoEn']) : null),
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.tryParse(json['actualizado_en'])
          : (json['actualizadoEn'] != null ? DateTime.tryParse(json['actualizadoEn']) : null),
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
    };
  }

  BotOrderModel copyWith({
    String? id,
    String? botId,
    String? telefonoCliente,
    String? nombreCliente,
    String? productoServicio,
    String? tipoServicio,
    String? direccion,
    String? fechaDeseada,
    String? estadoPedido,
    String? resumenPedido,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return BotOrderModel(
      id: id ?? this.id,
      botId: botId ?? this.botId,
      telefonoCliente: telefonoCliente ?? this.telefonoCliente,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      productoServicio: productoServicio ?? this.productoServicio,
      tipoServicio: tipoServicio ?? this.tipoServicio,
      direccion: direccion ?? this.direccion,
      fechaDeseada: fechaDeseada ?? this.fechaDeseada,
      estadoPedido: estadoPedido ?? this.estadoPedido,
      resumenPedido: resumenPedido ?? this.resumenPedido,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
