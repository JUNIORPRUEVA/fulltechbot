import 'package:flutter/material.dart';
import '../models/bot_model.dart';
import '../services/bot_api_service.dart';

class BotProvider extends ChangeNotifier {
  final BotApiService _apiService = BotApiService();

  List<BotModel> _bots = [];
  BotModel? _botSeleccionado;
  bool _isLoading = false;
  String? _error;

  List<BotModel> get bots => _bots;
  BotModel? get botSeleccionado => _botSeleccionado;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hayBotSeleccionado => _botSeleccionado != null;

  Future<void> cargarBots() async {
    _setLoading(true);
    try {
      _bots = await _apiService.listarBots();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  void seleccionarBot(BotModel bot) {
    _botSeleccionado = bot;
    notifyListeners();
  }

  void limpiarSeleccion() {
    _botSeleccionado = null;
    notifyListeners();
  }

  Future<void> crearBot(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.crearBot(data);
      await cargarBots();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> actualizarBot(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final botActualizado = await _apiService.actualizarBot(id, data);
      // Si el bot actualizado es el seleccionado, actualizarlo
      if (_botSeleccionado?.id == id) {
        _botSeleccionado = botActualizado;
      }
      await cargarBots();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> cambiarEstado(String id, String estado) async {
    _setLoading(true);
    try {
      final botActualizado = await _apiService.cambiarEstado(id, estado);
      if (_botSeleccionado?.id == id) {
        _botSeleccionado = botActualizado;
      }
      await cargarBots();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> eliminarBot(String id) async {
    _setLoading(true);
    try {
      await _apiService.eliminarBot(id);
      if (_botSeleccionado?.id == id) {
        _botSeleccionado = null;
      }
      await cargarBots();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
