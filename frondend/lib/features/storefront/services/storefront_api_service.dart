import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';

/// Servicio de API para Storefront con estrategia siempre-fresca.
/// 
/// - Siempre consulta API fresca (network-only) con headers anti-cache.
/// - No cachea respuestas críticas (productos, precios, ofertas, stock).
/// - Las imágenes se cachean con versionado por URL (v=updatedAt) en el SW.
/// - Si la API falla, usa datos cacheados en memoria como fallback offline.
class StorefrontApiService {
  static final String _baseUrl = '${ApiConfig.baseUrl}/api/storefront';
  static const Map<String, String> _slugAliases = {
    'fulltech': 'fulltech-seguridad',
  };
  
  // Headers anti-cache para todas las requests
  static final Map<String, String> _noCacheHeaders = {
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
  };
  
  // Cache en memoria SOLO para fallback offline (stale-while-revalidate)
  // NOTA: El catálogo NO se cachea en memoria para evitar datos viejos.
  // Cada vez que se abre la tienda, se consulta API fresca.
  // El cache de config es mínimo y solo para casos de error de red.
  static final Map<String, Map<String, dynamic>> _configCache = {};



  // ============================================
  // PUBLICAS
  // ============================================

  static Future<Map<String, dynamic>> getConfig(String slug) async {
    final response = await _getStorefront('/${_resolveSlug(slug)}/config');
    if (_isSuccessful(response)) {
      final data = _asMap(response['data']);
      if (data.isNotEmpty) {
        _configCache[slug] = data;
      }
      return response;
    }
    return _buildFallbackConfigResponse(slug);
  }

  static Future<Map<String, dynamic>> getBanners(String slug) async {
    final response = await _getStorefront('/${_resolveSlug(slug)}/banners');
    if (_isSuccessful(response)) {
      return response;
    }

    final config = await _ensureFallbackConfig(slug);
    final catalog = await _getFallbackCatalog(slug);
    final highlighted = catalog.where(_isFeaturedProduct).take(3).toList();

    final banners = highlighted.isNotEmpty
        ? highlighted.map((product) {
            return {
              'id': 'fallback-${product['id']}',
              'titulo': product['titulo'],
              'subtitulo':
                  product['descripcion'] ?? config['mensaje_secundario'],
              'imagen_url':
                  product['imagen_destacada_url'] ?? product['imagen1'],
              'cta_texto': 'Ver producto',
              'cta_url': '/tienda/$slug/producto/${product['id']}',
              'badge': product['categoria'],
            };
          }).toList()
        : [
            {
              'id': 'fallback-main',
              'titulo': config['mensaje_principal'],
              'subtitulo': config['mensaje_secundario'],
              'imagen_url': catalog.isNotEmpty
                  ? catalog.first['imagen_destacada_url']
                  : null,
              'cta_texto': 'Ver ofertas',
              'cta_url': '/tienda/$slug',
              'badge': 'FULLTECH SRL',
            },
          ];

    return {'ok': true, 'data': banners, 'source': 'bot-catalog-fallback'};
  }

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
    if (categoria != null) {
      params['categoria'] = categoria;
    }
    if (destacado == true) {
      params['destacado'] = 'true';
    }
    if (search != null) {
      params['search'] = search;
    }
    if (busqueda != null) {
      params['busqueda'] = busqueda;
    }
    if (sort != null) {
      params['sort'] = sort;
    }

    final response = await _getStorefront(
      '/${_resolveSlug(slug)}/products',
      queryParameters: params,
    );
    if (_isSuccessful(response)) {
      return response;
    }

    final catalog = await _getFallbackCatalog(slug);
    final query = (search ?? busqueda ?? '').trim().toLowerCase();
    var filtered = List<Map<String, dynamic>>.from(catalog);

    if (categoria != null && categoria.trim().isNotEmpty) {
      final wanted = categoria.trim().toLowerCase();
      filtered = filtered
          .where(
            (item) => item['categoria']?.toString().trim().toLowerCase() == wanted,
          )
          .toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((item) {
        final haystack = [
          item['titulo'],
          item['categoria'],
          item['descripcion'],
          item['informacion'],
          item['palabrasClave'],
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    if (destacado == true) {
      filtered = filtered.where(_isFeaturedProduct).toList();
    }

    filtered.sort((a, b) => _sortProducts(a, b, sort));

    final safeLimit = limit <= 0 ? 20 : limit;
    final total = filtered.length;
    final totalPages = total == 0 ? 1 : (total / safeLimit).ceil();
    final safePage = page < 1 ? 1 : page > totalPages ? totalPages : page;
    final start = (safePage - 1) * safeLimit;
    final end = start + safeLimit > total ? total : start + safeLimit;
    final items = start >= total ? <Map<String, dynamic>>[] : filtered.sublist(start, end);

    return {
      'ok': true,
      'items': items,
      'page': safePage,
      'limit': safeLimit,
      'total': total,
      'totalPages': totalPages,
      'source': 'bot-catalog-fallback',
    };
  }

  static Future<Map<String, dynamic>> getProduct(String slug, String id) async {
    final response = await _getStorefront('/${_resolveSlug(slug)}/products/$id');
    if (_isSuccessful(response)) {
      return response;
    }

    final catalog = await _getFallbackCatalog(slug);
    final product = catalog.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['id']?.toString() == id,
      orElse: () => null,
    );

    if (product == null) {
      return {'ok': false, 'message': 'Producto no encontrado'};
    }

    final relatedProducts = catalog
        .where(
          (item) =>
              item['id']?.toString() != id &&
              item['categoria']?.toString() == product['categoria'],
        )
        .take(4)
        .toList();

    return {
      'ok': true,
      'data': {
        ...product,
        'relatedProducts': relatedProducts,
      },
      'source': 'bot-catalog-fallback',
    };
  }

  static Future<Map<String, dynamic>> getCategories(String slug) async {
    final response = await _getStorefront('/${_resolveSlug(slug)}/categories');
    if (_isSuccessful(response)) {
      return response;
    }

    final catalog = await _getFallbackCatalog(slug);
    final counts = <String, int>{};
    for (final item in catalog) {
      final category = item['categoria']?.toString().trim();
      if (category == null || category.isEmpty) {
        continue;
      }
      counts.update(category, (value) => value + 1, ifAbsent: () => 1);
    }

    final categories = counts.entries.map((entry) {
      return {
        'nombre': entry.key,
        'slug': Uri.encodeComponent(entry.key.toLowerCase()),
        'cantidad': entry.value,
      };
    }).toList()
      ..sort((a, b) => (b['cantidad'] as int).compareTo(a['cantidad'] as int));

    return {'ok': true, 'data': categories, 'source': 'bot-catalog-fallback'};
  }

  // ============================================
  // CARRITO
  // ============================================

  static Future<Map<String, dynamic>> createCart(
    String slug,
    String sessionId,
  ) async {
    final resolvedSlug = _resolveSlug(slug);
    final res = await http.post(
      Uri.parse('$_baseUrl/$resolvedSlug/cart'),
      headers: {
        'Content-Type': 'application/json',
        ..._noCacheHeaders,
      },
      body: jsonEncode({'session_id': sessionId}),
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> getCart(
    String slug,
    String sessionId,
  ) async {
    final resolvedSlug = _resolveSlug(slug);
    final res = await http.get(
      Uri.parse('$_baseUrl/$resolvedSlug/cart/$sessionId'),
      headers: _noCacheHeaders,
    );
    return _decodeResponse(res);
  }

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
    final resolvedSlug = _resolveSlug(slug);
    final res = await http.post(
      Uri.parse('$_baseUrl/$resolvedSlug/cart/$sessionId/items'),
      headers: {
        'Content-Type': 'application/json',
        ..._noCacheHeaders,
      },
      body: jsonEncode({
        'producto_id': productoId,
        'nombre_producto': nombreProducto,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'imagen_url': imagenUrl,
        'metadata': metadata,
      }),
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> updateCartItem(
    String slug,
    String sessionId,
    String itemId, {
    required int cantidad,
  }) async {
    final resolvedSlug = _resolveSlug(slug);
    final res = await http.put(
      Uri.parse('$_baseUrl/$resolvedSlug/cart/$sessionId/items/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        ..._noCacheHeaders,
      },
      body: jsonEncode({'cantidad': cantidad}),
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> deleteCartItem(
    String slug,
    String sessionId,
    String itemId,
  ) async {
    final resolvedSlug = _resolveSlug(slug);
    final res = await http.delete(
      Uri.parse('$_baseUrl/$resolvedSlug/cart/$sessionId/items/$itemId'),
      headers: _noCacheHeaders,
    );
    return _decodeResponse(res);
  }

  // ============================================
  // CHECKOUT
  // ============================================

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
    final resolvedSlug = _resolveSlug(slug);
    final res = await http.post(
      Uri.parse('$_baseUrl/$resolvedSlug/checkout'),
      headers: {
        'Content-Type': 'application/json',
        ..._noCacheHeaders,
      },
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
    return _decodeResponse(res);
  }

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
    final resolvedSlug = _resolveSlug(slug);
    final res = await http.post(
      Uri.parse('$_baseUrl/$resolvedSlug/whatsapp-order'),
      headers: {
        'Content-Type': 'application/json',
        ..._noCacheHeaders,
      },
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
    return _decodeResponse(res);
  }

  // ============================================
  // ADMIN
  // ============================================

  static Future<Map<String, dynamic>> getAdminConfig(String botId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/$botId/config'),
      headers: _noCacheHeaders,
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> updateAdminConfig(
    String botId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/admin/$botId/config'),
      headers: {
        'Content-Type': 'application/json',
        ..._noCacheHeaders,
      },
      body: jsonEncode(data),
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> getAdminBanners(String botId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/$botId/banners'),
      headers: _noCacheHeaders,
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> createAdminBanner(
    String botId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/admin/$botId/banners'),
      headers: {
        'Content-Type': 'application/json',
        ..._noCacheHeaders,
      },
      body: jsonEncode(data),
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> updateAdminBanner(
    String botId,
    int id,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/admin/$botId/banners/$id'),
      headers: {
        'Content-Type': 'application/json',
        ..._noCacheHeaders,
      },
      body: jsonEncode(data),
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> deleteAdminBanner(
    String botId,
    int id,
  ) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/admin/$botId/banners/$id'),
      headers: _noCacheHeaders,
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> getAdminProductSettings(
    String botId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/$botId/product-settings'),
      headers: _noCacheHeaders,
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> updateAdminProductSetting(
    String botId,
    String productoId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/admin/$botId/product-settings/$productoId'),
      headers: {
        'Content-Type': 'application/json',
        ..._noCacheHeaders,
      },
      body: jsonEncode(data),
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> getAdminCarts(
    String botId, {
    String? estado,
  }) async {
    final params = <String, String>{};
    if (estado != null) {
      params['estado'] = estado;
    }
    final uri = Uri.parse(
      '$_baseUrl/admin/$botId/carts',
    ).replace(queryParameters: params);
    final res = await http.get(uri, headers: _noCacheHeaders);
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> getAdminPayments(String botId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/$botId/payments'),
      headers: _noCacheHeaders,
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> getAdminDeliveryZones(
    String botId,
  ) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/$botId/delivery-zones'),
      headers: _noCacheHeaders,
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> createAdminDeliveryZone(
    String botId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/admin/$botId/delivery-zones'),
      headers: {
        'Content-Type': 'application/json',
        ..._noCacheHeaders,
      },
      body: jsonEncode(data),
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> updateAdminDeliveryZone(
    String botId,
    int id,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/admin/$botId/delivery-zones/$id'),
      headers: {
        'Content-Type': 'application/json',
        ..._noCacheHeaders,
      },
      body: jsonEncode(data),
    );
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> deleteAdminDeliveryZone(
    String botId,
    int id,
  ) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/admin/$botId/delivery-zones/$id'),
      headers: _noCacheHeaders,
    );
    return _decodeResponse(res);
  }

  // ============================================
  // FALLBACKS
  // ============================================

  static Future<Map<String, dynamic>> _buildFallbackConfigResponse(
    String slug,
  ) async {
    final bot = await _getBotBySlug(_resolveSlug(slug));
    final data = {
      'id': 'fallback-${bot['id']}',
      'bot_id': bot['id'],
      'slug': bot['slug'],
      'nombre_tienda': bot['nombre'] ?? 'FULLTECH SRL',
      'descripcion': bot['descripcion'],
      'logo_url': null,
      'color_principal': '#0F172A',
      'color_secundario': '#2563EB',
      'whatsapp_numero': bot['telefonoWhatsapp'],
      'telefono_contacto': bot['telefonoWhatsapp'],
      'direccion': null,
      'horario': null,
      'mensaje_principal': 'Tienda oficial FULLTECH SRL',
      'mensaje_secundario': 'Compra facil, ofertas y productos para tu hogar, empresa y proyectos.',
      'activo': true,
      'permitir_paypal': false,
      'permitir_whatsapp': true,
      'permitir_retiro_tienda': true,
      'permitir_delivery': false,
      'source': 'bot-catalog-fallback',
    };
    _configCache[slug] = data;
    return {'ok': true, 'data': data, 'source': 'bot-catalog-fallback'};
  }

  static Future<Map<String, dynamic>> _ensureFallbackConfig(String slug) async {
    final cached = _configCache[slug];
    if (cached != null) {
      return cached;
    }
    final response = await _buildFallbackConfigResponse(slug);
    return _asMap(response['data']);
  }

  static Future<Map<String, dynamic>> _getBotBySlug(String slug) async {
    final response = await _getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/bots/slug/${_resolveSlug(slug)}'),
    );
    if (response['ok'] != true) {
      throw Exception(
        response['message']?.toString() ?? 'No se pudo resolver el bot publico',
      );
    }
    return _asMap(response['data']);
  }

  static Future<List<Map<String, dynamic>>> _getFallbackCatalog(
    String slug,
  ) async {
    // NOTA: No cacheamos el catálogo en memoria para evitar datos viejos.
    // Cada llamada consulta API fresca. Esto es intencional para que
    // cambios en productos/precios/ofertas se reflejen inmediatamente.

    final bot = await _getBotBySlug(_resolveSlug(slug));
    final botId = bot['id']?.toString() ?? '';
    if (botId.isEmpty) {
      throw Exception('El bot publico no tiene id valido');
    }

    final response = await _getJson(
      Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo'),
    );
    if (response['ok'] != true) {
      throw Exception(
        response['message']?.toString() ??
            'No se pudo cargar el catalogo de la tienda',
      );
    }

    final rawItems = _asList(response['data']);
    final items = rawItems
        .map((item) => _mapCatalogProduct(item, bot))
        .where((item) => item['estado']?.toString().toLowerCase() == 'activo')
        .toList();

    return items;
  }


  static Map<String, dynamic> _mapCatalogProduct(
    Map<String, dynamic> raw,
    Map<String, dynamic> bot,
  ) {
    final precio = _toDouble(raw['precio']);
    final precioOferta = _toNullableDouble(raw['precioOferta']);
    final precioOfertaWeb =
        precioOferta != null && precioOferta > 0 && precioOferta < precio
        ? precioOferta
        : null;
    final gallery = [
      raw['imagen1'],
      raw['imagen2'],
      raw['imagen3'],
    ].where((item) => item != null && item.toString().trim().isNotEmpty).toList();

    return {
      'id': raw['id']?.toString() ?? '',
      'titulo': raw['titulo']?.toString() ?? '',
      'categoria': raw['categoria']?.toString() ?? 'General',
      'descripcion': raw['descripcion']?.toString(),
      'informacion': raw['informacion']?.toString(),
      'precio': precio,
      'precioMinimo': _toNullableDouble(raw['precioMinimo']),
      'precioOferta': precioOferta,
      'stock': _toInt(raw['stock']),
      'imagen1': raw['imagen1'],
      'imagen2': raw['imagen2'],
      'imagen3': raw['imagen3'],
      'video': raw['video'],
      'palabrasClave': raw['palabrasClave'],
      'reglasNegociacion': raw['reglasNegociacion'],
      'estado': raw['estado']?.toString() ?? 'activo',
      'tipoProducto': raw['tipoProducto']?.toString() ?? 'producto',
      'incluye': raw['incluye'],
      'permiteAdicionales': raw['permiteAdicionales'] == true,
      'esCotizable': raw['esCotizable'] != false,
      'orden': _toInt(raw['orden']),
      'cantidadBase': _toInt(raw['cantidadBase'], fallback: 1),
      'precioAdicional': _toDouble(raw['precioAdicional']),
      'precioMinimoAdicional': _toDouble(raw['precioMinimoAdicional']),
      'instalacion_incluida': raw['instalacionIncluida'] == true,
      'precio_oferta_web': precioOfertaWeb,
      'descripcion_web': raw['descripcion']?.toString(),
      'imagen_destacada_url': raw['imagen1'] ?? raw['imagen2'] ?? raw['imagen3'],
      'visible_en_tienda': true,
      'destacado': _isFeaturedProduct(raw),
      'permitir_compra_online': true,
      'permitir_whatsapp': true,
      'requiere_instalacion': raw['instalacionIncluida'] == true,
      'gallery': gallery,
      'bot_id': bot['id']?.toString(),
      'bot_slug': bot['slug']?.toString(),
      'bot_nombre': bot['nombre']?.toString(),
      // Incluir updatedAt para versionado de imágenes
      'actualizadoEn': raw['actualizadoEn']?.toString() ?? raw['updatedAt']?.toString(),
    };
  }

  static bool _isFeaturedProduct(Map<String, dynamic> product) {
    final hasOffer = _toNullableDouble(
          product['precio_oferta_web'] ?? product['precioOferta'],
        ) !=
        null;
    return hasOffer ||
        _toInt(product['stock']) > 0 ||
        product['imagen1'] != null ||
        product['imagen_destacada_url'] != null;
  }

  static String _resolveSlug(String slug) {
    final normalized = slug.trim().toLowerCase();
    return _slugAliases[normalized] ?? slug;
  }

  static int _sortProducts(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    String? sort,
  ) {
    final mode = sort?.trim().toLowerCase();
    if (mode == 'offers') {
      final offerCompare = _compareOffers(a, b);
      if (offerCompare != 0) {
        return offerCompare;
      }
    }

    if (mode == 'featured') {
      final featuredCompare = _compareFeatured(a, b);
      if (featuredCompare != 0) {
        return featuredCompare;
      }
    }

    final stockCompare = _toInt(b['stock']).compareTo(_toInt(a['stock']));
    if (stockCompare != 0) {
      return stockCompare;
    }

    final orderCompare = _toInt(a['orden']).compareTo(_toInt(b['orden']));
    if (orderCompare != 0) {
      return orderCompare;
    }

    return (a['titulo']?.toString() ?? '').compareTo(b['titulo']?.toString() ?? '');
  }

  static int _compareOffers(Map<String, dynamic> a, Map<String, dynamic> b) {
    final hasOfferA = _toNullableDouble(
          a['precio_oferta_web'] ?? a['precioOferta'],
        ) !=
        null;
    final hasOfferB = _toNullableDouble(
          b['precio_oferta_web'] ?? b['precioOferta'],
        ) !=
        null;
    if (hasOfferA != hasOfferB) {
      return hasOfferB ? 1 : -1;
    }
    return 0;
  }

  static int _compareFeatured(Map<String, dynamic> a, Map<String, dynamic> b) {
    final featuredA = _isFeaturedProduct(a);
    final featuredB = _isFeaturedProduct(b);
    if (featuredA != featuredB) {
      return featuredB ? 1 : -1;
    }
    return _compareOffers(a, b);
  }

  static Future<Map<String, dynamic>> _getStorefront(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParameters);
    final res = await http.get(uri, headers: _noCacheHeaders);
    return _decodeResponse(res);
  }

  static Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final res = await http.get(uri, headers: _noCacheHeaders);
    return _decodeResponse(res);
  }

  static Map<String, dynamic> _decodeResponse(http.Response res) {
    if (res.body.isEmpty) {
      return {
        'ok': false,
        'message': 'Respuesta vacia del servidor',
        'statusCode': res.statusCode,
      };
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      return {
        ...decoded,
        'statusCode': res.statusCode,
      };
    }

    return {
      'ok': false,
      'message': 'Formato de respuesta invalido',
      'statusCode': res.statusCode,
    };
  }

  static bool _isSuccessful(Map<String, dynamic> response) {
    return response['ok'] == true &&
        (response['statusCode'] is! int ||
            (response['statusCode'] as int) < 400);
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
