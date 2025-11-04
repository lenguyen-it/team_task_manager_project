import 'package:flutter/material.dart';
import 'package:task_team_frontend_mobile/models/role_model.dart';
import 'package:task_team_frontend_mobile/services/role_service.dart';

class RoleProvider with ChangeNotifier {
  final RoleService _roleService = RoleService();

  List<RoleModel> _roles = [];
  List<RoleModel> get roles => _roles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<String> get roleNames => _roles.map((r) => r.roleName).toList();

  Future<void> getAllRole() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _roleService.getAllRole();
      _roles = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
