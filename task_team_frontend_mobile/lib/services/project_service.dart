import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/project_model.dart';

class ProjectService {
  Future<List<ProjectModel>> getAllProject() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.getAllProject));
      print('Respone body: \\n${response.body}');
      if (response.statusCode == 200) {
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
}
