import 'package:flutter/material.dart';

import '../models/scheduled_followup_model.dart';
import '../models/conversation_recovery_model.dart';
import '../services/followups_api_service.dart';

class FollowupsProvider extends ChangeNotifier {
  final FollowupsApiService _apiService = FollowupsApiService();

  // Scheduled Followups
  List<ScheduledFollowupModel> _scheduledFollowups = [];
  bool _isLoadingScheduled = false;
  String? _errorScheduled;
  int _totalScheduled = 0;
  bool _hasMoreScheduled = false;

  // Recovery Followups
  List<ConversationRecoveryModel> _recoveryFollowups = [];
  bool _isLoadingRecovery = false;
  String? _errorRecovery;
  int _totalRecovery = 0;
  bool _hasMoreRecovery = false;

  // Getters Scheduled
  List<ScheduledFollowupModel> get scheduledFollowups => _scheduledFollowups;
  bool get isLoadingScheduled => _isLoadingScheduled;
  String? get errorScheduled => _errorScheduled;
  int get totalScheduled => _totalScheduled;
  bool get hasMoreScheduled => _hasMoreScheduled;

  // Getters Recovery
  List<ConversationRecoveryModel> get recoveryFollowups => _recoveryFollowups;
  bool get isLoadingRecovery => _isLoadingRecovery;
  String? get errorRecovery => _errorRecovery;
  int get totalRecovery => _totalRecovery;
  bool get hasMoreRecovery => _hasMoreRecovery;

  // ================================================================
  // SCHEDULED FOLLOWUPS
  // ================================================================

  Future<void> cargarScheduled({
    required String botId,
    bool refresh = false,
    String? estado,
    String? tipoSeguimiento,
    String? nivel,
    String? clienteCompro,
    String? fecha,
    String? search,
  }) async {
    _isLoadingScheduled = true;
    _errorScheduled = null;
    notifyListeners();

    try {
      if (refresh) {
        _scheduledFollowups = [];
      }

      final result = await _apiService.listarScheduled(
        botId: botId,
        estado: estado,
        tipoSeguimiento: tipoSeguimiento,
        nivel: nivel,
        clienteCompro: clienteCompro,
        fecha: fecha,
        search: search,
        offset: refresh ? 0 : _scheduledFollowups.length,
      );

      final List<ScheduledFollowupModel> items = result['data'] as List<ScheduledFollowupModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      if (refresh) {
        _scheduledFollowups = items;
      } else {
        _scheduledFollowups.addAll(items);
      }

      _totalScheduled = pagination['total'] as int? ?? 0;
      _hasMoreScheduled = pagination['hasMore'] as bool? ?? false;
    } catch (e) {
      _errorScheduled = _cleanError(e);
    }

    _isLoadingScheduled = false;
    notifyListeners();
  }

  Future<void> finalizarScheduled(String botId, String id) async {
    try {
      await _apiService.finalizarScheduled(botId, id);
      await cargarScheduled(botId: botId, refresh: true);
    } catch (e) {
      _errorScheduled = _cleanError(e);
      notifyListeners();
    }
  }

  Future<void> cancelarScheduled(String botId, String id) async {
    try {
      await _apiService.cancelarScheduled(botId, id);
      await cargarScheduled(botId: botId, refresh: true);
    } catch (e) {
      _errorScheduled = _cleanError(e);
      notifyListeners();
    }
  }

  Future<void> reactivarScheduled(String botId, String id) async {
    try {
      await _apiService.reactivarScheduled(botId, id);
      await cargarScheduled(botId: botId, refresh: true);
    } catch (e) {
      _errorScheduled = _cleanError(e);
      notifyListeners();
    }
  }

  Future<void> actualizarScheduled(String botId, String id, Map<String, dynamic> data) async {
    try {
      await _apiService.actualizarScheduled(botId, id, data);
      await cargarScheduled(botId: botId, refresh: true);
    } catch (e) {
      _errorScheduled = _cleanError(e);
      notifyListeners();
    }
  }

  // ================================================================
  // RECOVERY FOLLOWUPS
  // ================================================================

  Future<void> cargarRecovery({
    required String botId,
    bool refresh = false,
    String? estado,
    String? etapa,
    String? nivel,
    String? fecha,
    String? search,
  }) async {
    _isLoadingRecovery = true;
    _errorRecovery = null;
    notifyListeners();

    try {
      if (refresh) {
        _recoveryFollowups = [];
      }

      final result = await _apiService.listarRecovery(
        botId: botId,
        estado: estado,
        etapa: etapa,
        nivel: nivel,
        fecha: fecha,
        search: search,
        offset: refresh ? 0 : _recoveryFollowups.length,
      );

      final List<ConversationRecoveryModel> items =
          result['data'] as List<ConversationRecoveryModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      if (refresh) {
        _recoveryFollowups = items;
      } else {
        _recoveryFollowups.addAll(items);
      }

      _totalRecovery = pagination['total'] as int? ?? 0;
      _hasMoreRecovery = pagination['hasMore'] as bool? ?? false;
    } catch (e) {
      _errorRecovery = _cleanError(e);
    }

    _isLoadingRecovery = false;
    notifyListeners();
  }

  Future<void> finalizarRecovery(String botId, String id) async {
    try {
      await _apiService.finalizarRecovery(botId, id);
      await cargarRecovery(botId: botId, refresh: true);
    } catch (e) {
      _errorRecovery = _cleanError(e);
      notifyListeners();
    }
  }

  Future<void> cancelarRecovery(String botId, String id) async {
    try {
      await _apiService.cancelarRecovery(botId, id);
      await cargarRecovery(botId: botId, refresh: true);
    } catch (e) {
      _errorRecovery = _cleanError(e);
      notifyListeners();
    }
  }

  Future<void> reactivarRecovery(String botId, String id) async {
    try {
      await _apiService.reactivarRecovery(botId, id);
      await cargarRecovery(botId: botId, refresh: true);
    } catch (e) {
      _errorRecovery = _cleanError(e);
      notifyListeners();
    }
  }

  Future<void> actualizarRecovery(String botId, String id, Map<String, dynamic> data) async {
    try {
      await _apiService.actualizarRecovery(botId, id, data);
      await cargarRecovery(botId: botId, refresh: true);
    } catch (e) {
      _errorRecovery = _cleanError(e);
      notifyListeners();
    }
  }

  void limpiarErrorScheduled() {
    _errorScheduled = null;
    notifyListeners();
  }

  void limpiarErrorRecovery() {
    _errorRecovery = null;
    notifyListeners();
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceAll('Exception: ', '')
        .replaceAll('ClientException: ', '')
        .trim();
  }
}
