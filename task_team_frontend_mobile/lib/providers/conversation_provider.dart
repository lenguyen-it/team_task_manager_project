import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:task_team_frontend_mobile/models/conversation_model.dart';
import 'package:task_team_frontend_mobile/models/message_model.dart';
import 'package:task_team_frontend_mobile/services/conversation_service.dart';

class ConversationProvider with ChangeNotifier {
  final ConversationService _conversationService = ConversationService();

  IO.Socket? socket;
  late String currentEmployeeId;
  late String token;

  List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  ConversationModel? _currentConversation;
  ConversationModel? get currentConversation => _currentConversation;

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

  int _totalUnreadCount = 0;
  int get totalUnreadCount => _totalUnreadCount;

  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;

  final Map<String, List<ConversationModel>> _taskConversations = {};
  Map<String, List<ConversationModel>> get taskConversations =>
      _taskConversations;

  bool _socketListenersSetup = false;

  ConversationProvider({
    required this.currentEmployeeId,
    required this.token,
    this.socket,
  }) {
    _initializeSocket();
  }

  void setActiveConversation(String? conversationId) {
    _activeConversationId = conversationId;
    debugPrint('🎯 Active conversation set to: $conversationId');
  }

  // ===================== SOCKET INITIALIZATION =====================

  void _initializeSocket() {
    if (socket != null && !_socketListenersSetup) {
      _setupSocketListeners();
      _socketListenersSetup = true;
    }
  }

  void _setupSocketListeners() {
    if (socket == null) return;

    socket!.on('new_conversation', (data) {
      _handleNewConversation(data);
    });

    socket!.on('new_task_conversation', (data) {
      _handleNewTaskConversation(data);
    });

    socket!.on('conversation_updated', (data) {
      _handleConversationUpdated(data);
    });

    socket!.on('participants_added', (data) {
      _handleParticipantsAdded(data);
    });

    socket!.on('added_to_conversation', (data) {
      _handleAddedToConversation(data);
    });

    socket!.on('participant_removed', (data) {
      _handleParticipantRemoved(data);
    });

    socket!.on('removed_from_conversation', (data) {
      _handleRemovedFromConversation(data);
    });

    socket!.on('participant_left', (data) {
      _handleParticipantLeft(data);
    });

    socket!.on('participant_joined', (data) {
      _handleParticipantJoined(data);
    });

    socket!.on('conversation_deleted', (data) {
      _handleConversationDeleted(data);
    });

    socket!.on('new_message', (data) {
      _handleNewMessage(data);
    });

    socket!.on('all_messages_read', (data) {
      _handleAllMessagesRead(data);
    });

    debugPrint('✅ Socket listeners setup complete');
  }

  // ===================== LOAD CONVERSATIONS =====================

  Future<void> loadConversations({
    bool refresh = false,
    String? type,
  }) async {
    if (token.isEmpty) {
      debugPrint('⚠️ Cannot load conversations: No token');
      return;
    }

    if (refresh) {
      _currentPage = 1;
      _conversations.clear();
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint(
          '📡 Loading conversations: page=$_currentPage, token=${token.isNotEmpty}');

      final result = await _conversationService.getConversations(
        token,
        page: _currentPage,
        limit: 20,
        type: type,
      );

      final List<ConversationModel> newConversations = result['conversations'];
      final pagination = result['pagination'];

      if (refresh) {
        _conversations = newConversations;
      } else {
        _conversations.addAll(newConversations);
      }

      _currentPage = pagination['page'] ?? _currentPage;
      _totalPages = pagination['totalPages'] ?? 1;
      _totalCount = pagination['total'] ?? 0;
      _hasMore = _currentPage < _totalPages;

      debugPrint('✅ Loaded ${newConversations.length} conversations');

      // DEBUG: In ra unread count của từng conversation
      debugPrint('🔍 === DEBUG UNREAD COUNT ===');
      for (var conv in _conversations) {
        debugPrint(
            '  Conv: ${conv.conversationId}, unreadCountForEmployee: ${conv.unreadCountForEmployee}');
      }

      // TÍNH TỔNG unread count từ conversations
      final calculatedTotal = _conversations.fold<int>(
        0,
        (sum, conv) => sum + (conv.unreadCountForEmployee ?? 0),
      );
      debugPrint(
          '🔢 Calculated total unread from conversations: $calculatedTotal');

      // FIX: Sử dụng unread count tính từ conversations thay vì từ API
      if (calculatedTotal != _totalUnreadCount) {
        _totalUnreadCount = calculatedTotal;
        debugPrint(
            '📊 Total unread count updated from conversations: $_totalUnreadCount');
      }

      // Vẫn gọi API để so sánh
      await loadTotalUnreadCount();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error loading conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreConversations() async {
    if (!_hasMore || _isLoading) return;

    _currentPage++;
    await loadConversations(refresh: false);
  }

  Future<void> loadConversationDetails(String conversationId) async {
    try {
      _error = null;
      _currentConversation = await _conversationService.getConversationDetails(
        conversationId,
        token,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading conversation details: $e');
      notifyListeners();
    }
  }

  // ===================== CREATE & UPDATE CONVERSATIONS =====================

  Future<ConversationModel?> createConversation({
    required String type,
    String? name,
    required List<String> participants,
  }) async {
    try {
      _error = null;

      final conversation = await _conversationService.createConversation(
        token,
        type: type,
        name: name,
        participants: participants,
      );

      _conversations.insert(0, conversation);
      notifyListeners();

      return conversation;
    } catch (e) {
      _error = 'Không thể tạo cuộc trò chuyện: $e';
      debugPrint('Error creating conversation: $e');
      notifyListeners();
      return null;
    }
  }

  Future<void> updateConversation(
    String conversationId, {
    required String name,
  }) async {
    try {
      _error = null;

      final updatedConversation = await _conversationService.updateConversation(
        conversationId,
        token,
        name: name,
      );

      final index = _conversations.indexWhere(
        (c) => c.conversationId == conversationId,
      );
      if (index != -1) {
        _conversations[index] = updatedConversation;
      }

      if (_currentConversation?.conversationId == conversationId) {
        _currentConversation = updatedConversation;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Không thể cập nhật: $e';
      debugPrint('Error updating conversation: $e');
      notifyListeners();
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      _error = null;

      await _conversationService.deleteConversation(conversationId, token);

      _conversations.removeWhere((c) => c.conversationId == conversationId);

      if (_currentConversation?.conversationId == conversationId) {
        _currentConversation = null;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Không thể xóa: $e';
      debugPrint('Error deleting conversation: $e');
      notifyListeners();
    }
  }

  // ===================== MANAGE PARTICIPANTS =====================

  Future<void> addParticipants(
    String conversationId,
    List<String> participants,
  ) async {
    try {
      _error = null;

      await _conversationService.addParticipants(
        conversationId,
        token,
        participants,
      );

      await loadConversationDetails(conversationId);
    } catch (e) {
      _error = 'Không thể thêm thành viên: $e';
      debugPrint('Error adding participants: $e');
      notifyListeners();
    }
  }

  Future<void> removeParticipant(
    String conversationId,
    String participantId,
  ) async {
    try {
      _error = null;

      await _conversationService.removeParticipant(
        conversationId,
        participantId,
        token,
      );

      await loadConversationDetails(conversationId);
    } catch (e) {
      _error = 'Không thể xóa thành viên: $e';
      debugPrint('Error removing participant: $e');
      notifyListeners();
    }
  }

  Future<void> leaveConversation(String conversationId) async {
    try {
      _error = null;

      await _conversationService.leaveConversation(conversationId, token);

      _conversations.removeWhere((c) => c.conversationId == conversationId);

      if (_currentConversation?.conversationId == conversationId) {
        _currentConversation = null;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Không thể rời khỏi: $e';
      debugPrint('Error leaving conversation: $e');
      notifyListeners();
    }
  }

  // ===================== TASK CONVERSATIONS =====================

  Future<void> loadTaskConversations(String taskId) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final conversations = await _conversationService.getTaskConversations(
        taskId,
        token,
      );

      _taskConversations[taskId] = conversations;
    } catch (e) {
      _error = 'Không thể tải task conversations: $e';
      debugPrint('Error loading task conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ConversationModel?> createTaskConversation({
    required String taskId,
    required String type,
    String? name,
    required List<String> participants,
  }) async {
    try {
      _error = null;

      final conversation = await _conversationService.createTaskConversation(
        taskId,
        token,
        type: type,
        name: name,
        participants: participants,
      );

      if (_taskConversations.containsKey(taskId)) {
        _taskConversations[taskId]!.insert(0, conversation);
      } else {
        _taskConversations[taskId] = [conversation];
      }

      notifyListeners();
      return conversation;
    } catch (e) {
      _error = 'Không thể tạo task conversation: $e';
      debugPrint('Error creating task conversation: $e');
      notifyListeners();
      return null;
    }
  }

  Future<void> joinTaskConversation(
      String taskId, String conversationId) async {
    try {
      _error = null;

      await _conversationService.joinTaskConversation(
        taskId,
        conversationId,
        token,
      );

      await loadTaskConversations(taskId);
    } catch (e) {
      _error = 'Không thể tham gia: $e';
      debugPrint('Error joining task conversation: $e');
      notifyListeners();
    }
  }

  // ===================== UNREAD COUNT =====================

  Future<void> loadTotalUnreadCount() async {
    if (token.isEmpty) {
      debugPrint('⚠️ Cannot load unread count: No token');
      return;
    }

    try {
      final apiCount = await _conversationService.getTotalUnreadCount(token);

      debugPrint('🔍 === UNREAD COUNT COMPARISON ===');
      debugPrint('  API returned: $apiCount');
      debugPrint('  Current _totalUnreadCount: $_totalUnreadCount');

      // FIX: Ưu tiên sử dụng giá trị đã tính từ conversations
      // Chỉ cập nhật nếu API trả về giá trị lớn hơn
      if (apiCount > _totalUnreadCount) {
        _totalUnreadCount = apiCount;
        debugPrint('📊 Updated total unread from API: $_totalUnreadCount');
        notifyListeners();
      } else {
        debugPrint('✅ Keeping calculated value: $_totalUnreadCount');
      }
    } catch (e) {
      debugPrint('❌ Error loading total unread count: $e');
    }
  }

  void updateUnreadCount(String conversationId, int count) {
    final index = _conversations.indexWhere(
      (c) => c.conversationId == conversationId,
    );

    if (index != -1) {
      final oldCount = _conversations[index].unreadCountForEmployee;
      final difference = count - oldCount;

      _conversations[index].unreadCountForEmployee = count;

      _totalUnreadCount =
          (_totalUnreadCount + difference).clamp(0, double.infinity).toInt();

      debugPrint(
          '📊 Updated unread count for $conversationId: $oldCount -> $count, total: $_totalUnreadCount');
      notifyListeners();
    }
  }

  void resetUnreadCount(String conversationId) {
    final index = conversations.indexWhere(
      (c) => c.conversationId == conversationId,
    );

    if (index != -1) {
      final oldCount = conversations[index].unreadCountForEmployee;

      if (oldCount > 0) {
        conversations[index].unreadCountForEmployee = 0;

        _totalUnreadCount =
            (_totalUnreadCount - oldCount).clamp(0, double.infinity).toInt();

        debugPrint(
            '✅ Reset unread count for $conversationId: $oldCount -> 0, total: $_totalUnreadCount');
        notifyListeners();
      }
    }
  }

  // ===================== SOCKET EVENT HANDLERS =====================

  void _handleNewConversation(dynamic data) {
    try {
      final conversation = ConversationModel.fromJson(data);

      final exists = _conversations.any(
        (c) => c.conversationId == conversation.conversationId,
      );

      if (!exists) {
        _conversations.insert(0, conversation);
        debugPrint('✅ New conversation added: ${conversation.conversationId}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error handling new conversation: $e');
    }
  }

  void _handleNewTaskConversation(dynamic data) {
    try {
      final taskId = data['task_id'];
      final conversation = ConversationModel.fromJson(data['conversation']);

      if (_taskConversations.containsKey(taskId)) {
        _taskConversations[taskId]!.insert(0, conversation);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling new task conversation: $e');
    }
  }

  void _handleConversationUpdated(dynamic data) {
    try {
      final conversationId = data['conversation_id'];

      final index = _conversations.indexWhere(
        (c) => c.conversationId == conversationId,
      );

      if (index != -1) {
        loadConversationDetails(conversationId);
      }
    } catch (e) {
      debugPrint('Error handling conversation updated: $e');
    }
  }

  void _handleParticipantsAdded(dynamic data) {
    try {
      final conversationId = data['conversation_id'];
      loadConversationDetails(conversationId);
    } catch (e) {
      debugPrint('Error handling participants added: $e');
    }
  }

  void _handleAddedToConversation(dynamic data) {
    try {
      loadConversations(refresh: true);
    } catch (e) {
      debugPrint('Error handling added to conversation: $e');
    }
  }

  void _handleParticipantRemoved(dynamic data) {
    try {
      final conversationId = data['conversation_id'];
      loadConversationDetails(conversationId);
    } catch (e) {
      debugPrint('Error handling participant removed: $e');
    }
  }

  void _handleRemovedFromConversation(dynamic data) {
    try {
      final conversationId = data['conversation_id'];
      _conversations.removeWhere((c) => c.conversationId == conversationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling removed from conversation: $e');
    }
  }

  void _handleParticipantLeft(dynamic data) {
    try {
      final conversationId = data['conversation_id'];
      loadConversationDetails(conversationId);
    } catch (e) {
      debugPrint('Error handling participant left: $e');
    }
  }

  void _handleParticipantJoined(dynamic data) {
    try {
      final conversationId = data['conversation_id'];
      loadConversationDetails(conversationId);
    } catch (e) {
      debugPrint('Error handling participant joined: $e');
    }
  }

  void _handleConversationDeleted(dynamic data) {
    try {
      final conversationId = data['conversation_id'];
      _conversations.removeWhere((c) => c.conversationId == conversationId);

      if (_currentConversation?.conversationId == conversationId) {
        _currentConversation = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling conversation deleted: $e');
    }
  }

  void _handleNewMessage(dynamic data) {
    try {
      debugPrint('📩 Processing new_message...');
      debugPrint('🔍 Raw data: $data');

      final message = data['message'];
      final conversationId = message['conversation_id'];
      final senderId = message['sender_id'];

      debugPrint(
          '📬 New message: conv=$conversationId, sender=$senderId, current=$currentEmployeeId');

      final index = _conversations.indexWhere(
        (c) => c.conversationId == conversationId,
      );

      if (index != -1) {
        final conversation = _conversations[index];
        final newLastMessage = MessageModel.fromJson(message);

        final isFromOther = senderId != currentEmployeeId;
        final isNotActive = _activeConversationId != conversationId;
        final shouldIncreaseUnread = isFromOther && isNotActive;

        final currentUnread = conversation.unreadCountForEmployee;
        final newUnread =
            shouldIncreaseUnread ? currentUnread + 1 : currentUnread;

        debugPrint('📢 Unread calculation:');
        debugPrint('  - senderId: $senderId');
        debugPrint('  - currentEmployeeId: $currentEmployeeId');
        debugPrint('  - activeConversationId: $_activeConversationId');
        debugPrint('  - isFromOther: $isFromOther');
        debugPrint('  - isNotActive: $isNotActive');
        debugPrint('  - shouldIncrease: $shouldIncreaseUnread');
        debugPrint('  - current: $currentUnread → new: $newUnread');

        final updatedConversation = ConversationModel(
          conversationId: conversation.conversationId,
          name: conversation.name,
          taskId: conversation.taskId,
          type: conversation.type,
          createdBy: conversation.createdBy,
          isTaskDefault: conversation.isTaskDefault,
          lastMessageAt: newLastMessage.createdAt,
          unreadCount: conversation.unreadCount,
          participants: conversation.participants,
          lastMessage: newLastMessage,
          unreadCountForEmployee: newUnread,
          otherEmployee: conversation.otherEmployee,
        );

        _conversations.removeAt(index);
        _conversations.insert(0, updatedConversation);

        if (shouldIncreaseUnread) {
          _totalUnreadCount++;
          debugPrint(
              '📬 Badge updated: conv=$conversationId, unread=$newUnread, total=$_totalUnreadCount');
        } else {
          debugPrint('✅ Message in active conversation, no badge increase');
        }

        notifyListeners();
      } else {
        debugPrint('⚠️ Conversation $conversationId not found in list');
        loadConversations(refresh: true);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error handling new message: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _handleAllMessagesRead(dynamic data) {
    try {
      final conversationId = data['conversation_id'];
      final employeeId = data['employee_id'];

      debugPrint(
          '👁️ All messages read: conv=$conversationId, employee=$employeeId, current=$currentEmployeeId');

      if (employeeId == currentEmployeeId) {
        resetUnreadCount(conversationId);
        debugPrint('✅ Reset unread count for conversation $conversationId');
      }
    } catch (e) {
      debugPrint('❌ Error handling all messages read: $e');
    }
  }

  void updateLastMessage(String conversationId, MessageModel message) {
    final index = _conversations.indexWhere(
      (c) => c.conversationId == conversationId,
    );

    if (index != -1) {
      final conversation = _conversations[index];

      final updatedConversation = ConversationModel(
        conversationId: conversation.conversationId,
        name: conversation.name,
        taskId: conversation.taskId,
        type: conversation.type,
        createdBy: conversation.createdBy,
        isTaskDefault: conversation.isTaskDefault,
        lastMessageAt: message.createdAt,
        unreadCount: conversation.unreadCount,
        participants: conversation.participants,
        lastMessage: message,
        unreadCountForEmployee: conversation.unreadCountForEmployee,
        otherEmployee: conversation.otherEmployee,
      );

      _conversations.removeAt(index);
      _conversations.insert(0, updatedConversation);

      notifyListeners();
    }
  }

  // ===================== UTILITY METHODS =====================

  ConversationModel? findConversationById(String conversationId) {
    try {
      return _conversations.firstWhere(
        (c) => c.conversationId == conversationId,
      );
    } catch (e) {
      return null;
    }
  }

  ConversationModel? findPrivateConversationWithEmployee(String employeeId) {
    try {
      return _conversations.firstWhere(
        (c) =>
            c.type == 'private' &&
            c.participants.any((p) => p.employeeId == employeeId),
      );
    } catch (e) {
      return null;
    }
  }

  void updateSocket(IO.Socket newSocket) {
    debugPrint('🔄 Updating socket in ConversationProvider');

    if (socket != null) {
      socket!.off('new_conversation');
      socket!.off('new_task_conversation');
      socket!.off('conversation_updated');
      socket!.off('participants_added');
      socket!.off('added_to_conversation');
      socket!.off('participant_removed');
      socket!.off('removed_from_conversation');
      socket!.off('participant_left');
      socket!.off('participant_joined');
      socket!.off('conversation_deleted');
      socket!.off('new_message');
      socket!.off('all_messages_read');
    }

    socket = newSocket;
    _socketListenersSetup = false;
    _setupSocketListeners();

    notifyListeners();
  }

  void clearAll() {
    _conversations.clear();
    _taskConversations.clear();
    _currentConversation = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalCount = 0;
    _hasMore = true;
    _totalUnreadCount = 0;
    _activeConversationId = null;
    _error = null;
    _socketListenersSetup = false;
    notifyListeners();
  }

  @override
  void dispose() {
    socket?.dispose();
    super.dispose();
  }
}
