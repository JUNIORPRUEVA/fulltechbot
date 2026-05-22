import 'package:flutter/material.dart';

import '../models/bot_order_model.dart';
import '../services/order_api_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderApiService _apiService = OrderApiService();

  List<BotOrderModel> _ordenes = [];
  BotOrderModel? _ordenSeleccionada;
  bool _isLoading = false;
  String? _error;

  List<BotOrderModel> get ordenes => _ordenes;
  BotOrderModel? get ordenSeleccionada => _ordenSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarOrdenes({
    String? sourceBotId,
    String? estado,
    String? telefono,
    String? botId,
  }) async {
    _setLoading(true);
    try {
      _ordenes = await _apiService.listarOrdenes(
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

  Future<void> crearOrden(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.crearOrden(data);
      await cargarOrdenes();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> actualizarOrden(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.actualizarOrden(id, data);
      await cargarOrdenes();
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
      await cargarOrdenes();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> eliminarOrden(String id) async {
    _setLoading(true);
    try {
      await _apiService.eliminarOrden(id);
      await cargarOrdenes();
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
