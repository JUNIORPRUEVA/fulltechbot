import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/bot_quotation_model.dart';

class BotQuotationApiService {
  String _url(String botId) =>
      '${ApiConfig.baseUrl}/api/bots/$botId/quotations';

  Future<List<BotQuotationModel>> listarCotizaciones(String botId) async {
    final response = await http.get(
      Uri.parse(_url(botId)),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => BotQuotationModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar cotizaciones');
  }

  Future<BotQuotationModel> obtenerCotizacion(
      String botId, String id) async {
    final response = await http.get(
      Uri.parse('${_url(botId)}/$id'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotQuotationModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al obtener cotización');
  }

  Future<BotQuotationModel> crearCotizacion(
      String botId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(_url(botId)),
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
      String botId, String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${_url(botId)}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotQuotationModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar cotización');
  }

  Future<BotQuotationModel> cambiarEstado(
      String botId, String id, String estado) async {
    final response = await http.patch(
      Uri.parse('${_url(botId)}/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estado': estado}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return BotQuotationModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al cambiar estado');
  }

  Future<void> eliminarCotizacion(String botId, String id) async {
    final response = await http.delete(
      Uri.parse('${_url(botId)}/$id'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar cotización');
  }
}
