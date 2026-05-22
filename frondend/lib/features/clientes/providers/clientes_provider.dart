import 'package:flutter/material.dart';

import '../models/cliente_model.dart';
import '../services/clientes_api_service.dart';

class ClientesProvider extends ChangeNotifier {
  final ClientesApiService _apiService = ClientesApiService();

  List<ClienteModel> _clientes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  List<ClienteModel> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarClientes({String? botId}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      _clientes = await _apiService.listarClientes(botId: botId);
      _error = null;
    } catch (e, st) {
      if (_clientes.isEmpty) {
        _error = e.toString();
      }
      debugPrint('[ClientesProvider] Error cargando clientes: $e');
      debugPrint('$st');
    }
    _isLoadingMore = false;
    _setLoading(false);
  }

  Future<void> crearCliente(ClienteModel cliente) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      await _apiService.crearCliente(cliente);
      await cargarClientes();
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[ClientesProvider] Error creando cliente: $e');
      debugPrint('$st');
      _isLoadingMore = false;
      _setLoading(false);
    }
  }

  Future<void> actualizarCliente(ClienteModel cliente) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      await _apiService.actualizarCliente(cliente);
      await cargarClientes();
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[ClientesProvider] Error actualizando cliente: $e');
      debugPrint('$st');
      _isLoadingMore = false;
      _setLoading(false);
    }
  }

  Future<void> eliminarCliente(String telefono, {String? chatid}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      await _apiService.eliminarCliente(telefono);
      await cargarClientes();
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[ClientesProvider] Error eliminando cliente: $e');
      debugPrint('$st');
      _isLoadingMore = false;
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
