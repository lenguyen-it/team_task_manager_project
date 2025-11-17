import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

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
        throw Exception(error['message'] ?? 'Không tải được danh sách task');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách task: $e');
    }
  }

  Future<TaskModel> getTaskById(String taskId, String token) async {
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
        return TaskModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không lấy được task');
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
        throw Exception(error['message'] ?? 'Không lấy được tên task');
      }
    } catch (e) {
      throw Exception('Đã xảy ra lỗi khi lấy tên task: $e');
    }
  }

  Future<List<TaskModel>> getTaskByEmployee(
      String employeeId, String token) async {
    if (token.length > 40) {
      print('TOKEN GỬI ĐI: ${token.substring(0, 40)}...');
    } else {
      print('TOKEN GỬI ĐI: $token');
    }
    print('EMPLOYEE ID: $employeeId');

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getTaskByEmployee(employeeId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET TASK BY EMPLOYEE - Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => TaskModel.fromJson(e)).toList();
      } else {
        throw Exception('Lỗi khi tải task của nhân viên');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TaskModel>> getTaskByName(String taskName, String token) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.getTaskByName(taskName)), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => TaskModel.fromJson(e)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Tạo task thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi tạo task: $e');
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
        return TaskModel.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Tạo task thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi tạo task: $e');
    }
  }

  // Cập nhật task (có thể kèm files hoặc không)
  Future<Map<String, dynamic>> updateTask({
    required String taskId,
    required String token,
    Map<String, dynamic>? taskData,
    List<File>? files,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(ApiConfig.updateTask(taskId)),
      );

      // Thêm header
      request.headers['Authorization'] = 'Bearer $token';

      print('=== REQUEST BODY ===');
      print(jsonEncode(taskData));
      print('assigned_to type: ${taskData?['assigned_to'].runtimeType}');
      print('assigned_to value: ${taskData?['assigned_to']}');

      // Thêm dữ liệu task (nếu có)
      if (taskData != null) {
        taskData.forEach((key, value) {
          if (value != null) {
            if (key == 'assigned_to' && value is List) {
              for (int i = 0; i < value.length; i++) {
                request.fields['assigned_to[$i]'] = value[i].toString();
              }
            } else {
              request.fields[key] = value.toString();
            }
          }
        });
      }

      // Thêm files (nếu có)
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          var stream = http.ByteStream(file.openRead());
          var length = await file.length();

          String? mimeType = lookupMimeType(file.path);

          var multipartFile = http.MultipartFile(
            'files',
            stream,
            length,
            filename: file.path.split('/').last,
            contentType: mimeType != null ? MediaType.parse(mimeType) : null,
          );
          request.files.add(multipartFile);
        }
      }

      print('Updating task $taskId...');
      print('Fields: ${request.fields}');
      print('Files count: ${request.files.length}');

      // Gửi request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Update task - Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Cập nhật task thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật task: $e');
    }
  }

  // Chỉ upload files
  Future<Map<String, dynamic>> uploadFilesForTask({
    required String taskId,
    required String token,
    required List<File> files,
  }) async {
    try {
      if (files.isEmpty) {
        throw Exception('Không có file nào để upload');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.updateOnlyFileforTask(taskId)),
      );

      // Thêm header
      request.headers['Authorization'] = 'Bearer $token';

      // Thêm files
      for (var file in files) {
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();
        String? mimeType = lookupMimeType(file.path);
        var multipartFile = http.MultipartFile(
          'files',
          stream,
          length,
          filename: file.path.split('/').last,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
        request.files.add(multipartFile);
      }

      print('Uploading ${files.length} file(s) for task $taskId...');

      // Gửi request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Upload files - Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Upload files thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi upload files: $e');
    }
  }

  // Xóa một file attachment
  Future<Map<String, dynamic>> deleteAttachment({
    required String taskId,
    required String attachmentId,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.getTaskById(taskId)}/attachments/$attachmentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete attachment - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Xóa file thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi xóa file: $e');
    }
  }

  Future<void> deleteTask(String taskId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteTask(taskId)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Xóa task thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi xóa task: $e');
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
        throw Exception(error['message'] ?? 'Xóa task thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi xóa toàn bộ task: $e');
    }
  }
}
