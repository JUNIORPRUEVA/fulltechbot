class BotCampaignModel {
  final String id;
  final String botId;
  final String campaignCode;
  final String campaignName;
  final String? campaignDescription;
  final String? productName;
  final String? productId;
  final double normalPrice;
  final double offerPrice;
  final String currency;
  final String campaignStatus;
  final List<String> triggerPhrases;
  final List<String> keywords;
  final String? initialMessage;
  final String? agentContext;
  final String? salesInstructions;
  final dynamic negotiationRules;
  final dynamic objectionHandling;
  final dynamic closingQuestions;
  final double extraCameraPrice;
  final double minimumExtraCameraPrice;
  final dynamic locationRules;
  final String? warrantyInfo;
  final String? installationInfo;
  final List<String> mediaUrls;
  final String crmInitialStatus;
  final String? crmTag;
  final int priority;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BotCampaignModel({
    required this.id,
    required this.botId,
    required this.campaignCode,
    required this.campaignName,
    this.campaignDescription,
    this.productName,
    this.productId,
    this.normalPrice = 0,
    this.offerPrice = 0,
    this.currency = 'DOP',
    this.campaignStatus = 'activa',
    this.triggerPhrases = const [],
    this.keywords = const [],
    this.initialMessage,
    this.agentContext,
    this.salesInstructions,
    this.negotiationRules,
    this.objectionHandling,
    this.closingQuestions,
    this.extraCameraPrice = 0,
    this.minimumExtraCameraPrice = 0,
    this.locationRules,
    this.warrantyInfo,
    this.installationInfo,
    this.mediaUrls = const [],
    this.crmInitialStatus = 'Nuevo interesado',
    this.crmTag,
    this.priority = 0,
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
      campaignDescription: json['campaign_description']?.toString(),
      productName: json['product_name']?.toString(),
      productId: json['product_id']?.toString(),
      normalPrice: _toDouble(json['normal_price']) ?? 0,
      offerPrice: _toDouble(json['offer_price']) ?? 0,
      currency: json['currency']?.toString() ?? 'DOP',
      campaignStatus: json['campaign_status']?.toString() ?? 'activa',
      triggerPhrases: _toStringList(json['trigger_phrases']),
      keywords: _toStringList(json['keywords']),
      initialMessage: json['initial_message']?.toString(),
      agentContext: json['agent_context']?.toString(),
      salesInstructions: json['sales_instructions']?.toString(),
      negotiationRules: json['negotiation_rules'],
      objectionHandling: json['objection_handling'],
      closingQuestions: json['closing_questions'],
      extraCameraPrice: _toDouble(json['extra_camera_price']) ?? 0,
      minimumExtraCameraPrice:
          _toDouble(json['minimum_extra_camera_price']) ?? 0,
      locationRules: json['location_rules'],
      warrantyInfo: json['warranty_info']?.toString(),
      installationInfo: json['installation_info']?.toString(),
      mediaUrls: _toStringList(json['media_urls']),
      crmInitialStatus:
          json['crm_initial_status']?.toString() ?? 'Nuevo interesado',
      crmTag: json['crm_tag']?.toString(),
      priority: _toInt(json['priority']),
      active: json['active'] == true,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'campaign_code': campaignCode,
      'campaign_name': campaignName,
      'campaign_description': campaignDescription,
      'product_name': productName,
      'product_id': productId,
      'normal_price': normalPrice,
      'offer_price': offerPrice,
      'currency': currency,
      'campaign_status': campaignStatus,
      'trigger_phrases': triggerPhrases,
      'keywords': keywords,
      'initial_message': initialMessage,
      'agent_context': agentContext,
      'sales_instructions': salesInstructions,
      'negotiation_rules': negotiationRules,
      'objection_handling': objectionHandling,
      'closing_questions': closingQuestions,
      'extra_camera_price': extraCameraPrice,
      'minimum_extra_camera_price': minimumExtraCameraPrice,
      'location_rules': locationRules,
      'warranty_info': warrantyInfo,
      'installation_info': installationInfo,
      'media_urls': mediaUrls,
      'crm_initial_status': crmInitialStatus,
      'crm_tag': crmTag,
      'priority': priority,
      'active': active,
    };
  }

  BotCampaignModel copyWith({
    String? id,
    String? botId,
    String? campaignCode,
    String? campaignName,
    String? campaignDescription,
    String? productName,
    String? productId,
    double? normalPrice,
    double? offerPrice,
    String? currency,
    String? campaignStatus,
    List<String>? triggerPhrases,
    List<String>? keywords,
    String? initialMessage,
    String? agentContext,
    String? salesInstructions,
    dynamic negotiationRules,
    dynamic objectionHandling,
    dynamic closingQuestions,
    double? extraCameraPrice,
    double? minimumExtraCameraPrice,
    dynamic locationRules,
    String? warrantyInfo,
    String? installationInfo,
    List<String>? mediaUrls,
    String? crmInitialStatus,
    String? crmTag,
    int? priority,
    bool? active,
  }) {
    return BotCampaignModel(
      id: id ?? this.id,
      botId: botId ?? this.botId,
      campaignCode: campaignCode ?? this.campaignCode,
      campaignName: campaignName ?? this.campaignName,
      campaignDescription: campaignDescription ?? this.campaignDescription,
      productName: productName ?? this.productName,
      productId: productId ?? this.productId,
      normalPrice: normalPrice ?? this.normalPrice,
      offerPrice: offerPrice ?? this.offerPrice,
      currency: currency ?? this.currency,
      campaignStatus: campaignStatus ?? this.campaignStatus,
      triggerPhrases: triggerPhrases ?? this.triggerPhrases,
      keywords: keywords ?? this.keywords,
      initialMessage: initialMessage ?? this.initialMessage,
      agentContext: agentContext ?? this.agentContext,
      salesInstructions: salesInstructions ?? this.salesInstructions,
      negotiationRules: negotiationRules ?? this.negotiationRules,
      objectionHandling: objectionHandling ?? this.objectionHandling,
      closingQuestions: closingQuestions ?? this.closingQuestions,
      extraCameraPrice: extraCameraPrice ?? this.extraCameraPrice,
      minimumExtraCameraPrice:
          minimumExtraCameraPrice ?? this.minimumExtraCameraPrice,
      locationRules: locationRules ?? this.locationRules,
      warrantyInfo: warrantyInfo ?? this.warrantyInfo,
      installationInfo: installationInfo ?? this.installationInfo,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      crmInitialStatus: crmInitialStatus ?? this.crmInitialStatus,
      crmTag: crmTag ?? this.crmTag,
      priority: priority ?? this.priority,
      active: active ?? this.active,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
