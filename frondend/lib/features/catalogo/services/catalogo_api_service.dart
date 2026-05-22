import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/catalogo_model.dart';

class CatalogoApiService {
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

  Future<List<CatalogoModel>> listarProductos({String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo')
        : Uri.parse(ApiConfig.catalogoEndpoint);
    final body = await _request(() => http.get(uri));

    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => CatalogoModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar productos');
  }

  Future<CatalogoModel> obtenerProducto(String id, {String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo/$id')
        : Uri.parse('${ApiConfig.catalogoEndpoint}/$id');
    final body = await _request(() => http.get(uri));

    if (body['ok'] == true) {
      return CatalogoModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al obtener producto');
  }

  Future<CatalogoModel> crearProducto(CatalogoModel producto,
      {String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo')
        : Uri.parse(ApiConfig.catalogoEndpoint);
    final body = await _request(
      () => http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(producto.toJson()),
      ),
    );

    if ((body['ok'] == true)) {
      return CatalogoModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al crear producto');
  }

  Future<CatalogoModel> actualizarProducto(CatalogoModel producto,
      {String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo/${producto.id}')
        : Uri.parse('${ApiConfig.catalogoEndpoint}/${producto.id}');
    final body = await _request(
      () => http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(producto.toJson()),
      ),
    );

    if (body['ok'] == true) {
      return CatalogoModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar producto');
  }

  Future<void> cambiarEstado({
    required String id,
    required String estado,
    String? botId,
  }) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo/$id/status')
        : Uri.parse('${ApiConfig.catalogoEndpoint}/$id/status');
    final body = await _request(
      () => http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': estado}),
      ),
    );

    if (body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al cambiar estado');
  }

  Future<void> eliminarProducto(String id, {String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.baseUrl}/api/bots/$botId/catalogo/$id')
        : Uri.parse('${ApiConfig.catalogoEndpoint}/$id');
    final body = await _request(() => http.delete(uri));

    if (body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar producto');
  }
}
