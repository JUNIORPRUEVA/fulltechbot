class AppConfig {
  // Slug publico por defecto para que la raiz "/" abra la tienda del cliente.
  static const String defaultStoreSlug = String.fromEnvironment(
    'DEFAULT_STOREFRONT_SLUG',
    defaultValue: 'fulltech-seguridad',
  );

  // Gate simple para el panel admin. Esto protege la interfaz, pero no sustituye
  // autenticacion real de backend porque estos valores terminan en el bundle web.
  static const String adminUsername = String.fromEnvironment(
    'ADMIN_USERNAME',
    defaultValue: '',
  );

  static const String adminPassword = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: '',
  );

  static const String adminSessionStorageKey = 'fulltech_admin_session';

  static bool get hasDefaultStore => defaultStoreSlug.trim().isNotEmpty;

  static bool get hasAdminCredentials =>
      adminUsername.trim().isNotEmpty && adminPassword.isNotEmpty;
}
