class ApiConfig {
  // Backend desplegado en EasyPanel
    // Puedes sobreescribir en tiempo de compilación con `--dart-define=API_BASE_URL=...`
    static const String baseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host',
    );

  // =========================
  // ENDPOINTS GENERALES
  // =========================

  static const String healthEndpoint = '$baseUrl/api/health';

  static const String catalogoEndpoint = '$baseUrl/api/catalogo';

  static const String storageUploadEndpoint = '$baseUrl/api/storage/upload';
  static const String uploadsImageEndpoint = '$baseUrl/api/uploads/image';

  static const String ordersEndpoint = '$baseUrl/api/orders';

  static const String quotationsEndpoint = '$baseUrl/api/quotations';

  // =========================
  // IMPORTANTE
  // =========================
  // No usar endpoints viejos como:
  // /api/bot/clients
  // /api/bot/conversations
  // /api/bot/quotations
  //
  // Todo lo relacionado al bot debe usar:
  // /api/bots/:botId/...

  // =========================
  // BOT - CLIENTES
  // =========================

  static String botClientsEndpoint(String botId) =>
      '$baseUrl/api/bots/${Uri.encodeComponent(botId)}/clients';

  static String botClientByPhoneEndpoint(String botId, String telefono) =>
      '${botClientsEndpoint(botId)}/${Uri.encodeComponent(telefono)}';

  static String botClientByChatIdEndpoint(String botId, String chatId) =>
      '${botClientsEndpoint(botId)}/by-chatid/${Uri.encodeComponent(chatId)}';

  static String botClientByPhoneLookupEndpoint(String botId, String telefono) =>
      '${botClientsEndpoint(botId)}/by-phone/${Uri.encodeComponent(telefono)}';

  static String botClientAssignBotEndpoint(String botId, String telefono) =>
      '${botClientsEndpoint(botId)}/${Uri.encodeComponent(telefono)}/assign-bot';

  // =========================
  // BOT - CONVERSACIONES
  // =========================

  static String botConversationsEndpoint(String botId) =>
      '$baseUrl/api/bots/${Uri.encodeComponent(botId)}/conversations';

  static String botConversationBySessionEndpoint(
    String botId,
    String sessionId,
  ) =>
      '${botConversationsEndpoint(botId)}/${Uri.encodeComponent(sessionId)}';

  static String botConversationChangeCampaignEndpoint(
    String botId,
    String conversationId,
  ) =>
      '${botConversationsEndpoint(botId)}/${Uri.encodeComponent(conversationId)}/change-campaign';

  // =========================
  // BOT - CAMPAÑAS
  // =========================

  static String botCampaignsEndpoint(String botId) =>
      '$baseUrl/api/bots/${Uri.encodeComponent(botId)}/campaigns';

  static String botCampaignByIdEndpoint(String botId, String campaignId) =>
      '${botCampaignsEndpoint(botId)}/${Uri.encodeComponent(campaignId)}';

  static String botCampaignDetectEndpoint(String botId) =>
      '${botCampaignsEndpoint(botId)}/detect';

  static String botCampaignContextEndpoint(String conversationId) =>
      '$baseUrl/api/conversations/${Uri.encodeComponent(conversationId)}/campaign-context';

  static String botCampaignContextHistoryEndpoint(String conversationId) =>
      '$baseUrl/api/conversations/${Uri.encodeComponent(conversationId)}/campaign-context/history';

  // =========================
  // BOT - COTIZACIONES
  // =========================

  static String botQuotationsEndpoint(String botId) =>
      '$baseUrl/api/bots/${Uri.encodeComponent(botId)}/quotations';

  static String botQuotationByIdEndpoint(String botId, String quotationId) =>
      '${botQuotationsEndpoint(botId)}/${Uri.encodeComponent(quotationId)}';

  // =========================
  // UTILIDADES
  // =========================

  static Uri uri(String endpoint) => Uri.parse(endpoint);

  static void printDebugInfo() {
    // Úsalo temporalmente para confirmar que la app apunta a la nube correcta.
    print('API BASE URL: $baseUrl');
    print('HEALTH ENDPOINT: $healthEndpoint');
  }
}
