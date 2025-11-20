// import 'package:flutter/material.dart';
// import 'package:task_team_frontend_mobile/models/notification_model.dart';
// import 'package:task_team_frontend_mobile/services/notification_service.dart';

// class NotificationProvider with ChangeNotifier {
//   final NotificationService _notificationService = NotificationService();

//   List<NotificationModel> _notifications = [];
//   List<NotificationModel> get notifications => _notifications;

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   String? _error;
//   String? get error => _error;

//   int _unreadCount = 0;
//   int get unreadCount => _unreadCount;

//   // Pagination
//   int _currentPage = 1;
//   int get currentPage => _currentPage;

//   int _totalPages = 1;
//   int get totalPages => _totalPages;

//   int _totalCount = 0;
//   int get totalCount => _totalCount;

//   // Lấy thông báo của user hiện tại với phân trang
//   Future<void> getMyNotifications({
//     required String token,
//     int page = 1,
//   }) async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final data = await _notificationService.getMyNotifications(
//         token,
//         page: page,
//         limit: 20,
//       );
//       _notifications = data['notifications'] as List<NotificationModel>;
//       _currentPage = data['currentPage'] as int;
//       _totalPages = data['totalPages'] as int;
//       _totalCount = data['totalCount'] as int;
//       _updateUnreadCount();
//     } catch (e) {
//       _error = e.toString().replaceAll('Exception: ', '');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   // Lấy tất cả thông báo với phân trang
//   Future<void> getAllNotifications({
//     required String token,
//     int page = 1,
//   }) async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final data = await _notificationService.getAllNotifications(
//         token,
//         page: page,
//         limit: 20,
//       );
//       _notifications = data['notifications'] as List<NotificationModel>;
//       _currentPage = data['currentPage'] as int;
//       _totalPages = data['totalPages'] as int;
//       _totalCount = data['totalCount'] as int;
//       _updateUnreadCount();
//     } catch (e) {
//       _error = e.toString().replaceAll('Exception: ', '');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> markAsRead(String notificationId, String token) async {
//     try {
//       final success =
//           await _notificationService.markAsRead(notificationId, token);

//       if (success) {
//         final index = _notifications.indexWhere((n) => n.id == notificationId);
//         if (index != -1 && !_notifications[index].isRead) {
//           _notifications[index] = _notifications[index].copyWith(
//             isRead: true,
//             readAt: DateTime.now(),
//           );
//           _updateUnreadCount();
//           notifyListeners();
//         }
//       }
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//     }
//   }

//   Future<void> markAllAsRead(String token, {bool canAccessAll = false}) async {
//     try {
//       final success = await _notificationService.markAllAsRead(token);

//       if (success) {
//         _notifications = _notifications.map((notification) {
//           return notification.copyWith(
//             isRead: true,
//             readAt: DateTime.now(),
//           );
//         }).toList();
//         _updateUnreadCount();
//         notifyListeners();
//       }
//     } catch (e) {
//       _error = e.toString();
//       notifyListeners();
//     }
//   }

//   void _updateUnreadCount() {
//     _unreadCount = _notifications.where((n) => !n.isRead).length;
//   }

//   // Clear error
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }

//   // Refresh notifications dựa trên quyền truy cập
//   Future<void> refresh(String token, {required bool canAccessAll}) async {
//     if (canAccessAll) {
//       await getAllNotifications(token: token);
//     } else {
//       await getMyNotifications(token: token);
//     }
//   }
// }


// notification_provider.dart
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
  }) async {
    if (reload) {
      _currentPage = 1;
      _notifications.clear();
      _hasMore = true;
    }

    if (!_hasMore || (_isLoadingMore && !reload)) return;

    if (_currentPage == 1) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final data = canAccessAll
          ? await _notificationService.getAllNotifications(token, page: _currentPage)
          : await _notificationService.getMyNotifications(token, page: _currentPage);

      final List<NotificationModel> newNotifications =
          (data['notifications'] as List).cast<NotificationModel>();

      if (reload || _currentPage == 1) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      _totalCount = data['totalCount'] as int;
      _totalPages = data['totalPages'] as int;
      _currentPage = data['currentPage'] as int;
      _hasMore = _currentPage < _totalPages;

      _updateUnreadCount();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Load thêm khi scroll
  Future<void> loadMore(String token, bool canAccessAll) async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    _currentPage++;
    await loadNotifications(token: token, canAccessAll: canAccessAll);
  }

  // Đánh dấu 1 thông báo đã đọc
  Future<void> markAsRead(String notificationId, String token) async {
    try {
      final success = await _notificationService.markAsRead(notificationId, token);
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

  // Đánh dấu tất cả đã đọc (admin được toàn quyền)
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
}