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

  List<ConversacionModel> get conversaciones => _conversaciones;
  List<ConversacionModel> get mensajesActuales => _mensajesActuales;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> listarConversaciones() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Primero cargar datos locales para mostrar inmediatamente
      await _cargarConversacionesLocales();

      // 2. Luego obtener datos frescos de la API
      _conversaciones = await _apiService.listarConversaciones();

      // 3. Guardar en almacenamiento local
      final jsonList = _conversaciones.map((c) => c.toJson()).toList();
      await LocalStorageService.guardarConversaciones(jsonList);
    } catch (e) {
      // Si falla la API, ya tenemos los datos locales cargados
      if (_conversaciones.isEmpty) {
        _error = e.toString();
      }
    }

    _cargando = false;
    notifyListeners();
  }

  Future<void> listarMensajes(String sessionId) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Primero cargar mensajes locales
      await _cargarMensajesLocales(sessionId);

      // 2. Luego obtener datos frescos de la API
      _mensajesActuales = await _apiService.listarPorSessionId(sessionId);

      // 3. Guardar en almacenamiento local
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
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.crearConversacion(
        sessionId: sessionId,
        message: message,
      );
      await listarMensajes(sessionId);
    } catch (e) {
      _error = e.toString();
    }

    _cargando = false;
    notifyListeners();
  }

  Future<void> eliminarConversaciones(String sessionId) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Eliminar del backend
      await _apiService.eliminarPorSessionId(sessionId);

      // 2. Eliminar de la lista local en memoria
      _conversaciones.removeWhere((c) => c.sessionId == sessionId);
      _mensajesActuales = [];

      // 3. Actualizar almacenamiento local
      final jsonList = _conversaciones.map((c) => c.toJson()).toList();
      await LocalStorageService.guardarConversaciones(jsonList);
      await LocalStorageService.guardarMensajes(sessionId, []);

      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _cargando = false;
    notifyListeners();
  }

  Future<void> _cargarConversacionesLocales() async {
    final data = await LocalStorageService.cargarConversaciones();
    if (data != null && data.isNotEmpty) {
      _conversaciones = data.map((json) => ConversacionModel.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> _cargarMensajesLocales(String sessionId) async {
    final data = await LocalStorageService.cargarMensajes(sessionId);
    if (data != null && data.isNotEmpty) {
      _mensajesActuales = data.map((json) => ConversacionModel.fromJson(json)).toList();
      notifyListeners();
    }
  }
}
