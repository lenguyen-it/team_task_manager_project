import 'package:flutter/material.dart';
import 'package:task_team_frontend_mobile/models/auth_model.dart';
import 'package:task_team_frontend_mobile/models/employee_model.dart';
import 'package:task_team_frontend_mobile/services/auth_service.dart';

import '../services/secure_storage.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  AuthStatus _status = AuthStatus.initial;
  String? _token;
  EmployeeModel? _currentEmployee;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get token => _token;
  EmployeeModel? get currentEmployee => _currentEmployee;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Khởi tạo - Kiểm tra token đã lưu
  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final rememberMe = await _storageService.getRememberMe();

      if (rememberMe) {
        final savedToken = await _storageService.getToken();
        final employeeId = await _storageService.getEmployeeId();

        if (savedToken != null && employeeId != null) {
          // Xác thực token
          final isValid = await _authService.validateToken(savedToken);

          if (isValid) {
            _token = savedToken;
            // Lấy thông tin employee đầy đủ
            _currentEmployee = await _authService.getEmployeeInfo(
              employeeId,
              savedToken,
            );
            _status = AuthStatus.authenticated;
          } else {
            await logout();
          }
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // Đăng nhập
  Future<bool> login({
    required String employeeId,
    required String password,
    bool rememberMe = false,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequest(
        employeeId: employeeId,
        employeePassword: password,
      );

      final response = await _authService.login(request);

      _token = response.token;

      // Lưu token và thông tin
      await _storageService.saveToken(response.token);
      await _storageService.saveUserInfo(
        response.employee.employeeId,
        response.employee.roleId,
      );
      await _storageService.setRememberMe(rememberMe);

      // Lấy thông tin employee đầy đủ
      _currentEmployee = await _authService.getEmployeeInfo(
        response.employee.employeeId,
        response.token,
      );

      _status = AuthStatus.authenticated;

      // LOG THÔNG TIN ĐĂNG NHẬP THÀNH CÔNG - FIXED
      print('========================================');
      print('🎉 LOGIN SUCCESSFUL!');
      print('========================================');
      print('📋 Employee ID: ${_currentEmployee?.employeeId}');
      print('👤 Employee Name: ${_currentEmployee?.employeeName}');
      print('🔑 Role ID: ${_currentEmployee?.roleId}');
      print('📧 Email: ${_currentEmployee?.email}');
      print('📱 Phone: ${_currentEmployee?.phone ?? 'N/A'}');
      // FIX: Kiểm tra độ dài token trước khi substring
      if (_token != null && _token!.length > 30) {
        print('🔐 Token: ${_token!.substring(0, 30)}...');
      } else {
        print('🔐 Token: ${_token ?? 'N/A'}');
      }
      print('💾 Remember Me: $rememberMe');
      print('========================================');

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Đăng ký
  Future<bool> register({
    required String employeeId,
    required String employeeName,
    required String password,
    required String roleId,
    required String email,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        employeeId: employeeId,
        employeeName: employeeName,
        employeePassword: password,
        roleId: roleId,
        email: email,
        phone: phone,
      );

      await _authService.register(request);

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Đăng xuất
  // Provider
  Future<void> logout() async {
    try {
      if (_token != null) {
        await _authService.logout(_token!);
      }

      await _storageService.clearAll();
      _token = null;
      _currentEmployee = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      await _storageService.clearAll();
      _token = null;
      _currentEmployee = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // Kiểm tra quyền
  bool hasPermission(List<String> allowedRoles) {
    if (_currentEmployee == null) return false;
    return allowedRoles.contains(_currentEmployee!.roleId);
  }

  void updateCurrentEmployee(EmployeeModel employee) {
    _currentEmployee = employee;
    notifyListeners();
  }

  // Reset error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
