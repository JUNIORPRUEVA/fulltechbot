import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/cliente_model.dart';

class ClientesApiService {
  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> _getHeaders({String? userRole}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (userRole != null && userRole.isNotEmpty) {
      headers['X-User-Role'] = userRole;
    }
    return headers;
  }

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

  Future<List<ClienteModel>> listarClientes({required String botId}) async {
    final body = await _request(
      () => http.get(Uri.parse(ApiConfig.botClientsEndpoint(botId))),
    );

    if (body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => ClienteModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar clientes');
  }

  Future<ClienteModel> obtenerCliente(String botId, String telefono) async {
    final body = await _request(
      () => http.get(
        Uri.parse(ApiConfig.botClientByPhoneLookupEndpoint(botId, telefono)),
      ),
    );

    if (body['ok'] == true) {
      return ClienteModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al obtener cliente');
  }

  Future<ClienteModel> crearCliente(String botId, ClienteModel cliente) async {
    final body = await _request(
      () => http.post(
        Uri.parse(ApiConfig.botClientsEndpoint(botId)),
        headers: _getHeaders(),
        body: jsonEncode(cliente.toJson()),
      ),
    );

    if (body['ok'] == true) {
      return ClienteModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al crear cliente');
  }

  Future<ClienteModel> actualizarCliente(
    String botId,
    ClienteModel cliente,
  ) async {
    final body = await _request(
      () => http.put(
        Uri.parse(ApiConfig.botClientByPhoneEndpoint(botId, cliente.telefono)),
        headers: _getHeaders(),
        body: jsonEncode(cliente.toJson()),
      ),
    );

    if (body['ok'] == true) {
      return ClienteModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar cliente');
  }

  Future<void> eliminarCliente(
    String botId,
    String telefono, {
    String? userRole,
  }) async {
    final body = await _request(
      () => http.delete(
        Uri.parse(ApiConfig.botClientByPhoneEndpoint(botId, telefono)),
        headers: _getHeaders(userRole: userRole),
      ),
    );

    if (body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar cliente');
  }
}
