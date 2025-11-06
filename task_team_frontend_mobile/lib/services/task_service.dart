import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/task_model.dart';

class TaskService {
  Future<List<TaskModel>> getAllTask(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getAllTask),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET ALL TASK - Status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List data = json.decode(response.body);
        return data.map((e) => TaskModel.fromJson(e)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không tải được danh sách vai trò');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách task: $e');
    }
  }
}
