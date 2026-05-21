import 'package:flutter/foundation.dart';

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
      _conversaciones = await _apiService.listarConversaciones();
    } catch (e) {
      _error = e.toString();
    }

    _cargando = false;
    notifyListeners();
  }

  Future<void> listarMensajes(String sessionId) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _mensajesActuales = await _apiService.listarPorSessionId(sessionId);
    } catch (e) {
      _error = e.toString();
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
}
