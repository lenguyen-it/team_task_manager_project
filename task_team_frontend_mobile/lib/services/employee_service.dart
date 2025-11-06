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
      print('Response body: \\n${response.body}');

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

  Future<EmployeeModel> createEmployee(
      EmployeeModel employee, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createEmployee),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(employee.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return EmployeeModel.fromJson(
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

  Future<EmployeeModel> updateEmployee(
      String employeeId, EmployeeModel employee, String token) async {
    try {
      final response = await http.put(
        Uri.parse(
          ApiConfig.updateEmployee(employeeId),
        ),
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
