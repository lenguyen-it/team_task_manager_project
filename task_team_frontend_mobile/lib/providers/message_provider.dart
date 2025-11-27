import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:task_team_frontend_mobile/models/message_model.dart';
import 'package:task_team_frontend_mobile/services/message_service.dart';

class MessageProvider with ChangeNotifier {
  final MessageService _messageService = MessageService();

  IO.Socket? socket;
  late String currentEmployeeId; // FIX: Changed from final to late
  late String token; // FIX: Changed from final to late

  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

  String? _currentConversationId;
  String? get currentConversationId => _currentConversationId;

  // Typing indicators
  final Map<String, bool> _typingUsers = {};
  Map<String, bool> get typingUsers => _typingUsers;

  final Function(MessageModel)? onMessageSent;

  // FIX: Track socket listeners
  bool _socketListenersSetup = false;

  MessageProvider({
    required this.currentEmployeeId,
    required this.token,
    this.socket,
    this.onMessageSent,
  }) {
    _initializeSocket();
  }

  void _initializeSocket() {
    if (socket != null && !_socketListenersSetup) {
      _setupSocketListeners();
      _socketListenersSetup = true;
    }
  }

  void _setupSocketListeners() {
    if (socket == null) return;

    socket!.on('new_message', (data) {
      _handleNewMessage(data);
    });

    socket!.on('message_read', (data) {
      _handleMessageRead(data);
    });

    socket!.on('all_messages_read', (data) {
      _handleAllMessagesRead(data);
    });

    socket!.on('message_deleted', (data) {
      _handleMessageDeleted(data);
    });

    socket!.on('typing', (data) {
      _handleEmployeeTyping(data);
    });

    socket!.on('stop_typing', (data) {
      _handleEmployeeStopTyping(data);
    });

    socket!.on('error', (data) {
      _error = data['message'] ?? 'Có lỗi xảy ra';
      notifyListeners();
    });

    debugPrint('✅ Message socket listeners setup complete');
  }

  Future<void> loadMessages(String conversationId,
      {bool refresh = false}) async {
    // FIX: Check token before loading
    if (token.isEmpty) {
      debugPrint('⚠️ Cannot load messages: No token');
      return;
    }

    if (refresh) {
      _currentPage = 1;
      _messages.clear();
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    _currentConversationId = conversationId;
    notifyListeners();

    try {
      final result = await _messageService.getMessages(
        conversationId,
        token,
        page: _currentPage,
        limit: 50,
      );

      final List<MessageModel> newMessages = result['messages'];
      final pagination = result['pagination'];

      if (refresh) {
        _messages = newMessages;
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else {
        final oldMessages = newMessages;
        oldMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _messages = [...oldMessages, ..._messages];
      }

      _currentPage = pagination['currentPage'] ?? _currentPage;
      _totalPages = pagination['totalPages'] ?? 1;
      _totalCount = pagination['totalCount'] ?? 0;
      _hasMore = _currentPage < _totalPages;

      _joinConversation(conversationId);
      await markAllMessagesAsRead(conversationId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMessages() async {
    if (_currentConversationId == null) return;

    _currentPage++;
    await loadMessages(_currentConversationId!, refresh: false);
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String? receiverId,
    String type = 'text',
  }) async {
    try {
      _error = null;

      // Tạo ID tạm duy nhất
      final tempId =
          'temp_${DateTime.now().millisecondsSinceEpoch}_${content.hashCode}';

      final tempMessage = MessageModel(
        id: tempId,
        senderId: currentEmployeeId,
        receiverId: receiverId,
        conversationId: conversationId,
        content: content,
        status: MessageStatus.sent,
        type: type,
        isDeleted: false,
        seenBy: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Thêm tin nhắn tạm
      _messages.add(tempMessage);
      notifyListeners();

      // Gửi qua socket
      if (socket != null && socket!.connected) {
        socket!.emit('send_message', {
          'conversation_id': conversationId,
          'content': content,
          'receiver_id': receiverId,
          'type': type,
          'temp_id': tempId,
        });

        // Thông báo cho ConversationProvider về tin nhắn mới
        onMessageSent?.call(tempMessage);
      } else {
        // Fallback: gửi qua HTTP
        final newMessage = await _messageService.createMessage(
          token,
          conversationId: conversationId,
          content: content,
          receiverId: receiverId,
          type: type,
        );

        // Thay thế tin nhắn tạm
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = newMessage;
          notifyListeners();
        }

        // Thông báo cho ConversationProvider
        onMessageSent?.call(newMessage);
      }
    } catch (e) {
      _error = 'Không thể gửi tin nhắn: $e';
      debugPrint('Error sending message: $e');

      // Xóa tin nhắn tạm khi lỗi
      _messages.removeWhere((m) => m.id.startsWith('temp_'));
      notifyListeners();
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _messageService.markAsRead(messageId, token);

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          status: MessageStatus.seen,
          seenBy: [
            ..._messages[index].seenBy,
            SeenBy(employeeId: currentEmployeeId, seenAt: DateTime.now()),
          ],
        );
        notifyListeners();
      }

      socket?.emit('mark_messages_read', {'id': messageId});
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  Future<void> markAllMessagesAsRead(String conversationId) async {
    try {
      await _messageService.markAllAsRead(conversationId, token);

      _messages = _messages.map((message) {
        if (message.senderId != currentEmployeeId) {
          return message.copyWith(
            status: MessageStatus.seen,
            seenBy: [
              ...message.seenBy,
              if (!message.seenBy.any((s) => s.employeeId == currentEmployeeId))
                SeenBy(employeeId: currentEmployeeId, seenAt: DateTime.now()),
            ],
          );
        }
        return message;
      }).toList();

      _unreadCount = 0;
      notifyListeners();

      socket?.emit('mark_messages_read', {'conversation_id': conversationId});
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(messageId, token);

      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();

      socket?.emit('delete_message', {'id': messageId});
    } catch (e) {
      _error = 'Không thể xóa tin nhắn: $e';
      debugPrint('Error deleting message: $e');
      notifyListeners();
    }
  }

  Future<void> searchMessages(String conversationId, String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _messageService.searchMessages(
        conversationId,
        token,
        query,
      );

      _messages = result['messages'];
      final pagination = result['pagination'];

      _currentPage = pagination['currentPage'] ?? 1;
      _totalPages = pagination['totalPages'] ?? 1;
      _totalCount = pagination['totalCount'] ?? 0;
    } catch (e) {
      _error = 'Không thể tìm kiếm: $e';
      debugPrint('Error searching messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount(String conversationId) async {
    try {
      _unreadCount =
          await _messageService.getUnreadCount(conversationId, token);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<Map<String, dynamic>?> uploadFile(String filePath) async {
    try {
      final result = await _messageService.uploadFile(filePath, token);
      return result;
    } catch (e) {
      _error = 'Không thể upload file: $e';
      debugPrint('Error uploading file: $e');
      notifyListeners();
      return null;
    }
  }

  void _joinConversation(String conversationId) {
    socket?.emit('join_conversation', {
      'conversation_id': conversationId,
      'employee_id': currentEmployeeId,
    });
  }

  void leaveConversation(String conversationId) {
    socket?.emit('leave_conversation', {
      'conversation_id': conversationId,
      'employee_id': currentEmployeeId,
    });
    _currentConversationId = null;
  }

  void emitTyping(String conversationId) {
    socket?.emit('typing', {
      'conversation_id': conversationId,
      'employee_id': currentEmployeeId,
    });
  }

  void emitStopTyping(String conversationId) {
    socket?.emit('stop_typing', {
      'conversation_id': conversationId,
      'employee_id': currentEmployeeId,
    });
  }

  // FIX: Cải thiện xử lý tin nhắn mới từ socket
  void _handleNewMessage(dynamic data) {
    try {
      final message = MessageModel.fromJson(data['message']);
      final tempId = data['temp_id']; // Nhận temp_id từ server

      // Chỉ xử lý nếu là conversation hiện tại
      if (message.conversationId != _currentConversationId) return;

      // Nếu có temp_id, thay thế tin nhắn tạm
      if (tempId != null) {
        final tempIndex = _messages.indexWhere((m) => m.id == tempId);
        if (tempIndex != -1) {
          _messages[tempIndex] = message;
          notifyListeners();
          return;
        }
      }

      // Kiểm tra tin nhắn đã tồn tại chưa (tránh duplicate)
      final existingIndex = _messages.indexWhere((m) => m.id == message.id);

      if (existingIndex == -1) {
        // Tin nhắn mới chưa có trong danh sách
        _messages.add(message);

        // Tăng unread count nếu không phải tin nhắn của mình
        if (message.senderId != currentEmployeeId) {
          _unreadCount++;
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  void _handleMessageRead(dynamic data) {
    try {
      final messageId = data['id'] ?? data['messageId'];
      final employeeId = data['employee_id'];
      final seenAt = DateTime.parse(data['seen_at'] ?? data['seenAt']);

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final message = _messages[index];
        final updatedSeenBy = List<SeenBy>.from(message.seenBy);

        if (!updatedSeenBy.any((s) => s.employeeId == employeeId)) {
          updatedSeenBy.add(SeenBy(employeeId: employeeId, seenAt: seenAt));
        }

        _messages[index] = message.copyWith(
          status: MessageStatus.seen,
          seenBy: updatedSeenBy,
        );

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling message read: $e');
    }
  }

  void _handleAllMessagesRead(dynamic data) {
    try {
      final conversationId = data['conversation_id'];
      final employeeId = data['employee_id'];

      if (conversationId == _currentConversationId &&
          employeeId != currentEmployeeId) {
        bool hasChanged = false;

        _messages = _messages.map((message) {
          if (message.senderId == currentEmployeeId &&
              message.status != MessageStatus.seen) {
            hasChanged = true;
            return message.copyWith(status: MessageStatus.seen);
          }
          return message;
        }).toList();

        if (hasChanged) {
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error handling all messages read: $e');
    }
  }

  void _handleMessageDeleted(dynamic data) {
    try {
      final messageId = data['message_id'];
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling message deleted: $e');
    }
  }

  void _handleEmployeeTyping(dynamic data) {
    final employeeId = data['employee_id'];
    final conversationId = data['conversation_id'];

    if (conversationId == _currentConversationId &&
        employeeId != currentEmployeeId) {
      debugPrint('Employee $employeeId is typing...');
    }
  }

  void _handleEmployeeStopTyping(dynamic data) {
    final employeeId = data['employee_id'];
    final conversationId = data['conversation_id'];

    if (conversationId == _currentConversationId &&
        employeeId != currentEmployeeId) {
      debugPrint('Employee $employeeId stopped typing');
    }
  }

  // Thêm method này vào MessageProvider class

  void updateSocket(IO.Socket newSocket) {
    debugPrint('🔄 Updating socket in MessageProvider');

    // Dispose old socket listeners if exists
    if (socket != null) {
      socket!.off('new_message');
      socket!.off('message_read');
      socket!.off('all_messages_read');
      socket!.off('message_deleted');
      socket!.off('typing');
      socket!.off('stop_typing');
      socket!.off('error');
    }

    // Update socket
    socket = newSocket;

    // Reset listener flag và setup lại
    _socketListenersSetup = false;
    _setupSocketListeners();

    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _currentPage = 1;
    _totalPages = 1;
    _totalCount = 0;
    _hasMore = true;
    _unreadCount = 0;
    _error = null;
    _socketListenersSetup = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_currentConversationId != null) {
      leaveConversation(_currentConversationId!);
    }
    socket?.dispose();
    super.dispose();
  }
}
