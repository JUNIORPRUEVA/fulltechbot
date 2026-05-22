class BotQuotationModel {
  final String id;
  final String? botId;
  final String numeroCotizacion;
  final String telefonoCliente;
  final String? nombreCliente;
  final String? direccionCliente;
  final String? ciudad;
  final String? sector;
  final String? titulo;
  final String? descripcionGeneral;
  final List<dynamic>? productos;
  final double subtotal;
  final double descuento;
  final double total;
  final String moneda;
  final String estado;
  final String? pdfUrl;
  final String? observaciones;
  final String? condiciones;
  final DateTime? validaHasta;
  final String? creadaPor;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  BotQuotationModel({
    required this.id,
    this.botId,
    required this.numeroCotizacion,
    required this.telefonoCliente,
    this.nombreCliente,
    this.direccionCliente,
    this.ciudad,
    this.sector,
    this.titulo,
    this.descripcionGeneral,
    this.productos,
    this.subtotal = 0,
    this.descuento = 0,
    this.total = 0,
    this.moneda = 'DOP',
    this.estado = 'pendiente',
    this.pdfUrl,
    this.observaciones,
    this.condiciones,
    this.validaHasta,
    this.creadaPor,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory BotQuotationModel.fromJson(Map<String, dynamic> json) {
    return BotQuotationModel(
      id: json['id'] ?? '',
      botId: json['bot_id'] ?? json['botId'],
      numeroCotizacion: json['numero_cotizacion'] ?? json['numeroCotizacion'] ?? '',
      telefonoCliente: json['telefono_cliente'] ?? json['telefonoCliente'] ?? '',
      nombreCliente: json['nombre_cliente'] ?? json['nombreCliente'],
      direccionCliente: json['direccion_cliente'] ?? json['direccionCliente'],
      ciudad: json['ciudad'],
      sector: json['sector'],
      titulo: json['titulo'] ?? 'Cotización de servicios',
      descripcionGeneral: json['descripcion_general'] ?? json['descripcionGeneral'],
      productos: json['productos'] ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      descuento: (json['descuento'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      moneda: json['moneda'] ?? 'DOP',
      estado: json['estado'] ?? 'pendiente',
      pdfUrl: json['pdf_url'] ?? json['pdfUrl'],
      observaciones: json['observaciones'],
      condiciones: json['condiciones'],
      validaHasta: json['valida_hasta'] != null
          ? DateTime.tryParse(json['valida_hasta'])
          : (json['validaHasta'] != null ? DateTime.tryParse(json['validaHasta']) : null),
      creadaPor: json['creada_por'] ?? json['creadaPor'] ?? 'bot',
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
      'numero_cotizacion': numeroCotizacion,
      'telefono_cliente': telefonoCliente,
      'nombre_cliente': nombreCliente,
      'direccion_cliente': direccionCliente,
      'ciudad': ciudad,
      'sector': sector,
      'titulo': titulo,
      'descripcion_general': descripcionGeneral,
      'productos': productos ?? [],
      'subtotal': subtotal,
      'descuento': descuento,
      'total': total,
      'moneda': moneda,
      'estado': estado,
      'pdf_url': pdfUrl,
      'observaciones': observaciones,
      'condiciones': condiciones,
      'valida_hasta': validaHasta?.toIso8601String(),
      'creada_por': creadaPor,
    };
  }

  BotQuotationModel copyWith({
    String? id,
    String? botId,
    String? numeroCotizacion,
    String? telefonoCliente,
    String? nombreCliente,
    String? direccionCliente,
    String? ciudad,
    String? sector,
    String? titulo,
    String? descripcionGeneral,
    List<dynamic>? productos,
    double? subtotal,
    double? descuento,
    double? total,
    String? moneda,
    String? estado,
    String? pdfUrl,
    String? observaciones,
    String? condiciones,
    DateTime? validaHasta,
    String? creadaPor,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return BotQuotationModel(
      id: id ?? this.id,
      botId: botId ?? this.botId,
      numeroCotizacion: numeroCotizacion ?? this.numeroCotizacion,
      telefonoCliente: telefonoCliente ?? this.telefonoCliente,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      direccionCliente: direccionCliente ?? this.direccionCliente,
      ciudad: ciudad ?? this.ciudad,
      sector: sector ?? this.sector,
      titulo: titulo ?? this.titulo,
      descripcionGeneral: descripcionGeneral ?? this.descripcionGeneral,
      productos: productos ?? this.productos,
      subtotal: subtotal ?? this.subtotal,
      descuento: descuento ?? this.descuento,
      total: total ?? this.total,
      moneda: moneda ?? this.moneda,
      estado: estado ?? this.estado,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      observaciones: observaciones ?? this.observaciones,
      condiciones: condiciones ?? this.condiciones,
      validaHasta: validaHasta ?? this.validaHasta,
      creadaPor: creadaPor ?? this.creadaPor,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
