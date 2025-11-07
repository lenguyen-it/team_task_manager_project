import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/role_model.dart';

class RoleService {
  // Lấy tất cả role
  Future<List<RoleModel>> getAllRole(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getAllRole),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('GET ALL ROLES - Status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List data = json.decode(response.body);
        return data.map((e) => RoleModel.fromJson(e)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không tải được danh sách vai trò');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách role: $e');
    }
  }

  Future<RoleModel> getRoleById(String roleId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(
          ApiConfig.getRoleById(roleId),
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return RoleModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không lấy được nhân viên');
      }
    } catch (e) {
      throw Exception('Lỗi lấy nhân viên: $e');
    }
  }

  // Tạo role mới
  Future<RoleModel> createRole(RoleModel role, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createRole),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(role.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RoleModel.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Tạo role thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi tạo role: $e');
    }
  }

  // Cập nhật role theo role_id
  Future<RoleModel> updateRole(
      String roleId, RoleModel role, String token) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.updateRole(roleId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(role.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RoleModel.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Cập nhật role thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật role: $e');
    }
  }

  // Xóa role theo role_id
  Future<void> deleteRole(String roleId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteRole(roleId)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Xóa role thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi xóa role: $e');
    }
  }

  //Xóa toàn bộ role
  Future<void> deleteAllRole(String token) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteAllRole),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Xóa role thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi xóa toàn bộ role: $e');
    }
  }
}
