import 'package:flutter/material.dart';

import '../../../core/services/local_storage_service.dart';
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

      // Actualizar caché local
      final clientesJson = _clientes.map((c) => c.toJson()).toList();
      await LocalStorageService.guardarClientes(clientesJson);
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

  /// Elimina un cliente de forma permanente.
  /// 1. Llama al API (que elimina en BD con transacción)
  /// 2. Elimina de la lista local inmediatamente
  /// 3. Limpia la caché local
  /// 4. Recarga desde el servidor para asegurar consistencia
  Future<void> eliminarCliente(String telefono, {String? chatid, String? userRole}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    _setLoading(true);
    try {
      // 1. Eliminar en backend (transacción con todas las dependencias)
      await _apiService.eliminarCliente(telefono, userRole: userRole);

      // 2. Eliminar de la lista local inmediatamente (respuesta visual instantánea)
      _clientes.removeWhere((c) => c.telefono == telefono);

      // 3. Limpiar caché local de conversaciones y mensajes asociados
      await LocalStorageService.limpiarCacheCliente(telefono);
      if (chatid != null && chatid != telefono) {
        await LocalStorageService.limpiarCacheCliente(chatid);
      }

      // 4. Actualizar caché de clientes
      final clientesJson = _clientes.map((c) => c.toJson()).toList();
      await LocalStorageService.guardarClientes(clientesJson);

      _error = null;
      _isLoadingMore = false;
      _setLoading(false);

      // 5. Recargar desde servidor para asegurar consistencia
      await cargarClientes();
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
