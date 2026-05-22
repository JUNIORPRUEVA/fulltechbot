class BotModel {
  final String id;
  final String nombre;
  final String slug;
  final String? descripcion;
  final String? tipoNegocio;
  final String estado;
  final String? promptBase;
  final String? tono;
  final String? instrucciones;
  final String? reglasNegocio;
  final String? instanciaWhatsapp;
  final String? telefonoWhatsapp;
  final String? apiKeyChatGPT;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  BotModel({
    required this.id,
    required this.nombre,
    required this.slug,
    this.descripcion,
    this.tipoNegocio,
    required this.estado,
    this.promptBase,
    this.tono,
    this.instrucciones,
    this.reglasNegocio,
    this.instanciaWhatsapp,
    this.telefonoWhatsapp,
    this.apiKeyChatGPT,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory BotModel.fromJson(Map<String, dynamic> json) {
    return BotModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      tipoNegocio: json['tipoNegocio']?.toString(),
      estado: json['estado']?.toString() ?? 'activo',
      promptBase: json['promptBase']?.toString(),
      tono: json['tono']?.toString(),
      instrucciones: json['instrucciones']?.toString(),
      reglasNegocio: json['reglasNegocio']?.toString(),
      instanciaWhatsapp: json['instanciaWhatsapp']?.toString(),
      telefonoWhatsapp: json['telefonoWhatsapp']?.toString(),
      apiKeyChatGPT: json['apiKeyChatGPT']?.toString(),
      creadoEn: _toDateTime(json['creadoEn']),
      actualizadoEn: _toDateTime(json['actualizadoEn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'slug': slug,
      'descripcion': descripcion,
      'tipoNegocio': tipoNegocio,
      'promptBase': promptBase,
      'tono': tono,
      'instrucciones': instrucciones,
      'reglasNegocio': reglasNegocio,
      'instanciaWhatsapp': instanciaWhatsapp,
      'telefonoWhatsapp': telefonoWhatsapp,
      'apiKeyChatGPT': apiKeyChatGPT,
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
