import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/conversation_model.dart';

class ConversationService {
  // ===================== GENERAL CONVERSATIONS =====================

  /// Lấy danh sách conversations
  Future<Map<String, dynamic>> getConversations(
    String token, {
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getConversations).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (type != null) 'type': type,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET CONVERSATIONS - Status: ${response.statusCode}');
      print('Response body: \n${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Parsed data: ${json.encode(data)}');
        return {
          'conversations': (data['conversations'] as List)
              .map((e) => ConversationModel.fromJson(e))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception(
            'Không tải được danh sách cuộc trò chuyện (status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi lấy cuộc trò chuyện: $e');
    }
  }

  /// Tạo conversation mới (private hoặc group)
  Future<ConversationModel> createConversation(
    String token, {
    required String type,
    String? name,
    required List<String> participants,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createConversation),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'type': type,
          if (name != null) 'name': name,
          'participants': participants,
        }),
      );

      print('CREATE CONVERSATION - Status: ${response.statusCode}');
      print('Response body: \n${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ConversationModel.fromJson(data['data']);
      } else {
        throw Exception('Không tạo được cuộc trò chuyện: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi tạo cuộc trò chuyện: $e');
    }
  }

  /// Lấy chi tiết conversation
  Future<ConversationModel> getConversationDetails(
    String conversationId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getConversationDetails(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET CONVERSATION DETAILS - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ConversationModel.fromJson(data['data']);
      } else {
        throw Exception('Không tải được chi tiết cuộc trò chuyện');
      }
    } catch (e) {
      throw Exception('Lỗi lấy chi tiết: $e');
    }
  }

  /// Cập nhật conversation (đổi tên group)
  Future<ConversationModel> updateConversation(
    String conversationId,
    String token, {
    required String name,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.updateConversation(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ConversationModel.fromJson(data['data']);
      } else {
        throw Exception('Không cập nhật được: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật: $e');
    }
  }

  /// Xóa conversation
  Future<void> deleteConversation(
    String conversationId,
    String token,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteConversation(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Không xóa được: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi xóa conversation: $e');
    }
  }

  /// Thêm participants vào conversation
  Future<Map<String, dynamic>> addParticipants(
    String conversationId,
    String token,
    List<String> participants,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.addParticipants(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'participants': participants}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Không thêm được thành viên: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi thêm thành viên: $e');
    }
  }

  /// Xóa participant khỏi conversation
  Future<void> removeParticipant(
    String conversationId,
    String participantId,
    String token,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.removeParticipant(conversationId, participantId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Không xóa được thành viên: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi xóa thành viên: $e');
    }
  }

  /// Rời khỏi conversation
  Future<void> leaveConversation(
    String conversationId,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.leaveConversation(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Không thể rời khỏi: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi rời conversation: $e');
    }
  }

  // ===================== TASK CONVERSATIONS =====================

  /// Lấy tất cả conversations của một task
  Future<List<ConversationModel>> getTaskConversations(
    String taskId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getTaskConversations(taskId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET TASK CONVERSATIONS - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((e) => ConversationModel.fromJson(e))
            .toList();
      } else {
        throw Exception('Không tải được conversations của task');
      }
    } catch (e) {
      throw Exception('Lỗi lấy task conversations: $e');
    }
  }

  /// Tạo conversation mới trong task
  Future<ConversationModel> createTaskConversation(
    String taskId,
    String token, {
    required String type,
    String? name,
    required List<String> participants,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createTaskConversation(taskId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'type': type,
          if (name != null) 'name': name,
          'participants': participants,
        }),
      );

      print('CREATE TASK CONVERSATION - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ConversationModel.fromJson(data['data']);
      } else {
        throw Exception('Không tạo được task conversation: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi tạo task conversation: $e');
    }
  }

  /// Admin/Manager tham gia vào conversation của task
  Future<Map<String, dynamic>> joinTaskConversation(
    String taskId,
    String conversationId,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.joinTaskConversation(taskId, conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Không tham gia được: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi tham gia task conversation: $e');
    }
  }

  // ===================== ADDITIONAL FEATURES =====================

  /// Lấy tổng số tin nhắn chưa đọc
  Future<int> getTotalUnreadCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getTotalUnreadCount),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data']['totalUnreadCount'] ?? 0;
      } else {
        throw Exception('Không lấy được unread count');
      }
    } catch (e) {
      throw Exception('Lỗi lấy unread count: $e');
    }
  }
}
