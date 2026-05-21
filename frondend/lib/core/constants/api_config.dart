class ApiConfig {
  // Backend desplegado en EasyPanel.
  static const String baseUrl =
      'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host';

  static const String catalogoEndpoint = '$baseUrl/api/catalogo';
  static const String storageUploadEndpoint = '$baseUrl/api/storage/upload';
  static const String botClientEndpoint = '$baseUrl/api/bot/clients';
  static const String botConversationEndpoint = '$baseUrl/api/bot/conversations';
  static const String botQuotationEndpoint = '$baseUrl/api/bot/quotations';
  static const String healthEndpoint = '$baseUrl/api/health';
}
