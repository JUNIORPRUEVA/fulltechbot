import 'package:flutter/material.dart';

import '../../../core/services/local_storage_service.dart';
import '../../../core/services/sync_service.dart';
import '../models/cliente_model.dart';
import '../services/clientes_api_service.dart';

class ClientesProvider extends ChangeNotifier {
  final ClientesApiService _apiService = ClientesApiService();
  final SyncService _syncService = SyncService.instance;

  List<ClienteModel> _clientes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String? _currentBotId;

  List<ClienteModel> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentBotId => _currentBotId;

  Future<void> cargarClientes({String? botId}) async {
    if (_isLoadingMore) return;
    if (botId == null || botId.isEmpty) {
      _error = 'Debes seleccionar un bot para ver sus clientes.';
      notifyListeners();
      return;
    }

    _isLoadingMore = true;
    _currentBotId = botId;
    _setLoading(true);

    try {
      _clientes = await _apiService.listarClientes(botId: botId);
      _error = null;

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

  Future<void> crearCliente(ClienteModel cliente, {String? botId}) async {
    final resolvedBotId = botId ?? _currentBotId ?? cliente.botId;
    if (resolvedBotId == null || resolvedBotId.isEmpty) {
      throw Exception('No hay un bot seleccionado para crear el cliente.');
    }

    if (_isLoadingMore) return;
    _isLoadingMore = true;
    _setLoading(true);

    try {
      await _apiService.crearCliente(resolvedBotId, cliente);
      await cargarClientes(botId: resolvedBotId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[ClientesProvider] Error creando cliente: $e');
      debugPrint('$st');
      rethrow;
    } finally {
      _isLoadingMore = false;
      _setLoading(false);
    }
  }

  Future<void> actualizarCliente(ClienteModel cliente, {String? botId}) async {
    final resolvedBotId = botId ?? _currentBotId ?? cliente.botId;
    if (resolvedBotId == null || resolvedBotId.isEmpty) {
      throw Exception('No hay un bot seleccionado para actualizar el cliente.');
    }

    if (_isLoadingMore) return;
    _isLoadingMore = true;
    _setLoading(true);

    try {
      await _apiService.actualizarCliente(resolvedBotId, cliente);
      await cargarClientes(botId: resolvedBotId);
      _error = null;
    } catch (e, st) {
      _error = e.toString();
      debugPrint('[ClientesProvider] Error actualizando cliente: $e');
      debugPrint('$st');
      rethrow;
    } finally {
      _isLoadingMore = false;
      _setLoading(false);
    }
  }

  Future<void> eliminarCliente(
    String telefono, {
    String? botId,
    String? chatid,
    String? userRole,
  }) async {
    final resolvedBotId = botId ?? _currentBotId;
    if (resolvedBotId == null || resolvedBotId.isEmpty) {
      throw Exception('No hay un bot seleccionado para eliminar el cliente.');
    }

    // Eliminación optimista: quitar de la UI inmediatamente
    _clientes.removeWhere((c) => c.telefono == telefono);
    notifyListeners();

    // Limpiar caché local
    await LocalStorageService.limpiarCacheCliente(telefono);
    if (chatid != null && chatid != telefono) {
      await LocalStorageService.limpiarCacheCliente(chatid);
      await LocalStorageService.limpiarCacheConversacion(chatid);
    }
    await LocalStorageService.limpiarCacheConversacion(telefono);

    final clientesJson = _clientes.map((c) => c.toJson()).toList();
    await LocalStorageService.guardarClientes(clientesJson);

    // Encolar operación de eliminación para sincronización
    await _syncService.encolarOperacion(
      tabla: 'clientes',
      operacion: 'delete',
      id: telefono,
      datos: {'botId': resolvedBotId},
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
