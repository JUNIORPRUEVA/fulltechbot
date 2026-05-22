import 'package:flutter/material.dart';

import '../../../core/services/local_storage_service.dart';
import '../../conversaciones/services/conversaciones_api_service.dart';
import '../models/cliente_model.dart';
import '../services/clientes_api_service.dart';

class ClientesProvider extends ChangeNotifier {
  final ClientesApiService _apiService = ClientesApiService();
  final ConversacionesApiService _conversacionesApiService = ConversacionesApiService();

  List<ClienteModel> _clientes = [];
  bool _isLoading = false;
  String? _error;

  List<ClienteModel> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> cargarClientes({String? botId}) async {
    _setLoading(true);

    try {
      // 1. Primero cargar datos locales para mostrar inmediatamente
      await _cargarClientesLocales();

      // 2. Luego obtener datos frescos de la API
      _clientes = await _apiService.listarClientes(botId: botId);

      // 3. Guardar en almacenamiento local
      final jsonList = _clientes.map((c) => c.toJson()).toList();
      await LocalStorageService.guardarClientes(jsonList);

      _error = null;
    } catch (e) {
      // Si falla la API, ya tenemos los datos locales cargados
      if (_clientes.isEmpty) {
        _error = e.toString();
      }
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

  Future<void> eliminarCliente(String telefono, {String? chatid}) async {
    _setLoading(true);

    try {
      // 1. Eliminar conversaciones asociadas si hay chatid
      if (chatid != null && chatid.isNotEmpty) {
        try {
          await _conversacionesApiService.eliminarPorSessionId(chatid);
        } catch (_) {
          // Si falla la eliminación de conversaciones, continuamos
        }
      }

      // 2. Eliminar el cliente
      await _apiService.eliminarCliente(telefono);

      // 3. Limpiar almacenamiento local
      await LocalStorageService.guardarClientes([]);

      // 4. Recargar lista
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

  Future<void> _cargarClientesLocales() async {
    final data = await LocalStorageService.cargarClientes();
    if (data != null && data.isNotEmpty) {
      _clientes = data.map((json) => ClienteModel.fromJson(json)).toList();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
