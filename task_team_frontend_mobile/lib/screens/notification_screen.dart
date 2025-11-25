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

  Future<void> _loadNextPage() async {
    if (_token != null) {
      final provider = context.read<NotificationProvider>();
      await provider.loadMore(_token!, _canAccessAllNotifications);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  Future<void> _loadPreviousPage() async {
    if (_token != null) {
      final provider = context.read<NotificationProvider>();
      if (provider.currentPage > 1) {
        await provider.loadPreviousPage(_token!, _canAccessAllNotifications);
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      }
    }
  }

  Future<void> _goToPage(int page) async {
    if (_token != null) {
      final provider = context.read<NotificationProvider>();
      await provider.goToPage(page, _token!, _canAccessAllNotifications);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
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
    if (difference.inMinutes < 60) return '${difference.inMinutes}p';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${date.day}/${date.month}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            _filter == 'unread'
                ? 'Không có thông báo chưa đọc'
                : 'Chưa có thông báo',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ✅ Filter tabs - Compact & Responsive
  Widget _buildFilterTab(String value, String label, int count) {
    final isSelected = _filter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey[700],
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.blue[700] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Pagination - Compact & Responsive (Đặt ở trên)
  Widget _buildCompactPagination(NotificationProvider provider) {
    if (provider.totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          IconButton(
            onPressed: provider.currentPage > 1 && !provider.isLoading
                ? _loadPreviousPage
                : null,
            icon: const Icon(Icons.chevron_left, size: 28),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Trang trước',
          ),

          // Page info & numbers
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Current page indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      '${provider.currentPage}/${provider.totalPages}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quick jump buttons (only show if many pages)
                  if (provider.totalPages > 3) ...[
                    _buildQuickJumpButton(1, provider, 'Đầu'),
                    if (provider.currentPage > 3)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('...', style: TextStyle(fontSize: 12)),
                      ),
                    if (provider.currentPage < provider.totalPages)
                      _buildQuickJumpButton(
                          provider.totalPages, provider, 'Cuối'),
                  ],
                ],
              ),
            ),
          ),

          // Next button
          IconButton(
            onPressed:
                provider.hasMore && !provider.isLoading ? _loadNextPage : null,
            icon: const Icon(Icons.chevron_right, size: 28),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Trang sau',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickJumpButton(
      int page, NotificationProvider provider, String label) {
    final isCurrent = page == provider.currentPage;
    return InkWell(
      onTap: !provider.isLoading && !isCurrent ? () => _goToPage(page) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCurrent ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isCurrent ? Colors.white : Colors.grey[700],
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
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return IconButton(
                onPressed: provider.notifications.isEmpty
                    ? null
                    : () async {
                        setState(() => _filter = 'all');
                        await provider.markAllAsRead(_token!);
                        await _loadNotifications(reload: true);
                      },
                icon: const Icon(Icons.done_all, color: Colors.black87),
                tooltip: 'Đánh dấu tất cả đã đọc',
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
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadNotifications(reload: true),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final unreadCount = provider.unreadCount;
          List<NotificationModel> filtered = provider.notifications;
          if (_filter == 'unread') {
            filtered = filtered.where((n) => !n.isRead).toList();
          } else if (_filter == 'read') {
            filtered = filtered.where((n) => n.isRead).toList();
          }

          return Column(
            children: [
              // Filter tabs (Tất cả - Chưa đọc - Đã đọc)
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

              // Danh sách thông báo
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadNotifications(reload: true),
                        child: Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                // ... (giữ nguyên phần itemBuilder như cũ)
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
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () async {
                                    if (!notification.isRead &&
                                        _token != null) {
                                      await provider.markAsRead(
                                          notification.id!, _token!);
                                    }
                                  },
                                  child: Card(
                                    elevation: 0,
                                    color: style.bgColor,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                          color: style.borderColor, width: 1),
                                    ),
                                    child: Stack(
                                      children: [
                                        if (!notification.isRead)
                                          const Positioned(
                                            top: 10,
                                            right: 10,
                                            child: CircleAvatar(
                                                radius: 4,
                                                backgroundColor: Colors.blue),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: style.iconBgColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(style.icon,
                                                    color: style.iconColor,
                                                    size: 20),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      notification.message,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[800],
                                                        fontWeight: notification
                                                                .isRead
                                                            ? FontWeight.normal
                                                            : FontWeight.w600,
                                                        height: 1.3,
                                                      ),
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.access_time,
                                                            size: 12,
                                                            color: Colors
                                                                .grey[500]),
                                                        const SizedBox(
                                                            width: 3),
                                                        Text(
                                                          _formatTimeAgo(
                                                              notification
                                                                  .createAt),
                                                          style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .grey[600]),
                                                        ),
                                                        const Spacer(),
                                                        if (notification
                                                                    .metadata?[
                                                                'overdue_days'] !=
                                                            null)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .red[100],
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Text(
                                                              'Quá ${notification.metadata!['overdue_days']}d',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .red[700],
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
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
                            if (provider.isLoading)
                              Container(
                                color: Colors.black.withOpacity(0.05),
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              ),
                          ],
                        ),
                      ),
              ),

              // PHÂN TRANG ĐƯỢC ĐƯA XUỐNG DƯỚI CÙNG (sau danh sách)
              if (provider.totalPages > 1)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: Colors.white,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Nút "Trước"
                          TextButton.icon(
                            onPressed:
                                provider.currentPage > 1 && !provider.isLoading
                                    ? _loadPreviousPage
                                    : null,
                            icon: const Icon(Icons.chevron_left, size: 20),
                            label: const Text('Trước',
                                style: TextStyle(fontSize: 13)),
                            style: TextButton.styleFrom(
                              foregroundColor: provider.currentPage > 1
                                  ? Colors.blue[700]
                                  : Colors.grey,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),

                          // Hiển thị trang ở giữa (responsive)
                          Container(
                            constraints: const BoxConstraints(minWidth: 80),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Text(
                                  '${provider.currentPage}/${provider.totalPages}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Nút "Sau"
                          TextButton.icon(
                            onPressed: provider.hasMore && !provider.isLoading
                                ? _loadNextPage
                                : null,
                            icon: const Icon(Icons.chevron_right, size: 20),
                            label: const Text('Sau',
                                style: TextStyle(fontSize: 13)),
                            style: TextButton.styleFrom(
                              foregroundColor: provider.hasMore
                                  ? Colors.blue[700]
                                  : Colors.grey,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.grey[50],
  //     appBar: AppBar(
  //       elevation: 0,
  //       backgroundColor: Colors.white,
  //       title: const Text(
  //         'Thông báo',
  //         style: TextStyle(
  //             color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
  //       ),
  //       actions: [
  //         Consumer<NotificationProvider>(
  //           builder: (context, provider, _) {
  //             return IconButton(
  //               onPressed: provider.notifications.isEmpty
  //                   ? null
  //                   : () async {
  //                       setState(() => _filter = 'all');
  //                       await provider.markAllAsRead(_token!);
  //                       await _loadNotifications(reload: true);
  //                     },
  //               icon: const Icon(Icons.done_all, color: Colors.black87),
  //               tooltip: 'Đánh dấu tất cả đã đọc',
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //     body: Consumer<NotificationProvider>(
  //       builder: (context, provider, _) {
  //         if (provider.isLoading && provider.notifications.isEmpty) {
  //           return const Center(child: CircularProgressIndicator());
  //         }

  //         if (provider.error != null) {
  //           return Center(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
  //                 const SizedBox(height: 12),
  //                 Padding(
  //                   padding: const EdgeInsets.symmetric(horizontal: 32),
  //                   child: Text(provider.error!,
  //                       style: const TextStyle(color: Colors.red, fontSize: 13),
  //                       textAlign: TextAlign.center),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 ElevatedButton(
  //                     onPressed: () => _loadNotifications(reload: true),
  //                     child: const Text('Thử lại')),
  //               ],
  //             ),
  //           );
  //         }

  //         final unreadCount = provider.unreadCount;
  //         List<NotificationModel> filtered = provider.notifications;
  //         if (_filter == 'unread') {
  //           filtered = filtered.where((n) => !n.isRead).toList();
  //         } else if (_filter == 'read') {
  //           filtered = filtered.where((n) => n.isRead).toList();
  //         }

  //         return Column(
  //           children: [
  //             // 1. Thanh tab: Tất cả - Chưa đọc - Đã đọc
  //             Container(
  //               color: Colors.white,
  //               child: Row(
  //                 children: [
  //                   _buildFilterTab('all', 'Tất cả', provider.totalCount),
  //                   _buildFilterTab('unread', 'Chưa đọc', unreadCount),
  //                   _buildFilterTab(
  //                       'read', 'Đã đọc', provider.totalCount - unreadCount),
  //                 ],
  //               ),
  //             ),

  //             // 2. PHÂN TRANG - ĐÚNG VỊ TRÍ: Dưới tab, trên danh sách
  //             if (provider.totalPages > 1)
  //               Container(
  //                 width: double.infinity,
  //                 padding: const EdgeInsets.symmetric(vertical: 10),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   border: Border(
  //                       bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
  //                 ),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     // Nút Trước
  //                     TextButton.icon(
  //                       onPressed:
  //                           provider.currentPage > 1 && !provider.isLoading
  //                               ? _loadPreviousPage
  //                               : null,
  //                       icon: const Icon(Icons.chevron_left, size: 18),
  //                       label:
  //                           const Text('Trước', style: TextStyle(fontSize: 13)),
  //                       style: TextButton.styleFrom(
  //                         foregroundColor: provider.currentPage > 1
  //                             ? Colors.blue[700]
  //                             : Colors.grey[400],
  //                         padding: const EdgeInsets.symmetric(
  //                             horizontal: 16, vertical: 8),
  //                         minimumSize: const Size(80, 36),
  //                       ),
  //                     ),

  //                     // Trang hiện tại / tổng (giữa màn hình)
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(
  //                           horizontal: 16, vertical: 6),
  //                       decoration: BoxDecoration(
  //                         color: Colors.blue[50],
  //                         borderRadius: BorderRadius.circular(8),
  //                         border: Border.all(color: Colors.blue[300]!),
  //                       ),
  //                       child: Text(
  //                         '${provider.currentPage}/${provider.totalPages}',
  //                         style: TextStyle(
  //                           color: Colors.blue[700],
  //                           fontWeight: FontWeight.w600,
  //                           fontSize: 14,
  //                         ),
  //                       ),
  //                     ),

  //                     // Nút Sau
  //                     TextButton.icon(
  //                       onPressed: provider.hasMore && !provider.isLoading
  //                           ? _loadNextPage
  //                           : null,
  //                       icon: const Icon(Icons.chevron_right, size: 18),
  //                       label:
  //                           const Text('Sau', style: TextStyle(fontSize: 13)),
  //                       style: TextButton.styleFrom(
  //                         foregroundColor: provider.hasMore
  //                             ? Colors.blue[700]
  //                             : Colors.grey[400],
  //                         padding: const EdgeInsets.symmetric(
  //                             horizontal: 16, vertical: 8),
  //                         minimumSize: const Size(80, 36),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),

  //             // 3. Danh sách thông báo (chiếm phần còn lại)
  //             Expanded(
  //               child: filtered.isEmpty
  //                   ? _buildEmptyState()
  //                   : RefreshIndicator(
  //                       onRefresh: () => _loadNotifications(reload: true),
  //                       child: Stack(
  //                         children: [
  //                           ListView.builder(
  //                             controller: _scrollController,
  //                             physics: const AlwaysScrollableScrollPhysics(),
  //                             padding: const EdgeInsets.all(12),
  //                             itemCount: filtered.length,
  //                             itemBuilder: (context, index) {
  //                               final notification = filtered[index];
  //                               final style = NotificationStyle(
  //                                 bgColor: notification.isRead
  //                                     ? Colors.grey[100]!
  //                                     : Colors.white,
  //                                 borderColor: notification.isRead
  //                                     ? Colors.transparent
  //                                     : Colors.blue.withOpacity(0.3),
  //                                 iconBgColor: Colors.blue[50]!,
  //                                 iconColor: Colors.blue[700]!,
  //                                 icon: Icons.notifications,
  //                               );

  //                               return InkWell(
  //                                 borderRadius: BorderRadius.circular(10),
  //                                 onTap: () async {
  //                                   if (!notification.isRead &&
  //                                       _token != null) {
  //                                     await provider.markAsRead(
  //                                         notification.id!, _token!);
  //                                   }
  //                                 },
  //                                 child: Card(
  //                                   elevation: 0,
  //                                   color: style.bgColor,
  //                                   margin: const EdgeInsets.only(bottom: 8),
  //                                   shape: RoundedRectangleBorder(
  //                                     borderRadius: BorderRadius.circular(10),
  //                                     side: BorderSide(
  //                                         color: style.borderColor, width: 1),
  //                                   ),
  //                                   child: Stack(
  //                                     children: [
  //                                       if (!notification.isRead)
  //                                         const Positioned(
  //                                           top: 10,
  //                                           right: 10,
  //                                           child: CircleAvatar(
  //                                               radius: 4,
  //                                               backgroundColor: Colors.blue),
  //                                         ),
  //                                       Padding(
  //                                         padding: const EdgeInsets.all(12),
  //                                         child: Row(
  //                                           crossAxisAlignment:
  //                                               CrossAxisAlignment.start,
  //                                           children: [
  //                                             Container(
  //                                               width: 40,
  //                                               height: 40,
  //                                               decoration: BoxDecoration(
  //                                                 color: style.iconBgColor,
  //                                                 borderRadius:
  //                                                     BorderRadius.circular(10),
  //                                               ),
  //                                               child: Icon(style.icon,
  //                                                   color: style.iconColor,
  //                                                   size: 20),
  //                                             ),
  //                                             const SizedBox(width: 10),
  //                                             Expanded(
  //                                               child: Column(
  //                                                 crossAxisAlignment:
  //                                                     CrossAxisAlignment.start,
  //                                                 children: [
  //                                                   Text(
  //                                                     notification.message,
  //                                                     style: TextStyle(
  //                                                       fontSize: 13,
  //                                                       color: Colors.grey[800],
  //                                                       fontWeight: notification
  //                                                               .isRead
  //                                                           ? FontWeight.normal
  //                                                           : FontWeight.w600,
  //                                                       height: 1.3,
  //                                                     ),
  //                                                     maxLines: 3,
  //                                                     overflow:
  //                                                         TextOverflow.ellipsis,
  //                                                   ),
  //                                                   const SizedBox(height: 6),
  //                                                   Row(
  //                                                     children: [
  //                                                       Icon(Icons.access_time,
  //                                                           size: 12,
  //                                                           color: Colors
  //                                                               .grey[500]),
  //                                                       const SizedBox(
  //                                                           width: 3),
  //                                                       Text(
  //                                                         _formatTimeAgo(
  //                                                             notification
  //                                                                 .createAt),
  //                                                         style: TextStyle(
  //                                                             fontSize: 11,
  //                                                             color: Colors
  //                                                                 .grey[600]),
  //                                                       ),
  //                                                       const Spacer(),
  //                                                       if (notification
  //                                                                   .metadata?[
  //                                                               'overdue_days'] !=
  //                                                           null)
  //                                                         Container(
  //                                                           padding:
  //                                                               const EdgeInsets
  //                                                                   .symmetric(
  //                                                                   horizontal:
  //                                                                       6,
  //                                                                   vertical:
  //                                                                       2),
  //                                                           decoration:
  //                                                               BoxDecoration(
  //                                                             color: Colors
  //                                                                 .red[100],
  //                                                             borderRadius:
  //                                                                 BorderRadius
  //                                                                     .circular(
  //                                                                         8),
  //                                                           ),
  //                                                           child: Text(
  //                                                             'Quá ${notification.metadata!['overdue_days']}d',
  //                                                             style: TextStyle(
  //                                                                 color: Colors
  //                                                                     .red[700],
  //                                                                 fontSize: 10,
  //                                                                 fontWeight:
  //                                                                     FontWeight
  //                                                                         .w600),
  //                                                           ),
  //                                                         ),
  //                                                     ],
  //                                                   ),
  //                                                 ],
  //                                               ),
  //                                             ),
  //                                           ],
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ),
  //                               );
  //                             },
  //                           ),
  //                           if (provider.isLoading)
  //                             Container(
  //                               color: Colors.black.withOpacity(0.05),
  //                               child: const Center(
  //                                   child: CircularProgressIndicator()),
  //                             ),
  //                         ],
  //                       ),
  //                     ),
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //   );
  // }
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
