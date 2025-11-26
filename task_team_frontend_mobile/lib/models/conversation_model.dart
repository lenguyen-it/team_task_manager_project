import 'package:task_team_frontend_mobile/models/message_model.dart';
import 'package:task_team_frontend_mobile/models/participant_conversation_model.dart';

class ConversationModel {
  final String conversationId;
  final String name;
  final String? taskId;
  final String type;
  final String createdBy;
  final bool isTaskDefault;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCount;
  final List<ParticipantConversationModel> participants;
  final MessageModel? lastMessage;
  final OtherEmployee? otherEmployee;

  int unreadCountForEmployee;

  ConversationModel({
    required this.conversationId,
    this.name = '',
    this.taskId,
    required this.type,
    required this.createdBy,
    this.isTaskDefault = false,
    required this.lastMessageAt,
    this.unreadCount = const {},
    this.participants = const [],
    this.lastMessage,
    this.unreadCountForEmployee = 0,
    this.otherEmployee,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    try {
      return ConversationModel(
        conversationId: json['conversation_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        taskId: json['task_id']?.toString(),
        type: json['type']?.toString() ?? 'private',
        createdBy: json['created_by']?.toString() ?? '',
        isTaskDefault: json['is_task_default'] == true,
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.parse(json['last_message_at'].toString())
            : DateTime.now(),
        unreadCount: json['unread_count'] != null
            ? Map<String, int>.from(json['unread_count'])
            : {},
        participants: (json['participants'] as List?)
                ?.map((e) => ParticipantConversationModel.fromJson(e))
                .toList() ??
            [],
        lastMessage: json['lastMessage'] != null
            ? MessageModel.fromJson(json['lastMessage'])
            : null,
        unreadCountForEmployee: (json['unreadCount'] as num?)?.toInt() ?? 0,
        otherEmployee: json['otherEmployee'] != null
            ? OtherEmployee.fromJson(json['otherEmployee'])
            : null,
      );
    } catch (e) {
      print('Error parsing ConversationModel: $e');
      print('JSON data: ${json.toString()}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'name': name,
      'task_id': taskId,
      'type': type,
      'created_by': createdBy,
      'is_task_default': isTaskDefault,
      'last_message_at': lastMessageAt.toIso8601String(),
      'unread_count': unreadCount,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCountForEmployee,
      'otherEmployee': otherEmployee?.toJson(),
    };
  }
}
