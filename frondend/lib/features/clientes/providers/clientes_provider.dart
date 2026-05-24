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
  bool _isDeleting = false;
  String? _error;
  String? _currentBotId;

  List<ClienteModel> get clientes => _clientes;
  bool get isLoading => _isLoading;
  bool get isDeleting => _isDeleting;
  String? get error => _error;
  String? get currentBotId => _currentBotId;

  Future<void> cargarClientes({String? botId}) async {
    final resolvedBotId = botId ?? _currentBotId;

    if (resolvedBotId == null || resolvedBotId.isEmpty) {
      _error = 'Debes seleccionar un bot para ver sus clientes.';
      notifyListeners();
      return;
    }

    _currentBotId = resolvedBotId;
    _setLoading(true);

    debugPrint('[ClientesProvider] Cargando clientes desde cloud...');
    debugPrint('[ClientesProvider] botId: $resolvedBotId');

    try {
      final clientesCloud = await _apiService.listarClientes(
        botId: resolvedBotId,
      );

      _clientes = clientesCloud;
      _error = null;

      debugPrint(
        '[ClientesProvider] Clientes recibidos desde cloud: ${_clientes.length}',
      );

      final clientesJson = _clientes.map((c) => c.toJson()).toList();
      await LocalStorageService.guardarClientes(clientesJson);
    } catch (e, st) {
      _error = _cleanError(e);

      debugPrint('[ClientesProvider] Error cargando clientes: $e');
      debugPrint('[ClientesProvider] Stacktrace: $st');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> crearCliente(ClienteModel cliente, {String? botId}) async {
    final resolvedBotId = botId ?? _currentBotId ?? cliente.botId;

    if (resolvedBotId == null || resolvedBotId.isEmpty) {
      throw Exception('No hay un bot seleccionado para crear el cliente.');
    }

    _setLoading(true);

    try {
      debugPrint('[ClientesProvider] Creando cliente...');
      debugPrint('[ClientesProvider] botId: $resolvedBotId');
      debugPrint('[ClientesProvider] telefono: ${cliente.telefono}');

      await _apiService.crearCliente(resolvedBotId, cliente);

      _error = null;

      await cargarClientes(botId: resolvedBotId);
    } catch (e, st) {
      _error = _cleanError(e);

      debugPrint('[ClientesProvider] Error creando cliente: $e');
      debugPrint('[ClientesProvider] Stacktrace: $st');

      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> actualizarCliente(ClienteModel cliente, {String? botId}) async {
    final resolvedBotId = botId ?? _currentBotId ?? cliente.botId;

    if (resolvedBotId == null || resolvedBotId.isEmpty) {
      throw Exception('No hay un bot seleccionado para actualizar el cliente.');
    }

    _setLoading(true);

    try {
      debugPrint('[ClientesProvider] Actualizando cliente...');
      debugPrint('[ClientesProvider] botId: $resolvedBotId');
      debugPrint('[ClientesProvider] telefono: ${cliente.telefono}');

      await _apiService.actualizarCliente(resolvedBotId, cliente);

      _error = null;

      await cargarClientes(botId: resolvedBotId);
    } catch (e, st) {
      _error = _cleanError(e);

      debugPrint('[ClientesProvider] Error actualizando cliente: $e');
      debugPrint('[ClientesProvider] Stacktrace: $st');

      rethrow;
    } finally {
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

    if (telefono.trim().isEmpty) {
      throw Exception('El teléfono del cliente es requerido para eliminar.');
    }

    _isDeleting = true;
    _error = null;
    notifyListeners();

    final clientesAntes = List<ClienteModel>.from(_clientes);

    try {
      debugPrint('[ClientesProvider] Eliminando cliente en cloud...');
      debugPrint('[ClientesProvider] botId: $resolvedBotId');
      debugPrint('[ClientesProvider] telefono: $telefono');
      debugPrint('[ClientesProvider] userRole: ${userRole ?? 'sin rol'}');

      await _apiService.eliminarCliente(
        resolvedBotId,
        telefono,
        userRole: userRole,
      );

      _clientes.removeWhere((c) {
        return c.telefono == telefono ||
            c.chatid == telefono ||
            (chatid != null && (c.telefono == chatid || c.chatid == chatid));
      });

      notifyListeners();

      await _limpiarCacheCliente(
        telefono: telefono,
        chatid: chatid,
      );

      final clientesJson = _clientes.map((c) => c.toJson()).toList();
      await LocalStorageService.guardarClientes(clientesJson);

      await cargarClientes(botId: resolvedBotId);

      _error = null;

      debugPrint('[ClientesProvider] Cliente eliminado correctamente.');
    } catch (e, st) {
      _clientes = clientesAntes;
      _error = _cleanError(e);

      debugPrint('[ClientesProvider] Error eliminando cliente: $e');
      debugPrint('[ClientesProvider] Stacktrace: $st');

      await _syncService.encolarOperacion(
        tabla: 'clientes',
        operacion: 'delete',
        id: telefono,
        datos: {
          'botId': resolvedBotId,
          if (chatid != null) 'chatid': chatid,
          if (userRole != null) 'userRole': userRole,
        },
      );

      notifyListeners();

      rethrow;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  Future<void> _limpiarCacheCliente({
    required String telefono,
    String? chatid,
  }) async {
    await LocalStorageService.limpiarCacheCliente(telefono);
    await LocalStorageService.limpiarCacheConversacion(telefono);

    if (chatid != null && chatid.isNotEmpty && chatid != telefono) {
      await LocalStorageService.limpiarCacheCliente(chatid);
      await LocalStorageService.limpiarCacheConversacion(chatid);
    }
  }

  void setError(String message) {
    _error = message;
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  void limpiarClientes() {
    _clientes = [];
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;

    _isLoading = value;
    notifyListeners();
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceAll('Exception: ', '')
        .replaceAll('ClientException: ', '')
        .trim();
  }
}