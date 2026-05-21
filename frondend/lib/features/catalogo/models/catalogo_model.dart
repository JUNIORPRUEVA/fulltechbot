class CatalogoModel {
  final String id;
  final String titulo;
  final String categoria;
  final String? descripcion;
  final String? informacion;
  final double precio;
  final double? precioMinimo;
  final double? precioOferta;
  final int stock;
  final String? imagen1;
  final String? imagen2;
  final String? imagen3;
  final String? video;
  final String? palabrasClave;
  final String? reglasNegociacion;
  final String estado;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  CatalogoModel({
    required this.id,
    required this.titulo,
    required this.categoria,
    this.descripcion,
    this.informacion,
    required this.precio,
    this.precioMinimo,
    this.precioOferta,
    required this.stock,
    this.imagen1,
    this.imagen2,
    this.imagen3,
    this.video,
    this.palabrasClave,
    this.reglasNegociacion,
    required this.estado,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory CatalogoModel.fromJson(Map<String, dynamic> json) {
    return CatalogoModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      informacion: json['informacion']?.toString(),
      precio: _toDouble(json['precio']),
      precioMinimo: _toNullableDouble(json['precioMinimo']),
      precioOferta: _toNullableDouble(json['precioOferta']),
      stock: _toInt(json['stock']),
      imagen1: json['imagen1']?.toString(),
      imagen2: json['imagen2']?.toString(),
      imagen3: json['imagen3']?.toString(),
      video: json['video']?.toString(),
      palabrasClave: json['palabrasClave']?.toString(),
      reglasNegociacion: json['reglasNegociacion']?.toString(),
      estado: json['estado']?.toString() ?? 'activo',
      creadoEn: _toDateTime(json['creadoEn']),
      actualizadoEn: _toDateTime(json['actualizadoEn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'categoria': categoria,
      'descripcion': descripcion,
      'informacion': informacion,
      'precio': precio,
      'precioMinimo': precioMinimo,
      'precioOferta': precioOferta,
      'stock': stock,
      'imagen1': imagen1,
      'imagen2': imagen2,
      'imagen3': imagen3,
      'video': video,
      'palabrasClave': palabrasClave,
      'reglasNegociacion': reglasNegociacion,
      'estado': estado,
    };
  }

  CatalogoModel copyWith({
    String? id,
    String? titulo,
    String? categoria,
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
    String? palabrasClave,
    String? reglasNegociacion,
    String? estado,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return CatalogoModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      categoria: categoria ?? this.categoria,
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
      palabrasClave: palabrasClave ?? this.palabrasClave,
      reglasNegociacion: reglasNegociacion ?? this.reglasNegociacion,
      estado: estado ?? this.estado,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}