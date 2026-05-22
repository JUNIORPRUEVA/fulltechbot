import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/bot_order_model.dart';

class OrderApiService {
  String get _baseUrl => '${ApiConfig.baseUrl}/api/orders';

  Future<List<BotOrderModel>> listarOrdenes({
    String? sourceBotId,
    String? estado,
    String? telefono,
    String? botId,
  }) async {
    final params = <String, String>{};
    if (sourceBotId != null) params['sourceBotId'] = sourceBotId;
    if (estado != null) params['estado'] = estado;
    if (telefono != null) params['telefono'] = telefono;
    if (botId != null) params['botId'] = botId;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri);

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => BotOrderModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar órdenes');
  }

  Future<BotOrderModel> obtenerOrden(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$id'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al obtener orden');
  }

  Future<BotOrderModel> crearOrden(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
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
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar orden');
  }

  Future<BotOrderModel> cambiarEstado(String id, String estado) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estado': estado}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al cambiar estado');
  }

  Future<void> eliminarOrden(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar orden');
  }
}
