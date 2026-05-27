class ApiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String storagePublicUrl = String.fromEnvironment(
    'STORAGE_PUBLIC_URL',
    defaultValue: '',
  );

  // Alias para compatibilidad con codigo existente.
  static const String baseUrl = apiBaseUrl;

  static const String healthEndpoint = '$apiBaseUrl/api/health';
  static const String catalogoEndpoint = '$apiBaseUrl/api/catalogo';
  static const String storageUploadEndpoint = '$apiBaseUrl/api/storage/upload';
  static const String uploadsImageEndpoint = '$apiBaseUrl/api/uploads/image';
  static const String ordersEndpoint = '$apiBaseUrl/api/orders';
  static const String quotationsEndpoint = '$apiBaseUrl/api/quotations';

  static String botClientsEndpoint(String botId) =>
      '$apiBaseUrl/api/bots/${Uri.encodeComponent(botId)}/clients';

  static String botClientByPhoneEndpoint(String botId, String telefono) =>
      '${botClientsEndpoint(botId)}/${Uri.encodeComponent(telefono)}';

  static String botClientByChatIdEndpoint(String botId, String chatId) =>
      '${botClientsEndpoint(botId)}/by-chatid/${Uri.encodeComponent(chatId)}';

  static String botClientByPhoneLookupEndpoint(String botId, String telefono) =>
      '${botClientsEndpoint(botId)}/by-phone/${Uri.encodeComponent(telefono)}';

  static String botClientAssignBotEndpoint(String botId, String telefono) =>
      '${botClientsEndpoint(botId)}/${Uri.encodeComponent(telefono)}/assign-bot';

  static String botConversationsEndpoint(String botId) =>
      '$apiBaseUrl/api/bots/${Uri.encodeComponent(botId)}/conversations';

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

  static String botCampaignsEndpoint(String botId) =>
      '$apiBaseUrl/api/bots/${Uri.encodeComponent(botId)}/campaigns';

  static String botCampaignByIdEndpoint(String botId, String campaignId) =>
      '${botCampaignsEndpoint(botId)}/${Uri.encodeComponent(campaignId)}';

  static String botCampaignDetectEndpoint(String botId) =>
      '${botCampaignsEndpoint(botId)}/detect';

  static String botCampaignContextEndpoint(String conversationId) =>
      '$apiBaseUrl/api/conversations/${Uri.encodeComponent(conversationId)}/campaign-context';

  static String botCampaignContextHistoryEndpoint(String conversationId) =>
      '$apiBaseUrl/api/conversations/${Uri.encodeComponent(conversationId)}/campaign-context/history';

  static String botQuotationsEndpoint(String botId) =>
      '$apiBaseUrl/api/bots/${Uri.encodeComponent(botId)}/quotations';

  static String botQuotationByIdEndpoint(String botId, String quotationId) =>
      '${botQuotationsEndpoint(botId)}/${Uri.encodeComponent(quotationId)}';

  static Uri uri(String endpoint) => Uri.parse(endpoint);

  static void printDebugInfo() {
    print('API BASE URL: $apiBaseUrl');
    print('STORAGE PUBLIC URL: $storagePublicUrl');
    print('HEALTH ENDPOINT: $healthEndpoint');
  }
}
