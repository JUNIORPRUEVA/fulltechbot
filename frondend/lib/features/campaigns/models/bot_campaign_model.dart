class BotCampaignModel {
  final String id;
  final String botId;
  final String campaignCode;
  final String campaignName;
  final List<String> keywords;
  final List<String> triggerPhrases;
  final String? initialMessage;
  final String? campaignContext;
  final List<String> mediaUrls;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BotCampaignModel({
    required this.id,
    required this.botId,
    required this.campaignCode,
    required this.campaignName,
    this.keywords = const [],
    this.triggerPhrases = const [],
    this.initialMessage,
    this.campaignContext,
    this.mediaUrls = const [],
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  factory BotCampaignModel.fromJson(Map<String, dynamic> json) {
    return BotCampaignModel(
      id: json['id']?.toString() ?? '',
      botId: json['bot_id']?.toString() ?? '',
      campaignCode: json['campaign_code']?.toString() ?? '',
      campaignName: json['campaign_name']?.toString() ?? '',
      keywords: _toStringList(json['keywords']),
      triggerPhrases: _toStringList(json['trigger_phrases']),
      initialMessage: json['initial_message']?.toString(),
      campaignContext: json['campaign_context']?.toString(),
      mediaUrls: _toStringList(json['media_urls']),
      active: json['active'] == true,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campaign_code': campaignCode,
      'campaign_name': campaignName,
      'keywords': keywords,
      'trigger_phrases': triggerPhrases,
      'initial_message': initialMessage,
      'campaign_context': campaignContext,
      'media_urls': mediaUrls,
      'active': active,
    };
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
