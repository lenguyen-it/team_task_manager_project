import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/activitylog_model.dart';

class ActivitylogService {
  Future<Map<String, dynamic>> getAllActivityLogs(
    String token, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getAllActivityLogs).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get all activity logs status code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('Response keys: ${jsonData.keys}');

        if (jsonData is Map<String, dynamic>) {
          final List<dynamic> activityLogsList =
              (jsonData['data'] as List?) ?? [];

          final pagination = jsonData['pagination'] as Map<String, dynamic>?;

          print('✓ Fetched ${activityLogsList.length} logs (page $page)');

          return {
            'logs': activityLogsList
                .map((json) => ActivityLogModel.fromJson(json))
                .toList(),
            'pagination': {
              'page': pagination?['page'] ?? page,
              'limit': pagination?['limit'] ?? limit,
              'total': pagination?['total'] ?? 0,
              'pages': pagination?['pages'] ?? 0,
            },
          };
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load activity logs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllActivityLogs service: $e');
      throw Exception('Failed to load activity logs: $e');
    }
  }

  Future<Map<String, dynamic>> getMyActivityLogs(
    String token, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getMyLogs).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get my activity logs status code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);

        if (jsonData is Map<String, dynamic>) {
          final List<dynamic> activityLogsList =
              (jsonData['data'] as List?) ?? [];

          final pagination = jsonData['pagination'] as Map<String, dynamic>?;

          print('✓ Fetched ${activityLogsList.length} logs (page $page)');

          return {
            'logs': activityLogsList
                .map((json) => ActivityLogModel.fromJson(json))
                .toList(),
            'pagination': {
              'page': pagination?['page'] ?? page,
              'limit': pagination?['limit'] ?? limit,
              'total': pagination?['total'] ?? 0,
              'pages': pagination?['pages'] ?? 0,
            },
          };
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load activity logs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMyActivityLogs service: $e');
      throw Exception('Failed to load activity logs: $e');
    }
  }
}
