import 'package:flutter/foundation.dart';

import '../models/bot_campaign_model.dart';
import '../services/bot_campaign_api_service.dart';

class BotCampaignProvider extends ChangeNotifier {
  final BotCampaignApiService _apiService = BotCampaignApiService();

  List<BotCampaignModel> _campaigns = [];
  bool _isLoading = false;
  String? _error;

  List<BotCampaignModel> get campaigns => _campaigns;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarCampanas(
    String botId, {
    bool? active,
    String? search,
  }) async {
    _setLoading(true);
    try {
      _campaigns = await _apiService.listarCampanas(
        botId,
        active: active,
        search: search,
      );
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _setLoading(false);
  }

  Future<BotCampaignModel?> crearCampana(
    String botId,
    Map<String, dynamic> payload,
  ) async {
    _setLoading(true);
    try {
      final campaign = await _apiService.crearCampana(botId, payload);
      _campaigns = [campaign, ..._campaigns];
      _sortCampaigns();
      _error = null;
      return campaign;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<BotCampaignModel?> actualizarCampana(
    String botId,
    String campaignId,
    Map<String, dynamic> payload,
  ) async {
    _setLoading(true);
    try {
      final campaign =
          await _apiService.actualizarCampana(botId, campaignId, payload);
      _campaigns = _campaigns
          .map((item) => item.id == campaign.id ? campaign : item)
          .toList();
      _sortCampaigns();
      _error = null;
      return campaign;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cambiarEstado(
    String botId,
    String campaignId,
    bool active,
  ) async {
    _setLoading(true);
    try {
      final campaign = await _apiService.cambiarEstado(botId, campaignId, active);
      _campaigns = _campaigns
          .map((item) => item.id == campaign.id ? campaign : item)
          .toList();
      _sortCampaigns();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> duplicarCampana(String botId, String campaignId) async {
    _setLoading(true);
    try {
      final campaign = await _apiService.duplicarCampana(botId, campaignId);
      _campaigns = [campaign, ..._campaigns];
      _sortCampaigns();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> eliminarCampana(String botId, String campaignId) async {
    _setLoading(true);
    try {
      await _apiService.eliminarCampana(botId, campaignId);
      _campaigns.removeWhere((item) => item.id == campaignId);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  void _sortCampaigns() {
    _campaigns.sort((a, b) {
      return a.campaignName.compareTo(b.campaignName);
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
