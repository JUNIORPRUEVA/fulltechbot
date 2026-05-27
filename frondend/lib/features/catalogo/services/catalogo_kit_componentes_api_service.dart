import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/catalogo_kit_componente_model.dart';
import '../../../core/constants/api_config.dart';

class CatalogoKitComponentesApiService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Obtener todos los componentes de un kit
  Future<List<CatalogoKitComponenteModel>> obtenerComponentesKit(
      String kitId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/catalogo/$kitId/componentes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data
            .map((e) => CatalogoKitComponenteModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener componentes del kit: $e');
      return [];
    }
  }

  /// Obtener detalle completo del kit (kit + componentes incluidos + extras)
  Future<Map<String, dynamic>?> obtenerDetalleKit(String kitId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/catalogo/$kitId/detalle'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'];
      }
      return null;
    } catch (e) {
      print('Error al obtener detalle del kit: $e');
      return null;
    }
  }

  /// Agregar un componente al kit
  Future<CatalogoKitComponenteModel?> agregarComponenteKit(
    String kitId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/catalogo/$kitId/componentes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return CatalogoKitComponenteModel.fromJson(body['data']);
      }
      return null;
    } catch (e) {
      print('Error al agregar componente al kit: $e');
      return null;
    }
  }

  /// Actualizar un componente del kit
  Future<CatalogoKitComponenteModel?> actualizarComponenteKit(
    String kitId,
    String relacionId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/catalogo/$kitId/componentes/$relacionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return CatalogoKitComponenteModel.fromJson(body['data']);
      }
      return null;
    } catch (e) {
      print('Error al actualizar componente del kit: $e');
      return null;
    }
  }

  /// Eliminar un componente del kit
  Future<bool> eliminarComponenteKit(String kitId, String relacionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/catalogo/$kitId/componentes/$relacionId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error al eliminar componente del kit: $e');
      return false;
    }
  }

  /// Buscar productos disponibles para agregar como componente
  Future<List<Map<String, dynamic>>> buscarProductosParaComponente({
    required String botId,
    String? query,
    String? excludeKitId,
  }) async {
    try {
      final params = <String, String>{
        'botId': botId,
      };
      if (query != null && query.isNotEmpty) params['query'] = query;
      if (excludeKitId != null && excludeKitId.isNotEmpty) {
        params['excludeKitId'] = excludeKitId;
      }

      final uri =
          Uri.parse('$_baseUrl/api/catalogo/buscar-componentes').replace(
        queryParameters: params,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(body['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error al buscar productos para componente: $e');
      return [];
    }
  }
}
