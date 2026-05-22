import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/conversacion_model.dart';

class ConversacionesApiService {
  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> _getHeaders({String? userRole}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (userRole != null && userRole.isNotEmpty) {
      headers['X-User-Role'] = userRole;
    }
    return headers;
  }

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      final response = await requestFn().timeout(_timeout);
      if (response.body.isEmpty) {
        throw Exception('Respuesta vacía del servidor');
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw Exception('Formato de respuesta inválido');
      }

      return body;
    } on TimeoutException {
      throw Exception('La solicitud tardó demasiado. Verifica tu conexión.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<ConversacionModel>> listarConversaciones(String botId) async {
    final body = await _request(
      () => http.get(Uri.parse(ApiConfig.botConversationsEndpoint(botId))),
    );

    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => ConversacionModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar conversaciones');
  }

  Future<List<ConversacionModel>> listarPorSessionId(
    String botId,
    String sessionId,
  ) async {
    final body = await _request(
      () => http.get(
        Uri.parse(ApiConfig.botConversationBySessionEndpoint(botId, sessionId)),
      ),
    );

    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => ConversacionModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar mensajes');
  }

  Future<ConversacionModel> crearConversacion({
    required String botId,
    required String sessionId,
    required Map<String, dynamic> message,
  }) async {
    final body = await _request(
      () => http.post(
        Uri.parse(ApiConfig.botConversationsEndpoint(botId)),
        headers: _getHeaders(),
        body: jsonEncode({
          'session_id': sessionId,
          'message': message,
        }),
      ),
    );

    if (body['ok'] == true) {
      return ConversacionModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al crear conversación');
  }

  Future<void> eliminarPorSessionId(
    String botId,
    String sessionId, {
    String? userRole,
  }) async {
    final body = await _request(
      () => http.delete(
        Uri.parse(ApiConfig.botConversationBySessionEndpoint(botId, sessionId)),
        headers: _getHeaders(userRole: userRole),
      ),
    );

    if (body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar conversaciones');
  }
}
