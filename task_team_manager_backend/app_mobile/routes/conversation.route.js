const express = require("express");
const router = express.Router();
const conversationController = require("../controllers/conversation.controller");
const { verifyToken } = require("../middlewares/auth.middleware");

// ===================== TASK CONVERSATION ROUTES =====================

/**
 * Lấy tất cả conversations của một task
 * GET /api/conversations/tasks/:taskId/conversations
 */
router.get(
  "/tasks/:task_id/conversations",
  verifyToken,
  conversationController.getTaskConversations
);

/**
 * Tạo conversation mới trong task (group hoặc private)
 * POST /api/conversations/tasks/:taskId/conversations
 * Body: { name: "Group Name", participants: ["emp1", "emp2"], type: "group" | "private" }
 */
router.post(
  "/tasks/:task_id/conversations",
  verifyToken,
  conversationController.createTaskConversation
);

/**
 * Admin/Manager tham gia vào conversation của task
 * POST /api/conversations/tasks/:taskId/conversations/:conversationId/join
 */
router.post(
  "/tasks/:task_id/conversations/:conversation_id/join",
  verifyToken,
  conversationController.joinTaskConversation
);

// ===================== GENERAL CONVERSATION ROUTES =====================

/**
 * Lấy tổng số tin nhắn chưa đọc (phải đặt trước :conversationId)
 * GET /api/conversations/unread/total
 */
router.get(
  "/unread/total",
  verifyToken,
  conversationController.getTotalUnreadCount
);

/**
 * Tạo conversation mới (private hoặc group) - không liên quan task
 * POST /api/conversations
 */
router.post("/", verifyToken, conversationController.createConversation);

/**
 * Lấy danh sách conversations
 * GET /api/conversations
 */
router.get("/", verifyToken, conversationController.getConversations);

/**
 * Lấy chi tiết conversation
 * GET /api/conversations/:conversationId
 */
router.get(
  "/:conversation_id",
  verifyToken,
  conversationController.getConversationDetails
);

/**
 * Cập nhật thông tin conversation
 * PUT /api/conversations/:conversationId
 */
router.put(
  "/:conversation_id",
  verifyToken,
  conversationController.updateConversation
);

/**
 * Xóa conversation
 * DELETE /api/conversations/:conversationId
 */
router.delete(
  "/:conversation_id",
  verifyToken,
  conversationController.deleteConversation
);

/**
 * Thêm participants vào conversation
 * POST /api/conversations/:conversationId/participants
 */
router.post(
  "/:conversation_id/participants",
  verifyToken,
  conversationController.addParticipants
);

/**
 * Xóa participant khỏi conversation
 * DELETE /api/conversations/:conversationId/participants/:participantId
 */
router.delete(
  "/:conversation_id/participants/:participant_id",
  verifyToken,
  conversationController.removeParticipant
);

/**
 * Rời khỏi conversation
 * POST /api/conversations/:conversationId/leave
 */
router.post(
  "/:conversation_id/leave",
  verifyToken,
  conversationController.leaveConversation
);

module.exports = router;
