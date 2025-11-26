class MessageModel {
  final String id;
  final String senderId;
  final String? receiverId;
  final String conversationId;
  final String content;
  late final MessageStatus status;
  final String type;
  final bool isDeleted;
  final List<SeenBy> seenBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  MessageModel({
    required this.id,
    required this.senderId,
    this.receiverId,
    required this.conversationId,
    required this.content,
    required this.status,
    this.type = 'text',
    this.isDeleted = false,
    this.seenBy = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString(),
      conversationId: json['conversation_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      status: _parseStatus(json['status']),
      type: json['type']?.toString() ?? 'text',
      isDeleted: json['is_deleted'] == true,
      seenBy:
          (json['seen_by'] as List?)?.map((e) => SeenBy.fromJson(e)).toList() ??
              [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  static MessageStatus _parseStatus(dynamic status) {
    if (status == null) return MessageStatus.sent;
    final statusStr = status.toString().toLowerCase();
    return MessageStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => MessageStatus.sent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'conversation_id': conversationId,
      'content': content,
      'status': status.name,
      'type': type,
      'is_deleted': isDeleted,
      'seen_by': seenBy.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? conversationId,
    String? content,
    MessageStatus? status,
    String? type,
    bool? isDeleted,
    List<SeenBy>? seenBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      status: status ?? this.status,
      type: type ?? this.type,
      isDeleted: isDeleted ?? this.isDeleted,
      seenBy: seenBy ?? this.seenBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum MessageStatus { sent, delivered, seen }

class SeenBy {
  final String employeeId;
  final DateTime seenAt;

  SeenBy({
    required this.employeeId,
    required this.seenAt,
  });

  factory SeenBy.fromJson(Map<String, dynamic> json) {
    return SeenBy(
      employeeId: json['employee_id']?.toString() ?? '',
      seenAt: json['seen_at'] != null
          ? DateTime.parse(json['seen_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'seen_at': seenAt.toIso8601String(),
    };
  }
}
