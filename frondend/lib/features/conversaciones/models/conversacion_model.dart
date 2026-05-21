class ConversacionModel {
  final int id;
  final String sessionId;
  final Map<String, dynamic> message;
  final DateTime? createdAt;

  ConversacionModel({
    required this.id,
    required this.sessionId,
    required this.message,
    this.createdAt,
  });

  factory ConversacionModel.fromJson(Map<String, dynamic> json) {
    return ConversacionModel(
      id: _toInt(json['id']),
      sessionId: json['session_id']?.toString() ?? '',
      message: json['message'] is Map
          ? Map<String, dynamic>.from(json['message'])
          : {'content': json['message']?.toString() ?? ''},
      createdAt: _toDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'message': message,
    };
  }

  String get role => message['role']?.toString() ?? 'user';
  String get content => message['content']?.toString() ?? '';

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
