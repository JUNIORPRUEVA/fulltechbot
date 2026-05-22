import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/conversacion_model.dart';

class ConversacionesApiService {
  /// Obtiene los headers incluyendo el rol del usuario para autorización.
  Map<String, String> _getHeaders({String? userRole}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (userRole != null) {
      headers['X-User-Role'] = userRole;
    }
    return headers;
  }

  Future<List<ConversacionModel>> listarConversaciones() async {
    final response = await http.get(
      Uri.parse(ApiConfig.botConversationEndpoint),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => ConversacionModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar conversaciones');
  }

  Future<List<ConversacionModel>> listarPorSessionId(String sessionId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.botConversationEndpoint}/$sessionId'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => ConversacionModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar mensajes');
  }

  Future<ConversacionModel> crearConversacion({
    required String sessionId,
    required Map<String, dynamic> message,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.botConversationEndpoint),
      headers: _getHeaders(),
      body: jsonEncode({
        'session_id': sessionId,
        'message': message,
      }),
    );

    final body = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['ok'] == true) {
      return ConversacionModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al crear conversación');
  }

  /// Elimina todas las conversaciones de un sessionId.
  /// Requiere rol admin/owner (se envía en header X-User-Role).
  Future<void> eliminarPorSessionId(String sessionId, {String? userRole}) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.botConversationEndpoint}/$sessionId'),
      headers: _getHeaders(userRole: userRole),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar conversaciones');
  }
}
