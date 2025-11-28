import 'package:flutter/material.dart';
import 'package:task_team_frontend_mobile/models/activitylog_model.dart';
import 'package:task_team_frontend_mobile/services/activitylog_service.dart';

class ActivitylogProvider with ChangeNotifier {
  final ActivitylogService _activitylogService = ActivitylogService();

  List<ActivityLogModel> _activityLogs = [];
  List<ActivityLogModel> get activityLogs => _activityLogs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Pagination
  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalPages = 0;
  int get totalPages => _totalPages;

  int _totalLogs = 0;
  int get totalLogs => _totalLogs;

  int _limit = 20;
  int get limit => _limit;

  Future<void> getAllActivityLogs({
    required String token,
    int page = 1,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _activitylogService.getAllActivityLogs(
        token,
        page: page,
        limit: _limit,
      );

      _activityLogs = result['logs'] ?? [];
      final pagination = result['pagination'] ?? {};

      _currentPage = pagination['page'] ?? 1;
      _totalPages = pagination['pages'] ?? 0;
      _totalLogs = pagination['total'] ?? 0;

      print('📊 Pagination: $_currentPage / $_totalPages (Total: $_totalLogs)');
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getMyActivityLogs({
    required String token,
    int page = 1,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _activitylogService.getMyActivityLogs(
        token,
        page: page,
        limit: _limit,
      );

      _activityLogs = result['logs'] ?? [];
      final pagination = result['pagination'] ?? {};

      _currentPage = pagination['page'] ?? 1;
      _totalPages = pagination['pages'] ?? 0;
      _totalLogs = pagination['total'] ?? 0;

      print('📊 Pagination: $_currentPage / $_totalPages (Total: $_totalLogs)');
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh Activity Logs
  Future<void> refresh(String token, {String? roleId}) async {
    _currentPage = 1; // Reset về trang 1
    final isAdmin = roleId != null &&
        (roleId.toLowerCase() == 'admin' || roleId.toLowerCase() == 'manager');

    if (isAdmin) {
      await getAllActivityLogs(token: token, page: 1);
    } else {
      await getMyActivityLogs(token: token, page: 1);
    }
  }

  // Chuyển trang tiếp theo
  Future<void> nextPage(String token, {String? roleId}) async {
    if (_currentPage < _totalPages) {
      final nextPage = _currentPage + 1;
      final isAdmin = roleId != null &&
          (roleId.toLowerCase() == 'admin' ||
              roleId.toLowerCase() == 'manager');

      if (isAdmin) {
        await getAllActivityLogs(token: token, page: nextPage);
      } else {
        await getMyActivityLogs(token: token, page: nextPage);
      }
    }
  }

  // Chuyển trang trước đó
  Future<void> previousPage(String token, {String? roleId}) async {
    if (_currentPage > 1) {
      final previousPage = _currentPage - 1;
      final isAdmin = roleId != null &&
          (roleId.toLowerCase() == 'admin' ||
              roleId.toLowerCase() == 'manager');

      if (isAdmin) {
        await getAllActivityLogs(token: token, page: previousPage);
      } else {
        await getMyActivityLogs(token: token, page: previousPage);
      }
    }
  }
}
