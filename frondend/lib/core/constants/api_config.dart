class ApiConfig {
  static const String _compiledBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String storagePublicUrl = String.fromEnvironment(
    'STORAGE_PUBLIC_URL',
    defaultValue: '',
  );

  static const String _cloudBackendUrl =
      'https://fulltech-bot-fulltechbot-app.gcdndd.easypanel.host';

  static String get apiBaseUrl {
    final compiled = _normalizeBaseUrl(_compiledBaseUrl);
    if (compiled.isNotEmpty) {
      return compiled;
    }

    return _cloudBackendUrl;
  }

  static String get baseUrl => apiBaseUrl;

  static String get catalogoEndpoint => '$apiBaseUrl/api/catalogo';
  static String get ordersEndpoint => '$apiBaseUrl/api/orders';
  static String get storageUploadEndpoint => '$apiBaseUrl/api/storage/upload';
  static String get uploadsImageEndpoint => '$apiBaseUrl/api/uploads/image';

  static String botClientsEndpoint(String botId) =>
      '$apiBaseUrl/api/bots/${Uri.encodeComponent(botId)}/clients';

  static String botClientByPhoneEndpoint(String botId, String phone) =>
      '${botClientsEndpoint(botId)}/${Uri.encodeComponent(phone)}';

  static String botClientByPhoneLookupEndpoint(String botId, String phone) =>
      '${botClientsEndpoint(botId)}/by-phone/${Uri.encodeComponent(phone)}';

  static String botConversationsEndpoint(String botId) =>
      '$apiBaseUrl/api/bots/${Uri.encodeComponent(botId)}/conversations';

  static String botConversationBySessionEndpoint(
    String botId,
    String sessionId,
  ) => '${botConversationsEndpoint(botId)}/${Uri.encodeComponent(sessionId)}';

  static String botQuotationsEndpoint(String botId) =>
      '$apiBaseUrl/api/bots/${Uri.encodeComponent(botId)}/quotations';

  static String botQuotationByIdEndpoint(String botId, String quotationId) =>
      '${botQuotationsEndpoint(botId)}/${Uri.encodeComponent(quotationId)}';

  static String botCampaignsEndpoint(String botId) =>
      '$apiBaseUrl/api/bots/${Uri.encodeComponent(botId)}/campaigns';

  static String botCampaignByIdEndpoint(String botId, String campaignId) =>
      '${botCampaignsEndpoint(botId)}/${Uri.encodeComponent(campaignId)}';

  static String botCampaignContextEndpoint(String conversationId) =>
      '$apiBaseUrl/api/conversations/${Uri.encodeComponent(conversationId)}/campaign-context';

  static String botCampaignContextHistoryEndpoint(String conversationId) =>
      '${botCampaignContextEndpoint(conversationId)}/history';

  static String botConversationChangeCampaignEndpoint(
    String botId,
    String conversationId,
  ) =>
      '$apiBaseUrl/api/bots/${Uri.encodeComponent(botId)}/conversations/${Uri.encodeComponent(conversationId)}/change-campaign';

  static String _normalizeBaseUrl(String value) =>
      value.trim().replaceAll(RegExp(r'/+$'), '');
}
