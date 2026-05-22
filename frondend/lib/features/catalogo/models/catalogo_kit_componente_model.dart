class CatalogoKitComponenteModel {
  final String id;
  final String kitId;
  final String componenteId;
  final double cantidad;
  final bool incluido;
  final bool esOpcional;
  final String? nota;
  final int orden;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  // Datos del componente (producto)
  final String? titulo;
  final String? categoria;
  final String? tipoProducto;
  final String? descripcion;
  final String? informacion;
  final double? precio;
  final double? precioMinimo;
  final double? precioOferta;
  final int? stock;
  final String? imagen1;
  final String? imagen2;
  final String? imagen3;
  final String? video;

  CatalogoKitComponenteModel({
    required this.id,
    required this.kitId,
    required this.componenteId,
    this.cantidad = 1,
    this.incluido = true,
    this.esOpcional = false,
    this.nota,
    this.orden = 0,
    this.creadoEn,
    this.actualizadoEn,
    this.titulo,
    this.categoria,
    this.tipoProducto,
    this.descripcion,
    this.informacion,
    this.precio,
    this.precioMinimo,
    this.precioOferta,
    this.stock,
    this.imagen1,
    this.imagen2,
    this.imagen3,
    this.video,
  });

  factory CatalogoKitComponenteModel.fromJson(Map<String, dynamic> json) {
    return CatalogoKitComponenteModel(
      id: json['id'] as String? ?? '',
      kitId: json['kitId'] as String? ?? json['kit_id'] as String? ?? '',
      componenteId:
          json['componenteId'] as String? ?? json['componente_id'] as String? ?? '',
      cantidad: _toDouble(json['cantidad']),
      incluido: _toBool(json['incluido']),
      esOpcional: _toBool(json['esOpcional'] ?? json['es_opcional']),
      nota: json['nota'] as String?,
      orden: _toInt(json['orden']),
      creadoEn: _parseDate(json['creadoEn'] ?? json['creado_en']),
      actualizadoEn: _parseDate(json['actualizadoEn'] ?? json['actualizado_en']),
      titulo: json['titulo'] as String?,
      categoria: json['categoria'] as String?,
      tipoProducto:
          json['tipoProducto'] as String? ?? json['tipo_producto'] as String?,
      descripcion: json['descripcion'] as String?,
      informacion: json['informacion'] as String?,
      precio: _toDoubleNullable(json['precio']),
      precioMinimo: _toDoubleNullable(json['precioMinimo'] ?? json['precio_minimo']),
      precioOferta: _toDoubleNullable(json['precioOferta'] ?? json['precio_oferta']),
      stock: _toIntNullable(json['stock']),
      imagen1: json['imagen1'] as String?,
      imagen2: json['imagen2'] as String?,
      imagen3: json['imagen3'] as String?,
      video: json['video'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'componente_id': componenteId,
      'cantidad': cantidad,
      'incluido': incluido,
      'es_opcional': esOpcional,
      'nota': nota,
      'orden': orden,
    };
  }

  CatalogoKitComponenteModel copyWith({
    String? id,
    String? kitId,
    String? componenteId,
    double? cantidad,
    bool? incluido,
    bool? esOpcional,
    String? nota,
    int? orden,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
    String? titulo,
    String? categoria,
    String? tipoProducto,
    String? descripcion,
    String? informacion,
    double? precio,
    double? precioMinimo,
    double? precioOferta,
    int? stock,
    String? imagen1,
    String? imagen2,
    String? imagen3,
    String? video,
  }) {
    return CatalogoKitComponenteModel(
      id: id ?? this.id,
      kitId: kitId ?? this.kitId,
      componenteId: componenteId ?? this.componenteId,
      cantidad: cantidad ?? this.cantidad,
      incluido: incluido ?? this.incluido,
      esOpcional: esOpcional ?? this.esOpcional,
      nota: nota ?? this.nota,
      orden: orden ?? this.orden,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      titulo: titulo ?? this.titulo,
      categoria: categoria ?? this.categoria,
      tipoProducto: tipoProducto ?? this.tipoProducto,
      descripcion: descripcion ?? this.descripcion,
      informacion: informacion ?? this.informacion,
      precio: precio ?? this.precio,
      precioMinimo: precioMinimo ?? this.precioMinimo,
      precioOferta: precioOferta ?? this.precioOferta,
      stock: stock ?? this.stock,
      imagen1: imagen1 ?? this.imagen1,
      imagen2: imagen2 ?? this.imagen2,
      imagen3: imagen3 ?? this.imagen3,
      video: video ?? this.video,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return false;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
