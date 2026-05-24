import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';

/// Servicio central de sincronización entre dispositivos.
///
/// Gestiona:
/// - Cola de operaciones pendientes (crear, actualizar, eliminar)
/// - Sincronización inmediata cuando hay internet
/// - Reintentos automáticos al recuperar conexión
/// - Resolución de conflictos (delete gana contra update)
/// - Propagación de eliminaciones a otros dispositivos
class SyncService {
  static const String _pendingOpsKey = 'sync_pending_operations';
  static const String _lastSyncKey = 'sync_last_timestamp';
  static const String _deviceIdKey = 'sync_device_id';

  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isSyncing = false;
  Timer? _retryTimer;

  SyncService._() {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final hasInternet = results.any((r) => r != ConnectivityResult.none);

      if (hasInternet) {
        debugPrint('[SyncService] Conexión recuperada, procesando cola...');
        procesarCola();
      }
    });
  }

  /// Obtiene o genera un ID único para este dispositivo.
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null || deviceId.isEmpty) {
      deviceId =
          'device_${DateTime.now().millisecondsSinceEpoch}_${_randomString(8)}';

      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;

    return List.generate(
      length,
      (i) => chars[(random + i) % chars.length],
    ).join();
  }

  /// Agrega una operación a la cola de sincronización pendiente.
  Future<void> encolarOperacion({
    required String tabla,
    required String operacion, // create, update, delete
    required String id,
    Map<String, dynamic>? datos,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final opsJson = prefs.getString(_pendingOpsKey);

    final List<dynamic> ops = _safeDecodeList(opsJson);

    // Si llega delete, gana contra cualquier create/update pendiente del mismo registro.
    if (operacion == 'delete') {
      ops.removeWhere((op) => op['tabla'] == tabla && op['id'] == id);
    }

    final existingIndex = ops.indexWhere(
      (op) =>
          op['tabla'] == tabla &&
          op['id'] == id &&
          op['operacion'] == operacion,
    );

    final nuevaOperacion = {
      'tabla': tabla,
      'operacion': operacion,
      'id': id,
      'datos': datos,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (existingIndex >= 0 && operacion != 'delete') {
      ops[existingIndex] = nuevaOperacion;
    } else {
      ops.add(nuevaOperacion);
    }

    await prefs.setString(_pendingOpsKey, jsonEncode(ops));

    debugPrint('[SyncService] Operación encolada: $operacion $tabla/$id');

    await procesarCola();
  }

  /// Procesa todas las operaciones pendientes en la cola.
  Future<void> procesarCola() async {
    if (_isSyncing) {
      debugPrint('[SyncService] Ya hay una sincronización en curso.');
      return;
    }

    final hasInternet = await _checkInternet();

    if (!hasInternet) {
      debugPrint('[SyncService] Sin internet, no se procesa la cola.');
      return;
    }

    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final opsJson = prefs.getString(_pendingOpsKey);

      if (opsJson == null || opsJson.isEmpty) {
        debugPrint('[SyncService] No hay operaciones pendientes.');
        return;
      }

      final List<dynamic> ops = _safeDecodeList(opsJson);

      if (ops.isEmpty) {
        await prefs.remove(_pendingOpsKey);
        return;
      }

      debugPrint('[SyncService] Procesando ${ops.length} operaciones...');

      final deletes = ops.where((op) => op['operacion'] == 'delete').toList();
      final others = ops.where((op) => op['operacion'] != 'delete').toList();

      final processedIds = <String>{};
      final failedOps = <dynamic>[];

      // Deletes primero.
      for (final op in deletes) {
        final opKey = '${op['tabla']}:${op['id']}';

        if (processedIds.contains(opKey)) continue;

        processedIds.add(opKey);

        try {
          await _ejecutarOperacion(Map<String, dynamic>.from(op));
        } catch (e) {
          debugPrint(
            '[SyncService] Error en delete ${op['tabla']}/${op['id']}: $e',
          );
          failedOps.add(op);
        }
      }

      // Luego create/update.
      for (final op in others) {
        final opKey = '${op['tabla']}:${op['id']}';

        if (processedIds.contains(opKey)) continue;

        processedIds.add(opKey);

        try {
          await _ejecutarOperacion(Map<String, dynamic>.from(op));
        } catch (e) {
          debugPrint(
            '[SyncService] Error en ${op['operacion']} ${op['tabla']}/${op['id']}: $e',
          );
          failedOps.add(op);
        }
      }

      if (failedOps.isNotEmpty) {
        await prefs.setString(_pendingOpsKey, jsonEncode(failedOps));
        _programarReintento();

        debugPrint(
          '[SyncService] Quedaron ${failedOps.length} operaciones fallidas.',
        );
      } else {
        await prefs.remove(_pendingOpsKey);
        await _actualizarTimestampSync();

        debugPrint('[SyncService] Sincronización completada correctamente.');
      }
    } catch (e) {
      debugPrint('[SyncService] Error procesando cola: $e');
      _programarReintento();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _ejecutarOperacion(Map<String, dynamic> op) async {
    final tabla = op['tabla'] as String?;
    final operacion = op['operacion'] as String?;
    final id = op['id'] as String?;
    final rawDatos = op['datos'];

    if (tabla == null || operacion == null || id == null || id.isEmpty) {
      debugPrint('[SyncService] Operación inválida: $op');
      return;
    }

    final Map<String, dynamic>? datos = rawDatos is Map
        ? Map<String, dynamic>.from(rawDatos)
        : null;

    final deviceId = await getDeviceId();

    switch (tabla) {
      case 'clientes':
        await _sincronizarCliente(operacion, id, datos, deviceId);
        break;

      case 'conversaciones':
        await _sincronizarConversacion(operacion, id, datos, deviceId);
        break;

      case 'cotizaciones':
        await _sincronizarCotizacion(operacion, id, datos, deviceId);
        break;

      case 'pedidos':
        await _sincronizarPedido(operacion, id, datos, deviceId);
        break;

      case 'productos':
        await _sincronizarProducto(operacion, id, datos, deviceId);
        break;

      case 'campanas':
        await _sincronizarCampana(operacion, id, datos, deviceId);
        break;

      default:
        debugPrint('[SyncService] Tabla desconocida: $tabla');
    }
  }

  Future<void> _sincronizarCliente(
    String operacion,
    String id,
    Map<String, dynamic>? datos,
    String deviceId,
  ) async {
    final botId = _extraerBotId(datos);

    if (botId == null || botId.isEmpty) {
      debugPrint('[SyncService] No se puede sincronizar cliente sin botId.');
      return;
    }

    final url = ApiConfig.botClientByPhoneEndpoint(botId, id);

    if (operacion == 'delete') {
      debugPrint('[SyncService] DELETE cliente URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: _headers(deviceId),
      ).timeout(const Duration(seconds: 15));

      _validarRespuesta(response, 'Error al eliminar cliente');
    } else if (operacion == 'create' && datos != null) {
      final createUrl = ApiConfig.botClientsEndpoint(botId);

      debugPrint('[SyncService] POST cliente URL: $createUrl');

      final response = await http.post(
        Uri.parse(createUrl),
        headers: _headers(deviceId),
        body: jsonEncode(datos),
      ).timeout(const Duration(seconds: 15));

      _validarRespuesta(response, 'Error al crear cliente');
    } else if (operacion == 'update' && datos != null) {
      debugPrint('[SyncService] PUT cliente URL: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: _headers(deviceId),
        body: jsonEncode(datos),
      ).timeout(const Duration(seconds: 15));

      _validarRespuesta(response, 'Error al actualizar cliente');
    }
  }

  Future<void> _sincronizarConversacion(
    String operacion,
    String id,
    Map<String, dynamic>? datos,
    String deviceId,
  ) async {
    final botId = _extraerBotId(datos);

    if (botId == null || botId.isEmpty) {
      debugPrint(
        '[SyncService] No se puede sincronizar conversación sin botId.',
      );
      return;
    }

    if (operacion == 'delete') {
      final url = ApiConfig.botConversationBySessionEndpoint(botId, id);

      debugPrint('[SyncService] DELETE conversación URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: _headers(deviceId),
      ).timeout(const Duration(seconds: 15));

      _validarRespuesta(response, 'Error al eliminar conversación');
    }
  }

  Future<void> _sincronizarCotizacion(
    String operacion,
    String id,
    Map<String, dynamic>? datos,
    String deviceId,
  ) async {
    final botId = _extraerBotId(datos);

    if (botId == null || botId.isEmpty) {
      debugPrint('[SyncService] No se puede sincronizar cotización sin botId.');
      return;
    }

    if (operacion == 'delete') {
      final url = ApiConfig.botQuotationByIdEndpoint(botId, id);

      debugPrint('[SyncService] DELETE cotización URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: _headers(deviceId),
      ).timeout(const Duration(seconds: 15));

      _validarRespuesta(response, 'Error al eliminar cotización');
    }
  }

  Future<void> _sincronizarPedido(
    String operacion,
    String id,
    Map<String, dynamic>? datos,
    String deviceId,
  ) async {
    if (operacion == 'delete') {
      final url = '${ApiConfig.ordersEndpoint}/${Uri.encodeComponent(id)}';

      debugPrint('[SyncService] DELETE pedido URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: _headers(deviceId),
      ).timeout(const Duration(seconds: 15));

      _validarRespuesta(response, 'Error al eliminar pedido');
    }
  }

  Future<void> _sincronizarProducto(
    String operacion,
    String id,
    Map<String, dynamic>? datos,
    String deviceId,
  ) async {
    if (operacion == 'delete') {
      final url = '${ApiConfig.catalogoEndpoint}/${Uri.encodeComponent(id)}';

      debugPrint('[SyncService] DELETE producto URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: _headers(deviceId),
      ).timeout(const Duration(seconds: 15));

      _validarRespuesta(response, 'Error al eliminar producto');
    }
  }

  Future<void> _sincronizarCampana(
    String operacion,
    String id,
    Map<String, dynamic>? datos,
    String deviceId,
  ) async {
    final botId = _extraerBotId(datos);

    if (botId == null || botId.isEmpty) {
      debugPrint('[SyncService] No se puede sincronizar campaña sin botId.');
      return;
    }

    if (operacion == 'delete') {
      final url = ApiConfig.botCampaignByIdEndpoint(botId, id);

      debugPrint('[SyncService] DELETE campaña URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: _headers(deviceId),
      ).timeout(const Duration(seconds: 15));

      _validarRespuesta(response, 'Error al eliminar campaña');
    }
  }

  Map<String, String> _headers(String deviceId) {
    return {
      'Content-Type': 'application/json',
      'X-Device-Id': deviceId,
    };
  }

  String? _extraerBotId(Map<String, dynamic>? datos) {
    if (datos == null) return null;

    final value = datos['botId'] ?? datos['bot_id'];

    if (value == null) return null;

    return value.toString();
  }

  void _validarRespuesta(http.Response response, String defaultMessage) {
    if (response.statusCode < 400) return;

    final body = _safeDecodeMap(response.body);
    final message = body['message']?.toString();

    throw Exception(
      message == null || message.isEmpty ? defaultMessage : message,
    );
  }

  List<dynamic> _safeDecodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : [];
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _safeDecodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
    } catch (_) {
      return {};
    }
  }

  Future<bool> _checkInternet() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  void _programarReintento() {
    _retryTimer?.cancel();

    _retryTimer = Timer(const Duration(seconds: 30), () {
      procesarCola();
    });
  }

  Future<void> _actualizarTimestampSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Obtiene el timestamp del último sync exitoso.
  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(_lastSyncKey);

    return ts != null ? DateTime.tryParse(ts) : null;
  }

  /// Limpia todas las operaciones pendientes.
  Future<void> limpiarCola() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOpsKey);
  }

  /// Obtiene el conteo de operaciones pendientes.
  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final opsJson = prefs.getString(_pendingOpsKey);

    if (opsJson == null) return 0;

    return _safeDecodeList(opsJson).length;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
  }
}