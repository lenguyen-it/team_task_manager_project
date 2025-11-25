import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/notification_model.dart';

class NotificationService {
  Future<Map<String, dynamic>> getMyNotifications(
    String token, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getMyNotifications}?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get my notifications status code: ${response.statusCode}');
      print('Get my notifications response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        List<dynamic> notificationsList = [];
        int totalCount = 0;
        int totalPages = 1;
        int currentPage = page;

        // Parse response theo cấu trúc từ backend
        if (jsonData is Map<String, dynamic>) {
          // ✅ Ưu tiên: Backend trả về { success: true, data: [...], pagination: {...} }
          if (jsonData.containsKey('pagination')) {
            notificationsList = jsonData['data'] as List? ?? [];
            final pagination = jsonData['pagination'] as Map<String, dynamic>;
            totalCount = pagination['total'] as int? ?? 0;
            totalPages = pagination['pages'] as int? ?? 1;
            currentPage = pagination['page'] as int? ?? page;
          }
          // Format mới: { success: true, data: [...], totalCount: X, totalPages: Y, currentPage: Z }
          else if (jsonData.containsKey('data') &&
              jsonData.containsKey('totalCount')) {
            notificationsList = jsonData['data'] as List? ?? [];
            totalCount = jsonData['totalCount'] as int? ?? 0;
            totalPages = jsonData['totalPages'] as int? ?? 1;
            currentPage = jsonData['currentPage'] as int? ?? page;
          }
          // Fallback cho các format khác
          else if (jsonData.containsKey('notifications')) {
            notificationsList = jsonData['notifications'] as List? ?? [];
            totalCount = jsonData['total'] as int? ?? notificationsList.length;
            totalPages =
                jsonData['pages'] as int? ?? (totalCount / limit).ceil();
            currentPage = jsonData['page'] as int? ?? page;
          } else if (jsonData.containsKey('results')) {
            notificationsList = jsonData['results'] as List? ?? [];
            totalCount = jsonData['count'] as int? ?? notificationsList.length;
            totalPages =
                jsonData['pages'] as int? ?? (totalCount / limit).ceil();
            currentPage = jsonData['page'] as int? ?? page;
          }
          // Nếu không có key cụ thể, có thể data nằm ngay trong jsonData
          else {
            notificationsList = [];
            totalCount = 0;
            totalPages = 1;
          }
        }
        // Nếu backend trả về array trực tiếp
        else if (jsonData is List) {
          notificationsList = jsonData;
          totalCount = notificationsList.length;
          totalPages = (totalCount / limit).ceil();
          currentPage = page;
        }

        print(
            '📊 Parsed - Total: $totalCount, Pages: $totalPages, Current: $currentPage');
        print('📋 Notifications count: ${notificationsList.length}');

        return {
          'notifications': notificationsList
              .map((json) => NotificationModel.fromJson(json))
              .toList(),
          'totalCount': totalCount,
          'totalPages': totalPages,
          'currentPage': currentPage,
        };
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMyNotifications service: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  // Lấy tất cả thông báo với phân trang
  Future<Map<String, dynamic>> getAllNotifications(
    String token, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getAllNotifications}?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get all notifications status code: ${response.statusCode}');
      print('Get all notifications response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        List<dynamic> notificationsList = [];
        int totalCount = 0;
        int totalPages = 1;
        int currentPage = page;

        // Parse response theo cấu trúc từ backend
        if (jsonData is Map<String, dynamic>) {
          // ✅ Ưu tiên: Backend trả về { success: true, data: [...], pagination: {...} }
          if (jsonData.containsKey('pagination')) {
            notificationsList = jsonData['data'] as List? ?? [];
            final pagination = jsonData['pagination'] as Map<String, dynamic>;
            totalCount = pagination['total'] as int? ?? 0;
            totalPages = pagination['pages'] as int? ?? 1;
            currentPage = pagination['page'] as int? ?? page;
          }
          // Format mới: { success: true, data: [...], totalCount: X, totalPages: Y, currentPage: Z }
          else if (jsonData.containsKey('data') &&
              jsonData.containsKey('totalCount')) {
            notificationsList = jsonData['data'] as List? ?? [];
            totalCount = jsonData['totalCount'] as int? ?? 0;
            totalPages = jsonData['totalPages'] as int? ?? 1;
            currentPage = jsonData['currentPage'] as int? ?? page;
          }
          // Fallback cho các format khác
          else if (jsonData.containsKey('notifications')) {
            notificationsList = jsonData['notifications'] as List? ?? [];
            totalCount = jsonData['total'] as int? ?? notificationsList.length;
            totalPages =
                jsonData['pages'] as int? ?? (totalCount / limit).ceil();
            currentPage = jsonData['page'] as int? ?? page;
          } else if (jsonData.containsKey('results')) {
            notificationsList = jsonData['results'] as List? ?? [];
            totalCount = jsonData['count'] as int? ?? notificationsList.length;
            totalPages =
                jsonData['pages'] as int? ?? (totalCount / limit).ceil();
            currentPage = jsonData['page'] as int? ?? page;
          } else {
            notificationsList = [];
            totalCount = 0;
            totalPages = 1;
          }
        }
        // Nếu backend trả về array trực tiếp
        else if (jsonData is List) {
          notificationsList = jsonData;
          totalCount = notificationsList.length;
          totalPages = (totalCount / limit).ceil();
          currentPage = page;
        }

        print(
            '📊 Parsed - Total: $totalCount, Pages: $totalPages, Current: $currentPage');
        print('📋 Notifications count: ${notificationsList.length}');

        return {
          'notifications': notificationsList
              .map((json) => NotificationModel.fromJson(json))
              .toList(),
          'totalCount': totalCount,
          'totalPages': totalPages,
          'currentPage': currentPage,
        };
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllNotifications service: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  Future<bool> markAsRead(String notificationId, String token) async {
    try {
      final url = Uri.parse(ApiConfig.markAsRead(notificationId));
      print('Mark as read URL: $url');
      print('Notification ID: $notificationId');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'isRead': true}),
      );

      print('Mark as read status code: ${response.statusCode}');
      print('Mark as read response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ??
            'Failed to mark as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in markAsRead service: $e');
      throw Exception('Failed to mark as read: $e');
    }
  }

  Future<bool> markAllAsRead(String token) async {
    try {
      final url = Uri.parse(ApiConfig.markAllAsRead);
      print('Mark all as read URL: $url');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}),
      );

      print('Mark all as read status code: ${response.statusCode}');
      print('Mark all as read response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ??
            'Failed to mark all as read: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in markAllAsRead service: $e');
      throw Exception('Failed to mark all as read: $e');
    }
  }
}
