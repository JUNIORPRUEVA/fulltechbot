import '../../../core/constants/api_config.dart';

/// Helper central para construir URLs de imágenes con versionado automático.
/// 
/// Uso:
/// ```dart
/// buildImageUrl(product['imagen1'], version: product['actualizadoEn']);
/// buildImageUrl('uploads/producto.jpg', version: '2024-01-01T00:00:00Z');
/// ```
String buildImageUrl(String? url, {String? version, String? baseUrl}) {
  if (url == null || url.trim().isEmpty || url == 'null') return '';
  
  final clean = url.trim();
  
  // Si ya es URL absoluta, usarla directamente
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return _addVersionParam(clean, version);
  }
  
  // Si es asset local, devolver sin cambios
  if (clean.startsWith('assets/') || clean.startsWith('web/')) {
    return clean;
  }
  
  // Construir URL absoluta
  final base = baseUrl ?? ApiConfig.baseUrl;
  final normalized = clean.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
  final absolute = '$base/$normalized';
  
  return _addVersionParam(absolute, version);
}

/// Agrega parámetro de versión a una URL para evitar cache del navegador.
String _addVersionParam(String url, String? version) {
  if (version == null || version.isEmpty) return url;
  
  final separator = url.contains('?') ? '&' : '?';
  return '$url${separator}v=$version';
}

/// Obtiene la versión (updatedAt) de un producto para usar en URLs de imágenes.
String? getProductVersion(Map<String, dynamic> product) {
  return product['actualizadoEn']?.toString() ??
         product['updatedAt']?.toString() ??
         product['creadoEn']?.toString() ??
         product['imageVersion']?.toString();
}
