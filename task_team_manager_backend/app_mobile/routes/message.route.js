const express = require("express");
const router = express.Router();
const messageController = require("../controllers/message.controller");
const { verifyToken } = require("../middlewares/auth.middleware");
const { uploadFile } = require("../middlewares/upload.middleware");

// Tất cả routes đều cần authentication
router.use(verifyToken);

// Tạo tin nhắn mới (backup cho socket)
router.post("/", messageController.createMessage);

// Lấy danh sách tin nhắn theo đoạn chat
router.get("/conversation/:conversation_id", messageController.getMessages);

// Đánh dấu tin nhắn đã đọc
router.put("/:message_id/read", messageController.markMessageAsRead);

// Đánh dấu tất cả đã đọc
router.put(
  "/:conversation_id/readall",
  messageController.markAllMessagesAsRead
);

// Xóa tin nhắn
router.delete("/:message_id", messageController.deleteMessage);

// Tìm kiếm tin nhắn
router.get("/:conversation_id/search", messageController.searchMessages);

// Lấy số tin nhắn chưa đọc
router.get("/:conversation_id/unreadcount", messageController.getUnreadCount);

// Upload file đính kèm
router.post(
  "/upload",
  uploadFile.single("file"),
  messageController.uploadMessageFile
);

module.exports = router;
