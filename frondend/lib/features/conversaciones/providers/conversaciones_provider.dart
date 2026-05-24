import 'package:flutter/foundation.dart';

import '../../../core/services/local_storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../models/conversacion_model.dart';
import '../services/conversaciones_api_service.dart';

class ConversacionesProvider extends ChangeNotifier {
  final ConversacionesApiService _apiService = ConversacionesApiService();
  final SyncService _syncService = SyncService.instance;

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
      _conversaciones = await _apiService.listarConversaciones(botId);

      final jsonList = _conversaciones.map((c) => c.toJson()).toList();
      await LocalStorageService.guardarConversaciones(jsonList);
    } catch (e) {
      _error = e.toString();
      debugPrint('[ConversacionesProvider] Error cargando conversaciones: $e');
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
      _mensajesActuales = await _apiService.listarPorSessionId(
        resolvedBotId,
        sessionId,
      );

      final jsonList = _mensajesActuales.map((m) => m.toJson()).toList();
      await LocalStorageService.guardarMensajes(sessionId, jsonList);
    } catch (e) {
      _error = e.toString();
      debugPrint('[ConversacionesProvider] Error cargando mensajes: $e');
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

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[ConversacionesProvider] Eliminando conversación en cloud...');
      debugPrint('[ConversacionesProvider] botId: $resolvedBotId');
      debugPrint('[ConversacionesProvider] sessionId: $sessionId');

      await _apiService.eliminarPorSessionId(
        resolvedBotId,
        sessionId,
        userRole: userRole,
      );

      // Eliminar de la lista local después de éxito en cloud
      _conversaciones.removeWhere((c) => c.sessionId == sessionId);
      _mensajesActuales = [];

      // Limpiar caché local
      final jsonList = _conversaciones.map((c) => c.toJson()).toList();
      await LocalStorageService.guardarConversaciones(jsonList);
      await LocalStorageService.limpiarCacheConversacion(sessionId);

      _error = null;
      debugPrint('[ConversacionesProvider] Conversación eliminada correctamente.');
    } catch (e) {
      _error = e.toString();
      debugPrint('[ConversacionesProvider] Error eliminando conversación: $e');

      // Encolar para reintento
      await _syncService.encolarOperacion(
        tabla: 'conversaciones',
        operacion: 'delete',
        id: sessionId,
        datos: {'botId': resolvedBotId},
      );

      rethrow;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
