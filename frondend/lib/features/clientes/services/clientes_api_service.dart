import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/cliente_model.dart';

class ClientesApiService {
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

  Future<List<ClienteModel>> listarClientes({String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.botClientEndpoint}?botId=$botId')
        : Uri.parse(ApiConfig.botClientEndpoint);
    final body = await _request(() => http.get(uri));

    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => ClienteModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar clientes');
  }

  Future<ClienteModel> obtenerCliente(String telefono) async {
    final body = await _request(
      () => http.get(
        Uri.parse('${ApiConfig.botClientEndpoint}/by-phone/$telefono'),
      ),
    );

    if (body['ok'] == true) {
      return ClienteModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al obtener cliente');
  }

  Future<ClienteModel> crearCliente(ClienteModel cliente) async {
    final body = await _request(
      () => http.post(
        Uri.parse(ApiConfig.botClientEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cliente.toJson()),
      ),
    );

    if ((body['ok'] == true)) {
      return ClienteModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al crear cliente');
  }

  Future<ClienteModel> actualizarCliente(ClienteModel cliente) async {
    final body = await _request(
      () => http.put(
        Uri.parse('${ApiConfig.botClientEndpoint}/${cliente.telefono}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(cliente.toJson()),
      ),
    );

    if (body['ok'] == true) {
      return ClienteModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar cliente');
  }

  Future<void> eliminarCliente(String telefono) async {
    final body = await _request(
      () => http.delete(
        Uri.parse('${ApiConfig.botClientEndpoint}/$telefono'),
      ),
    );

    if (body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar cliente');
  }
}
