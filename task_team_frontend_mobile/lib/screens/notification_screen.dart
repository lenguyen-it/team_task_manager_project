// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:task_team_frontend_mobile/models/notification_model.dart';
// import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
// import 'package:task_team_frontend_mobile/providers/notification_provider.dart';

// class NotificationScreen extends StatefulWidget {
//   const NotificationScreen({super.key});

//   @override
//   State<NotificationScreen> createState() => _NotificationScreenState();
// }

// class _NotificationScreenState extends State<NotificationScreen> {
//   String _filter = 'all';
//   String? _token;
//   String? _roleId;
//   bool _canAccessAllNotifications = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadNotifications();
//     });
//   }

//   Future<void> _loadNotifications({int page = 1}) async {
//     final auth = Provider.of<AuthProvider>(context, listen: false);
//     _token = auth.token;
//     _roleId = auth.currentEmployee?.roleId;

//     _canAccessAllNotifications = _roleId != null &&
//         (_roleId!.toLowerCase() == 'admin' ||
//             _roleId!.toLowerCase() == 'manager');

//     print('Role ID: $_roleId');
//     print('Role type: ${_roleId.runtimeType}');
//     print('Can access all: $_canAccessAllNotifications');

//     if (_token != null) {
//       final provider = context.read<NotificationProvider>();

//       if (_canAccessAllNotifications) {
//         await provider.getAllNotifications(token: _token!, page: page);
//       } else {
//         await provider.getMyNotifications(token: _token!, page: page);
//       }
//     }
//   }

//   Future<void> _handleRefresh() async {
//     if (_token != null) {
//       await context
//           .read<NotificationProvider>()
//           .refresh(_token!, canAccessAll: _canAccessAllNotifications);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         title: Row(
//           children: [
//             const Text(
//               'Thông báo',
//               style: TextStyle(
//                 color: Colors.black87,
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           Consumer<NotificationProvider>(
//             builder: (context, provider, _) {
//               return TextButton(
//                 onPressed: () async {
//                   if (_token != null) {
//                     setState(() {
//                       _filter = 'all';
//                     });
//                     await provider.markAllAsRead(_token!);
//                   }
//                 },
//                 child: const Icon(
//                   Icons.checklist,
//                   size: 24,
//                   color: Colors.black,
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Consumer<NotificationProvider>(
//         builder: (context, provider, _) {
//           if (provider.isLoading) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }

//           if (provider.error != null) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
//                   const SizedBox(height: 16),
//                   Text(
//                     provider.error!,
//                     style: const TextStyle(color: Colors.red),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () => _loadNotifications(),
//                     child: const Text('Thử lại'),
//                   ),
//                 ],
//               ),
//             );
//           }

//           final unreadCount =
//               provider.notifications.where((n) => !n.isRead).length;

//           List<NotificationModel> filteredNotifications =
//               provider.notifications;
//           if (_filter == 'unread') {
//             filteredNotifications =
//                 provider.notifications.where((n) => !n.isRead).toList();
//           } else if (_filter == 'read') {
//             filteredNotifications =
//                 provider.notifications.where((n) => n.isRead).toList();
//           }

//           return Column(
//             children: [
//               // Filter Tabs
//               Container(
//                 color: Colors.white,
//                 child: Row(
//                   children: [
//                     _buildFilterTab(
//                       'all',
//                       'Tất cả',
//                       provider.totalCount,
//                     ),
//                     _buildFilterTab('unread', 'Chưa đọc', unreadCount),
//                     _buildFilterTab(
//                       'read',
//                       'Đã đọc',
//                       provider.totalCount - unreadCount,
//                     ),
//                   ],
//                 ),
//               ),
//               // Notifications List
//               Expanded(
//                 child: filteredNotifications.isEmpty
//                     ? _buildEmptyState()
//                     : RefreshIndicator(
//                         onRefresh: _handleRefresh,
//                         child: ListView.builder(
//                           padding: const EdgeInsets.all(16),
//                           itemCount: filteredNotifications.length + 1,
//                           itemBuilder: (context, index) {
//                             // Pagination controls at the bottom
//                             if (index == filteredNotifications.length) {
//                               if (provider.totalPages <= 1) {
//                                 return const SizedBox.shrink();
//                               }

//                               return Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 16,
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     // Previous button
//                                     ElevatedButton.icon(
//                                       onPressed: provider.currentPage > 1
//                                           ? () {
//                                               _loadNotifications(
//                                                 page: provider.currentPage - 1,
//                                               );
//                                             }
//                                           : null,
//                                       icon: const Icon(Icons.arrow_back),
//                                       label: const Text('Trước'),
//                                     ),
//                                     const SizedBox(width: 16),
//                                     // Page indicator
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 16,
//                                         vertical: 8,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: Colors.blue[100],
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       child: Text(
//                                         'Trang ${provider.currentPage}/${provider.totalPages}',
//                                         style: TextStyle(
//                                           color: Colors.blue[700],
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 16),
//                                     // Next button
//                                     ElevatedButton.icon(
//                                       onPressed: provider.currentPage <
//                                               provider.totalPages
//                                           ? () {
//                                               _loadNotifications(
//                                                 page: provider.currentPage + 1,
//                                               );
//                                             }
//                                           : null,
//                                       icon: const Icon(Icons.arrow_forward),
//                                       label: const Text('Sau'),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }

//                             final notification = filteredNotifications[index];
//                             return NotificationCard(
//                               notification: notification,
//                               canAccessAll: _canAccessAllNotifications,
//                               onTap: () async {
//                                 if (!notification.isRead && _token != null) {
//                                   await Provider.of<NotificationProvider>(
//                                     context,
//                                     listen: false,
//                                   ).markAsRead(
//                                     notification.id!,
//                                     _token!,
//                                   );
//                                 }
//                               },
//                             );
//                           },
//                         ),
//                       ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildFilterTab(String key, String label, int count) {
//     final isSelected = _filter == key;
//     return Expanded(
//       child: InkWell(
//         onTap: () {
//           setState(() {
//             _filter = key;
//           });
//         },
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           decoration: BoxDecoration(
//             border: Border(
//               bottom: BorderSide(
//                 color: isSelected ? Colors.blue : Colors.transparent,
//                 width: 2,
//               ),
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: isSelected ? Colors.blue : Colors.grey[600],
//                   fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                   fontSize: 14,
//                 ),
//               ),
//               if (count > 0) ...[
//                 const SizedBox(width: 6),
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: isSelected ? Colors.blue[100] : Colors.grey[200],
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     count.toString(),
//                     style: TextStyle(
//                       color: isSelected ? Colors.blue[700] : Colors.grey[600],
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.notifications_none,
//             size: 80,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Không có thông báo nào',
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class NotificationCard extends StatelessWidget {
//   final NotificationModel notification;
//   final bool canAccessAll;
//   final VoidCallback onTap;

//   const NotificationCard({
//     super.key,
//     required this.notification,
//     required this.canAccessAll,
//     required this.onTap,
//   });

//   NotificationStyle _getNotificationStyle(String type) {
//     switch (type) {
//       case 'task_assigned':
//       case 'role_assigned':
//       case 'project_assigned':
//         return NotificationStyle(
//           bgColor: Colors.green[50]!,
//           borderColor: Colors.green[200]!,
//           iconColor: Colors.green[600]!,
//           iconBgColor: Colors.green[100]!,
//           icon: Icons.person_add,
//         );

//       case 'task_updated':
//       case 'role_update':
//       case 'project_updated':
//         return NotificationStyle(
//           bgColor: Colors.orange[50]!,
//           borderColor: Colors.orange[200]!,
//           iconColor: Colors.orange[600]!,
//           iconBgColor: Colors.orange[100]!,
//           icon: Icons.edit,
//         );

//       case 'task_completed':
//       case 'task_confirmed':
//       case 'project_completed':
//         return NotificationStyle(
//           bgColor: Colors.blue[50]!,
//           borderColor: Colors.blue[200]!,
//           iconColor: Colors.blue[600]!,
//           iconBgColor: Colors.blue[100]!,
//           icon: Icons.check_circle,
//         );

//       case 'task_deadline_near':
//       case 'project_deadline_near':
//         return NotificationStyle(
//           bgColor: Colors.deepOrange[50]!,
//           borderColor: Colors.deepOrange[300]!,
//           iconColor: Colors.deepOrange[600]!,
//           iconBgColor: Colors.deepOrange[100]!,
//           icon: Icons.access_time,
//         );

//       case 'task_overdue':
//         return NotificationStyle(
//           bgColor: Colors.red[50]!,
//           borderColor: Colors.red[300]!,
//           iconColor: Colors.red[600]!,
//           iconBgColor: Colors.red[100]!,
//           icon: Icons.error_outline,
//         );

//       case 'task_comment':
//         return NotificationStyle(
//           bgColor: Colors.purple[50]!,
//           borderColor: Colors.purple[200]!,
//           iconColor: Colors.purple[600]!,
//           iconBgColor: Colors.purple[100]!,
//           icon: Icons.comment,
//         );

//       default:
//         return NotificationStyle(
//           bgColor: Colors.grey[50]!,
//           borderColor: Colors.grey[200]!,
//           iconColor: Colors.grey[600]!,
//           iconBgColor: Colors.grey[100]!,
//           icon: Icons.notifications,
//         );
//     }
//   }

//   String _formatTimeAgo(DateTime date) {
//     final now = DateTime.now();
//     final diff = now.difference(date);

//     if (diff.inMinutes < 1) return 'Vừa xong';
//     if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
//     if (diff.inHours < 24) return '${diff.inHours} giờ trước';
//     if (diff.inDays < 7) return '${diff.inDays} ngày trước';

//     return '${date.day}/${date.month}/${date.year}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final style = _getNotificationStyle(notification.type);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Material(
//         color: style.bgColor,
//         borderRadius: BorderRadius.circular(12),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(12),
//           child: Container(
//             decoration: BoxDecoration(
//               border: Border.all(color: style.borderColor, width: 1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Stack(
//               children: [
//                 // Dot chưa đọc
//                 if (!notification.isRead)
//                   Positioned(
//                     top: 12,
//                     right: 12,
//                     child: Container(
//                       width: 8,
//                       height: 8,
//                       decoration: const BoxDecoration(
//                         color: Colors.blue,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   ),
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Icon
//                       Container(
//                         width: 48,
//                         height: 48,
//                         decoration: BoxDecoration(
//                           color: style.iconBgColor,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(
//                           style.icon,
//                           color: style.iconColor,
//                           size: 24,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       // Content
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Message
//                             Text(
//                               notification.message,
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.grey[800],
//                                 fontWeight: notification.isRead
//                                     ? FontWeight.normal
//                                     : FontWeight.w600,
//                                 height: 1.4,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             // Footer
//                             Row(
//                               children: [
//                                 // Time
//                                 Icon(
//                                   Icons.access_time,
//                                   size: 14,
//                                   color: Colors.grey[500],
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   _formatTimeAgo(notification.createAt),
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                                 const Spacer(),
//                                 if (notification.metadata != null) ...[
//                                   if (notification.metadata!['overdue_days'] !=
//                                       null) ...[
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 8,
//                                         vertical: 4,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: Colors.red[100],
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: Text(
//                                         'Quá ${notification.metadata!['overdue_days']} ngày',
//                                         style: TextStyle(
//                                           color: Colors.red[700],
//                                           fontSize: 11,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                     ),
//                                   ] else if (notification
//                                           .metadata!['hours_remaining'] !=
//                                       null) ...[
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 8,
//                                         vertical: 4,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: Colors.orange[100],
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: Text(
//                                         'Còn ${notification.metadata!['hours_remaining']}h',
//                                         style: TextStyle(
//                                           color: Colors.orange[700],
//                                           fontSize: 11,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ],
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class NotificationStyle {
//   final Color bgColor;
//   final Color borderColor;
//   final Color iconColor;
//   final Color iconBgColor;
//   final IconData icon;

//   NotificationStyle({
//     required this.bgColor,
//     required this.borderColor,
//     required this.iconColor,
//     required this.iconBgColor,
//     required this.icon,
//   });
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/models/notification_model.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _filter = 'all';
  String? _token;
  String? _roleId;
  bool _canAccessAllNotifications = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications(reload: true);
    });
  }

  Future<void> _loadNotifications({bool reload = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _token = auth.token;
    _roleId = auth.currentEmployee?.roleId;

    _canAccessAllNotifications = _roleId != null &&
        (_roleId!.toLowerCase() == 'admin' ||
            _roleId!.toLowerCase() == 'manager');

    if (_token != null) {
      final provider = context.read<NotificationProvider>();
      await provider.loadNotifications(
        token: _token!,
        canAccessAll: _canAccessAllNotifications,
        reload: reload,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
    if (difference.inHours < 24) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _filter == 'unread'
                ? 'Không có thông báo chưa đọc'
                : 'Chưa có thông báo',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label, int count) {
    final isSelected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Thông báo',
          style: TextStyle(
              color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return TextButton(
                onPressed: provider.notifications.isEmpty
                    ? null
                    : () async {
                        setState(() => _filter = 'all');
                        await provider.markAllAsRead(_token!);
                        await _loadNotifications(reload: true); // Reload sạch
                      },
                child:
                    const Icon(Icons.checklist, size: 24, color: Colors.black),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(provider.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => _loadNotifications(reload: true),
                      child: const Text('Thử lại')),
                ],
              ),
            );
          }

          final unreadCount = provider.unreadCount;

          List<NotificationModel> filtered = provider.notifications;
          if (_filter == 'unread')
            filtered = filtered.where((n) => !n.isRead).toList();
          if (_filter == 'read')
            filtered = filtered.where((n) => n.isRead).toList();

          return Column(
            children: [
              Container(
                color: Colors.white,
                child: Row(
                  children: [
                    _buildFilterTab('all', 'Tất cả', provider.totalCount),
                    _buildFilterTab('unread', 'Chưa đọc', unreadCount),
                    _buildFilterTab(
                        'read', 'Đã đọc', provider.totalCount - unreadCount),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadNotifications(reload: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              filtered.length + (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Auto load more khi gần cuối
                            if (index >= filtered.length - 3 &&
                                provider.hasMore &&
                                !provider.isLoadingMore) {
                              provider.loadMore(
                                  _token!, _canAccessAllNotifications);
                            }

                            if (index == filtered.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final notification = filtered[index];
                            final style = NotificationStyle(
                              bgColor: notification.isRead
                                  ? Colors.grey[100]!
                                  : Colors.white,
                              borderColor: notification.isRead
                                  ? Colors.transparent
                                  : Colors.blue.withOpacity(0.3),
                              iconBgColor: Colors.blue[50]!,
                              iconColor: Colors.blue[700]!,
                              icon: Icons.notifications,
                            );

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                // Chỉ mark nếu chưa đọc + có token
                                if (!notification.isRead && _token != null) {
                                  await provider.markAsRead(
                                      notification.id!, _token!);
                                }
                                // Có thể thêm navigate vào chi tiết task ở đây sau
                              },
                              child: Card(
                                elevation: 0,
                                color: style.bgColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: style.borderColor, width: 1),
                                ),
                                child: Stack(
                                  children: [
                                    if (!notification.isRead)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: style.iconBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(style.icon,
                                                color: style.iconColor,
                                                size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  notification.message,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[800],
                                                    fontWeight:
                                                        notification.isRead
                                                            ? FontWeight.normal
                                                            : FontWeight.w600,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(Icons.access_time,
                                                        size: 14,
                                                        color:
                                                            Colors.grey[500]),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                        _formatTimeAgo(
                                                            notification
                                                                .createAt),
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey[600])),
                                                    const Spacer(),
                                                    if (notification.metadata?[
                                                            'overdue_days'] !=
                                                        null)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4),
                                                        decoration: BoxDecoration(
                                                            color:
                                                                Colors.red[100],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12)),
                                                        child: Text(
                                                            'Quá ${notification.metadata!['overdue_days']} ngày',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .red[700],
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NotificationStyle {
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final Color iconBgColor;
  final IconData icon;

  NotificationStyle({
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.icon,
  });
}
