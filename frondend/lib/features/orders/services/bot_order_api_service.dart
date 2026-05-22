import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/bot_order_model.dart';

class BotOrderApiService {
  String _url(String botId) =>
      '${ApiConfig.baseUrl}/api/bots/$botId/orders';

  Future<List<BotOrderModel>> listarOrdenes(String botId) async {
    final response = await http.get(
      Uri.parse(_url(botId)),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => BotOrderModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar órdenes');
  }

  Future<BotOrderModel> obtenerOrden(String botId, String id) async {
    final response = await http.get(
      Uri.parse('${_url(botId)}/$id'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al obtener orden');
  }

  Future<BotOrderModel> crearOrden(
      String botId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(_url(botId)),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al crear orden');
  }

  Future<BotOrderModel> actualizarOrden(
      String botId, String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${_url(botId)}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar orden');
  }

  Future<BotOrderModel> cambiarEstado(
      String botId, String id, String estado) async {
    final response = await http.patch(
      Uri.parse('${_url(botId)}/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estado': estado}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al cambiar estado');
  }

  Future<void> eliminarOrden(String botId, String id) async {
    final response = await http.delete(
      Uri.parse('${_url(botId)}/$id'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar orden');
  }
}
