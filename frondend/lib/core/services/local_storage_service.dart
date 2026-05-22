import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _clientesKey = 'clientes_cache';
  static const String _conversacionesKey = 'conversaciones_cache';
  static const String _mensajesKeyPrefix = 'mensajes_';
  static const String _productosKey = 'productos_cache';
  static const String _lastSyncKey = 'last_sync_';

  // ==================== CLIENTES ====================

  static Future<void> guardarClientes(List<Map<String, dynamic>> clientesJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(clientesJson);
    await prefs.setString(_clientesKey, jsonString);
    await prefs.setString('${_lastSyncKey}clientes', DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>?> cargarClientes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_clientesKey);
    if (jsonString == null) return null;
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // ==================== CONVERSACIONES ====================

  static Future<void> guardarConversaciones(List<Map<String, dynamic>> conversacionesJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(conversacionesJson);
    await prefs.setString(_conversacionesKey, jsonString);
    await prefs.setString('${_lastSyncKey}conversaciones', DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>?> cargarConversaciones() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_conversacionesKey);
    if (jsonString == null) return null;
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // ==================== MENSAJES POR SESSION ID ====================

  static Future<void> guardarMensajes(String sessionId, List<Map<String, dynamic>> mensajesJson) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_mensajesKeyPrefix$sessionId';
    final jsonString = jsonEncode(mensajesJson);
    await prefs.setString(key, jsonString);
  }

  static Future<List<Map<String, dynamic>>?> cargarMensajes(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_mensajesKeyPrefix$sessionId';
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // ==================== PRODUCTOS (CATÁLOGO) ====================

  static Future<void> guardarProductos(List<Map<String, dynamic>> productosJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(productosJson);
    await prefs.setString(_productosKey, jsonString);
    await prefs.setString('${_lastSyncKey}productos', DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>?> cargarProductos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_productosKey);
    if (jsonString == null) return null;
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // ==================== LIMPIAR CACHE DE UN CLIENTE ESPECÍFICO ====================

  /// Limpia la caché de conversaciones y mensajes asociados a un cliente/sessionId.
  /// Esto evita que datos eliminados vuelvan a aparecer desde la caché local.
  static Future<void> limpiarCacheCliente(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();

    // Eliminar mensajes cacheados de este sessionId
    final mensajesKey = '$_mensajesKeyPrefix$sessionId';
    await prefs.remove(mensajesKey);

    // Nota: La caché de conversaciones se actualiza al recargar desde el servidor
    // después de eliminar. No eliminamos toda la caché de conversaciones porque
    // podría contener datos de otros clientes.
  }

  /// Limpia la caché de conversaciones y mensajes de una conversación específica.
  static Future<void> limpiarCacheConversacion(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();

    // Eliminar mensajes cacheados de este sessionId
    final mensajesKey = '$_mensajesKeyPrefix$sessionId';
    await prefs.remove(mensajesKey);
  }

  // ==================== LIMPIAR TODO ====================

  static Future<void> limpiarTodo() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) =>
        key.startsWith(_clientesKey) ||
        key.startsWith(_conversacionesKey) ||
        key.startsWith(_mensajesKeyPrefix) ||
        key.startsWith(_productosKey) ||
        key.startsWith(_lastSyncKey));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
