import 'package:flutter/material.dart';
import 'package:task_team_frontend_mobile/models/notification_model.dart';
import 'package:task_team_frontend_mobile/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalPages = 1;
  int get totalPages => _totalPages;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  // Tải dữ liệu (có hỗ trợ reload)
  Future<void> loadNotifications({
    required String token,
    required bool canAccessAll,
    bool reload = false,
    int? page, // Thêm tham số page để chuyển trang cụ thể
  }) async {
    if (reload) {
      _currentPage = page ?? 1;
      _notifications.clear();
      _hasMore = true;
    } else if (page != null) {
      _currentPage = page;
    }

    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = canAccessAll
          ? await _notificationService.getAllNotifications(token,
              page: _currentPage)
          : await _notificationService.getMyNotifications(token,
              page: _currentPage);

      final List<NotificationModel> newNotifications =
          (data['notifications'] as List).cast<NotificationModel>();

      _notifications = newNotifications;
      _totalCount = data['totalCount'] as int;
      _totalPages = data['totalPages'] as int;
      _currentPage = data['currentPage'] as int;
      _hasMore = _currentPage < _totalPages;

      _updateUnreadCount();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load trang tiếp theo
  Future<void> loadMore(String token, bool canAccessAll) async {
    if (!_hasMore || _isLoading) return;

    await loadNotifications(
      token: token,
      canAccessAll: canAccessAll,
      page: _currentPage + 1,
    );
  }

  // Load trang trước
  Future<void> loadPreviousPage(String token, bool canAccessAll) async {
    if (_currentPage <= 1 || _isLoading) return;

    await loadNotifications(
      token: token,
      canAccessAll: canAccessAll,
      page: _currentPage - 1,
    );
  }

  // Chuyển đến trang cụ thể
  Future<void> goToPage(int page, String token, bool canAccessAll) async {
    if (page < 1 || page > _totalPages || _isLoading) return;

    await loadNotifications(
      token: token,
      canAccessAll: canAccessAll,
      page: page,
    );
  }

  // Đánh dấu 1 thông báo đã đọc
  Future<void> markAsRead(String notificationId, String token) async {
    try {
      final success =
          await _notificationService.markAsRead(notificationId, token);
      if (success) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = _notifications[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _updateUnreadCount();
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead(String token) async {
    try {
      final success = await _notificationService.markAllAsRead(token);
      if (success) {
        _notifications = _notifications.map((n) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }).toList();
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset về trạng thái ban đầu
  void reset() {
    _notifications.clear();
    _currentPage = 1;
    _totalPages = 1;
    _totalCount = 0;
    _hasMore = true;
    _unreadCount = 0;
    _error = null;
    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }
}
