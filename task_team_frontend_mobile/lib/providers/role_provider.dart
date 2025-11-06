import 'package:flutter/material.dart';
import 'package:task_team_frontend_mobile/models/role_model.dart';
import 'package:task_team_frontend_mobile/services/role_service.dart';

class RoleProvider extends ChangeNotifier {
  final RoleService _roleService = RoleService();

  List<RoleModel> _roles = [];
  List<RoleModel> get roles => _roles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<String> get roleIds => _roles.map((r) => r.roleId).toList();
  List<String> get roleNames => _roles.map((r) => r.roleName).toList();

  // Lấy tất cả role (có thể truyền token nếu cần auth)
  Future<void> getAllRole({required String token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _roleService.getAllRole(token); // ← truyền token
      _roles = data;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getRoleById(String roleId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _roleService.getRoleById(roleId, token);
      _roles = [data];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tạo role mới
  Future<bool> createRole(RoleModel role, String token) async {
    try {
      final newRole = await _roleService.createRole(role, token);
      _roles.add(newRole);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cập nhật role
  Future<bool> updateRole(
      String roleId, RoleModel updatedRole, String token) async {
    try {
      final role = await _roleService.updateRole(roleId, updatedRole, token);
      final index = _roles.indexWhere((r) => r.roleId == roleId);
      if (index != -1) {
        _roles[index] = role;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Xóa role
  Future<bool> deleteRole(String roleId, String token) async {
    try {
      await _roleService.deleteRole(roleId, token);
      _roles.removeWhere((r) => r.roleId == roleId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Tìm role theo ID
  // RoleModel? getRoleById(String roleId) {
  //   try {
  //     return _roles.firstWhere((r) => r.roleId == roleId);
  //   } catch (e) {
  //     return null;
  //   }
  // }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh
  Future<void> refresh(String token) async {
    await getAllRole(token: token);
  }
}
