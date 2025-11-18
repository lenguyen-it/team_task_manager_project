import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:task_team_frontend_mobile/models/employee_model.dart';
import 'package:task_team_frontend_mobile/config/api_config.dart';

class EmployeeService {
  Future<List<EmployeeModel>> getAllEmployee(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getAllEmployee),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET ALL EMPLOYEES - Status: ${response.statusCode}');
      print('Response body: \n${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as List;
        return data.map((e) => EmployeeModel.fromJson(e)).toList();
      } else {
        throw Exception(
            'Không tải được danh sách nhân viên (status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: $e');
    }
  }

  Future<EmployeeModel> getEmployeeById(String employeeId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getEmployeeById(employeeId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return EmployeeModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không lấy được nhân viên');
      }
    } catch (e) {
      throw Exception('Lỗi lấy nhân viên: $e');
    }
  }

  Future<EmployeeModel> createEmployee(EmployeeModel employee, String token,
      {File? imageFile}) async {
    try {
      // Nếu có file ảnh, dùng multipart request
      if (imageFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiConfig.createEmployee),
        );

        request.headers['Authorization'] = 'Bearer $token';

        // Thêm các field dữ liệu
        request.fields['employee_id'] = employee.employeeId;
        request.fields['employee_name'] = employee.employeeName;
        request.fields['employee_password'] = employee.employeePassword;
        request.fields['phone'] = employee.phone!;
        request.fields['email'] = employee.email!;
        request.fields['role_id'] = employee.roleId;

        if (employee.address != null) {
          request.fields['address'] = employee.address!;
        }

        if (employee.birth != null) {
          request.fields['birth'] = employee.birth!.toIso8601String();
        }

        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();

        final mimeType =
            lookupMimeType(imageFile.path) ?? 'application/octet-stream';

        var multipartFile = http.MultipartFile(
          'avatar',
          stream,
          length,
          filename: imageFile.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);

        print('Creating employee with image: ${imageFile.path}');

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        print('CREATE EMPLOYEE WITH IMAGE - Status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          return EmployeeModel.fromJson(json.decode(response.body));
        } else {
          final error = json.decode(response.body);
          throw Exception(error['message'] ?? 'Tạo nhân viên thất bại');
        }
      } else {
        // Không có file ảnh, dùng JSON request
        final response = await http.post(
          Uri.parse(ApiConfig.createEmployee),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(employee.toJson()),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return EmployeeModel.fromJson(json.decode(response.body));
        } else {
          final error = json.decode(response.body);
          throw Exception(error['message'] ?? 'Tạo nhân viên thất bại');
        }
      }
    } catch (e) {
      throw Exception('Lỗi tạo nhân viên: $e');
    }
  }

  Future<EmployeeModel> updateEmployee(
      String employeeId, EmployeeModel employee, String token,
      {File? imageFile}) async {
    try {
      if (imageFile != null) {
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse(ApiConfig.updateEmployee(employeeId)),
        );

        request.headers['Authorization'] = 'Bearer $token';

        request.fields['employee_id'] = employee.employeeId;
        request.fields['employee_name'] = employee.employeeName;
        request.fields['employee_password'] = employee.employeePassword;
        request.fields['phone'] = employee.phone!;
        request.fields['email'] = employee.email!;
        request.fields['role_id'] = employee.roleId;

        if (employee.address != null) {
          request.fields['address'] = employee.address!;
        }

        if (employee.birth != null) {
          request.fields['birth'] = employee.birth!.toIso8601String();
        }

        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();

        final mimeType =
            lookupMimeType(imageFile.path) ?? 'application/octet-stream';

        var multipartFile = http.MultipartFile(
          'avatar',
          stream,
          length,
          filename: imageFile.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        );

        request.files.add(multipartFile);

        print('Uploading image: ${imageFile.path}');

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        print('UPDATE EMPLOYEE WITH IMAGE - Status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          return EmployeeModel.fromJson(json.decode(response.body));
        } else {
          final error = json.decode(response.body);
          throw Exception(error['message'] ?? 'Cập nhật nhân viên thất bại');
        }
      } else {
        final response = await http.put(
          Uri.parse(ApiConfig.updateEmployee(employeeId)),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(employee.toJson()),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return EmployeeModel.fromJson(json.decode(response.body));
        } else {
          final error = json.decode(response.body);
          throw Exception(error['message'] ?? 'Cập nhật nhân viên thất bại');
        }
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật nhân viên: $e');
    }
  }

  Future<void> deleteEmployee(String employeeId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteEmployee(employeeId)),
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

  Future<void> deleteAllEmployee(String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteAllEmployee),
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
