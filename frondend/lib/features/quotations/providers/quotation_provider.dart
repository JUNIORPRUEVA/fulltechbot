import 'package:flutter/material.dart';

import '../models/bot_quotation_model.dart';
import '../services/quotation_api_service.dart';

class QuotationProvider extends ChangeNotifier {
  final QuotationApiService _apiService = QuotationApiService();

  List<BotQuotationModel> _cotizaciones = [];
  BotQuotationModel? _cotizacionSeleccionada;
  bool _isLoading = false;
  String? _error;
  String? _currentBotId;

  List<BotQuotationModel> get cotizaciones => _cotizaciones;
  BotQuotationModel? get cotizacionSeleccionada => _cotizacionSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarCotizaciones({
    String? sourceBotId,
    String? estado,
    String? telefono,
    String? botId,
  }) async {
    _currentBotId = botId;
    _setLoading(true);
    try {
      _cotizaciones = await _apiService.listarCotizaciones(
        sourceBotId: sourceBotId,
        estado: estado,
        telefono: telefono,
        botId: botId,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> crearCotizacion(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.crearCotizacion(data, botId: _currentBotId);
      await cargarCotizaciones(botId: _currentBotId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> actualizarCotizacion(
    String id,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    try {
      await _apiService.actualizarCotizacion(id, data, botId: _currentBotId);
      await cargarCotizaciones(botId: _currentBotId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> cambiarEstado(String id, String estado) async {
    _setLoading(true);
    try {
      await _apiService.cambiarEstado(id, estado, botId: _currentBotId);
      await cargarCotizaciones(botId: _currentBotId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> eliminarCotizacion(String id) async {
    _setLoading(true);
    try {
      await _apiService.eliminarCotizacion(id, botId: _currentBotId);
      await cargarCotizaciones(botId: _currentBotId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  void seleccionarCotizacion(BotQuotationModel cotizacion) {
    _cotizacionSeleccionada = cotizacion;
    notifyListeners();
  }

  void limpiarSeleccion() {
    _cotizacionSeleccionada = null;
    notifyListeners();
  }

  void limpiar() {
    _cotizaciones = [];
    _cotizacionSeleccionada = null;
    _error = null;
    _isLoading = false;
    _currentBotId = null;
    notifyListeners();
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
