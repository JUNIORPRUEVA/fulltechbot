import 'package:flutter/foundation.dart';
import '../services/store_admin_api_service.dart';

/// Provider para la administración de la tienda desde el panel admin.
class StoreAdminProvider extends ChangeNotifier {
  final StoreAdminApiService _api = StoreAdminApiService();

  // ============================================
  // ESTADOS
  // ============================================

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // Config
  Map<String, dynamic>? _config;
  Map<String, dynamic>? get config => _config;

  // Banners
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> get banners => _banners;

  // Carritos
  List<Map<String, dynamic>> _carts = [];
  List<Map<String, dynamic>> get carts => _carts;

  // Pagos
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> get payments => _payments;

  // Políticas
  List<Map<String, dynamic>> _policies = [];
  List<Map<String, dynamic>> get policies => _policies;

  // ============================================
  // CONFIGURACIÓN
  // ============================================

  Future<void> loadConfig() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _config = await _api.getConfig();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> saveConfig(Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _config = await _api.updateConfig(data);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // BANNERS
  // ============================================

  Future<void> loadBanners() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _banners = await _api.getBanners();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> createBanner(Map<String, dynamic> data) async {
    try {
      await _api.createBanner(data);
      await loadBanners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBanner(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateBanner(id, data);
      await loadBanners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBanner(int id) async {
    try {
      await _api.deleteBanner(id);
      await loadBanners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // CARRITOS
  // ============================================

  Future<void> loadCarts({String? estado}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _carts = await _api.getCarts(estado: estado);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  // ============================================
  // PAGOS
  // ============================================

  Future<void> loadPayments() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _payments = await _api.getPayments();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  // ============================================
  // POLÍTICAS
  // ============================================

  Future<void> loadPolicies() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _policies = await _api.getPolicies();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> savePolicy(String tipo, Map<String, dynamic> data) async {
    try {
      await _api.upsertPolicy(tipo, data);
      await loadPolicies();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePolicy(String tipo) async {
    try {
      await _api.deletePolicy(tipo);
      await loadPolicies();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
