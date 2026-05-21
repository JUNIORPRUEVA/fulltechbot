import 'package:flutter/material.dart';

import '../models/catalogo_model.dart';
import '../services/catalogo_api_service.dart';

class CatalogoProvider extends ChangeNotifier {
  final CatalogoApiService _apiService = CatalogoApiService();

  List<CatalogoModel> _productos = [];
  bool _isLoading = false;
  String? _error;

  List<CatalogoModel> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarProductos() async {
    _setLoading(true);

    try {
      _productos = await _apiService.listarProductos();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  Future<void> crearProducto(CatalogoModel producto) async {
    _setLoading(true);

    try {
      await _apiService.crearProducto(producto);
      await cargarProductos();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> actualizarProducto(CatalogoModel producto) async {
    _setLoading(true);

    try {
      await _apiService.actualizarProducto(producto);
      await cargarProductos();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> cambiarEstado({
    required String id,
    required String estado,
  }) async {
    _setLoading(true);

    try {
      await _apiService.cambiarEstado(id: id, estado: estado);
      await cargarProductos();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> eliminarProducto(String id) async {
    _setLoading(true);

    try {
      await _apiService.eliminarProducto(id);
      await cargarProductos();
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