import 'package:shared_preferences/shared_preferences.dart';
import 'storefront_image_resolver.dart';

class StorefrontHelpers {
  /// Obtiene la versión (updatedAt) de un producto para versionado de imágenes.
  static String? getProductVersion(Map<String, dynamic> product) {
    return product['actualizadoEn']?.toString() ??
           product['updatedAt']?.toString() ??
           product['creadoEn']?.toString() ??
           product['imageVersion']?.toString();
  }


  static String? resolveMediaUrl(dynamic value, {String? version}) {
    return StorefrontImageResolver.resolve(value, version: version)?.value;
  }

  static String? normalizeImageUrl(dynamic value, {String? version}) {
    final resolved = StorefrontImageResolver.resolveUrl(value, version: version);
    if (resolved == null) {
      return null;
    }

    final clean = resolved.trim();
    return clean.isEmpty ? null : clean;
  }

  static Future<String> ensureSessionId(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'storefront_session_$slug';
    var sessionId = prefs.getString(key);
    if (sessionId != null && sessionId.isNotEmpty) {
      return sessionId;
    }

    sessionId = '${slug}_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(key, sessionId);
    return sessionId;
  }

  static num getEffectivePrice(Map<String, dynamic> product) {
    return getDisplayPrice(product) ?? 0;
  }

  static num? getDisplayPrice(Map<String, dynamic> product) {
    final offerPrice = _toNum(product['precio_oferta_web'] ?? product['precioOferta']);
    if (offerPrice != null && offerPrice > 0) {
      return offerPrice;
    }

    final regularPrice = _toNum(product['precio']);
    if (regularPrice != null && regularPrice > 0) {
      return regularPrice;
    }

    return null;
  }

  static num? getOriginalPrice(Map<String, dynamic> product) {
    final original = _toNum(product['precio']);
    final actual = getDisplayPrice(product);
    if (original == null || actual == null || original <= actual) return null;
    return original;
  }

  static String getShortDescription(
    Map<String, dynamic> product, {
    String fallback = 'Producto disponible en tienda',
  }) {
    final candidates = [
      product['descripcion_corta'],
      product['descripcion_web'],
      product['descripcion'],
      product['informacion'],
      product['detalle'],
    ];

    for (final candidate in candidates) {
      final clean = candidate?.toString().trim() ?? '';
      if (clean.isNotEmpty && clean.toLowerCase() != 'null') {
        return clean;
      }
    }

    return fallback;
  }

  /// Obtiene la imagen principal con versionado automático.
  static String? getPrimaryImage(Map<String, dynamic> product) {
    final images = getProductImages(product);
    return images.isEmpty ? null : images.first;
  }

  static List<String> getGallery(Map<String, dynamic> product) {
    return getProductImages(product);
  }

  /// Obtiene todas las imágenes del producto con versionado automático.
  static List<String> getProductImages(Map<String, dynamic> product) {
    final version = getProductVersion(product);
    final rawImages = <dynamic>[
      product['imagen_destacada_url'],
      product['imageUrl'],
      product['image'],
      product['foto'],
      product['imagen1'],
      product['imagen2'],
      product['imagen3'],
    ];

    final gallery = product['gallery'];
    if (gallery is Iterable) {
      rawImages.addAll(gallery);
    }

    final images = product['images'];
    if (images is Iterable) {
      rawImages.addAll(images);
    }

    final mediaUrls = product['media_urls'];
    if (mediaUrls is Iterable) {
      rawImages.addAll(mediaUrls);
    }

    return StorefrontImageResolver.resolveGallery(rawImages, version: version);
  }

  static num? _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }
}
