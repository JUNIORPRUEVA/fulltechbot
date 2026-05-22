import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/bot_order_model.dart';

class OrderApiService {
  static const Duration _timeout = Duration(seconds: 15);

  String _baseUrl({String? botId}) => botId != null && botId.isNotEmpty
      ? '${ApiConfig.baseUrl}/api/bots/$botId/orders'
      : '${ApiConfig.baseUrl}/api/orders';

  Map<String, dynamic> _validateAndDecode(http.Response response) {
    final body = response.body;

    if (body.isEmpty) {
      throw Exception('Respuesta vacia del servidor');
    }

    if (body.trimLeft().startsWith('<!DOCTYPE html>') ||
        body.trimLeft().startsWith('<html') ||
        body.trimLeft().startsWith('<')) {
      throw Exception(
        'La API devolvio HTML. Revisa la URL del backend o la ruta del endpoint.\n'
        'URL: ${response.request?.url}\n'
        'Status: ${response.statusCode}',
      );
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Formato de respuesta invalido: se esperaba un objeto JSON',
        );
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
      throw Exception('La solicitud tardo demasiado. Verifica tu conexion.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexion: $e');
    }
  }

  bool _shouldFallbackToGlobal(Object error) {
    final message = error.toString().toLowerCase();
    return (message.contains('html') && message.contains('404')) ||
        message.contains('ruta no encontrada') ||
        message.contains('status: 404');
  }

  Future<Map<String, dynamic>> _requestWithFallback({
    required Future<Map<String, dynamic>> Function() primary,
    required Future<Map<String, dynamic>> Function() fallback,
  }) async {
    try {
      return await primary();
    } catch (error) {
      if (_shouldFallbackToGlobal(error)) {
        return fallback();
      }
      rethrow;
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

    final nestedUri = Uri.parse(_baseUrl(botId: botId));
    final globalUri = Uri.parse(
      _baseUrl(),
    ).replace(queryParameters: params.isNotEmpty ? params : null);

    final body = botId != null && botId.isNotEmpty
        ? await _requestWithFallback(
            primary: () => _request(() => http.get(nestedUri)),
            fallback: () => _request(() => http.get(globalUri)),
          )
        : await _request(() => http.get(globalUri));

    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => BotOrderModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar ordenes');
  }

  Future<BotOrderModel> obtenerOrden(String id, {String? botId}) async {
    final nestedUri = Uri.parse('${_baseUrl(botId: botId)}/$id');
    final globalUri = Uri.parse('${_baseUrl()}/$id');

    final body = botId != null && botId.isNotEmpty
        ? await _requestWithFallback(
            primary: () => _request(() => http.get(nestedUri)),
            fallback: () => _request(() => http.get(globalUri)),
          )
        : await _request(() => http.get(globalUri));

    if (body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al obtener orden');
  }

  Future<BotOrderModel> crearOrden(
    Map<String, dynamic> data, {
    String? botId,
  }) async {
    final resolvedBotId = botId ?? data['botId']?.toString();
    final nestedUri = Uri.parse(_baseUrl(botId: resolvedBotId));
    final globalUri = Uri.parse(_baseUrl());
    final globalPayload = {
      ...data,
      if (resolvedBotId != null && resolvedBotId.isNotEmpty)
        'botId': resolvedBotId,
    };

    final body = resolvedBotId != null && resolvedBotId.isNotEmpty
        ? await _requestWithFallback(
            primary: () => _request(
              () => http.post(
                nestedUri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(data),
              ),
            ),
            fallback: () => _request(
              () => http.post(
                globalUri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(globalPayload),
              ),
            ),
          )
        : await _request(
            () => http.post(
              globalUri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(globalPayload),
            ),
          );

    if (body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al crear orden');
  }

  Future<BotOrderModel> actualizarOrden(
    String id,
    Map<String, dynamic> data, {
    String? botId,
  }) async {
    final resolvedBotId = botId ?? data['botId']?.toString();
    final nestedUri = Uri.parse('${_baseUrl(botId: resolvedBotId)}/$id');
    final globalUri = Uri.parse('${_baseUrl()}/$id');

    final body = resolvedBotId != null && resolvedBotId.isNotEmpty
        ? await _requestWithFallback(
            primary: () => _request(
              () => http.put(
                nestedUri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(data),
              ),
            ),
            fallback: () => _request(
              () => http.put(
                globalUri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(data),
              ),
            ),
          )
        : await _request(
            () => http.put(
              globalUri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(data),
            ),
          );

    if (body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar orden');
  }

  Future<BotOrderModel> cambiarEstado(
    String id,
    String estado, {
    String? botId,
  }) async {
    final nestedUri = Uri.parse('${_baseUrl(botId: botId)}/$id/status');
    final globalUri = Uri.parse('${_baseUrl()}/$id/status');
    final payload = {'estado': estado};

    final body = botId != null && botId.isNotEmpty
        ? await _requestWithFallback(
            primary: () => _request(
              () => http.patch(
                nestedUri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(payload),
              ),
            ),
            fallback: () => _request(
              () => http.patch(
                globalUri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(payload),
              ),
            ),
          )
        : await _request(
            () => http.patch(
              globalUri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            ),
          );

    if (body['ok'] == true) {
      return BotOrderModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al cambiar estado');
  }

  Future<void> eliminarOrden(String id, {String? botId}) async {
    final nestedUri = Uri.parse('${_baseUrl(botId: botId)}/$id');
    final globalUri = Uri.parse('${_baseUrl()}/$id');

    final body = botId != null && botId.isNotEmpty
        ? await _requestWithFallback(
            primary: () => _request(() => http.delete(nestedUri)),
            fallback: () => _request(() => http.delete(globalUri)),
          )
        : await _request(() => http.delete(globalUri));

    if (body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar orden');
  }
}
