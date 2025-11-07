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

  Future<TaskModel> getTaskById(String taskId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(
          ApiConfig.getTaskById(taskId),
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return TaskModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không lấy được nhân viên');
      }
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  Future<String> getTaskNameById(String taskId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getTaskById(taskId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final task = TaskModel.fromJson(data);
        return task.taskName;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không lấy được tên dự án');
      }
    } catch (e) {
      throw Exception('Đã xảy ra lỗi khi lấy tên dự án: $e');
    }
  }

  Future<TaskModel> createTask(TaskModel task, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createTask),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TaskModel.fromJson(
          json.decode(response.body),
        );
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Tạo nhân viên thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi tạo nhân viên: $e');
    }
  }

  Future<TaskModel> updateTask(
      String taskId, TaskModel task, String token) async {
    try {
      final response = await http.put(
        Uri.parse(
          ApiConfig.updateTask(taskId),
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TaskModel.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Cập nhật nhân viên thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật nhân viên: $e');
    }
  }

  Future<void> deleteTassk(String taskId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteTask(taskId)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Xóa nhân viên thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi xóa nhân viên: $e');
    }
  }

  Future<void> deleteAllTask(String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteAllTask),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Xóa nhân viên thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi xóa toàn bộ nhân viên: $e');
    }
  }
}
