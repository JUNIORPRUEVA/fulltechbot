import 'package:flutter/material.dart';

import '../../../core/services/sync_service.dart';
import '../models/catalogo_model.dart';
import '../services/catalogo_api_service.dart';

class CatalogoProvider extends ChangeNotifier {
  final CatalogoApiService _apiService = CatalogoApiService();
  final SyncService _syncService = SyncService.instance;

  List<CatalogoModel> _productos = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  List<CatalogoModel> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarProductos({String? botId}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      _productos = await _apiService.listarProductos(botId: botId);
      _error = null;
    } catch (e, st) {
      if (_productos.isEmpty) {
        _error = e.toString();
      }
      debugPrint('[CatalogoProvider] Error cargando productos: $e');
      debugPrint('$st');
    }
    _isLoadingMore = false;
    _setLoading(false);
  }

  Future<void> crearProducto(CatalogoModel producto, {String? botId}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      await _apiService.crearProducto(producto, botId: botId);
      await cargarProductos(botId: botId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[CatalogoProvider] Error creando producto: $e');
      debugPrint('$st');
      _isLoadingMore = false;
      _setLoading(false);
    }
  }

  Future<void> actualizarProducto(CatalogoModel producto,
      {String? botId}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      await _apiService.actualizarProducto(producto, botId: botId);
      await cargarProductos(botId: botId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[CatalogoProvider] Error actualizando producto: $e');
      debugPrint('$st');
      _isLoadingMore = false;
      _setLoading(false);
    }
  }

  Future<void> cambiarEstado({
    required String id,
    required String estado,
    String? botId,
  }) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      await _apiService.cambiarEstado(id: id, estado: estado, botId: botId);
      await cargarProductos(botId: botId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[CatalogoProvider] Error cambiando estado: $e');
      debugPrint('$st');
      _isLoadingMore = false;
      _setLoading(false);
    }
  }

  Future<void> eliminarProducto(String id, {String? botId}) async {
    // Eliminación optimista: quitar de la UI inmediatamente
    _productos.removeWhere((p) => p.id == id);
    notifyListeners();

    // Encolar operación de eliminación para sincronización
    await _syncService.encolarOperacion(
      tabla: 'productos',
      operacion: 'delete',
      id: id,
      datos: {'botId': botId},
    );

    _error = null;
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
