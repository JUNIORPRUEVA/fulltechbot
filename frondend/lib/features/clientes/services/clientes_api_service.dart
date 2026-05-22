import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/cliente_model.dart';

class ClientesApiService {
  Future<List<ClienteModel>> listarClientes({String? botId}) async {
    final uri = botId != null
        ? Uri.parse('${ApiConfig.botClientEndpoint}?botId=$botId')
        : Uri.parse(ApiConfig.botClientEndpoint);
    final response = await http.get(uri);

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      final List data = body['data'] ?? [];
      return data.map((item) => ClienteModel.fromJson(item)).toList();
    }

    throw Exception(body['message'] ?? 'Error al listar clientes');
  }

  Future<ClienteModel> obtenerCliente(String telefono) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.botClientEndpoint}/by-phone/$telefono'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return ClienteModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al obtener cliente');
  }

  Future<ClienteModel> crearCliente(ClienteModel cliente) async {
    final response = await http.post(
      Uri.parse(ApiConfig.botClientEndpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(cliente.toJson()),
    );

    final body = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['ok'] == true) {
      return ClienteModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al crear cliente');
  }

  Future<ClienteModel> actualizarCliente(ClienteModel cliente) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.botClientEndpoint}/${cliente.telefono}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(cliente.toJson()),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return ClienteModel.fromJson(body['data']);
    }

    throw Exception(body['message'] ?? 'Error al actualizar cliente');
  }

  Future<void> eliminarCliente(String telefono) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.botClientEndpoint}/$telefono'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['ok'] == true) {
      return;
    }

    throw Exception(body['message'] ?? 'Error al eliminar cliente');
  }
}
