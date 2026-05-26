import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/scheduled_followup_model.dart';
import '../models/conversation_recovery_model.dart';

class FollowupsApiService {
  static const Duration _timeout = Duration(seconds: 15);

  String _scheduledEndpoint(String botId) =>
      '${ApiConfig.baseUrl}/api/bots/${Uri.encodeComponent(botId)}/followups/scheduled';

  String _recoveryEndpoint(String botId) =>
      '${ApiConfig.baseUrl}/api/bots/${Uri.encodeComponent(botId)}/followups/recovery';

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> _request(
    String label,
    String url,
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      debugPrint('[$label] URL: $url');
      final response = await requestFn().timeout(_timeout);
      debugPrint('[$label] STATUS: ${response.statusCode}');

      if (response.body.isEmpty) {
        throw Exception('Respuesta vacía del servidor');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Formato de respuesta inválido');
      }

      if (response.statusCode >= 400) {
        throw Exception(decoded['message']?.toString() ?? 'Error HTTP ${response.statusCode}');
      }

      return decoded;
    } on TimeoutException {
      throw Exception('La solicitud tardó demasiado. Verifica tu conexión.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: $e');
    }
  }

  // ================================================================
  // SCHEDULED FOLLOWUPS
  // ================================================================

  Future<Map<String, dynamic>> listarScheduled({
    required String botId,
    String? estado,
    String? tipoSeguimiento,
    String? nivel,
    String? clienteCompro,
    String? fecha,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (estado != null) params['estado'] = estado;
    if (tipoSeguimiento != null) params['tipo_seguimiento'] = tipoSeguimiento;
    if (nivel != null) params['nivel'] = nivel;
    if (clienteCompro != null) params['cliente_compro'] = clienteCompro;
    if (fecha != null) params['fecha'] = fecha;
    if (search != null) params['search'] = search;

    final uri = Uri.parse(_scheduledEndpoint(botId)).replace(queryParameters: params);
    final body = await _request(
      'FollowupsApiService.listarScheduled',
      uri.toString(),
      () => http.get(uri, headers: _headers()),
    );

    if (body['ok'] == true) {
      final rawData = body['data'];
      final List<ScheduledFollowupModel> items = (rawData as List?)
              ?.map((item) => ScheduledFollowupModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ))
              .toList() ??
          [];

      return {
        'data': items,
        'pagination': body['pagination'] ?? {'total': 0, 'hasMore': false},
      };
    }

    throw Exception(body['message']?.toString() ?? 'Error al listar seguimientos');
  }

  Future<ScheduledFollowupModel> obtenerScheduled(String botId, String id) async {
    final url = '${_scheduledEndpoint(botId)}/${Uri.encodeComponent(id)}';
    final body = await _request(
      'FollowupsApiService.obtenerScheduled',
      url,
      () => http.get(Uri.parse(url), headers: _headers()),
    );

    if (body['ok'] == true) {
      return ScheduledFollowupModel.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw Exception(body['message']?.toString() ?? 'Error al obtener seguimiento');
  }

  Future<ScheduledFollowupModel> actualizarScheduled(
      String botId, String id, Map<String, dynamic> data) async {
    final url = '${_scheduledEndpoint(botId)}/${Uri.encodeComponent(id)}';
    final body = await _request(
      'FollowupsApiService.actualizarScheduled',
      url,
      () => http.patch(
        Uri.parse(url),
        headers: _headers(),
        body: jsonEncode(data),
      ),
    );

    if (body['ok'] == true) {
      return ScheduledFollowupModel.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw Exception(body['message']?.toString() ?? 'Error al actualizar seguimiento');
  }

  Future<ScheduledFollowupModel> finalizarScheduled(String botId, String id) async {
    final url = '${_scheduledEndpoint(botId)}/${Uri.encodeComponent(id)}/finalize';
    final body = await _request(
      'FollowupsApiService.finalizarScheduled',
      url,
      () => http.post(Uri.parse(url), headers: _headers()),
    );

    if (body['ok'] == true) {
      return ScheduledFollowupModel.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw Exception(body['message']?.toString() ?? 'Error al finalizar seguimiento');
  }

  Future<ScheduledFollowupModel> cancelarScheduled(String botId, String id) async {
    final url = '${_scheduledEndpoint(botId)}/${Uri.encodeComponent(id)}/cancel';
    final body = await _request(
      'FollowupsApiService.cancelarScheduled',
      url,
      () => http.post(Uri.parse(url), headers: _headers()),
    );

    if (body['ok'] == true) {
      return ScheduledFollowupModel.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw Exception(body['message']?.toString() ?? 'Error al cancelar seguimiento');
  }

  Future<ScheduledFollowupModel> reactivarScheduled(String botId, String id) async {
    final url = '${_scheduledEndpoint(botId)}/${Uri.encodeComponent(id)}/reactivate';
    final body = await _request(
      'FollowupsApiService.reactivarScheduled',
      url,
      () => http.post(Uri.parse(url), headers: _headers()),
    );

    if (body['ok'] == true) {
      return ScheduledFollowupModel.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw Exception(body['message']?.toString() ?? 'Error al reactivar seguimiento');
  }

  // ================================================================
  // RECOVERY FOLLOWUPS
  // ================================================================

  Future<Map<String, dynamic>> listarRecovery({
    required String botId,
    String? estado,
    String? etapa,
    String? nivel,
    String? fecha,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (estado != null) params['estado'] = estado;
    if (etapa != null) params['etapa'] = etapa;
    if (nivel != null) params['nivel'] = nivel;
    if (fecha != null) params['fecha'] = fecha;
    if (search != null) params['search'] = search;

    final uri = Uri.parse(_recoveryEndpoint(botId)).replace(queryParameters: params);
    final body = await _request(
      'FollowupsApiService.listarRecovery',
      uri.toString(),
      () => http.get(uri, headers: _headers()),
    );

    if (body['ok'] == true) {
      final rawData = body['data'];
      final List<ConversationRecoveryModel> items = (rawData as List?)
              ?.map((item) => ConversationRecoveryModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ))
              .toList() ??
          [];

      return {
        'data': items,
        'pagination': body['pagination'] ?? {'total': 0, 'hasMore': false},
      };
    }

    throw Exception(body['message']?.toString() ?? 'Error al listar recuperaciones');
  }

  Future<ConversationRecoveryModel> obtenerRecovery(String botId, String id) async {
    final url = '${_recoveryEndpoint(botId)}/${Uri.encodeComponent(id)}';
    final body = await _request(
      'FollowupsApiService.obtenerRecovery',
      url,
      () => http.get(Uri.parse(url), headers: _headers()),
    );

    if (body['ok'] == true) {
      return ConversationRecoveryModel.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw Exception(body['message']?.toString() ?? 'Error al obtener recuperación');
  }

  Future<ConversationRecoveryModel> actualizarRecovery(
      String botId, String id, Map<String, dynamic> data) async {
    final url = '${_recoveryEndpoint(botId)}/${Uri.encodeComponent(id)}';
    final body = await _request(
      'FollowupsApiService.actualizarRecovery',
      url,
      () => http.patch(
        Uri.parse(url),
        headers: _headers(),
        body: jsonEncode(data),
      ),
    );

    if (body['ok'] == true) {
      return ConversationRecoveryModel.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw Exception(body['message']?.toString() ?? 'Error al actualizar recuperación');
  }

  Future<ConversationRecoveryModel> finalizarRecovery(String botId, String id) async {
    final url = '${_recoveryEndpoint(botId)}/${Uri.encodeComponent(id)}/finalize';
    final body = await _request(
      'FollowupsApiService.finalizarRecovery',
      url,
      () => http.post(Uri.parse(url), headers: _headers()),
    );

    if (body['ok'] == true) {
      return ConversationRecoveryModel.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw Exception(body['message']?.toString() ?? 'Error al finalizar recuperación');
  }

  Future<ConversationRecoveryModel> cancelarRecovery(String botId, String id) async {
    final url = '${_recoveryEndpoint(botId)}/${Uri.encodeComponent(id)}/cancel';
    final body = await _request(
      'FollowupsApiService.cancelarRecovery',
      url,
      () => http.post(Uri.parse(url), headers: _headers()),
    );

    if (body['ok'] == true) {
      return ConversationRecoveryModel.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw Exception(body['message']?.toString() ?? 'Error al cancelar recuperación');
  }

  Future<ConversationRecoveryModel> reactivarRecovery(String botId, String id) async {
    final url = '${_recoveryEndpoint(botId)}/${Uri.encodeComponent(id)}/reactivate';
    final body = await _request(
      'FollowupsApiService.reactivarRecovery',
      url,
      () => http.post(Uri.parse(url), headers: _headers()),
    );

    if (body['ok'] == true) {
      return ConversationRecoveryModel.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    throw Exception(body['message']?.toString() ?? 'Error al reactivar recuperación');
  }
}
