const Message = require("../models/message.model");
const Conversation = require("../models/conversation.model");
const ParticipantConversation = require("../models/participantconversation.model");

class MessageService {
  // Lấy danh sách tin nhắn của conversation với pagination
  async getMessages(conversationId, employeeId, options = {}) {
    const { page = 1, limit = 50 } = options;
    const skip = (page - 1) * limit;

    // Kiểm tra quyền truy cập conversation
    const hasAccess = await this.checkConversationAccess(
      conversationId,
      employeeId
    );
    if (!hasAccess) {
      throw new Error("Bạn không có quyền truy cập cuộc trò chuyện này");
    }

    // Lấy tin nhắn
    const messages = await Message.find({
      conversation_id: conversationId,
      is_deleted: false,
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    // Đếm tổng số tin nhắn
    const total = await Message.countDocuments({
      conversation_id: conversationId,
      is_deleted: false,
    });

    return {
      messages: messages.reverse(),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // Tạo tin nhắn mới
  async createMessage(data) {
    const {
      sender_id,
      receiver_id,
      conversation_id,
      content,
      type = "text",
    } = data;

    // Kiểm tra quyền truy cập
    const hasAccess = await this.checkConversationAccess(
      conversation_id,
      sender_id
    );
    if (!hasAccess) {
      throw new Error(
        "Bạn không có quyền gửi tin nhắn trong cuộc trò chuyện này"
      );
    }

    // Tạo tin nhắn
    const message = await Message.create({
      sender_id,
      receiver_id,
      conversation_id,
      content,
      type,
      status: "sent",
    });

    // Cập nhật last_message_at
    await Conversation.findOneAndUpdate(
      { conversation_id },
      { last_message_at: new Date() }
    );

    // Tăng unread_count cho các thành viên khác
    await this.incrementUnreadCount(conversation_id, sender_id);

    return message;
  }

  // Đánh dấu tin nhắn đã đọc
  async markMessageAsRead(messageId, employeeId) {
    if (!messageId || !mongoose.Types.ObjectId.isValid(messageId)) {
      throw new Error("ID tin nhắn không hợp lệ");
    }

    const message = await Message.findById(messageId);

    if (!message) {
      throw new Error("Không tìm thấy tin nhắn");
    }

    // Kiểm tra quyền
    const hasAccess = await this.checkConversationAccess(
      message.conversation_id,
      employeeId
    );
    if (!hasAccess) {
      throw new Error("Bạn không có quyền truy cập tin nhắn này");
    }

    // Kiểm tra xem đã đọc chưa
    const alreadySeen = message.seen_by.some(
      (item) => item.employee_id === employeeId
    );

    if (!alreadySeen) {
      message.seen_by.push({
        employee_id: employeeId,
        seen_at: new Date(),
      });

      // Cập nhật status nếu là tin nhắn 1-1
      if (message.receiver_id === employeeId) {
        message.status = "seen";
      }

      await message.save();

      // Giảm unread_count
      await this.decrementUnreadCount(message.conversation_id, employeeId);
    }

    return message;
  }

  // Đánh dấu tất cả tin nhắn trong conversation đã đọc
  async markAllMessagesAsRead(conversationId, employeeId) {
    const hasAccess = await this.checkConversationAccess(
      conversationId,
      employeeId
    );
    if (!hasAccess) {
      throw new Error("Bạn không có quyền truy cập cuộc trò chuyện này");
    }

    // Lấy tất cả tin nhắn chưa đọc
    const messages = await Message.find({
      conversation_id: conversationId,
      sender_id: { $ne: employeeId },
      "seen_by.employee_id": { $ne: employeeId },
    });

    // Đánh dấu đã đọc
    for (const message of messages) {
      message.seen_by.push({
        employee_id: employeeId,
        seen_at: new Date(),
      });

      if (message.receiver_id === employeeId) {
        message.status = "seen";
      }

      await message.save();
    }

    // Reset unread_count
    await Conversation.findOneAndUpdate(
      { conversation_id: conversationId },
      { [`unread_count.${employeeId}`]: 0 }
    );

    return { success: true, count: messages.length };
  }

  // Xóa tin nhắn (soft delete)
  async deleteMessage(messageId, employeeId) {
    const message = await Message.findById(messageId);

    if (!message) {
      throw new Error("Không tìm thấy tin nhắn");
    }

    // Chỉ người gửi mới được xóa
    if (message.sender_id !== employeeId) {
      throw new Error("Bạn chỉ có thể xóa tin nhắn của chính mình");
    }

    message.is_deleted = true;
    await message.save();

    return message;
  }

  // Tìm kiếm tin nhắn
  async searchMessages(conversationId, employeeId, searchQuery, options = {}) {
    const { page = 1, limit = 20 } = options;
    const skip = (page - 1) * limit;

    const hasAccess = await this.checkConversationAccess(
      conversationId,
      employeeId
    );
    if (!hasAccess) {
      throw new Error("Bạn không có quyền truy cập cuộc trò chuyện này");
    }

    const messages = await Message.find({
      conversation_id: conversationId,
      is_deleted: false,
      content: { $regex: searchQuery, $options: "i" },
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await Message.countDocuments({
      conversation_id: conversationId,
      is_deleted: false,
      content: { $regex: searchQuery, $options: "i" },
    });

    return {
      messages,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // Lấy số lượng tin nhắn chưa đọc
  async getUnreadCount(conversationId, employeeId) {
    const conversation = await Conversation.findOne({
      conversation_id: conversationId,
    });

    if (!conversation) {
      throw new Error("Không tìm thấy cuộc trò chuyện");
    }

    return conversation.unread_count.get(employeeId) || 0;
  }

  // Lấy tin nhắn với thông tin người gửi (populated)
  async getMessagesWithSender(conversationId, employeeId, options = {}) {
    const { page = 1, limit = 50 } = options;
    const skip = (page - 1) * limit;

    // Kiểm tra quyền truy cập conversation
    const hasAccess = await this.checkConversationAccess(
      conversationId,
      employeeId
    );
    if (!hasAccess) {
      throw new Error("Bạn không có quyền truy cập cuộc trò chuyện này");
    }

    // Lấy tin nhắn (có thể populate sender info nếu cần)
    const messages = await Message.find({
      conversation_id: conversationId,
      is_deleted: false,
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    // Đếm tổng số tin nhắn
    const total = await Message.countDocuments({
      conversation_id: conversationId,
      is_deleted: false,
    });

    return {
      messages: messages.reverse(),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  // Helper: Kiểm tra quyền truy cập conversation
  async checkConversationAccess(conversationId, employeeId) {
    const participant = await ParticipantConversation.findOne({
      conversation_id: conversationId,
      employee_id: employeeId,
    });

    return !!participant;
  }

  // Helper: Tăng unread_count cho các thành viên khác
  async incrementUnreadCount(conversationId, senderId) {
    const participants = await ParticipantConversation.find({
      conversation_id: conversationId,
      employee_id: { $ne: senderId },
    });

    const conversation = await Conversation.findOne({
      conversation_id: conversationId,
    });

    if (conversation) {
      participants.forEach((participant) => {
        const currentCount =
          conversation.unread_count.get(participant.employee_id) || 0;
        conversation.unread_count.set(
          participant.employee_id,
          currentCount + 1
        );
      });

      await conversation.save();
    }
  }

  // Helper: Giảm unread_count
  async decrementUnreadCount(conversationId, employeeId) {
    const conversation = await Conversation.findOne({
      conversation_id: conversationId,
    });

    if (conversation) {
      const currentCount = conversation.unread_count.get(employeeId) || 0;
      if (currentCount > 0) {
        conversation.unread_count.set(employeeId, currentCount - 1);
        await conversation.save();
      }
    }
  }

  // Cập nhật status tin nhắn (sent -> delivered)
  async updateMessageStatus(messageId, status) {
    const message = await Message.findByIdAndUpdate(
      messageId,
      { status },
      { new: true }
    );

    return message;
  }
}

module.exports = MessageService;
