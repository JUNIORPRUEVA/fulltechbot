import 'package:shared_preferences/shared_preferences.dart';
import 'storefront_image_resolver.dart';

class StorefrontHelpers {
  static String? resolveMediaUrl(dynamic value) {
    return StorefrontImageResolver.resolve(value)?.value;
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

  static String? getPrimaryImage(Map<String, dynamic> product) {
    final image =
        product['imagen_destacada_url'] ??
        product['imagen1'] ??
        product['imagen2'] ??
        product['imagen3'];
    return StorefrontImageResolver.resolveUrl(image);
  }

  static List<String> getGallery(Map<String, dynamic> product) {
    final dynamic gallery = product['gallery'];
    if (gallery is List) {
      return StorefrontImageResolver.resolveGallery(gallery);
    }

    return StorefrontImageResolver.resolveGallery([
          product['imagen_destacada_url'],
          product['imagen1'],
          product['imagen2'],
          product['imagen3'],
        ]);
  }

  static num? _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }
}
