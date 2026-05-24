import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    String label,
    String url,
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      debugPrint('[$label] URL: $url');

      final response = await requestFn().timeout(_timeout);

      debugPrint('[$label] STATUS: ${response.statusCode}');
      debugPrint('[$label] BODY: ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Respuesta vacía del servidor. Status: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw Exception('Formato de respuesta inválido. Body: ${response.body}');
      }

      if (response.statusCode >= 400) {
        final message = body['message']?.toString();
        final error = body['error']?.toString();
        throw Exception(
          [
            if (message != null && message.isNotEmpty) message,
            if (error != null && error.isNotEmpty) error,
          ].join(' | ').isNotEmpty
              ? [
                  if (message != null && message.isNotEmpty) message,
                  if (error != null && error.isNotEmpty) error,
                ].join(' | ')
              : 'Error HTTP ${response.statusCode}',
        );
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
    final url = ApiConfig.botConversationsEndpoint(botId);
    final body = await _request(
      'ConversacionesApiService.listarConversaciones',
      url,
      () => http.get(Uri.parse(url)),
    );

    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => ConversacionModel.fromJson(item)).toList();
    }

    final message = body['message']?.toString() ?? 'Error al listar conversaciones';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<List<ConversacionModel>> listarPorSessionId(
    String botId,
    String sessionId,
  ) async {
    final url = ApiConfig.botConversationBySessionEndpoint(botId, sessionId);
    final body = await _request(
      'ConversacionesApiService.listarPorSessionId',
      url,
      () => http.get(Uri.parse(url)),
    );

    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => ConversacionModel.fromJson(item)).toList();
    }

    final message = body['message']?.toString() ?? 'Error al listar mensajes';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<ConversacionModel> crearConversacion({
    required String botId,
    required String sessionId,
    required Map<String, dynamic> message,
  }) async {
    final url = ApiConfig.botConversationsEndpoint(botId);
    final body = await _request(
      'ConversacionesApiService.crearConversacion',
      url,
      () => http.post(
        Uri.parse(url),
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

    final msg = body['message']?.toString() ?? 'Error al crear conversación';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? msg : '$msg | $error',
    );
  }

  Future<void> eliminarPorSessionId(
    String botId,
    String sessionId, {
    String? userRole,
  }) async {
    final url = ApiConfig.botConversationBySessionEndpoint(botId, sessionId);
    final body = await _request(
      'ConversacionesApiService.eliminarPorSessionId',
      url,
      () => http.delete(
        Uri.parse(url),
        headers: _getHeaders(userRole: userRole),
      ),
    );

    if (body['ok'] == true) {
      return;
    }

    final message = body['message']?.toString() ?? 'Error al eliminar conversaciones';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }
}
