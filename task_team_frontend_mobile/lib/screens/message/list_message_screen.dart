import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/conversation_model.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/conversation_provider.dart';
import 'package:task_team_frontend_mobile/providers/employee_provider.dart';
import 'package:task_team_frontend_mobile/screens/message/message_screen.dart';
import 'package:intl/intl.dart';
import 'package:task_team_frontend_mobile/utils/time_helper.dart';

class ListMessageScreen extends StatefulWidget {
  const ListMessageScreen({super.key});

  @override
  State<ListMessageScreen> createState() => _ListMessageScreenState();
}

String _getFullImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) return '';
  final path = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
  return '${ApiConfig.getUrl}/api/$path';
}

class _ListMessageScreenState extends State<ListMessageScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isScreenVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _isScreenVisible = true;
      // Reload conversations khi quay lại app
      _loadConversations();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isScreenVisible = false;
    }
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.token == null) {
      debugPrint('⚠️ No token available, skipping conversation load');
      return;
    }

    final conversationProvider = context.read<ConversationProvider>();
    await conversationProvider.loadConversations(refresh: true);
  }

  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _NewChatBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm cuộc trò chuyện...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text('Tin nhắn'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<ConversationProvider>(
        builder: (context, conversationProvider, child) {
          if (conversationProvider.isLoading &&
              conversationProvider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (conversationProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    conversationProvider.error!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadConversations,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final conversations =
              conversationProvider.conversations.where((conv) {
            if (_searchQuery.isEmpty) return true;
            return conv.name.toLowerCase().contains(_searchQuery) ||
                conv.otherEmployee?.employeeName
                        .toLowerCase()
                        .contains(_searchQuery) ==
                    true;
          }).toList();

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Chưa có cuộc trò chuyện nào'
                        : 'Không tìm thấy cuộc trò chuyện',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showNewChatDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Bắt đầu chat mới'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadConversations,
            child: Column(
              children: [
                // THÊM: Unread count badge với animation
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: conversationProvider.totalUnreadCount > 0
                      ? Container(
                          key: ValueKey(conversationProvider.totalUnreadCount),
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[400]!, Colors.blue[600]!],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${conversationProvider.totalUnreadCount}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'tin nhắn chưa đọc',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                Expanded(
                  child: ListView.separated(
                    itemCount: conversations.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return _ConversationTile(
                        conversation: conversation,
                        onTap: () async {
                          // Navigate to message screen
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessageScreen(
                                conversation: conversation,
                              ),
                            ),
                          );

                          // Reload conversations khi quay lại
                          if (mounted) {
                            await _loadConversations();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }
}

// Conversation Tile Widget
class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  String _formatTime(DateTime dateTime) {
    final dt = TimeUtils.toVietnamTime(dateTime);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final inputDate = DateTime(dt.year, dt.month, dt.day);

    if (inputDate == today) {
      return DateFormat('HH:mm', 'vi_VN').format(dt);
    } else if (inputDate == yesterday) {
      return 'Hôm qua';
    } else if (now.difference(dt).inDays < 7) {
      return DateFormat('EEEE', 'vi_VN').format(dt);
    } else {
      return DateFormat('dd/MM/yyyy', 'vi_VN').format(dt);
    }
  }

  String _getDisplayName() {
    if (conversation.type == 'private') {
      return conversation.otherEmployee?.employeeName ?? 'Unknown';
    }
    return conversation.name;
  }

  String _getLastMessagePreview() {
    if (conversation.lastMessage == null) {
      return 'Chưa có tin nhắn';
    }

    final message = conversation.lastMessage!;
    if (message.type == 'image') return '📷 Hình ảnh';
    if (message.type == 'file') return '📎 File đính kèm';

    return message.content;
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = (conversation.unreadCountForEmployee) > 0;

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue[100],
            backgroundImage: conversation.type == 'private' &&
                    conversation.otherEmployee?.image != null
                ? NetworkImage(
                    _getFullImageUrl(conversation.otherEmployee!.image!))
                : null,
            child: conversation.type == 'private' &&
                    conversation.otherEmployee?.image == null
                ? Text(
                    _getDisplayName()[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  )
                : conversation.type == 'group'
                    ? const Icon(Icons.group, size: 28)
                    : conversation.type == 'task'
                        ? const Icon(Icons.work, size: 28)
                        : null,
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  conversation.unreadCountForEmployee > 99
                      ? '99+'
                      : conversation.unreadCountForEmployee.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _getDisplayName(),
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.type == 'task')
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Task',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        _getLastMessagePreview(),
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
          color: hasUnread ? Colors.black87 : Colors.grey[600],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatTime(conversation.lastMessageAt),
        style: TextStyle(
          fontSize: 12,
          color: hasUnread ? Colors.blue : Colors.grey[600],
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// Bottom Sheet for New Chat
class _NewChatBottomSheet extends StatefulWidget {
  const _NewChatBottomSheet();

  @override
  State<_NewChatBottomSheet> createState() => _NewChatBottomSheetState();
}

class _NewChatBottomSheetState extends State<_NewChatBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedEmployees = {};
  bool _isGroupChat = false;
  final TextEditingController _groupNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      context
          .read<EmployeeProvider>()
          .getAllEmployee(token: authProvider.token!);
    });
  }

  void _createChat() async {
    final authProvider = context.read<AuthProvider>();
    final conversationProvider = context.read<ConversationProvider>();

    if (_selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một người')),
      );
      return;
    }

    if (_isGroupChat && _groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên nhóm')),
      );
      return;
    }

    final conversation = await conversationProvider.createConversation(
      type: _isGroupChat ? 'group' : 'private',
      name: _isGroupChat ? _groupNameController.text.trim() : null,
      participants: _selectedEmployees.toList(),
    );

    if (!mounted) return;

    if (conversation != null) {
      Navigator.pop(context);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageScreen(conversation: conversation),
        ),
      );

      if (mounted) {
        final listContext = context;
        listContext
            .findAncestorStateOfType<_ListMessageScreenState>()
            ?._loadConversations();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(conversationProvider.error ?? 'Không thể tạo chat'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentEmployeeId = authProvider.currentEmployee?.employeeId;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Bắt đầu chat mới',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _createChat,
                        child: const Text('Tạo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm nhân viên...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Tạo nhóm chat'),
                    value: _isGroupChat,
                    onChanged: (value) {
                      setState(() {
                        _isGroupChat = value;
                        if (!value) {
                          if (_selectedEmployees.length > 1) {
                            _selectedEmployees.clear();
                          }
                        }
                      });
                    },
                  ),
                  if (_isGroupChat) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _groupNameController,
                      decoration: InputDecoration(
                        hintText: 'Tên nhóm',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_selectedEmployees.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  children: _selectedEmployees.map((id) {
                    final employee = context
                        .read<EmployeeProvider>()
                        .employees
                        .firstWhere((e) => e.employeeId == id);
                    return Chip(
                      avatar: CircleAvatar(
                        child: Text(employee.employeeName[0]),
                      ),
                      label: Text(employee.employeeName),
                      onDeleted: () {
                        setState(() {
                          _selectedEmployees.remove(id);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            Expanded(
              child: Consumer<EmployeeProvider>(
                builder: (context, employeeProvider, child) {
                  if (employeeProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final employees = employeeProvider.employees
                      .where((emp) =>
                          emp.employeeId != currentEmployeeId &&
                          emp.employeeName.toLowerCase().contains(_searchQuery))
                      .toList();

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      final isSelected =
                          _selectedEmployees.contains(employee.employeeId);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              if (!_isGroupChat &&
                                  _selectedEmployees.isNotEmpty) {
                                _selectedEmployees.clear();
                              }
                              _selectedEmployees.add(employee.employeeId);
                            } else {
                              _selectedEmployees.remove(employee.employeeId);
                            }
                          });
                        },
                        title: Text(employee.employeeName),
                        subtitle: Text(employee.email!),
                        secondary: CircleAvatar(
                          backgroundImage: employee.image != null
                              ? NetworkImage(_getFullImageUrl(employee.image!))
                              : null,
                          child: employee.image == null
                              ? Text(employee.employeeName[0])
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }
}
