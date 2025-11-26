const ConversationService = require("../services/conversation.service");
const Task = require("../models/task.model");
const { getIO } = require("../sockets/socket");

// ===================== TASK CONVERSATION ENDPOINTS =====================

/**
 * Lấy tất cả conversations của một task
 * GET /api/tasks/:taskId/conversations
 */
exports.getTaskConversations = async (req, res) => {
  try {
    const { task_id } = req.params;
    const employee_id = req.employee.employee_id;
    const role_id = req.employee.role_id;

    const conversationService = new ConversationService();
    const conversations = await conversationService.getTaskConversations(
      task_id,
      employee_id,
      role_id
    );

    res.json({
      success: true,
      data: conversations,
    });
  } catch (error) {
    console.error("Error in getTaskConversations:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Tạo conversation mới trong task (group hoặc private)
 * POST /api/tasks/:taskId/conversations
 * Body: { name: "Group Name", participants: ["emp1", "emp2"], type: "group" | "private" }
 */
exports.createTaskConversation = async (req, res) => {
  try {
    const { task_id } = req.params;
    const { name, participants, type } = req.body;
    const created_by = req.employee.employee_id;
    const isAdminOrManager = ["admin", "manager"].includes(
      req.employee.role_id
    );

    if (!participants || !Array.isArray(participants)) {
      return res.status(400).json({
        success: false,
        message: "Thiếu thông tin participants (phải là array)",
      });
    }

    const conversationService = new ConversationService();
    const conversation = await conversationService.createTaskConversation({
      created_by,
      task_id: task_id,
      name,
      participants,
      type: type || "group",
      isAdminOrManager, // Truyền quyền admin/manager
    });

    // Thông báo qua socket
    const io = getIO();
    conversation.participants.forEach((participant) => {
      io.to(participant.employee_id).emit("new_task_conversation", {
        task_id,
        conversation,
      });
    });

    res.status(201).json({
      success: true,
      data: conversation,
    });
  } catch (error) {
    console.error("Error in createTaskConversation:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 400).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Admin/Manager tham gia vào conversation của task
 * POST /api/tasks/:taskId/conversations/:conversationId/join
 */
exports.joinTaskConversation = async (req, res) => {
  try {
    const { conversation_id } = req.params;
    const employee_id = req.employee.employee_id;
    const role_id = req.employee.role_id;

    const conversationService = new ConversationService();
    const result = await conversationService.joinTaskConversation(
      conversation_id,
      employee_id,
      role_id
    );

    // Thông báo qua socket
    const io = getIO();
    io.to(conversation_id).emit("participant_joined", {
      conversation_id,
      joinedParticipant: employee_id,
    });

    res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error("Error in joinTaskConversation:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 400).json({
      success: false,
      message: error.message,
    });
  }
};

// ===================== GENERAL CONVERSATION ENDPOINTS =====================

/**
 * Tạo conversation mới (private hoặc group) - không liên quan task
 * POST /api/conversations
 */
exports.createConversation = async (req, res) => {
  try {
    const { type, name, participants } = req.body;
    const created_by = req.employee.employee_id;

    if (!participants || !Array.isArray(participants)) {
      return res.status(400).json({
        success: false,
        message: "Thiếu thông tin participants (phải là array)",
      });
    }

    const conversationService = new ConversationService();
    const conversation = await conversationService.createConversation({
      created_by,
      type: type || "private",
      name,
      participants,
    });

    // Thông báo qua socket
    const io = getIO();
    conversation.participants.forEach((participant) => {
      io.to(participant.employee_id).emit("new_conversation", conversation);
    });

    res.status(201).json({
      success: true,
      data: conversation,
    });
  } catch (error) {
    console.error("Error in createConversation:", error);
    res.status(400).json({
      success: false,
      message: error.message || "Lỗi khi tạo cuộc trò chuyện",
    });
  }
};

/**
 * Lấy danh sách conversations
 * GET /api/conversations
 */
exports.getConversations = async (req, res) => {
  try {
    const employee_id = req.employee.employee_id;
    const { page = 1, limit = 20, type } = req.query;

    const conversationService = new ConversationService();
    const result = await conversationService.getConversations(employee_id, {
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      type,
    });

    res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error("Error in getConversations:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Lỗi khi lấy danh sách cuộc trò chuyện",
    });
  }
};

/**
 * Lấy chi tiết conversation
 * GET /api/conversations/:conversationId
 */
exports.getConversationDetails = async (req, res) => {
  try {
    const { conversation_id } = req.params;
    const employee_id = req.employee.employee_id;

    const conversationService = new ConversationService();
    const conversation = await conversationService.getConversationDetails(
      conversation_id,
      employee_id
    );

    res.status(200).json({
      success: true,
      data: conversation,
    });
  } catch (error) {
    console.error("Error in getConversationDetails:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 404).json({
      success: false,
      message: error.message || "Lỗi khi lấy thông tin cuộc trò chuyện",
    });
  }
};

/**
 * Cập nhật thông tin conversation
 * PUT /api/conversations/:conversationId
 */
exports.updateConversation = async (req, res) => {
  try {
    const { conversation_id } = req.params;
    const employee_id = req.employee.employee_id;
    const { name } = req.body;

    if (!name) {
      return res.status(400).json({
        success: false,
        message: "Thiếu thông tin name",
      });
    }

    const conversationService = new ConversationService();
    const conversation = await conversationService.updateConversation(
      conversation_id,
      employee_id,
      { name }
    );

    // Thông báo qua socket
    const io = getIO();
    io.to(conversation_id).emit("conversation_updated", {
      conversation_id,
      name,
      updatedBy: employee_id,
    });

    res.status(200).json({
      success: true,
      data: conversation,
    });
  } catch (error) {
    console.error("Error in updateConversation:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 400).json({
      success: false,
      message: error.message || "Lỗi khi cập nhật cuộc trò chuyện",
    });
  }
};

/**
 * Thêm participants
 * POST /api/conversations/:conversationId/participants
 */
exports.addParticipants = async (req, res) => {
  try {
    const { conversation_id } = req.params;
    const employee_id = req.employee.employee_id;
    const { participants } = req.body;

    if (!participants || !Array.isArray(participants)) {
      return res.status(400).json({
        success: false,
        message: "Thiếu thông tin participants (phải là array)",
      });
    }

    const conversationService = new ConversationService();
    const result = await conversationService.addParticipants(
      conversation_id,
      employee_id,
      participants
    );

    // Thông báo qua socket
    const io = getIO();
    io.to(conversation_id).emit("participants_added", {
      conversation_id,
      addedParticipants: result.addedParticipants,
      addedBy: employee_id,
    });

    // Thông báo cho người mới được thêm
    result.addedParticipants.forEach((participantId) => {
      io.to(participantId).emit("added_to_conversation", {
        conversation_id,
        addedBy: employee_id,
      });
    });

    res.status(200).json({
      success: true,
      message: `Đã thêm ${result.count} thành viên`,
      data: result,
    });
  } catch (error) {
    console.error("Error in addParticipants:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 400).json({
      success: false,
      message: error.message || "Lỗi khi thêm thành viên",
    });
  }
};

/**
 * Xóa participant
 * DELETE /api/conversations/:conversationId/participants/:participantId
 */
exports.removeParticipant = async (req, res) => {
  try {
    const { conversation_id, participant_id } = req.params;
    const employee_id = req.employee.employee_id;

    const conversationService = new ConversationService();
    const result = await conversationService.removeParticipant(
      conversation_id,
      employee_id,
      participant_id
    );

    // Thông báo qua socket
    const io = getIO();
    io.to(conversation_id).emit("participant_removed", {
      conversation_id,
      removedParticipant: participant_id,
      removedBy: employee_id,
    });

    // Thông báo cho người bị xóa
    io.to(participant_id).emit("removed_from_conversation", {
      conversation_id,
      removedBy: employee_id,
    });

    res.status(200).json({
      success: true,
      message: "Đã xóa thành viên",
      data: result,
    });
  } catch (error) {
    console.error("Error in removeParticipant:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 400).json({
      success: false,
      message: error.message || "Lỗi khi xóa thành viên",
    });
  }
};

/**
 * Rời khỏi conversation
 * POST /api/conversations/:conversationId/leave
 */
exports.leaveConversation = async (req, res) => {
  try {
    const { conversation_id } = req.params;
    const employee_id = req.employee.employee_id;

    const conversationService = new ConversationService();
    const result = await conversationService.leaveConversation(
      conversation_id,
      employee_id
    );

    // Thông báo qua socket
    const io = getIO();
    io.to(conversation_id).emit("participant_left", {
      conversation_id,
      leftParticipant: employee_id,
    });

    res.status(200).json({
      success: true,
      message: "Đã rời khỏi cuộc trò chuyện",
      data: result,
    });
  } catch (error) {
    console.error("Error in leaveConversation:", error);
    res.status(400).json({
      success: false,
      message: error.message || "Lỗi khi rời cuộc trò chuyện",
    });
  }
};

/**
 * Xóa conversation
 * DELETE /api/conversations/:conversationId
 */
exports.deleteConversation = async (req, res) => {
  try {
    const { conversation_id } = req.params;
    const employee_id = req.employee.employee_id;

    const conversationService = new ConversationService();
    const result = await conversationService.deleteConversation(
      conversation_id,
      employee_id
    );

    // Thông báo qua socket
    const io = getIO();
    io.to(conversation_id).emit("conversation_deleted", {
      conversation_id,
      deletedBy: employee_id,
    });

    res.status(200).json({
      success: true,
      message: "Đã xóa cuộc trò chuyện",
      data: result,
    });
  } catch (error) {
    console.error("Error in deleteConversation:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 400).json({
      success: false,
      message: error.message || "Lỗi khi xóa cuộc trò chuyện",
    });
  }
};

/**
 * Lấy tổng số tin nhắn chưa đọc
 * GET /api/conversations/unread/total
 */
exports.getTotalUnreadCount = async (req, res) => {
  try {
    const employee_id = req.employee.employee_id;

    const conversationService = new ConversationService();
    const totalUnread = await conversationService.getTotalUnreadCount(
      employee_id
    );

    res.status(200).json({
      success: true,
      data: {
        totalUnreadCount: totalUnread,
      },
    });
  } catch (error) {
    console.error("Error in getTotalUnreadCount:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Lỗi khi lấy tổng số tin nhắn chưa đọc",
    });
  }
};
