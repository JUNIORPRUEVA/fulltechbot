import 'package:flutter/material.dart';

import '../models/bot_order_model.dart';
import '../services/bot_order_api_service.dart';

class BotOrderProvider extends ChangeNotifier {
  final BotOrderApiService _apiService = BotOrderApiService();

  List<BotOrderModel> _ordenes = [];
  BotOrderModel? _ordenSeleccionada;
  bool _isLoading = false;
  String? _error;

  List<BotOrderModel> get ordenes => _ordenes;
  BotOrderModel? get ordenSeleccionada => _ordenSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarOrdenes(String botId) async {
    _setLoading(true);
    try {
      _ordenes = await _apiService.listarOrdenes(botId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> crearOrden(String botId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.crearOrden(botId, data);
      await cargarOrdenes(botId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> actualizarOrden(
      String botId, String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.actualizarOrden(botId, id, data);
      await cargarOrdenes(botId);
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
      await cargarOrdenes(botId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> eliminarOrden(String botId, String id) async {
    _setLoading(true);
    try {
      await _apiService.eliminarOrden(botId, id);
      await cargarOrdenes(botId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  void seleccionarOrden(BotOrderModel orden) {
    _ordenSeleccionada = orden;
    notifyListeners();
  }

  void limpiarSeleccion() {
    _ordenSeleccionada = null;
    notifyListeners();
  }

  void limpiar() {
    _ordenes = [];
    _ordenSeleccionada = null;
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
