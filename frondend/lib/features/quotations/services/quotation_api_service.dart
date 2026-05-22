import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/bot_quotation_model.dart';

class QuotationApiService {
  String get _baseUrl => '${ApiConfig.baseUrl}/api/quotations';

  Future<List<BotQuotationModel>> listarCotizaciones({
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
      return data.map((item) => BotQuotationModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar cotizaciones');
  }

  Future<BotQuotationModel> obtenerCotizacion(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$id'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotQuotationModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al obtener cotización');
  }

  Future<BotQuotationModel> crearCotizacion(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['ok'] == true) {
      return BotQuotationModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al crear cotización');
  }

  Future<BotQuotationModel> actualizarCotizacion(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotQuotationModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar cotización');
  }

  Future<BotQuotationModel> cambiarEstado(String id, String estado) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estado': estado}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotQuotationModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al cambiar estado');
  }

  Future<void> eliminarCotizacion(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar cotización');
  }
}
