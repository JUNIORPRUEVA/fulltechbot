class ApiConfig {
  // Para Windows, Web o escritorio local:
  static const String baseUrl = 'http://localhost:3000';

  // Si pruebas en Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:3000';

  static const String catalogoEndpoint = '$baseUrl/api/catalogo';
  static const String storageUploadEndpoint = '$baseUrl/api/storage/upload';
  static const String botClientEndpoint = '$baseUrl/api/bot/clients';
  static const String botConversationEndpoint = '$baseUrl/api/bot/conversations';
  static const String botQuotationEndpoint = '$baseUrl/api/bot/quotations';
}
