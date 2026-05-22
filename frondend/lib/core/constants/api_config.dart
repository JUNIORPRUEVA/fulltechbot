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

  // Endpoints globales
  static const String ordersEndpoint = '$baseUrl/api/orders';
  static const String quotationsEndpoint = '$baseUrl/api/quotations';

  static String botCampaignsEndpoint(String botId) =>
      '$baseUrl/api/bots/$botId/campaigns';

  static String botCampaignByIdEndpoint(String botId, String campaignId) =>
      '${botCampaignsEndpoint(botId)}/$campaignId';

  static String botCampaignDetectEndpoint(String botId) =>
      '${botCampaignsEndpoint(botId)}/detect';

  static String botCampaignContextEndpoint(String conversationId) =>
      '$baseUrl/api/conversations/$conversationId/campaign-context';

  static String botCampaignContextHistoryEndpoint(String conversationId) =>
      '$baseUrl/api/conversations/$conversationId/campaign-context/history';

  static String botConversationChangeCampaignEndpoint(
    String botId,
    String conversationId,
  ) =>
      '$baseUrl/api/bots/$botId/conversations/$conversationId/change-campaign';
}
