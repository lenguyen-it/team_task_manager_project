const MessageService = require("../services/message.service");
const { getIO } = require("../sockets/socket");

// Lấy danh sách tin nhắn của conversation
exports.getMessages = async (req, res) => {
  try {
    const { conversation_id } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const employee_id = req.employee.employee_id;

    const messageService = new MessageService();
    const result = await messageService.getMessages(
      conversation_id,
      employee_id,
      {
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
      }
    );

    res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error("Error in getMessages:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 500).json({
      success: false,
      message: error.message || "Lỗi khi lấy tin nhắn",
    });
  }
};

// Tạo tin nhắn mới (qua HTTP - backup cho socket)
exports.createMessage = async (req, res) => {
  try {
    const { conversation_id, content, receiver_id, type } = req.body;
    const sender_id = req.employee.employee_id;

    if (!conversation_id || !content) {
      return res.status(400).json({
        success: false,
        message: "Thiếu thông tin conversation_id hoặc content",
      });
    }

    const messageService = new MessageService();
    const message = await messageService.createMessage({
      sender_id,
      receiver_id,
      conversation_id,
      content,
      type: type || "text",
    });

    // Gửi qua socket
    const io = getIO();
    io.to(conversation_id).emit("new_message", message);

    res.status(201).json({
      success: true,
      data: message,
    });
  } catch (error) {
    console.error("Error in createMessage:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 500).json({
      success: false,
      message: error.message || "Lỗi khi tạo tin nhắn",
    });
  }
};

// Đánh dấu tin nhắn đã đọc
exports.markMessageAsRead = async (req, res) => {
  try {
    const { messageId } = req.params;
    const employee_id = req.employee.employee_id;

    const messageService = new MessageService();
    const message = await messageService.markMessageAsRead(
      messageId,
      employee_id
    );

    // Thông báo qua socket
    const io = getIO();
    io.to(message.conversation_id).emit("message_read", {
      messageId: message._id,
      employee_id,
      seenAt: new Date(),
    });

    res.status(200).json({
      success: true,
      data: message,
    });
  } catch (error) {
    console.error("Error in markMessageAsRead:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 500).json({
      success: false,
      message: error.message || "Lỗi khi đánh dấu đã đọc",
    });
  }
};

// Đánh dấu tất cả tin nhắn trong conversation đã đọc
exports.markAllMessagesAsRead = async (req, res) => {
  try {
    const { conversation_id } = req.params;
    const employee_id = req.employee.employee_id;

    const messageService = new MessageService();
    const result = await messageService.markAllMessagesAsRead(
      conversation_id,
      employee_id
    );

    // Thông báo qua socket
    const io = getIO();
    io.to(conversation_id).emit("all_messages_read", {
      conversation_id,
      employee_id,
      readAt: new Date(),
    });

    res.status(200).json({
      success: true,
      message: `Đã đánh dấu ${result.count} tin nhắn là đã đọc`,
      data: result,
    });
  } catch (error) {
    console.error("Error in markAllMessagesAsRead:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 500).json({
      success: false,
      message: error.message || "Lỗi khi đánh dấu tất cả đã đọc",
    });
  }
};

// Xóa tin nhắn
exports.deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const employee_id = req.employee.employee_id;

    const messageService = new MessageService();
    const message = await messageService.deleteMessage(messageId, employee_id);

    // Thông báo qua socket
    const io = getIO();
    io.to(message.conversation_id).emit("message_deleted", {
      messageId: message._id,
      conversation_id: message.conversation_id,
    });

    res.status(200).json({
      success: true,
      message: "Đã xóa tin nhắn",
      data: message,
    });
  } catch (error) {
    console.error("Error in deleteMessage:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 500).json({
      success: false,
      message: error.message || "Lỗi khi xóa tin nhắn",
    });
  }
};

// Tìm kiếm tin nhắn
exports.searchMessages = async (req, res) => {
  try {
    const { conversation_id } = req.params;
    const { q, page = 1, limit = 20 } = req.query;
    const employee_id = req.employee.employee_id;

    if (!q) {
      return res.status(400).json({
        success: false,
        message: "Thiếu từ khóa tìm kiếm (q)",
      });
    }

    const messageService = new MessageService();
    const result = await messageService.searchMessages(
      conversation_id,
      employee_id,
      q,
      {
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
      }
    );

    res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error("Error in searchMessages:", error);
    res.status(error.message.includes("không có quyền") ? 403 : 500).json({
      success: false,
      message: error.message || "Lỗi khi tìm kiếm tin nhắn",
    });
  }
};

// Lấy số lượng tin nhắn chưa đọc
exports.getUnreadCount = async (req, res) => {
  try {
    const { conversation_id } = req.params;
    const employee_id = req.employee.employee_id;

    const messageService = new MessageService();
    const count = await messageService.getUnreadCount(
      conversation_id,
      employee_id
    );

    res.status(200).json({
      success: true,
      data: {
        conversation_id,
        unreadCount: count,
      },
    });
  } catch (error) {
    console.error("Error in getUnreadCount:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Lỗi khi lấy số tin nhắn chưa đọc",
    });
  }
};

// Upload file trong tin nhắn
exports.uploadMessageFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Không có file được upload",
      });
    }

    const fileUrl = `/uploads/files/${req.file.filename}`;

    res.status(200).json({
      success: true,
      data: {
        filename: req.file.filename,
        originalname: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size,
        url: fileUrl,
      },
    });
  } catch (error) {
    console.error("Error in uploadMessageFile:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Lỗi khi upload file",
    });
  }
};
