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
    return resolveForDisplay(rawValue, version: version);
  }

  static ResolvedStorefrontImage? resolveForDisplay(
    dynamic rawValue, {
    String? version,
    int? width,
    int? height,
    int quality = 72,
    String format = 'webp',
    String fit = 'inside',
  }) {
    if (rawValue == null) {
      return null;
    }

    final clean = rawValue.toString().trim();
    if (clean.isEmpty || clean.toLowerCase() == 'null') {
      return null;
    }

    if (_isAbsoluteUrl(clean)) {
      return ResolvedStorefrontImage(
        value: _optimize(
          clean,
          version: version,
          width: width,
          height: height,
          quality: quality,
          format: format,
          fit: fit,
        ),
        isAsset: false,
      );
    }

    if (_isAssetPath(clean)) {
      return ResolvedStorefrontImage(value: clean, isAsset: true);
    }

    final normalized = clean.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
    if (normalized.isEmpty) {
      return null;
    }

    String absolute;
    if (_startsWithApiPath(normalized) || clean.startsWith('/')) {
      absolute = _join(ApiConfig.apiBaseUrl, normalized);
    } else if (ApiConfig.storagePublicUrl.trim().isNotEmpty) {
      absolute = _join(ApiConfig.storagePublicUrl, normalized);
    } else {
      absolute = _join('${ApiConfig.apiBaseUrl}/api/storage/file', normalized);
    }

    return ResolvedStorefrontImage(
      value: _optimize(
        absolute,
        version: version,
        width: width,
        height: height,
        quality: quality,
        format: format,
        fit: fit,
      ),
      isAsset: false,
    );
  }

  /// Versión simple que solo devuelve la URL como String.
  static String? resolveUrl(
    dynamic rawValue, {
    String? version,
    int? width,
    int? height,
    int quality = 72,
    String format = 'webp',
    String fit = 'inside',
  }) {
    final resolved = resolveForDisplay(
      rawValue,
      version: version,
      width: width,
      height: height,
      quality: quality,
      format: format,
      fit: fit,
    );
    if (resolved == null || resolved.isAsset) {
      return resolved?.value;
    }
    return resolved.value;
  }

  /// Resuelve una galería de imágenes aplicando versionado.
  static List<String> resolveGallery(
    Iterable<dynamic> values, {
    String? version,
    int? width,
    int? height,
    int quality = 72,
    String format = 'webp',
    String fit = 'inside',
  }) {
    return values
        .map(
          (item) => resolveForDisplay(
            item,
            version: version,
            width: width,
            height: height,
            quality: quality,
            format: format,
            fit: fit,
          ),
        )
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

  static String _optimize(
    String url, {
    String? version,
    int? width,
    int? height,
    int quality = 72,
    String format = 'webp',
    String fit = 'inside',
  }) {
    return buildOptimizedImageUrl(
      url,
      version: version,
      width: width,
      height: height,
      quality: quality,
      format: format,
      fit: fit,
    );
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

  static bool _startsWithApiPath(String value) {
    return value.startsWith('uploads/') ||
        value.startsWith('api/') ||
        value.startsWith('catalogo/') ||
        value.startsWith('storefront/');
  }

  static String _join(String base, String path) {
    final safeBase = base.replaceAll(RegExp(r'/+$'), '');
    final safePath = path.replaceAll(RegExp(r'^/+'), '');
    return '$safeBase/$safePath';
  }
}
