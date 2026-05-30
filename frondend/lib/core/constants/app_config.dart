class AppConfig {
  /// Slug público por defecto para que la raíz "/" abra la tienda del cliente.
  static const String defaultStoreSlug = String.fromEnvironment(
    'DEFAULT_STOREFRONT_SLUG',
    defaultValue: 'fulltech',
  );

  /// Clave para guardar la sesión en SharedPreferences
  static const String adminSessionStorageKey = 'fulltech_admin_session';

  static bool get hasDefaultStore => defaultStoreSlug.trim().isNotEmpty;
}
