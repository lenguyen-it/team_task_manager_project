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

        List<dynamic> notificationsList;
        int totalCount = 0;
        int totalPages = 1;

        if (jsonData is List) {
          notificationsList = jsonData;
          totalCount = notificationsList.length;
          totalPages = (totalCount / limit).ceil();
        } else if (jsonData is Map<String, dynamic>) {
          if (jsonData.containsKey('data')) {
            notificationsList = jsonData['data'] as List;
            totalCount = jsonData['totalCount'] ?? notificationsList.length;
            totalPages = jsonData['totalPages'] ?? (totalCount / limit).ceil();
          } else if (jsonData.containsKey('notifications')) {
            notificationsList = jsonData['notifications'] as List;
            totalCount = jsonData['total'] ?? notificationsList.length;
            totalPages = jsonData['pages'] ?? (totalCount / limit).ceil();
          } else if (jsonData.containsKey('results')) {
            notificationsList = jsonData['results'] as List;
            totalCount = jsonData['count'] ?? notificationsList.length;
            totalPages = jsonData['pages'] ?? (totalCount / limit).ceil();
          } else {
            throw Exception('Response does not contain notifications array');
          }
        } else {
          throw Exception('Invalid response format');
        }

        return {
          'notifications': notificationsList
              .map((json) => NotificationModel.fromJson(json))
              .toList(),
          'totalCount': totalCount,
          'totalPages': totalPages,
          'currentPage': page,
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

        List<dynamic> notificationsList;
        int totalCount = 0;
        int totalPages = 1;

        if (jsonData is List) {
          notificationsList = jsonData;
          totalCount = notificationsList.length;
          totalPages = (totalCount / limit).ceil();
        } else if (jsonData is Map<String, dynamic>) {
          if (jsonData.containsKey('data')) {
            notificationsList = jsonData['data'] as List;
            totalCount = jsonData['totalCount'] ?? notificationsList.length;
            totalPages = jsonData['totalPages'] ?? (totalCount / limit).ceil();
          } else if (jsonData.containsKey('notifications')) {
            notificationsList = jsonData['notifications'] as List;
            totalCount = jsonData['total'] ?? notificationsList.length;
            totalPages = jsonData['pages'] ?? (totalCount / limit).ceil();
          } else if (jsonData.containsKey('results')) {
            notificationsList = jsonData['results'] as List;
            totalCount = jsonData['count'] ?? notificationsList.length;
            totalPages = jsonData['pages'] ?? (totalCount / limit).ceil();
          } else {
            throw Exception('Response does not contain notifications array');
          }
        } else {
          throw Exception('Invalid response format');
        }

        return {
          'notifications': notificationsList
              .map((json) => NotificationModel.fromJson(json))
              .toList(),
          'totalCount': totalCount,
          'totalPages': totalPages,
          'currentPage': page,
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
      // ✅ FIX: Log the full URL
      final url = Uri.parse(ApiConfig.markAllAsRead);
      print('Mark all as read URL: $url');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // ✅ FIX: Send body even if empty
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
