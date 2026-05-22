import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/bot_order_model.dart';

class OrderApiService {
  static const Duration _timeout = Duration(seconds: 15);

  String get _baseUrl => '${ApiConfig.baseUrl}/api/orders';

  /// Valida que la respuesta no sea HTML y lanza error descriptivo.
  Map<String, dynamic> _validateAndDecode(http.Response response) {
    final body = response.body;

    if (body.isEmpty) {
      throw Exception('Respuesta vacía del servidor');
    }

    // Detectar HTML (error 404 del servidor Express sin middleware JSON)
    if (body.trimLeft().startsWith('<!DOCTYPE html>') ||
        body.trimLeft().startsWith('<html') ||
        body.trimLeft().startsWith('<')) {
      throw Exception(
        'La API devolvió HTML. Revisa la URL del backend o la ruta del endpoint.\n'
        'URL: ${response.request?.url}\n'
        'Status: ${response.statusCode}',
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Formato de respuesta inválido: se esperaba un objeto JSON');
      }
      return decoded;
    } on FormatException catch (e) {
      throw Exception(
        'Error al decodificar respuesta del servidor. '
        'Status: ${response.statusCode}, Content-Type: ${response.headers['content-type']}\n'
        'Detalle: $e',
      );
    }
  }

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      final response = await requestFn().timeout(_timeout);
      return _validateAndDecode(response);
    } on TimeoutException {
      throw Exception('La solicitud tardó demasiado. Verifica tu conexión.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: $e');
    }
  }

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
    final body = await _request(() => http.get(uri));

    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => BotOrderModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar órdenes');
  }

  Future<BotOrderModel> obtenerOrden(String id) async {
    final body = await _request(
      () => http.get(Uri.parse('$_baseUrl/$id')),
    );

    if (body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al obtener orden');
  }

  Future<BotOrderModel> crearOrden(Map<String, dynamic> data) async {
    final body = await _request(
      () => http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ),
    );

    if (body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al crear orden');
  }

  Future<BotOrderModel> actualizarOrden(
      String id, Map<String, dynamic> data) async {
    final body = await _request(
      () => http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ),
    );

    if (body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar orden');
  }

  Future<BotOrderModel> cambiarEstado(String id, String estado) async {
    final body = await _request(
      () => http.patch(
        Uri.parse('$_baseUrl/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': estado}),
      ),
    );

    if (body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al cambiar estado');
  }

  Future<void> eliminarOrden(String id) async {
    final body = await _request(
      () => http.delete(Uri.parse('$_baseUrl/$id')),
    );

    if (body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar orden');
  }
}
