import 'package:flutter/material.dart';

import '../../../core/services/sync_service.dart';
import '../models/bot_order_model.dart';
import '../services/order_api_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderApiService _apiService = OrderApiService();
  final SyncService _syncService = SyncService.instance;

  List<BotOrderModel> _ordenes = [];
  BotOrderModel? _ordenSeleccionada;
  bool _isLoading = false;
  String? _error;
  String? _currentBotId;

  List<BotOrderModel> get ordenes => _ordenes;
  BotOrderModel? get ordenSeleccionada => _ordenSeleccionada;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarOrdenes({String? botId}) async {
    _currentBotId = botId;

    _setLoading(true);
    try {
      _ordenes = await _apiService.listarOrdenes(botId: botId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[OrderProvider] Error cargando órdenes: $e');
      debugPrint('$st');
    }
    _setLoading(false);
  }

  Future<void> crearOrden(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.crearOrden(data, botId: _currentBotId);
      await cargarOrdenes(botId: _currentBotId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[OrderProvider] Error creando orden: $e');
      debugPrint('$st');
      _setLoading(false);
    }
  }

  Future<void> actualizarOrden(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.actualizarOrden(id, data, botId: _currentBotId);
      await cargarOrdenes(botId: _currentBotId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[OrderProvider] Error actualizando orden: $e');
      debugPrint('$st');
      _setLoading(false);
    }
  }

  Future<void> cambiarEstado(String id, String estado) async {
    _setLoading(true);
    try {
      await _apiService.cambiarEstado(id, estado, botId: _currentBotId);
      await cargarOrdenes(botId: _currentBotId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[OrderProvider] Error cambiando estado: $e');
      debugPrint('$st');
      _setLoading(false);
    }
  }

  Future<void> eliminarOrden(String id) async {
    _setLoading(true);
    try {
      debugPrint('[OrderProvider] Eliminando orden en cloud...');
      debugPrint('[OrderProvider] id: $id');
      debugPrint('[OrderProvider] botId: $_currentBotId');

      await _apiService.eliminarOrden(id, botId: _currentBotId);

      // Recargar desde cloud después de eliminar
      await cargarOrdenes(botId: _currentBotId);
      _error = null;
      debugPrint('[OrderProvider] Orden eliminada correctamente.');
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[OrderProvider] Error eliminando orden: $e');
      debugPrint('$st');

      // Encolar para reintento
      await _syncService.encolarOperacion(
        tabla: 'pedidos',
        operacion: 'delete',
        id: id,
        datos: {'botId': _currentBotId},
      );

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
