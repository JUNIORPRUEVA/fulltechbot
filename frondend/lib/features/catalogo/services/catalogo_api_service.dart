import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_config.dart';
import '../models/catalogo_model.dart';

class CatalogoApiService {
  String _buildUrl(String? botId) {
    if (botId != null && botId.isNotEmpty) {
      return '${ApiConfig.baseUrl}/api/bots/$botId/catalogo';
    }
    return ApiConfig.catalogoEndpoint;
  }

  Future<List<CatalogoModel>> listarProductos({String? botId}) async {
    final baseUrl = _buildUrl(botId);
    final response = await http.get(
      Uri.parse(baseUrl),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => CatalogoModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar productos');
  }

  Future<List<CatalogoModel>> listarProductosActivos({String? botId}) async {
    final baseUrl = _buildUrl(botId);
    final response = await http.get(
      Uri.parse('$baseUrl/activos'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => CatalogoModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar productos activos');
  }

  Future<CatalogoModel> crearProducto(CatalogoModel producto, {String? botId}) async {
    final baseUrl = _buildUrl(botId);
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(producto.toJson()),
    );

    final body = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['ok'] == true) {
      return CatalogoModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al crear producto');
  }

  Future<CatalogoModel> actualizarProducto(CatalogoModel producto, {String? botId}) async {
    final baseUrl = _buildUrl(botId);
    final response = await http.put(
      Uri.parse('$baseUrl/${producto.id}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(producto.toJson()),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return CatalogoModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar producto');
  }

  Future<CatalogoModel> cambiarEstado({
    required String id,
    required String estado,
    String? botId,
  }) async {
    final baseUrl = _buildUrl(botId);
    final response = await http.patch(
      Uri.parse('$baseUrl/$id/estado'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'estado': estado,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return CatalogoModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al cambiar estado');
  }

  Future<void> eliminarProducto(String id, {String? botId}) async {
    final baseUrl = _buildUrl(botId);
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar producto');
  }
}
