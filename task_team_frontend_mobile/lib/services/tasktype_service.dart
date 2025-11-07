import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/tasktype_model.dart';

class TasktypeService {
  Future<List<TasktypeModel>> getAllTaskType(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getAllTaskType),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET ALL TaskType - Status: ${response.statusCode}');
      print('Response body: \\n${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as List;
        return data.map((e) => TasktypeModel.fromJson(e)).toList();
      } else {
        throw Exception(
            'Không tải được danh sách nhân viên (status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  Future<TasktypeModel> getTaskTypeById(String tasktypeId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getTaskTypeById(tasktypeId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return TasktypeModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không lấy được nhân viên');
      }
    } catch (e) {
      throw Exception('Lỗi lấy nhân viên: $e');
    }
  }

  Future<TasktypeModel> createTaskType(
      TasktypeModel employee, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createTaskType),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(employee.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TasktypeModel.fromJson(
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

  Future<TasktypeModel> updateTaskType(
      String tasktypeId, TasktypeModel tasktype, String token) async {
    try {
      final response = await http.put(
        Uri.parse(
          ApiConfig.updateTaskType(tasktypeId),
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(tasktype.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TasktypeModel.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Cập nhật nhân viên thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật nhân viên: $e');
    }
  }

  Future<void> deleteTaskType(String tasktypeId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteTaskType(tasktypeId)),
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

  Future<void> deleteAllTaskType(String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteAllTaskType),
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
