import 'package:flutter/material.dart';

import '../models/cliente_model.dart';
import '../services/clientes_api_service.dart';

class ClientesProvider extends ChangeNotifier {
  final ClientesApiService _apiService = ClientesApiService();

  List<ClienteModel> _clientes = [];
  bool _isLoading = false;
  String? _error;

  List<ClienteModel> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarClientes() async {
    _setLoading(true);

    try {
      _clientes = await _apiService.listarClientes();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  Future<void> crearCliente(ClienteModel cliente) async {
    _setLoading(true);

    try {
      await _apiService.crearCliente(cliente);
      await cargarClientes();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> actualizarCliente(ClienteModel cliente) async {
    _setLoading(true);

    try {
      await _apiService.actualizarCliente(cliente);
      await cargarClientes();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> eliminarCliente(String telefono) async {
    _setLoading(true);

    try {
      await _apiService.eliminarCliente(telefono);
      await cargarClientes();
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
