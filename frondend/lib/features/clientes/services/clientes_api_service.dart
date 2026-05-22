import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/cliente_model.dart';

class ClientesApiService {
  static const Duration _timeout = Duration(seconds: 15);

  /// Obtiene los headers base incluyendo el rol del usuario para autorización.
  /// Por defecto envía 'admin' para que funcione en desarrollo.
  /// En producción, esto debe venir del sistema de autenticación.
  Map<String, String> _getHeaders({String? userRole}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (userRole != null) {
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
        headers: _getHeaders(),
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
        headers: _getHeaders(),
        body: jsonEncode(cliente.toJson()),
      ),
    );

    if (body['ok'] == true) {
      return ClienteModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar cliente');
  }

  /// Elimina un cliente de forma permanente.
  /// Requiere rol admin/owner (se envía en header X-User-Role).
  Future<void> eliminarCliente(String telefono, {String? userRole}) async {
    final body = await _request(
      () => http.delete(
        Uri.parse('${ApiConfig.botClientEndpoint}/$telefono'),
        headers: _getHeaders(userRole: userRole),
      ),
    );

    if (body['ok'] == true) {
      return;
    }

    // Si es error 403, lanzar mensaje claro de permisos
    throw Exception(body['message'] ?? 'Error al eliminar cliente');
  }
}
