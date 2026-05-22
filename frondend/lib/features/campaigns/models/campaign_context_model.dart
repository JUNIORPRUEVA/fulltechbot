class CampaignContextModel {
  final String id;
  final String botId;
  final String conversationId;
  final String? customerId;
  final String? campaignId;
  final String? campaignCode;
  final String? campaignName;
  final String? matchedKeyword;
  final String? matchedTriggerPhrase;
  final String? customerMessage;
  final double detectionConfidence;
  final String sourceChannel;
  final String status;
  final DateTime? initialMessageSentAt;
  final DateTime? lastResponseAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? campaign;

  const CampaignContextModel({
    required this.id,
    required this.botId,
    required this.conversationId,
    this.customerId,
    this.campaignId,
    this.campaignCode,
    this.campaignName,
    this.matchedKeyword,
    this.matchedTriggerPhrase,
    this.customerMessage,
    this.detectionConfidence = 0,
    this.sourceChannel = 'whatsapp',
    this.status = 'detectada',
    this.initialMessageSentAt,
    this.lastResponseAt,
    this.createdAt,
    this.updatedAt,
    this.campaign,
  });

  factory CampaignContextModel.fromJson(Map<String, dynamic> json) {
    return CampaignContextModel(
      id: json['id']?.toString() ?? '',
      botId: json['bot_id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString(),
      campaignId: json['campaign_id']?.toString(),
      campaignCode: json['campaign_code']?.toString(),
      campaignName: json['campaign_name']?.toString(),
      matchedKeyword: json['matched_keyword']?.toString(),
      matchedTriggerPhrase: json['matched_trigger_phrase']?.toString(),
      customerMessage: json['customer_message']?.toString(),
      detectionConfidence: _toDouble(json['detection_confidence']) ?? 0,
      sourceChannel: json['source_channel']?.toString() ?? 'whatsapp',
      status: json['status']?.toString() ?? 'detectada',
      initialMessageSentAt: _toDateTime(json['initial_message_sent_at']),
      lastResponseAt: _toDateTime(json['last_response_at']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      campaign: json['campaign'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['campaign'])
          : null,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
