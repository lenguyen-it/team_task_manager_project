import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/auth_model.dart';
import 'package:task_team_frontend_mobile/models/employee_model.dart';

class AuthService {
  // Đăng nhập
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoginResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Error during login: ${e.toString()}');
    }
  }

  //Đăng xuất
  Future<void> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.logout),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Logout failed');
      }
    } catch (e) {
      throw Exception('Error during logout: ${e.toString()}');
    }
  }

  // Đăng ký
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resgiter),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RegisterResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Error during registration: ${e.toString()}');
    }
  }

  // Lấy thông tin employee chi tiết
  Future<EmployeeModel> getEmployeeInfo(String employeeId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getEmployeeById(employeeId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmployeeModel.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get employee info');
      }
    } catch (e) {
      throw Exception('Error getting employee info: ${e.toString()}');
    }
  }

  // Xác thực token (kiểm tra token còn hiệu lực)
  Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getAllEmployee),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
