import 'package:flutter/foundation.dart';

import '../../../core/services/local_storage_service.dart';
import '../models/conversacion_model.dart';
import '../services/conversaciones_api_service.dart';

class ConversacionesProvider extends ChangeNotifier {
  final ConversacionesApiService _apiService = ConversacionesApiService();

  List<ConversacionModel> _conversaciones = [];
  List<ConversacionModel> _mensajesActuales = [];
  bool _cargando = false;
  String? _error;
  String? _currentBotId;

  List<ConversacionModel> get conversaciones => _conversaciones;
  List<ConversacionModel> get mensajesActuales => _mensajesActuales;
  bool get cargando => _cargando;
  String? get error => _error;
  String? get currentBotId => _currentBotId;

  Future<void> listarConversaciones({String? botId}) async {
    if (botId == null || botId.isEmpty) {
      _error = 'Debes seleccionar un bot para ver sus conversaciones.';
      notifyListeners();
      return;
    }

    _currentBotId = botId;
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _cargarConversacionesLocales();
      _conversaciones = await _apiService.listarConversaciones(botId);

      final jsonList = _conversaciones.map((c) => c.toJson()).toList();
      await LocalStorageService.guardarConversaciones(jsonList);
    } catch (e) {
      if (_conversaciones.isEmpty) {
        _error = e.toString();
      }
    }

    _cargando = false;
    notifyListeners();
  }

  Future<void> listarMensajes(String sessionId, {String? botId}) async {
    final resolvedBotId = botId ?? _currentBotId;
    if (resolvedBotId == null || resolvedBotId.isEmpty) {
      _error = 'Debes seleccionar un bot para ver los mensajes.';
      notifyListeners();
      return;
    }

    _currentBotId = resolvedBotId;
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _cargarMensajesLocales(sessionId);
      _mensajesActuales = await _apiService.listarPorSessionId(
        resolvedBotId,
        sessionId,
      );

      final jsonList = _mensajesActuales.map((m) => m.toJson()).toList();
      await LocalStorageService.guardarMensajes(sessionId, jsonList);
    } catch (e) {
      if (_mensajesActuales.isEmpty) {
        _error = e.toString();
      }
    }

    _cargando = false;
    notifyListeners();
  }

  Future<void> enviarMensaje({
    required String sessionId,
    required Map<String, dynamic> message,
    String? botId,
  }) async {
    final resolvedBotId = botId ?? _currentBotId;
    if (resolvedBotId == null || resolvedBotId.isEmpty) {
      throw Exception('No hay un bot seleccionado para enviar mensajes.');
    }

    _currentBotId = resolvedBotId;
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.crearConversacion(
        botId: resolvedBotId,
        sessionId: sessionId,
        message: message,
      );
      await listarMensajes(sessionId, botId: resolvedBotId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> eliminarConversaciones(
    String sessionId, {
    String? botId,
    String? userRole,
  }) async {
    final resolvedBotId = botId ?? _currentBotId;
    if (resolvedBotId == null || resolvedBotId.isEmpty) {
      throw Exception(
        'No hay un bot seleccionado para eliminar la conversación.',
      );
    }

    _currentBotId = resolvedBotId;
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.eliminarPorSessionId(
        resolvedBotId,
        sessionId,
        userRole: userRole,
      );

      _conversaciones.removeWhere((c) => c.sessionId == sessionId);
      _mensajesActuales = [];

      final jsonList = _conversaciones.map((c) => c.toJson()).toList();
      await LocalStorageService.guardarConversaciones(jsonList);
      await LocalStorageService.limpiarCacheConversacion(sessionId);

      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> _cargarConversacionesLocales() async {
    final data = await LocalStorageService.cargarConversaciones();
    if (data != null && data.isNotEmpty) {
      _conversaciones = data
          .map((json) => ConversacionModel.fromJson(json))
          .toList();
      notifyListeners();
    }
  }

  Future<void> _cargarMensajesLocales(String sessionId) async {
    final data = await LocalStorageService.cargarMensajes(sessionId);
    if (data != null && data.isNotEmpty) {
      _mensajesActuales = data
          .map((json) => ConversacionModel.fromJson(json))
          .toList();
      notifyListeners();
    }
  }
}
