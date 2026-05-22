import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_config.dart';
import '../models/bot_model.dart';

class BotApiService {
  Future<List<BotModel>> listarBots() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/bots'),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => BotModel.fromJson(item)).toList();
    }
    throw Exception(body['message'] ?? 'Error al listar bots');
  }

  Future<BotModel> obtenerBotPorId(String id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/bots/$id'),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['ok'] == true) {
      return BotModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Error al obtener bot');
  }

  Future<BotModel> obtenerBotPorSlug(String slug) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/bots/slug/$slug'),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['ok'] == true) {
      return BotModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Error al obtener bot por slug');
  }

  Future<BotModel> crearBot(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/bots'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final body = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) && body['ok'] == true) {
      return BotModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Error al crear bot');
  }

  Future<BotModel> actualizarBot(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/bots/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['ok'] == true) {
      return BotModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Error al actualizar bot');
  }

  Future<BotModel> cambiarEstado(String id, String estado) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/api/bots/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estado': estado}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['ok'] == true) {
      return BotModel.fromJson(body['data']);
    }
    throw Exception(body['message'] ?? 'Error al cambiar estado');
  }

  Future<void> eliminarBot(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/bots/$id'),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['ok'] == true) {
      return;
    }
    throw Exception(body['message'] ?? 'Error al eliminar bot');
  }
}
