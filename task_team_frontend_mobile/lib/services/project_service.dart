import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/project_model.dart';

class ProjectService {
  Future<List<ProjectModel>> getAllProject(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getAllProject),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET ALL PROJECTS - Status: ${response.statusCode}');
      print('Response body: \\n${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as List;
        return data.map((e) => ProjectModel.fromJson(e)).toList();
      } else {
        throw Exception(
            'Không tải được danh sách dự án (status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  Future<ProjectModel> getProjectById(String projectId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(
          ApiConfig.getProjectById(projectId),
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ProjectModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không lấy được nhân viên');
      }
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  Future<String> getProjectNameById(String projectId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getProjectById(projectId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final project = ProjectModel.fromJson(data);
        return project.projectName;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không lấy được tên dự án');
      }
    } catch (e) {
      throw Exception('Đã xảy ra lỗi khi lấy tên dự án: $e');
    }
  }
}
