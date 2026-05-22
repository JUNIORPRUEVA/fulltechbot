import 'package:flutter/material.dart';

import '../models/bot_order_model.dart';
import '../services/bot_order_api_service.dart';

class BotOrderProvider extends ChangeNotifier {
  final BotOrderApiService _apiService = BotOrderApiService();

  List<BotOrderModel> _ordenes = [];
  BotOrderModel? _ordenSeleccionada;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  List<BotOrderModel> get ordenes => _ordenes;
  BotOrderModel? get ordenSeleccionada => _ordenSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarOrdenes(String botId) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      _ordenes = await _apiService.listarOrdenes(botId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[BotOrderProvider] Error cargando órdenes: $e');
      debugPrint('$st');
    }
    _isLoadingMore = false;
    _setLoading(false);
  }

  Future<void> crearOrden(String botId, Map<String, dynamic> data) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      await _apiService.crearOrden(botId, data);
      await cargarOrdenes(botId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[BotOrderProvider] Error creando orden: $e');
      debugPrint('$st');
      _isLoadingMore = false;
      _setLoading(false);
    }
  }

  Future<void> actualizarOrden(
      String botId, String id, Map<String, dynamic> data) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      await _apiService.actualizarOrden(botId, id, data);
      await cargarOrdenes(botId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[BotOrderProvider] Error actualizando orden: $e');
      debugPrint('$st');
      _isLoadingMore = false;
      _setLoading(false);
    }
  }

  Future<void> cambiarEstado(
      String botId, String id, String estado) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      await _apiService.cambiarEstado(botId, id, estado);
      await cargarOrdenes(botId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[BotOrderProvider] Error cambiando estado: $e');
      debugPrint('$st');
      _isLoadingMore = false;
      _setLoading(false);
    }
  }

  Future<void> eliminarOrden(String botId, String id) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      await _apiService.eliminarOrden(botId, id);
      await cargarOrdenes(botId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[BotOrderProvider] Error eliminando orden: $e');
      debugPrint('$st');
      _isLoadingMore = false;
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
    _isLoadingMore = false;
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
