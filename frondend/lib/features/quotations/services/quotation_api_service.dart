import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/bot_quotation_model.dart';

class QuotationApiService {
  static const Duration _timeout = Duration(seconds: 15);

  String _baseUrl({String? botId}) => botId != null && botId.isNotEmpty
      ? '${ApiConfig.baseUrl}/api/bots/$botId/quotations'
      : '${ApiConfig.baseUrl}/api/quotations';

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

      if (response.body.trimLeft().startsWith('<!DOCTYPE html>') ||
          response.body.trimLeft().startsWith('<html') ||
          response.body.trimLeft().startsWith('<')) {
        throw Exception(
          'La API devolvió HTML. Revisa la URL del backend o la ruta del endpoint.\n'
          'URL: $url\n'
          'Status: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Formato de respuesta inválido: se esperaba un objeto JSON',
        );
      }

      if (response.statusCode >= 400) {
        final message = decoded['message']?.toString();
        final error = decoded['error']?.toString();
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

      return decoded;
    } on TimeoutException {
      throw Exception('La solicitud tardó demasiado. Verifica tu conexión.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: $e');
    }
  }

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

    final url = _baseUrl(botId: botId);
    final uri = Uri.parse(url).replace(
      queryParameters: botId == null && params.isNotEmpty ? params : null,
    );

    final body = await _request(
      'QuotationApiService.listarCotizaciones',
      uri.toString(),
      () => http.get(uri),
    );

    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => BotQuotationModel.fromJson(item)).toList();
    }

    final message = body['message']?.toString() ?? 'Error al listar cotizaciones';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<BotQuotationModel> obtenerCotizacion(
    String id, {
    String? botId,
  }) async {
    final url = '${_baseUrl(botId: botId)}/$id';
    final body = await _request(
      'QuotationApiService.obtenerCotizacion',
      url,
      () => http.get(Uri.parse(url)),
    );

    if (body['ok'] == true) {
      return BotQuotationModel.fromJson(body['data']);
    }

    final message = body['message']?.toString() ?? 'Error al obtener cotización';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<BotQuotationModel> crearCotizacion(
    Map<String, dynamic> data, {
    String? botId,
  }) async {
    final resolvedBotId = botId ?? data['botId']?.toString();
    final url = _baseUrl(botId: resolvedBotId);
    final body = await _request(
      'QuotationApiService.crearCotizacion',
      url,
      () => http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ),
    );

    if (body['ok'] == true) {
      return BotQuotationModel.fromJson(body['data']);
    }

    final message = body['message']?.toString() ?? 'Error al crear cotización';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<BotQuotationModel> actualizarCotizacion(
    String id,
    Map<String, dynamic> data, {
    String? botId,
  }) async {
    final resolvedBotId = botId ?? data['botId']?.toString();
    final url = '${_baseUrl(botId: resolvedBotId)}/$id';
    final body = await _request(
      'QuotationApiService.actualizarCotizacion',
      url,
      () => http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ),
    );

    if (body['ok'] == true) {
      return BotQuotationModel.fromJson(body['data']);
    }

    final message = body['message']?.toString() ?? 'Error al actualizar cotización';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<BotQuotationModel> cambiarEstado(
    String id,
    String estado, {
    String? botId,
  }) async {
    final url = '${_baseUrl(botId: botId)}/$id/status';
    final body = await _request(
      'QuotationApiService.cambiarEstado',
      url,
      () => http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': estado}),
      ),
    );

    if (body['ok'] == true) {
      return BotQuotationModel.fromJson(body['data']);
    }

    final message = body['message']?.toString() ?? 'Error al cambiar estado';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<void> eliminarCotizacion(String id, {String? botId}) async {
    final url = '${_baseUrl(botId: botId)}/$id';
    final body = await _request(
      'QuotationApiService.eliminarCotizacion',
      url,
      () => http.delete(Uri.parse(url)),
    );

    if (body['ok'] == true) {
      return;
    }

    final message = body['message']?.toString() ?? 'Error al eliminar cotización';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }
}
