import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';
import '../../auth/services/admin_session_service.dart';

/// API Service para la administración de la tienda desde el panel admin.
/// Todos los endpoints requieren autenticación (token).
class StoreAdminApiService {
  static final StoreAdminApiService _instance = StoreAdminApiService._();
  StoreAdminApiService._();
  factory StoreAdminApiService() => _instance;

  String get _baseUrl => ApiConfig.apiBaseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await AdminSessionService.getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String _botIdParam() => 'primary';

  // ============================================
  // CONFIGURACIÓN DE TIENDA
  // ============================================

  Future<Map<String, dynamic>> getConfig() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_baseUrl/api/storefront/admin/${_botIdParam()}/config'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception('Error al obtener configuración: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> updateConfig(Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.put(
      Uri.parse('$_baseUrl/api/storefront/admin/${_botIdParam()}/config'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception('Error al guardar configuración: ${res.statusCode}');
  }

  // ============================================
  // BANNERS
  // ============================================

  Future<List<Map<String, dynamic>>> getBanners() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_baseUrl/api/storefront/admin/${_botIdParam()}/banners'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(body['data'] ?? []);
    }
    throw Exception('Error al obtener banners: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> createBanner(Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_baseUrl/api/storefront/admin/${_botIdParam()}/banners'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) {
      final body = jsonDecode(res.body);
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception('Error al crear banner: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> updateBanner(
      int id, Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.put(
      Uri.parse(
          '$_baseUrl/api/storefront/admin/${_botIdParam()}/banners/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception('Error al actualizar banner: ${res.statusCode}');
  }

  Future<void> deleteBanner(int id) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse(
          '$_baseUrl/api/storefront/admin/${_botIdParam()}/banners/$id'),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Error al eliminar banner: ${res.statusCode}');
    }
  }

  // ============================================
  // CARRITOS
  // ============================================

  Future<List<Map<String, dynamic>>> getCarts({String? estado}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse(
        '$_baseUrl/api/storefront/admin/${_botIdParam()}/carts')
        .replace(queryParameters: estado != null ? {'estado': estado} : null);
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(body['data'] ?? []);
    }
    throw Exception('Error al obtener carritos: ${res.statusCode}');
  }

  // ============================================
  // PAGOS
  // ============================================

  Future<List<Map<String, dynamic>>> getPayments() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_baseUrl/api/storefront/admin/${_botIdParam()}/payments'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(body['data'] ?? []);
    }
    throw Exception('Error al obtener pagos: ${res.statusCode}');
  }

  // ============================================
  // POLÍTICAS
  // ============================================

  Future<List<Map<String, dynamic>>> getPolicies() async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$_baseUrl/api/storefront/admin/${_botIdParam()}/policies'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(body['data'] ?? []);
    }
    throw Exception('Error al obtener políticas: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> upsertPolicy(
      String tipo, Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final res = await http.put(
      Uri.parse(
          '$_baseUrl/api/storefront/admin/${_botIdParam()}/policies/$tipo'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception('Error al guardar política: ${res.statusCode}');
  }

  Future<void> deletePolicy(String tipo) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse(
          '$_baseUrl/api/storefront/admin/${_botIdParam()}/policies/$tipo'),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Error al eliminar política: ${res.statusCode}');
    }
  }
}
