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
      print('Response body: \n${response.body}');

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
        throw Exception(error['message'] ?? 'Không lấy được dự án'); // ✅ Fixed
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

  Future<ProjectModel> createProject(ProjectModel project, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createProject),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(project.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProjectModel.fromJson(
          json.decode(response.body),
        );
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Tạo dự án thất bại'); // ✅ Fixed
      }
    } catch (e) {
      throw Exception('Lỗi tạo dự án: $e'); // ✅ Fixed
    }
  }

  Future<ProjectModel> updateProject(
      String projectId, ProjectModel project, String token) async {
    try {
      final response = await http.put(
        Uri.parse(
          ApiConfig.updateProject(projectId),
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(project.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProjectModel.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Cập nhật dự án thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật dự án: $e');
    }
  }

  Future<void> deleteProject(String projectId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteProject(projectId)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Xóa dự án thất bại'); // ✅ Fixed
      }
    } catch (e) {
      throw Exception('Lỗi xóa dự án: $e'); // ✅ Fixed
    }
  }

  Future<void> deleteAllProject(String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteAllProject),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Xóa dự án thất bại'); // ✅ Fixed
      }
    } catch (e) {
      throw Exception('Lỗi xóa toàn bộ dự án: $e'); // ✅ Fixed
    }
  }
}
