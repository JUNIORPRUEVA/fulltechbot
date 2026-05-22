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

  // === CAMPOS NUEVOS: productos inteligentes ===
  final String tipoProducto;
  final String? incluye;
  final bool permiteAdicionales;
  final bool esCotizable;
  final int orden;
  final int cantidadBase;
  final String? unidadAdicionalNombre;
  final double precioAdicional;
  final double precioMinimoAdicional;
  final bool permiteCalculoAdicional;
  final String ciudadBase;
  final double cargoFueraCiudad;
  final bool aplicaCargoFueraCiudad;
  final bool instalacionIncluida;
  final Map<String, dynamic> reglasCalculo;

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
    // Campos nuevos con defaults
    this.tipoProducto = 'producto',
    this.incluye,
    this.permiteAdicionales = false,
    this.esCotizable = true,
    this.orden = 0,
    this.cantidadBase = 1,
    this.unidadAdicionalNombre,
    this.precioAdicional = 0,
    this.precioMinimoAdicional = 0,
    this.permiteCalculoAdicional = false,
    this.ciudadBase = 'Higüey',
    this.cargoFueraCiudad = 0,
    this.aplicaCargoFueraCiudad = false,
    this.instalacionIncluida = false,
    this.reglasCalculo = const {},
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
      // Campos nuevos - soporta camelCase y snake_case
      tipoProducto: _readString(json, 'tipoProducto', 'tipo_producto') ?? 'producto',
      incluye: _readString(json, 'incluye', 'incluye'),
      permiteAdicionales: _readBool(json, 'permiteAdicionales', 'permite_adicionales'),
      esCotizable: _readBool(json, 'esCotizable', 'es_cotizable'),
      orden: _readInt(json, 'orden', 'orden'),
      cantidadBase: _readInt(json, 'cantidadBase', 'cantidad_base'),
      unidadAdicionalNombre: _readString(json, 'unidadAdicionalNombre', 'unidad_adicional_nombre'),
      precioAdicional: _readDouble(json, 'precioAdicional', 'precio_adicional'),
      precioMinimoAdicional: _readDouble(json, 'precioMinimoAdicional', 'precio_minimo_adicional'),
      permiteCalculoAdicional: _readBool(json, 'permiteCalculoAdicional', 'permite_calculo_adicional'),
      ciudadBase: _readString(json, 'ciudadBase', 'ciudad_base') ?? 'Higüey',
      cargoFueraCiudad: _readDouble(json, 'cargoFueraCiudad', 'cargo_fuera_ciudad'),
      aplicaCargoFueraCiudad: _readBool(json, 'aplicaCargoFueraCiudad', 'aplica_cargo_fuera_ciudad'),
      instalacionIncluida: _readBool(json, 'instalacionIncluida', 'instalacion_incluida'),
      reglasCalculo: _readMap(json, 'reglasCalculo', 'reglas_calculo'),
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
      // Campos nuevos
      'tipoProducto': tipoProducto,
      'incluye': incluye,
      'permiteAdicionales': permiteAdicionales,
      'esCotizable': esCotizable,
      'orden': orden,
      'cantidadBase': cantidadBase,
      'unidadAdicionalNombre': unidadAdicionalNombre,
      'precioAdicional': precioAdicional,
      'precioMinimoAdicional': precioMinimoAdicional,
      'permiteCalculoAdicional': permiteCalculoAdicional,
      'ciudadBase': ciudadBase,
      'cargoFueraCiudad': cargoFueraCiudad,
      'aplicaCargoFueraCiudad': aplicaCargoFueraCiudad,
      'instalacionIncluida': instalacionIncluida,
      'reglasCalculo': reglasCalculo,
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
    String? tipoProducto,
    String? incluye,
    bool? permiteAdicionales,
    bool? esCotizable,
    int? orden,
    int? cantidadBase,
    String? unidadAdicionalNombre,
    double? precioAdicional,
    double? precioMinimoAdicional,
    bool? permiteCalculoAdicional,
    String? ciudadBase,
    double? cargoFueraCiudad,
    bool? aplicaCargoFueraCiudad,
    bool? instalacionIncluida,
    Map<String, dynamic>? reglasCalculo,
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
      tipoProducto: tipoProducto ?? this.tipoProducto,
      incluye: incluye ?? this.incluye,
      permiteAdicionales: permiteAdicionales ?? this.permiteAdicionales,
      esCotizable: esCotizable ?? this.esCotizable,
      orden: orden ?? this.orden,
      cantidadBase: cantidadBase ?? this.cantidadBase,
      unidadAdicionalNombre: unidadAdicionalNombre ?? this.unidadAdicionalNombre,
      precioAdicional: precioAdicional ?? this.precioAdicional,
      precioMinimoAdicional: precioMinimoAdicional ?? this.precioMinimoAdicional,
      permiteCalculoAdicional: permiteCalculoAdicional ?? this.permiteCalculoAdicional,
      ciudadBase: ciudadBase ?? this.ciudadBase,
      cargoFueraCiudad: cargoFueraCiudad ?? this.cargoFueraCiudad,
      aplicaCargoFueraCiudad: aplicaCargoFueraCiudad ?? this.aplicaCargoFueraCiudad,
      instalacionIncluida: instalacionIncluida ?? this.instalacionIncluida,
      reglasCalculo: reglasCalculo ?? this.reglasCalculo,
    );
  }

  // === HELPERS ===

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

  static String? _readString(Map<String, dynamic> json, String camelKey, String snakeKey) {
    return json[camelKey]?.toString() ?? json[snakeKey]?.toString();
  }

  static bool _readBool(Map<String, dynamic> json, String camelKey, String snakeKey) {
    final value = json[camelKey] ?? json[snakeKey];
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static int _readInt(Map<String, dynamic> json, String camelKey, String snakeKey) {
    final value = json[camelKey] ?? json[snakeKey];
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _readDouble(Map<String, dynamic> json, String camelKey, String snakeKey) {
    final value = json[camelKey] ?? json[snakeKey];
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static Map<String, dynamic> _readMap(Map<String, dynamic> json, String camelKey, String snakeKey) {
    final value = json[camelKey] ?? json[snakeKey];
    if (value == null) return {};
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }
}
