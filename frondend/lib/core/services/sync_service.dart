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
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  Timer? _retryTimer;
  
  SyncService._() {
    _initConnectivityListener();
  }
  
  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      // connectivity_plus returns List<ConnectivityResult>
      final hasInternet = results.any((r) => r != ConnectivityResult.none);
      if (hasInternet) {
        debugPrint('[SyncService] Conexión recuperada, procesando cola...');
        procesarCola();
      }
    });
  }
  
  /// Obtiene o genera un ID único para este dispositivo
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${_randomString(8)}';
      await prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }
  
  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return List.generate(length, (i) => chars[(random + i) % chars.length]).join();
  }
  
  /// Agrega una operación a la cola de sincronización pendiente
  Future<void> encolarOperacion({
    required String tabla,
    required String operacion, // 'create', 'update', 'delete'
    required String id,
    Map<String, dynamic>? datos,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final opsJson = prefs.getString(_pendingOpsKey);
    final List<dynamic> ops = opsJson != null ? jsonDecode(opsJson) : [];
    
    // Si ya existe una operación de delete para este ID, no agregar más
    if (operacion == 'delete') {
      ops.removeWhere((op) => op['tabla'] == tabla && op['id'] == id);
    }
    
    // Si hay una operación pendiente del mismo tipo, actualizarla
    final existingIndex = ops.indexWhere((op) => op['tabla'] == tabla && op['id'] == id && op['operacion'] == operacion);
    if (existingIndex >= 0 && operacion != 'delete') {
      ops[existingIndex] = {
        'tabla': tabla,
        'operacion': operacion,
        'id': id,
        'datos': datos,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } else {
      ops.add({
        'tabla': tabla,
        'operacion': operacion,
        'id': id,
        'datos': datos,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    
    await prefs.setString(_pendingOpsKey, jsonEncode(ops));
    debugPrint('[SyncService] Operación encolada: $operacion $tabla/$id');
    
    // Intentar sincronizar inmediatamente si hay internet
    await procesarCola();
  }
  
  /// Procesa todas las operaciones pendientes en la cola
  Future<void> procesarCola() async {
    if (_isSyncing) {
      debugPrint('[SyncService] Ya hay una sincronización en curso, saltando...');
      return;
    }
    
    final hasInternet = await _checkInternet();
    if (!hasInternet) {
      debugPrint('[SyncService] Sin internet, no se puede procesar la cola');
      return;
    }
    
    _isSyncing = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final opsJson = prefs.getString(_pendingOpsKey);
      if (opsJson == null) {
        debugPrint('[SyncService] No hay operaciones pendientes');
        return;
      }
      
      List<dynamic> ops = jsonDecode(opsJson);
      if (ops.isEmpty) return;
      
      debugPrint('[SyncService] Procesando ${ops.length} operaciones pendientes...');
      
      // Procesar deletes primero (prioridad máxima)
      final deletes = ops.where((op) => op['operacion'] == 'delete').toList();
      final others = ops.where((op) => op['operacion'] != 'delete').toList();
      
      final processedIds = <String>{};
      final failedOps = <dynamic>[];
      
      // Procesar deletes
      for (final op in deletes) {
        final opKey = '${op['tabla']}:${op['id']}';
        if (processedIds.contains(opKey)) continue;
        processedIds.add(opKey);
        
        try {
          await _ejecutarOperacion(op);
        } catch (e) {
          debugPrint('[SyncService] Error en delete ${op['tabla']}/${op['id']}: $e');
          failedOps.add(op);
        }
      }
      
      // Procesar creates y updates
      for (final op in others) {
        final opKey = '${op['tabla']}:${op['id']}';
        if (processedIds.contains(opKey)) continue;
        processedIds.add(opKey);
        
        try {
          await _ejecutarOperacion(op);
        } catch (e) {
          debugPrint('[SyncService] Error en ${op['operacion']} ${op['tabla']}/${op['id']}: $e');
          failedOps.add(op);
        }
      }
      
      // Guardar operaciones fallidas para reintentar
      if (failedOps.isNotEmpty) {
        await prefs.setString(_pendingOpsKey, jsonEncode(failedOps));
        _programarReintento();
      } else {
        await prefs.remove(_pendingOpsKey);
        await _actualizarTimestampSync();
        debugPrint('[SyncService] Todas las operaciones sincronizadas exitosamente');
      }
    } catch (e) {
      debugPrint('[SyncService] Error procesando cola: $e');
      _programarReintento();
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<void> _ejecutarOperacion(Map<String, dynamic> op) async {
    final tabla = op['tabla'] as String;
    final operacion = op['operacion'] as String;
    final id = op['id'] as String;
    final datos = op['datos'] as Map<String, dynamic>?;
    
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
  
  Future<void> _sincronizarCliente(String operacion, String id, Map<String, dynamic>? datos, String deviceId) async {
    final botId = datos?['botId'] as String?;
    if (botId == null || botId.isEmpty) return;
    
    final url = ApiConfig.botClientByPhoneEndpoint(botId, id);
    
    if (operacion == 'delete') {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'X-Device-Id': deviceId},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode >= 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Error al eliminar cliente');
      }
    } else if (operacion == 'create' && datos != null) {
      final response = await http.post(
        Uri.parse(ApiConfig.botClientsEndpoint(botId)),
        headers: {'Content-Type': 'application/json', 'X-Device-Id': deviceId},
        body: jsonEncode(datos),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode >= 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Error al crear cliente');
      }
    } else if (operacion == 'update' && datos != null) {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'X-Device-Id': deviceId},
        body: jsonEncode(datos),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode >= 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Error al actualizar cliente');
      }
    }
  }
  
  Future<void> _sincronizarConversacion(String operacion, String id, Map<String, dynamic>? datos, String deviceId) async {
    final botId = datos?['botId'] as String?;
    if (botId == null || botId.isEmpty) return;
    
    if (operacion == 'delete') {
      final response = await http.delete(
        Uri.parse(ApiConfig.botConversationBySessionEndpoint(botId, id)),
        headers: {'Content-Type': 'application/json', 'X-Device-Id': deviceId},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode >= 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Error al eliminar conversación');
      }
    }
  }
  
  Future<void> _sincronizarCotizacion(String operacion, String id, Map<String, dynamic>? datos, String deviceId) async {
    final botId = datos?['botId'] as String?;
    if (botId == null || botId.isEmpty) return;
    
    if (operacion == 'delete') {
      final response = await http.delete(
        Uri.parse('${ApiConfig.botQuotationEndpoint}/$id'),
        headers: {'Content-Type': 'application/json', 'X-Device-Id': deviceId},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode >= 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Error al eliminar cotización');
      }
    }
  }
  
  Future<void> _sincronizarPedido(String operacion, String id, Map<String, dynamic>? datos, String deviceId) async {
    if (operacion == 'delete') {
      final response = await http.delete(
        Uri.parse('${ApiConfig.ordersEndpoint}/$id'),
        headers: {'Content-Type': 'application/json', 'X-Device-Id': deviceId},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode >= 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Error al eliminar pedido');
      }
    }
  }
  
  Future<void> _sincronizarProducto(String operacion, String id, Map<String, dynamic>? datos, String deviceId) async {
    if (operacion == 'delete') {
      final response = await http.delete(
        Uri.parse('${ApiConfig.catalogoEndpoint}/$id'),
        headers: {'Content-Type': 'application/json', 'X-Device-Id': deviceId},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode >= 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Error al eliminar producto');
      }
    }
  }
  
  Future<void> _sincronizarCampana(String operacion, String id, Map<String, dynamic>? datos, String deviceId) async {
    final botId = datos?['botId'] as String?;
    if (botId == null || botId.isEmpty) return;
    
    if (operacion == 'delete') {
      final response = await http.delete(
        Uri.parse(ApiConfig.botCampaignByIdEndpoint(botId, id)),
        headers: {'Content-Type': 'application/json', 'X-Device-Id': deviceId},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode >= 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Error al eliminar campaña');
      }
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
  
  /// Obtiene el timestamp del último sync exitoso
  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(_lastSyncKey);
    return ts != null ? DateTime.tryParse(ts) : null;
  }
  
  /// Limpia todas las operaciones pendientes
  Future<void> limpiarCola() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOpsKey);
  }
  
  /// Obtiene el conteo de operaciones pendientes
  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final opsJson = prefs.getString(_pendingOpsKey);
    if (opsJson == null) return 0;
    final List<dynamic> ops = jsonDecode(opsJson);
    return ops.length;
  }
  
  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
  }
}
