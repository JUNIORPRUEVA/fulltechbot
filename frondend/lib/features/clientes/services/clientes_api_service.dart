import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/cliente_model.dart';

class ClientesApiService {
  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> _getHeaders({String? userRole}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (userRole != null && userRole.isNotEmpty) {
      headers['X-User-Role'] = userRole;
    }

    return headers;
  }

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

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Respuesta no es JSON válido. Status: ${response.statusCode}. Body: ${response.body}',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Formato de respuesta inválido. Se esperaba un objeto JSON. Body: ${response.body}',
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

  Future<List<ClienteModel>> listarClientes({required String botId}) async {
    if (botId.trim().isEmpty) {
      throw Exception('botId requerido para listar clientes');
    }

    final url = ApiConfig.botClientsEndpoint(botId);

    final body = await _request(
      'ClientesApiService.listarClientes',
      url,
      () => http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ),
    );

    if (body['ok'] == true) {
      final rawData = body['data'];

      if (rawData == null) {
        return [];
      }

      if (rawData is! List) {
        throw Exception(
          'La respuesta de clientes no es una lista. data=${rawData.runtimeType}',
        );
      }

      return rawData
          .map((item) => ClienteModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    }

    final message = body['message']?.toString() ?? 'Error al listar clientes';
    final error = body['error']?.toString();

    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<ClienteModel> obtenerCliente(String botId, String telefono) async {
    if (botId.trim().isEmpty) {
      throw Exception('botId requerido para obtener cliente');
    }

    if (telefono.trim().isEmpty) {
      throw Exception('telefono requerido para obtener cliente');
    }

    final url = ApiConfig.botClientByPhoneLookupEndpoint(botId, telefono);

    final body = await _request(
      'ClientesApiService.obtenerCliente',
      url,
      () => http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ),
    );

    if (body['ok'] == true) {
      final data = body['data'];

      if (data == null) {
        throw Exception('El servidor no devolvió datos del cliente');
      }

      return ClienteModel.fromJson(Map<String, dynamic>.from(data as Map));
    }

    final message = body['message']?.toString() ?? 'Error al obtener cliente';
    final error = body['error']?.toString();

    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<ClienteModel> crearCliente(String botId, ClienteModel cliente) async {
    if (botId.trim().isEmpty) {
      throw Exception('botId requerido para crear cliente');
    }

    final url = ApiConfig.botClientsEndpoint(botId);

    final body = await _request(
      'ClientesApiService.crearCliente',
      url,
      () => http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode(cliente.toJson()),
      ),
    );

    if (body['ok'] == true) {
      final data = body['data'];

      if (data == null) {
        throw Exception('El servidor no devolvió datos del cliente creado');
      }

      return ClienteModel.fromJson(Map<String, dynamic>.from(data as Map));
    }

    final message = body['message']?.toString() ?? 'Error al crear cliente';
    final error = body['error']?.toString();

    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<ClienteModel> actualizarCliente(
    String botId,
    ClienteModel cliente,
  ) async {
    if (botId.trim().isEmpty) {
      throw Exception('botId requerido para actualizar cliente');
    }

    if (cliente.telefono.trim().isEmpty) {
      throw Exception('telefono requerido para actualizar cliente');
    }

    final url = ApiConfig.botClientByPhoneEndpoint(botId, cliente.telefono);

    final body = await _request(
      'ClientesApiService.actualizarCliente',
      url,
      () => http.put(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode(cliente.toJson()),
      ),
    );

    if (body['ok'] == true) {
      final data = body['data'];

      if (data == null) {
        throw Exception('El servidor no devolvió datos del cliente actualizado');
      }

      return ClienteModel.fromJson(Map<String, dynamic>.from(data as Map));
    }

    final message = body['message']?.toString() ?? 'Error al actualizar cliente';
    final error = body['error']?.toString();

    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }

  Future<void> eliminarCliente(
    String botId,
    String telefono, {
    String? userRole,
  }) async {
    if (botId.trim().isEmpty) {
      throw Exception('botId requerido para eliminar cliente');
    }

    if (telefono.trim().isEmpty) {
      throw Exception('telefono requerido para eliminar cliente');
    }

    final url = ApiConfig.botClientByPhoneEndpoint(botId, telefono);

    final body = await _request(
      'ClientesApiService.eliminarCliente',
      url,
      () => http.delete(
        Uri.parse(url),
        headers: _getHeaders(userRole: userRole),
      ),
    );

    if (body['ok'] == true) {
      return;
    }

    final message = body['message']?.toString() ?? 'Error al eliminar cliente';
    final error = body['error']?.toString();

    throw Exception(
      error == null || error.isEmpty ? message : '$message | $error',
    );
  }
}