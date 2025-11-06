import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _secureStorage = const FlutterSecureStorage();

  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _employeeIdKey = 'employee_id';
  static const String _roleIdKey = 'role_id';
  static const String _rememberMeKey = 'remember_me';

  // Lưu token vào secure storage
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  // Lấy token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Xóa token
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  // Lưu thông tin user
  Future<void> saveUserInfo(String employeeId, String roleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_employeeIdKey, employeeId);
    await prefs.setString(_roleIdKey, roleId);
  }

  // Lấy employee ID
  Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_employeeIdKey);
  }

  // Lấy role ID
  Future<String?> getRoleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleIdKey);
  }

  // Lưu trạng thái "Ghi nhớ đăng nhập"
  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
  }

  // Kiểm tra trạng thái "Ghi nhớ đăng nhập"
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  // Xóa tất cả dữ liệu (đăng xuất)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Kiểm tra có token không
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
