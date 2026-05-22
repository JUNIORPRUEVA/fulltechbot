import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/bot_model.dart';

class BotApiService {
  static const Duration _timeout = Duration(seconds: 15);

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

  Future<List<BotModel>> listarBots() async {
    final body = await _request(
      () => http.get(Uri.parse('${ApiConfig.baseUrl}/api/bots')),
    );
    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => BotModel.fromJson(item)).toList();
    }
    throw Exception(body['message'] ?? 'Error al listar bots');
  }

  Future<BotModel> obtenerBotPorId(String id) async {
    final body = await _request(
      () => http.get(Uri.parse('${ApiConfig.baseUrl}/api/bots/$id')),
    );
    if (body['ok'] == true) {
      return BotModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Error al obtener bot');
  }

  Future<BotModel> obtenerBotPorSlug(String slug) async {
    final body = await _request(
      () => http.get(Uri.parse('${ApiConfig.baseUrl}/api/bots/slug/$slug')),
    );
    if (body['ok'] == true) {
      return BotModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Error al obtener bot por slug');
  }

  Future<BotModel> crearBot(Map<String, dynamic> data) async {
    final body = await _request(
      () => http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/bots'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ),
    );
    if ((body['ok'] == true)) {
      return BotModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Error al crear bot');
  }

  Future<BotModel> actualizarBot(String id, Map<String, dynamic> data) async {
    final body = await _request(
      () => http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/bots/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ),
    );
    if (body['ok'] == true) {
      return BotModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Error al actualizar bot');
  }

  Future<BotModel> cambiarEstado(String id, String estado) async {
    final body = await _request(
      () => http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/bots/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': estado}),
      ),
    );
    if (body['ok'] == true) {
      return BotModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Error al cambiar estado');
  }

  Future<void> eliminarBot(String id) async {
    final body = await _request(
      () => http.delete(Uri.parse('${ApiConfig.baseUrl}/api/bots/$id')),
    );
    if (body['ok'] == true) {
      return;
    }
    throw Exception(body['message'] ?? 'Error al eliminar bot');
  }
}
