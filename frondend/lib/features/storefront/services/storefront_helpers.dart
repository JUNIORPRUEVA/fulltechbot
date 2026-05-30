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
    return _toNum(
          product['precio_oferta_web'] ??
              product['precioOferta'] ??
              product['precio'],
        ) ??
        0;
  }

  static num? getOriginalPrice(Map<String, dynamic> product) {
    final original = _toNum(product['precio']);
    final actual = getEffectivePrice(product);
    if (original == null || original <= actual) return null;
    return original;
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

