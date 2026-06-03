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

String buildOptimizedImageUrl(
  String? url, {
  String? version,
  String? baseUrl,
  int? width,
  int? height,
  int quality = 72,
  String format = 'webp',
  String fit = 'inside',
}) {
  final resolved = buildImageUrl(url, version: version, baseUrl: baseUrl);
  if (resolved.isEmpty) {
    return '';
  }

  if (!_canOptimizeThroughStorageProxy(resolved)) {
    return resolved;
  }

  final uri = Uri.parse(resolved);
  final marker = '/api/storage/file/';
  final markerIndex = uri.path.indexOf(marker);
  if (markerIndex == -1) {
    return resolved;
  }

  final key = uri.path.substring(markerIndex + marker.length);
  if (key.isEmpty) {
    return resolved;
  }

  final query = <String, String>{};
  if (width != null && width > 0) {
    query['w'] = width.toString();
  }
  if (height != null && height > 0) {
    query['h'] = height.toString();
  }
  if (quality > 0) {
    query['q'] = quality.toString();
  }
  if (format.isNotEmpty) {
    query['format'] = format;
  }
  if (fit.isNotEmpty) {
    query['fit'] = fit;
  }
  if (version != null && version.isNotEmpty) {
    query['v'] = version;
  }

  return uri.replace(
    path: '${uri.path.substring(0, markerIndex)}/api/storage/image/$key',
    queryParameters: query,
  ).toString();
}

/// Agrega parámetro de versión a una URL para evitar cache del navegador.
String _addVersionParam(String url, String? version) {
  if (version == null || version.isEmpty) return url;
  
  final separator = url.contains('?') ? '&' : '?';
  return '$url${separator}v=$version';
}

bool _canOptimizeThroughStorageProxy(String url) {
  return url.contains('/api/storage/file/');
}

/// Obtiene la versión (updatedAt) de un producto para usar en URLs de imágenes.
String? getProductVersion(Map<String, dynamic> product) {
  return product['actualizadoEn']?.toString() ??
         product['updatedAt']?.toString() ??
         product['creadoEn']?.toString() ??
         product['imageVersion']?.toString();
}
