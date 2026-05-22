import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../models/bot_campaign_model.dart';
import '../models/campaign_context_model.dart';

class BotCampaignApiService {
  static const Duration _timeout = Duration(seconds: 20);

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

      if (body['ok'] != true) {
        throw Exception(body['message'] ?? 'Error en la solicitud');
      }

      return body;
    } on TimeoutException {
      throw Exception('La solicitud tardó demasiado. Verifica tu conexión.');
    }
  }

  Future<List<BotCampaignModel>> listarCampanas(
    String botId, {
    bool? active,
    String? search,
  }) async {
    final uri = Uri.parse(ApiConfig.botCampaignsEndpoint(botId)).replace(
      queryParameters: {
        if (active != null) 'active': active.toString(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final body = await _request(() => http.get(uri));
    final List data = body['data'] ?? [];
    return data
        .map((item) => BotCampaignModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<BotCampaignModel> crearCampana(
    String botId,
    Map<String, dynamic> payload,
  ) async {
    final body = await _request(
      () => http.post(
        Uri.parse(ApiConfig.botCampaignsEndpoint(botId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ),
    );
    return BotCampaignModel.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<BotCampaignModel> actualizarCampana(
    String botId,
    String campaignId,
    Map<String, dynamic> payload,
  ) async {
    final body = await _request(
      () => http.patch(
        Uri.parse(ApiConfig.botCampaignByIdEndpoint(botId, campaignId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ),
    );
    return BotCampaignModel.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<BotCampaignModel> cambiarEstado(
    String botId,
    String campaignId,
    bool active,
  ) async {
    final body = await _request(
      () => http.patch(
        Uri.parse('${ApiConfig.botCampaignByIdEndpoint(botId, campaignId)}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'active': active}),
      ),
    );
    return BotCampaignModel.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<void> eliminarCampana(String botId, String campaignId) async {
    await _request(
      () => http.delete(
        Uri.parse(ApiConfig.botCampaignByIdEndpoint(botId, campaignId)),
      ),
    );
  }

  Future<BotCampaignModel> duplicarCampana(
    String botId,
    String campaignId, {
    String? campaignCode,
  }) async {
    final body = await _request(
      () => http.post(
        Uri.parse('${ApiConfig.botCampaignByIdEndpoint(botId, campaignId)}/duplicate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (campaignCode != null && campaignCode.trim().isNotEmpty)
            'campaign_code': campaignCode.trim(),
        }),
      ),
    );
    return BotCampaignModel.fromJson(Map<String, dynamic>.from(body['data']));
  }

  Future<CampaignContextModel?> obtenerContextoConversacion(
    String conversationId,
  ) async {
    final body = await _request(
      () => http.get(Uri.parse(ApiConfig.botCampaignContextEndpoint(conversationId))),
    );
    final data = body['data'];
    if (data == null) return null;
    return CampaignContextModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<CampaignContextModel>> obtenerHistorialContexto(
    String conversationId,
  ) async {
    final body = await _request(
      () => http.get(
        Uri.parse(ApiConfig.botCampaignContextHistoryEndpoint(conversationId)),
      ),
    );
    final List data = body['data'] ?? [];
    return data
        .map((item) => CampaignContextModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<BotCampaignModel> cambiarCampanaConversacion({
    required String botId,
    required String conversationId,
    required String campaignId,
    String? customerId,
  }) async {
    final body = await _request(
      () => http.post(
        Uri.parse(
          ApiConfig.botConversationChangeCampaignEndpoint(botId, conversationId),
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'campaign_id': campaignId,
          if (customerId != null && customerId.trim().isNotEmpty)
            'customer_id': customerId,
        }),
      ),
    );
    return BotCampaignModel.fromJson(Map<String, dynamic>.from(body['data']));
  }
}
