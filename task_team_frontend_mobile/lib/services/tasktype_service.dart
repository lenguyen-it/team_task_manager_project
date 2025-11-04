import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/tasktype_model.dart';

class TasktypeService {
  Future<List<TasktypeModel>> getAllTaskType() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.getAllTaskType));
      print('Response body: \\n${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((e) => TasktypeModel.fromJson(e)).toList();
      } else {
        throw Exception(
            'Không tải được danh sách vai trò (status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }
}
