import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/catalogo_model.dart';

class CatalogoApiService {
  static const Duration _timeout = Duration(seconds: 15);

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

  Future<List<CatalogoModel>> listarProductos({String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo')
        : Uri.parse(ApiConfig.catalogoEndpoint);
    final url = uri.toString();
    final body = await _request(
      'CatalogoApiService.listarProductos',
      url,
      () => http.get(uri),
    );

    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => CatalogoModel.fromJson(item)).toList();
    }

    final message = body['message']?.toString() ?? 'Error al listar productos';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<CatalogoModel> obtenerProducto(String id, {String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo/$id')
        : Uri.parse('${ApiConfig.catalogoEndpoint}/$id');
    final url = uri.toString();
    final body = await _request(
      'CatalogoApiService.obtenerProducto',
      url,
      () => http.get(uri),
    );

    if (body['ok'] == true) {
      return CatalogoModel.fromJson(body['data']);
    }

    final message = body['message']?.toString() ?? 'Error al obtener producto';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<CatalogoModel> crearProducto(CatalogoModel producto,
      {String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo')
        : Uri.parse(ApiConfig.catalogoEndpoint);
    final url = uri.toString();
    final body = await _request(
      'CatalogoApiService.crearProducto',
      url,
      () => http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(producto.toJson()),
      ),
    );

    if ((body['ok'] == true)) {
      return CatalogoModel.fromJson(body['data']);
    }

    final message = body['message']?.toString() ?? 'Error al crear producto';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<CatalogoModel> actualizarProducto(CatalogoModel producto,
      {String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo/${producto.id}')
        : Uri.parse('${ApiConfig.catalogoEndpoint}/${producto.id}');
    final url = uri.toString();
    final body = await _request(
      'CatalogoApiService.actualizarProducto',
      url,
      () => http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(producto.toJson()),
      ),
    );

    if (body['ok'] == true) {
      return CatalogoModel.fromJson(body['data']);
    }

    final message = body['message']?.toString() ?? 'Error al actualizar producto';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<void> cambiarEstado({
    required String id,
    required String estado,
    String? botId,
  }) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo/$id/status')
        : Uri.parse('${ApiConfig.catalogoEndpoint}/$id/status');
    final url = uri.toString();
    final body = await _request(
      'CatalogoApiService.cambiarEstado',
      url,
      () => http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': estado}),
      ),
    );

    if (body['ok'] == true) {
      return;
    }

    final message = body['message']?.toString() ?? 'Error al cambiar estado';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<void> eliminarProducto(String id, {String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo/$id')
        : Uri.parse('${ApiConfig.catalogoEndpoint}/$id');
    final url = uri.toString();
    final body = await _request(
      'CatalogoApiService.eliminarProducto',
      url,
      () => http.delete(uri),
    );

    if (body['ok'] == true) {
      return;
    }

    final message = body['message']?.toString() ?? 'Error al eliminar producto';
    final error = body['error']?.toString();
    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }
}
