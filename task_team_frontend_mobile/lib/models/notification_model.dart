class NotificationModel {
  final String? id;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createAt,
    this.readAt,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'],
      message: json['message'] ?? '',
      type: json['type'] ?? 'default',
      isRead: json['isRead'] ?? false,
      createAt: DateTime.parse(json['create_at'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()),
      readAt: json['read_at'] != null || json['readAt'] != null
          ? DateTime.parse(json['read_at'] ?? json['readAt'])
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createAt: createAt ?? this.createAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
