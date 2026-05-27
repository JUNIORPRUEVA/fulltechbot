import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';

class StorefrontApiService {
  static final String _baseUrl = '${ApiConfig.baseUrl}/api/storefront';

  // ============================================
  // PÚBLICAS
  // ============================================

  /// Obtener configuración de la tienda por slug
  static Future<Map<String, dynamic>> getConfig(String slug) async {
    final res = await http.get(Uri.parse('$_baseUrl/$slug/config'));
    return jsonDecode(res.body);
  }

  /// Obtener banners activos
  static Future<Map<String, dynamic>> getBanners(String slug) async {
    final res = await http.get(Uri.parse('$_baseUrl/$slug/banners'));
    return jsonDecode(res.body);
  }

  /// Obtener productos con paginación y filtros
  static Future<Map<String, dynamic>> getProducts(
    String slug, {
    String? categoria,
    bool? destacado,
    String? search,
    String? busqueda,
    int page = 1,
    int limit = 20,
    String? sort,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (categoria != null) params['categoria'] = categoria;
    if (destacado == true) params['destacado'] = 'true';
    if (search != null) params['search'] = search;
    if (busqueda != null) params['busqueda'] = busqueda;
    if (sort != null) params['sort'] = sort;

    final uri = Uri.parse(
      '$_baseUrl/$slug/products',
    ).replace(queryParameters: params);
    final res = await http.get(uri);
    return jsonDecode(res.body);
  }

  /// Obtener producto individual
  static Future<Map<String, dynamic>> getProduct(String slug, String id) async {
    final res = await http.get(Uri.parse('$_baseUrl/$slug/products/$id'));
    return jsonDecode(res.body);
  }

  /// Obtener categorías
  static Future<Map<String, dynamic>> getCategories(String slug) async {
    final res = await http.get(Uri.parse('$_baseUrl/$slug/categories'));
    return jsonDecode(res.body);
  }

  // ============================================
  // CARRITO
  // ============================================

  /// Crear u obtener carrito
  static Future<Map<String, dynamic>> createCart(
    String slug,
    String sessionId,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/$slug/cart'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'session_id': sessionId}),
    );
    return jsonDecode(res.body);
  }

  /// Obtener carrito por sessionId
  static Future<Map<String, dynamic>> getCart(
    String slug,
    String sessionId,
  ) async {
    final res = await http.get(Uri.parse('$_baseUrl/$slug/cart/$sessionId'));
    return jsonDecode(res.body);
  }

  /// Agregar item al carrito
  static Future<Map<String, dynamic>> addCartItem(
    String slug,
    String sessionId, {
    required String productoId,
    required String nombreProducto,
    required int cantidad,
    required double precioUnitario,
    String? imagenUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/$slug/cart/$sessionId/items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'producto_id': productoId,
        'nombre_producto': nombreProducto,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'imagen_url': imagenUrl,
        'metadata': metadata,
      }),
    );
    return jsonDecode(res.body);
  }

  /// Actualizar item del carrito
  static Future<Map<String, dynamic>> updateCartItem(
    String slug,
    String sessionId,
    String itemId, {
    required int cantidad,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/$slug/cart/$sessionId/items/$itemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cantidad': cantidad}),
    );
    return jsonDecode(res.body);
  }

  /// Eliminar item del carrito
  static Future<Map<String, dynamic>> deleteCartItem(
    String slug,
    String sessionId,
    String itemId,
  ) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/$slug/cart/$sessionId/items/$itemId'),
    );
    return jsonDecode(res.body);
  }

  // ============================================
  // CHECKOUT
  // ============================================

  /// Procesar checkout
  static Future<Map<String, dynamic>> checkout(
    String slug,
    String sessionId, {
    required String telefonoCliente,
    String? nombreCliente,
    String? direccion,
    String? ciudad,
    String? sector,
    String metodoEntrega = 'retiro_tienda',
    String metodoPago = 'whatsapp',
    String? notas,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/$slug/checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': sessionId,
        'telefono_cliente': telefonoCliente,
        'nombre_cliente': nombreCliente,
        'direccion': direccion,
        'ciudad': ciudad,
        'sector': sector,
        'metodo_entrega': metodoEntrega,
        'metodo_pago': metodoPago,
        'notas': notas,
      }),
    );
    return jsonDecode(res.body);
  }

  /// Generar link de WhatsApp
  static Future<Map<String, dynamic>> whatsappOrder(
    String slug,
    String sessionId, {
    String? nombreCliente,
    String? telefonoCliente,
    String? direccion,
    String? ciudad,
    String? sector,
    String metodoEntrega = 'retiro_tienda',
    String? notas,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/$slug/whatsapp-order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': sessionId,
        'nombre_cliente': nombreCliente,
        'telefono_cliente': telefonoCliente,
        'direccion': direccion,
        'ciudad': ciudad,
        'sector': sector,
        'metodo_entrega': metodoEntrega,
        'notas': notas,
      }),
    );
    return jsonDecode(res.body);
  }

  // ============================================
  // ADMIN
  // ============================================

  /// Obtener configuración admin
  static Future<Map<String, dynamic>> getAdminConfig(String botId) async {
    final res = await http.get(Uri.parse('$_baseUrl/admin/$botId/config'));
    return jsonDecode(res.body);
  }

  /// Guardar configuración admin
  static Future<Map<String, dynamic>> updateAdminConfig(
    String botId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/admin/$botId/config'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  /// Obtener banners (admin)
  static Future<Map<String, dynamic>> getAdminBanners(String botId) async {
    final res = await http.get(Uri.parse('$_baseUrl/admin/$botId/banners'));
    return jsonDecode(res.body);
  }

  /// Crear banner
  static Future<Map<String, dynamic>> createAdminBanner(
    String botId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/admin/$botId/banners'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  /// Actualizar banner
  static Future<Map<String, dynamic>> updateAdminBanner(
    String botId,
    int id,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/admin/$botId/banners/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  /// Eliminar banner
  static Future<Map<String, dynamic>> deleteAdminBanner(
    String botId,
    int id,
  ) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/admin/$botId/banners/$id'),
    );
    return jsonDecode(res.body);
  }

  /// Obtener configuraciones de productos
  static Future<Map<String, dynamic>> getAdminProductSettings(
    String botId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/$botId/product-settings'),
    );
    return jsonDecode(res.body);
  }

  /// Actualizar configuración de producto
  static Future<Map<String, dynamic>> updateAdminProductSetting(
    String botId,
    String productoId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/admin/$botId/product-settings/$productoId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  /// Obtener carritos
  static Future<Map<String, dynamic>> getAdminCarts(
    String botId, {
    String? estado,
  }) async {
    final params = <String, String>{};
    if (estado != null) params['estado'] = estado;
    final uri = Uri.parse(
      '$_baseUrl/admin/$botId/carts',
    ).replace(queryParameters: params);
    final res = await http.get(uri);
    return jsonDecode(res.body);
  }

  /// Obtener pagos
  static Future<Map<String, dynamic>> getAdminPayments(String botId) async {
    final res = await http.get(Uri.parse('$_baseUrl/admin/$botId/payments'));
    return jsonDecode(res.body);
  }

  /// Obtener zonas de delivery
  static Future<Map<String, dynamic>> getAdminDeliveryZones(
    String botId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/$botId/delivery-zones'),
    );
    return jsonDecode(res.body);
  }

  /// Crear zona de delivery
  static Future<Map<String, dynamic>> createAdminDeliveryZone(
    String botId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/admin/$botId/delivery-zones'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  /// Actualizar zona de delivery
  static Future<Map<String, dynamic>> updateAdminDeliveryZone(
    String botId,
    int id,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/admin/$botId/delivery-zones/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  /// Eliminar zona de delivery
  static Future<Map<String, dynamic>> deleteAdminDeliveryZone(
    String botId,
    int id,
  ) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/admin/$botId/delivery-zones/$id'),
    );
    return jsonDecode(res.body);
  }
}
