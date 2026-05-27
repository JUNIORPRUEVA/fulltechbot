import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';

class StorefrontHelpers {
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
    if (image == null) return null;
    final text = image.toString().trim();
    if (text.isEmpty) return null;

    // Normalizar: si la URL es relativa (p. ej. "/uploads/.." o "uploads/..")
    // prefijar el baseUrl del API para que apunte al backend en producción.
    final lower = text.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return text;
    }

    final clean = text.replaceAll(RegExp(r'^/+'), '');
    if (clean.isEmpty) return null;

    // Si la ruta ya contiene 'uploads/' o 'api/storage', la convertimos en absoluta
    if (clean.startsWith('uploads/') || clean.startsWith('api/storage/') || clean.startsWith('api/')) {
      final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
      return '$base/${clean}';
    }

    // Si no tiene esquema ni paths conocidos, lo devolvemos tal cual
    return text;
  }

  static List<String> getGallery(Map<String, dynamic> product) {
    final dynamic gallery = product['gallery'];
    if (gallery is List) {
      return gallery
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .map((item) {
            final text = item.trim();
            if (text.toLowerCase().startsWith('http')) return text;
            final clean = text.replaceAll(RegExp(r'^/+'), '');
            if (clean.startsWith('uploads/') || clean.startsWith('api/storage/') || clean.startsWith('api/')) {
              final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
              return '$base/${clean}';
            }
            return text;
          })
          .toList();
    }

    return [
          product['imagen_destacada_url'],
          product['imagen1'],
          product['imagen2'],
          product['imagen3'],
        ]
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .map((text) {
          if (text.toLowerCase().startsWith('http')) return text;
          final clean = text.replaceAll(RegExp(r'^/+'), '');
          if (clean.startsWith('uploads/') || clean.startsWith('api/storage/') || clean.startsWith('api/')) {
            final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
            return '$base/${clean}';
          }
          return text;
        })
        .toSet()
        .toList();
  }

  static num? _toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }
}
