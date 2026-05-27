import '../../../core/constants/api_config.dart';

class ResolvedStorefrontImage {
  final String value;
  final bool isAsset;

  const ResolvedStorefrontImage({
    required this.value,
    required this.isAsset,
  });

  bool get isNetwork => !isAsset && value.isNotEmpty;
  bool get isEmpty => value.isEmpty;
}

class StorefrontImageResolver {
  static ResolvedStorefrontImage? resolve(dynamic rawValue) {
    if (rawValue == null) {
      return null;
    }

    final clean = rawValue.toString().trim();
    if (clean.isEmpty) {
      return null;
    }

    if (_isAbsoluteUrl(clean)) {
      return ResolvedStorefrontImage(value: clean, isAsset: false);
    }

    if (_isAssetPath(clean)) {
      return ResolvedStorefrontImage(value: clean, isAsset: true);
    }

    final normalized = clean.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
    if (normalized.isEmpty) {
      return null;
    }

    if (_startsWithApiPath(normalized) || clean.startsWith('/')) {
      return ResolvedStorefrontImage(
        value: _join(ApiConfig.apiBaseUrl, normalized),
        isAsset: false,
      );
    }

    if (ApiConfig.storagePublicUrl.trim().isNotEmpty) {
      return ResolvedStorefrontImage(
        value: _join(ApiConfig.storagePublicUrl, normalized),
        isAsset: false,
      );
    }

    return ResolvedStorefrontImage(
      value: _join('${ApiConfig.apiBaseUrl}/api/storage/file', normalized),
      isAsset: false,
    );
  }

  static String? resolveUrl(dynamic rawValue) {
    final resolved = resolve(rawValue);
    if (resolved == null || resolved.isAsset) {
      return resolved?.value;
    }
    return resolved.value;
  }

  static List<String> resolveGallery(Iterable<dynamic> values) {
    return values
        .map(resolve)
        .whereType<ResolvedStorefrontImage>()
        .map((item) => item.value)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
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
