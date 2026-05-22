import 'package:flutter/material.dart';

import '../models/bot_quotation_model.dart';
import '../services/bot_quotation_api_service.dart';

class BotQuotationProvider extends ChangeNotifier {
  final BotQuotationApiService _apiService = BotQuotationApiService();

  List<BotQuotationModel> _cotizaciones = [];
  BotQuotationModel? _cotizacionSeleccionada;
  bool _isLoading = false;
  String? _error;

  List<BotQuotationModel> get cotizaciones => _cotizaciones;
  BotQuotationModel? get cotizacionSeleccionada => _cotizacionSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarCotizaciones(String botId) async {
    _setLoading(true);
    try {
      _cotizaciones = await _apiService.listarCotizaciones(botId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> crearCotizacion(String botId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.crearCotizacion(botId, data);
      await cargarCotizaciones(botId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> actualizarCotizacion(
      String botId, String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.actualizarCotizacion(botId, id, data);
      await cargarCotizaciones(botId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> cambiarEstado(
      String botId, String id, String estado) async {
    _setLoading(true);
    try {
      await _apiService.cambiarEstado(botId, id, estado);
      await cargarCotizaciones(botId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> eliminarCotizacion(String botId, String id) async {
    _setLoading(true);
    try {
      await _apiService.eliminarCotizacion(botId, id);
      await cargarCotizaciones(botId);
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
