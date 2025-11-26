import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_team_frontend_mobile/config/api_config.dart';
import '../models/message_model.dart';

class MessageService {
  Future<Map<String, dynamic>> getMessages(
    String conversationId,
    String token, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getMessages(conversationId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET MESSAGES - Status: ${response.statusCode}');
      print('Response body: \n${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'messages': (data['messages'] as List)
              .map((e) => MessageModel.fromJson(e))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception(
            'Không tải được danh sách tin nhắn (status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi lấy tin nhắn: $e');
    }
  }

  Future<MessageModel> createMessage(
    String token, {
    required String conversationId,
    required String content,
    String? receiverId,
    String type = 'text',
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.createMessage),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'conversation_id': conversationId,
        'content': content,
        'receiver_id': receiverId,
        'type': type,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return MessageModel.fromJson(data['data']);
    } else {
      throw Exception('Failed to create message: ${response.body}');
    }
  }

  // Đánh dấu đã đọc
  Future<MessageModel> markAsRead(String messageId, String token) async {
    final response = await http.put(
      Uri.parse(ApiConfig.markMessageAsRead(messageId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return MessageModel.fromJson(data['data']);
    } else {
      throw Exception('Failed to mark as read: ${response.body}');
    }
  }

  // Đánh dấu tất cả đã đọc
  Future<Map<String, dynamic>> markAllAsRead(
      String conversationId, String token) async {
    final response = await http.put(
      Uri.parse(ApiConfig.markAllMessagesAsRead(conversationId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to mark all as read: ${response.body}');
    }
  }

  // Xóa tin nhắn
  Future<void> deleteMessage(String messageId, String token) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.deleteMessage(messageId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to delete message: ${response.body}');
    }
  }

  // Tìm kiếm tin nhắn
  Future<Map<String, dynamic>> searchMessages(
    String conversationId,
    String token,
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse(ApiConfig.searchMessages(conversationId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return {
        'messages': (data['messages'] as List)
            .map((e) => MessageModel.fromJson(e))
            .toList(),
        'pagination': data['pagination'],
      };
    } else {
      throw Exception('Failed to search messages: ${response.body}');
    }
  }

  // Lấy số lượng tin nhắn chưa đọc
  Future<int> getUnreadCount(String conversationId, String token) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getUnreadMessageCount(conversationId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['data']['unreadCount'];
    } else {
      throw Exception('Failed to get unread count: ${response.body}');
    }
  }

  // Upload file
  Future<Map<String, dynamic>> uploadFile(String filePath, String token) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.uploadMessageFile()),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to upload file: ${response.body}');
    }
  }
}
