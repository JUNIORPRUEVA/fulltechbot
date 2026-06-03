import '../../../core/constants/api_config.dart';
import '../../../core/utils/image_utils.dart';

class ResolvedStorefrontImage {
  final String value;
  final bool isAsset;

  const ResolvedStorefrontImage({required this.value, required this.isAsset});

  bool get isNetwork => !isAsset && value.isNotEmpty;
  bool get isEmpty => value.isEmpty;
}

class StorefrontImageResolver {
  /// Resuelve una URL de imagen aplicando versionado automático
  /// basado en el campo `actualizadoEn` del producto si está disponible.
  static ResolvedStorefrontImage? resolve(dynamic rawValue, {String? version}) {
    if (rawValue == null) {
      return null;
    }

    final clean = rawValue.toString().trim();
    if (clean.isEmpty || clean.toLowerCase() == 'null') {
      return null;
    }

    if (_isAbsoluteUrl(clean)) {
      return ResolvedStorefrontImage(
        value: _addVersion(clean, version),
        isAsset: false,
      );
    }

    if (_isAssetPath(clean)) {
      return ResolvedStorefrontImage(value: clean, isAsset: true);
    }

    final normalized = clean
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/+'), '');
    if (normalized.isEmpty) {
      return null;
    }

    final absolute = _resolveRelativeUrl(normalized, rawValue: clean);

    return ResolvedStorefrontImage(
      value: _addVersion(absolute, version),
      isAsset: false,
    );
  }

  /// Versión simple que solo devuelve la URL como String.
  static String? resolveUrl(dynamic rawValue, {String? version}) {
    final resolved = resolve(rawValue, version: version);
    if (resolved == null || resolved.isAsset) {
      return resolved?.value;
    }
    return resolved.value;
  }

  /// Resuelve una galería de imágenes aplicando versionado.
  static List<String> resolveGallery(
    Iterable<dynamic> values, {
    String? version,
  }) {
    return values
        .map((item) => resolve(item, version: version))
        .whereType<ResolvedStorefrontImage>()
        .map((item) => item.value)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
  }

  /// Extrae la versión (updatedAt) de un mapa de producto.
  static String? extractVersion(Map<String, dynamic>? product) {
    if (product == null) return null;
    return getProductVersion(product);
  }

  static String _addVersion(String url, String? version) {
    return buildImageUrl(url, version: version);
  }

  static bool _isAbsoluteUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('data:');
  }

  static bool _isAssetPath(String value) {
    final normalized = value.replaceAll('\\', '/').toLowerCase();
    return normalized.startsWith('assets/') || normalized.startsWith('web/');
  }

  static String _resolveRelativeUrl(
    String normalized, {
    required String rawValue,
  }) {
    if (normalized.startsWith('api/storage/file/')) {
      return _join(ApiConfig.apiBaseUrl, normalized);
    }

    if (normalized.startsWith('api/')) {
      return _join(ApiConfig.apiBaseUrl, normalized);
    }

    final storageKey = _normalizeStorageKey(normalized);
    if (storageKey != null) {
      return _join('${ApiConfig.apiBaseUrl}/api/storage/file', storageKey);
    }

    if (rawValue.startsWith('/')) {
      return _join(ApiConfig.apiBaseUrl, normalized);
    }

    if (ApiConfig.storagePublicUrl.trim().isNotEmpty) {
      return _join(ApiConfig.storagePublicUrl, normalized);
    }

    return _join(ApiConfig.apiBaseUrl, normalized);
  }

  static String? _normalizeStorageKey(String value) {
    final normalized = value
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/+'), '');
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('data:')) {
      return null;
    }

    if (normalized.startsWith('api/storage/file/')) {
      return normalized.replaceFirst('api/storage/file/', '');
    }

    if (normalized.startsWith('uploads/')) {
      return normalized.replaceFirst('uploads/', '');
    }

    if (normalized.startsWith('catalogo/') ||
        normalized.startsWith('storefront/')) {
      return normalized;
    }

    return null;
  }

  static String _join(String base, String path) {
    final safeBase = base.replaceAll(RegExp(r'/+$'), '');
    final safePath = path.replaceAll(RegExp(r'^/+'), '');
    return '$safeBase/$safePath';
  }
}
