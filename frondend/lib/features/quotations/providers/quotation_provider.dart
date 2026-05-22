import 'package:flutter/material.dart';

import '../models/bot_quotation_model.dart';
import '../services/quotation_api_service.dart';

class QuotationProvider extends ChangeNotifier {
  final QuotationApiService _apiService = QuotationApiService();

  List<BotQuotationModel> _cotizaciones = [];
  BotQuotationModel? _cotizacionSeleccionada;
  bool _isLoading = false;
  String? _error;

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
      await _apiService.crearCotizacion(data);
      await cargarCotizaciones();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> actualizarCotizacion(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.actualizarCotizacion(id, data);
      await cargarCotizaciones();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> cambiarEstado(String id, String estado) async {
    _setLoading(true);
    try {
      await _apiService.cambiarEstado(id, estado);
      await cargarCotizaciones();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> eliminarCotizacion(String id) async {
    _setLoading(true);
    try {
      await _apiService.eliminarCotizacion(id);
      await cargarCotizaciones();
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
