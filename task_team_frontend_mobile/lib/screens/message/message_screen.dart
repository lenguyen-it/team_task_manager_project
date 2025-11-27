import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/conversation_model.dart';
import 'package:task_team_frontend_mobile/models/message_model.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/conversation_provider.dart';
import 'package:task_team_frontend_mobile/providers/message_provider.dart';
import 'dart:async';

import 'package:task_team_frontend_mobile/utils/time_helper.dart';

class MessageScreen extends StatefulWidget {
  final ConversationModel conversation;

  const MessageScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

String _getFullImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) return '';
  final path = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
  return '${ApiConfig.getUrl}/api/$path';
}

class _MessageScreenState extends State<MessageScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  Timer? _scrollDebounce;
  bool _isTyping = false;
  bool _shouldScrollToBottom = true;
  bool _isScreenActive = true;

  MessageProvider? _messageProvider;
  ConversationProvider? _conversationProvider;

  Timer? _markAsReadDebounce;

  late final IO.Socket _socket;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageProvider = context.read<MessageProvider>();
      _conversationProvider = context.read<ConversationProvider>();

      // Đánh dấu conversation này là đang active
      _conversationProvider
          ?.setActiveConversation(widget.conversation.conversationId);

      _loadMessages();
      _markAllAsRead();

      _socket = context.read<IO.Socket>();
      if (_socket.connected) {
        _socket.emit('join_conversation', widget.conversation.conversationId);
        debugPrint(
            '🚪 Joined conversation: ${widget.conversation.conversationId}');
      }

      // Lắng nghe thay đổi messages để auto scroll và auto mark as read
      _messageProvider?.addListener(_onMessagesChanged);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _isScreenActive = true;
      // Khi quay lại app, mark all as read
      _markAllAsRead();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isScreenActive = false;
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      _shouldScrollToBottom = (maxScroll - currentScroll) < 100;

      if (currentScroll == 0) {
        _loadMoreMessages();
      }
    }
  }

  void _onMessagesChanged() {
    // Tự động scroll xuống khi có tin nhắn mới và user đang ở gần đáy
    if (_shouldScrollToBottom) {
      _scrollDebounce?.cancel();
      _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    }

    // QUAN TRỌNG: Mark as read khi có tin nhắn mới từ người khác
    if (_isScreenActive && mounted && _messageProvider != null) {
      final messages = _messageProvider!.messages;
      final currentUserId =
          context.read<AuthProvider>().currentEmployee?.employeeId;

      // Kiểm tra xem có tin nhắn mới từ người khác chưa đọc không
      final hasUnreadFromOthers = messages.any((msg) =>
          msg.senderId != currentUserId && msg.status != MessageStatus.seen);

      if (hasUnreadFromOthers) {
        // Debounce để tránh gọi API quá nhiều
        _markAsReadDebounce?.cancel();
        _markAsReadDebounce = Timer(const Duration(milliseconds: 500), () {
          _markAllAsRead();
        });
      }
    }
  }

  void _scrollToBottom({bool instant = false}) {
    if (!_scrollController.hasClients) return;

    if (instant) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    } else {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    if (!mounted || !_isScreenActive || _messageProvider == null) return;

    // Kiểm tra xem có tin nhắn chưa đọc không
    final messages = _messageProvider!.messages;
    final currentUserId =
        context.read<AuthProvider>().currentEmployee?.employeeId;

    final hasUnread = messages.any((msg) =>
        msg.senderId != currentUserId && msg.status != MessageStatus.seen);

    // Chỉ gọi API nếu thực sự có tin nhắn chưa đọc
    if (!hasUnread) {
      return;
    }

    debugPrint(
        '✅ Marking messages as read for: ${widget.conversation.conversationId}');

    try {
      await _messageProvider
          ?.markAllMessagesAsRead(widget.conversation.conversationId);

      // Socket sẽ tự động emit 'all_messages_read' event
      // ConversationProvider sẽ tự động reset unread count qua socket listener

      debugPrint('✅ Mark as read completed');
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
    }
  }

  Future<void> _loadMessages() async {
    final messageProvider = context.read<MessageProvider>();
    await messageProvider.loadMessages(
      widget.conversation.conversationId,
      refresh: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(instant: true);
    });
  }

  Future<void> _loadMoreMessages() async {
    final messageProvider = context.read<MessageProvider>();
    if (messageProvider.hasMore && !messageProvider.isLoading) {
      final previousHeight = _scrollController.position.maxScrollExtent;
      await messageProvider.loadMoreMessages();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newHeight = _scrollController.position.maxScrollExtent;
          final scrollDifference = newHeight - previousHeight;
          _scrollController.jumpTo(
            _scrollController.offset + scrollDifference,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final messageProvider = context.read<MessageProvider>();
    final conversationProvider = context.read<ConversationProvider>();

    messageProvider.sendMessage(
      conversationId: widget.conversation.conversationId,
      content: text,
      receiverId: widget.conversation.type == 'private'
          ? widget.conversation.otherEmployee?.employeeId
          : null,
    );

    _messageController.clear();
    _stopTyping();

    final tempMessage = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: context.read<AuthProvider>().currentEmployee!.employeeId,
      receiverId: widget.conversation.type == 'private'
          ? widget.conversation.otherEmployee?.employeeId
          : null,
      conversationId: widget.conversation.conversationId,
      content: text,
      status: MessageStatus.sent,
      type: 'text',
      isDeleted: false,
      seenBy: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    conversationProvider.updateLastMessage(
      widget.conversation.conversationId,
      tempMessage,
    );

    _shouldScrollToBottom = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _handleTyping() {
    final messageProvider = context.read<MessageProvider>();

    if (!_isTyping) {
      _isTyping = true;
      messageProvider.emitTyping(widget.conversation.conversationId);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      final messageProvider = context.read<MessageProvider>();
      messageProvider.emitStopTyping(widget.conversation.conversationId);
    }
  }

  String _getDisplayName() {
    if (widget.conversation.type == 'private') {
      return widget.conversation.otherEmployee?.employeeName ?? 'Unknown';
    }
    return widget.conversation.name;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentEmployeeId = authProvider.currentEmployee?.employeeId;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: widget.conversation.type == 'private' &&
                        widget.conversation.otherEmployee?.image != null
                    ? NetworkImage(_getFullImageUrl(
                        widget.conversation.otherEmployee!.image!))
                    : null,
                child: widget.conversation.type == 'private' &&
                        widget.conversation.otherEmployee?.image == null
                    ? Text(
                        _getDisplayName()[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      )
                    : widget.conversation.type == 'group'
                        ? const Icon(Icons.group, size: 28)
                        : widget.conversation.type == 'task'
                            ? const Icon(Icons.work, size: 28)
                            : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayName(),
                      style: const TextStyle(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Consumer<MessageProvider>(
                      builder: (context, messageProvider, child) {
                        if (messageProvider.typingUsers.isNotEmpty) {
                          return const Text(
                            'đang gõ...',
                            style: TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic),
                          );
                        }
                        if (widget.conversation.participants.isNotEmpty) {
                          return Text(
                            '${widget.conversation.participants.length} thành viên',
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showConversationInfo,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<MessageProvider>(
                builder: (context, messageProvider, child) {
                  if (messageProvider.isLoading &&
                      messageProvider.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (messageProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(messageProvider.error!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMessages,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = messageProvider.messages;

                  if (messages.isEmpty) {
                    return const Center(child: Text('Chưa có tin nhắn nào'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: false,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentEmployeeId;
                      final showDate = index == 0 ||
                          !_isSameDay(
                              message.createdAt, messages[index - 1].createdAt);

                      return Column(
                        children: [
                          if (showDate) _DateDivider(date: message.createdAt),
                          _MessageBubble(
                            message: message,
                            isMe: isMe,
                            showAvatar: widget.conversation.type != 'private',
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
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
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Chức năng đính kèm file đang phát triển'),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        onChanged: (_) => _handleTyping(),
                        onTap: () {
                          _shouldScrollToBottom = true;
                          Future.delayed(const Duration(milliseconds: 300), () {
                            _scrollToBottom();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showConversationInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ConversationInfoSheet(
        conversation: widget.conversation,
      ),
    );
  }

  @override
  void dispose() {
    // Hủy đăng ký observer
    WidgetsBinding.instance.removeObserver(this);

    // Clear active conversation
    _conversationProvider?.setActiveConversation(null);

    _messageProvider?.removeListener(_onMessagesChanged);

    _typingTimer?.cancel();
    _scrollDebounce?.cancel();
    _markAsReadDebounce?.cancel();

    _stopTyping();

    _messageProvider?.leaveConversation(widget.conversation.conversationId);

    _socket.emit('leave_conversation', widget.conversation.conversationId);

    _scrollController.removeListener(_onScroll);

    _scrollController.dispose();
    _messageController.dispose();

    super.dispose();
  }
}

// Message Bubble Widget
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.showAvatar = false,
  });

  String _formatTime(DateTime dateTime) {
    return TimeUtils.formatMessageTime(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              child: Text(message.senderId[0].toUpperCase()),
            ),
          if (!isMe && showAvatar) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && showAvatar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderId,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == MessageStatus.seen
                              ? Icons.done_all
                              : message.status == MessageStatus.delivered
                                  ? Icons.done_all
                                  : Icons.done,
                          size: 14,
                          color: message.status == MessageStatus.seen
                              ? Colors.blue[300]
                              : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe && showAvatar) const SizedBox(width: 8),
          if (isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              child: Text(message.senderId[0].toUpperCase()),
            ),
        ],
      ),
    );
  }
}

// Date Divider Widget
class _DateDivider extends StatelessWidget {
  final DateTime date;

  const _DateDivider({required this.date});

  _formatDate(DateTime dateTime) {
    return TimeUtils.formatDateDivider(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// Conversation Info Bottom Sheet
class _ConversationInfoSheet extends StatelessWidget {
  final ConversationModel conversation;

  const _ConversationInfoSheet({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.blue[100],
                backgroundImage: conversation.type == 'private' &&
                        conversation.otherEmployee?.image != null
                    ? NetworkImage(
                        _getFullImageUrl(conversation.otherEmployee!.image!))
                    : null,
                child: conversation.type == 'private' &&
                        conversation.otherEmployee?.image == null
                    ? Text(
                        conversation.otherEmployee?.employeeName[0]
                                .toUpperCase() ??
                            'U',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      )
                    : conversation.type == 'group'
                        ? const Icon(Icons.group, size: 28)
                        : conversation.type == 'task'
                            ? const Icon(Icons.work, size: 28)
                            : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.type == 'private'
                          ? conversation.otherEmployee?.employeeName ??
                              'Unknown'
                          : conversation.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${conversation.participants.length} thành viên',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Thành viên',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...conversation.participants.map((participant) {
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: participant.image != null
                    ? NetworkImage(_getFullImageUrl(participant.image!))
                    : null,
                child: participant.image == null
                    ? Text(participant.employeeName![0].toUpperCase())
                    : null,
              ),
              title: Text(participant.employeeId),
              subtitle: Text(participant.roleConversationId),
              trailing: participant.roleConversationId == 'owner'
                  ? Chip(
                      label: const Text('Trưởng nhóm',
                          style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.orange[100],
                    )
                  : null,
            );
          }),
          const SizedBox(height: 16),
          if (conversation.type == 'group' || conversation.type == 'task')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chức năng rời nhóm đang phát triển'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Rời nhóm'),
              ),
            ),
        ],
      ),
    );
  }
}
