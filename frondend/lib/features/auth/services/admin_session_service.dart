import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';

class AdminSessionService {
  static const String _tokenKey = 'fulltech_admin_token';
  static const String _userKey = 'fulltech_admin_user';

  /// Verificar si hay una sesión activa (token guardado)
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Obtener el token guardado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Obtener datos del usuario guardados
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  /// Guardar sesión después de login exitoso
  static Future<void> saveSession({
    required String token,
    required Map<String, dynamic> usuario,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(usuario));
  }

  /// Cerrar sesión
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Iniciar sesión contra el backend
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.apiBaseUrl}/api/auth/login');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final errorBody = response.body.isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(response.body))
          : <String, dynamic>{};
      throw Exception(
        errorBody['message'] ?? 'Error al iniciar sesión (${response.statusCode})',
      );
    }

    final result = Map<String, dynamic>.from(jsonDecode(response.body));

    if (result['ok'] != true) {
      throw Exception(result['message'] ?? 'Error al iniciar sesión');
    }

    final data = result['data'];
    if (data == null) {
      throw Exception('Respuesta inválida del servidor');
    }

    // Guardar sesión
    await saveSession(
      token: data['token'] as String,
      usuario: Map<String, dynamic>.from(data['usuario']),
    );

    return data;
  }

  /// Verificar si el token actual sigue siendo válido
  static Future<bool> verifyToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/api/auth/verificar');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return false;

      final result = Map<String, dynamic>.from(jsonDecode(response.body));
      return result['valido'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Headers de autenticación para peticiones API
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
    }
    return {'Content-Type': 'application/json'};
  }
}
