const Conversation = require("../models/conversation.model");
const ParticipantConversation = require("../models/participantconversation.model");
const Message = require("../models/message.model");
const Task = require("../models/task.model");
const { v4: uuidv4 } = require("uuid");

class ConversationService {
  // ===================== TASK CONVERSATION =====================

  /**
   * Tạo conversation mặc định cho task (tự động khi tạo task)
   * Conversation này sẽ có tất cả assigned_to của task
   */
  async createDefaultTaskConversation(task_id, created_by, assigned_to = []) {
    const conversation_id = uuidv4();

    // Tạo conversation mặc định
    const conversation = await Conversation.create({
      conversation_id,
      name: "General", // Tên mặc định
      type: "task",
      task_id: task_id,
      created_by: created_by,
      last_message_at: new Date(),
      is_task_default: true, // Đánh dấu là conversation mặc định
      unread_count: {},
    });

    // Thêm tất cả assigned_to vào conversation
    const allParticipants = [created_by, ...assigned_to];
    const uniqueParticipants = [...new Set(allParticipants)];

    const participantPromises = uniqueParticipants.map((employee_id) =>
      ParticipantConversation.create({
        conversation_id,
        employee_id,
        role_conversation_id: employee_id === created_by ? "owner" : "member",
        joined_at: new Date(),
        last_seen: new Date(),
      })
    );

    await Promise.all(participantPromises);

    // Khởi tạo unread_count
    uniqueParticipants.forEach((employee_id) => {
      conversation.unread_count.set(employee_id, 0);
    });
    await conversation.save();

    return conversation;
  }

  /**
   * Tạo conversation mới trong task (group hoặc private)
   * Bất kỳ thành viên nào của task đều có thể tạo
   */
  async createTaskConversation(data) {
    const { created_by, task_id, name, participants, type = "group" } = data;

    // Kiểm tra task tồn tại
    const task = await Task.findOne({ task_id: task_id });
    if (!task) {
      throw new Error("Task không tồn tại");
    }

    // Kiểm tra quyền tạo conversation
    const assignedIds = task.assigned_to.map((e) => e.employee_id);
    const canCreate = assignedIds.includes(created_by);

    // Kiểm tra admin/manager có thể tạo
    // Lưu ý: cần truyền role từ controller
    if (!canCreate && !data.isAdminOrManager) {
      throw new Error("Bạn không có quyền tạo conversation trong task này");
    }

    // Validate participants phải thuộc task
    if (participants && participants.length > 0) {
      const invalidParticipants = participants.filter(
        (p) => !assignedIds.includes(p) && p !== created_by
      );

      if (invalidParticipants.length > 0 && !data.isAdminOrManager) {
        throw new Error("Chỉ có thể thêm người đã được assign vào task");
      }
    }

    // Validate
    if (!participants || participants.length === 0) {
      throw new Error("Cần ít nhất 1 người tham gia");
    }

    // Nếu là private chat (1-1), kiểm tra đã tồn tại chưa
    if (type === "private" && participants.length === 1) {
      const existingConversation = await this.findPrivateTaskConversation(
        task_id,
        created_by,
        participants[0]
      );
      if (existingConversation) {
        return existingConversation;
      }
    }

    // Validate group chat phải có tên
    if (type === "group" && !name) {
      throw new Error("Group chat phải có tên");
    }

    const conversation_id = uuidv4();

    // Tạo conversation
    const conversation = await Conversation.create({
      conversation_id,
      name: type === "group" ? name : "",
      type: "task",
      task_id,
      created_by,
      is_task_default: false,
      last_message_at: new Date(),
      unread_count: {},
    });

    // Thêm participants
    const allParticipants = [created_by, ...participants];
    const uniqueParticipants = [...new Set(allParticipants)];

    const participantPromises = uniqueParticipants.map((employee_id) =>
      ParticipantConversation.create({
        conversation_id,
        employee_id,
        role_conversation_id: employee_id === created_by ? "owner" : "member",
        joined_at: new Date(),
        last_seen: new Date(),
      })
    );

    await Promise.all(participantPromises);

    // Khởi tạo unread_count
    uniqueParticipants.forEach((employee_id) => {
      conversation.unread_count.set(employee_id, 0);
    });
    await conversation.save();

    return await this.getConversationDetails(conversation_id, created_by);
  }

  /**
   * Thêm người mới vào conversation mặc định của task
   * Được gọi khi assign thêm người vào task
   */
  async addParticipantToDefaultTaskConversation(task_id, newEmployeeIds) {
    // Tìm conversation mặc định của task
    const conversation = await Conversation.findOne({
      task_id: task_id,
      is_task_default: true,
    });

    if (!conversation) {
      throw new Error("Không tìm thấy conversation mặc định của task");
    }

    const addedParticipants = [];

    for (const employee_id of newEmployeeIds) {
      // Kiểm tra đã tồn tại chưa
      const existing = await ParticipantConversation.findOne({
        conversation_id: conversation.conversation_id,
        employee_id: employee_id,
      });

      if (!existing) {
        await ParticipantConversation.create({
          conversation_id: conversation.conversation_id,
          employee_id: employee_id,
          role_conversation_id: "member",
          joined_at: new Date(),
          last_seen: new Date(),
        });

        // Khởi tạo unread_count
        conversation.unread_count.set(employee_id, 0);
        addedParticipants.push(employee_id);
      }
    }

    await conversation.save();

    return {
      success: true,
      addedParticipants,
      count: addedParticipants.length,
    };
  }

  /**
   * Lấy tất cả conversations của một task
   */
  async getTaskConversations(task_id, employee_id, role_id) {
    // Kiểm tra task tồn tại
    const task = await Task.findOne({ task_id: task_id });

    if (!task) {
      throw new Error("Task không tồn tại");
    }

    // Kiểm tra quyền truy cập
    const assignedIds = task.assigned_to;
    const isAssigned = assignedIds.includes(employee_id);
    const isAdminOrManager = ["admin", "manager"].includes(role_id);

    if (!isAssigned && !isAdminOrManager) {
      throw new Error("Bạn không có quyền truy cập chat của task này");
    }

    // Lấy tất cả conversations của task
    let conversations;

    if (isAdminOrManager) {
      // Admin/Manager thấy tất cả conversations của task
      conversations = await Conversation.find({
        task_id: task_id,
      })
        .sort({ is_task_default: -1, last_message_at: -1 })
        .lean();
    } else {
      // User thường chỉ thấy conversations mà họ tham gia
      const participantRecords = await ParticipantConversation.find({
        employee_id: employee_id,
      }).select("conversation_id");

      const conversationIds = participantRecords.map((p) => p.conversation_id);

      conversations = await Conversation.find({
        task_id: task_id,
        conversation_id: { $in: conversationIds },
      })
        .sort({ is_task_default: -1, last_message_at: -1 })
        .lean();
    }

    // Lấy thông tin creators một lần cho tất cả conversations
    const Employee = require("../models/employee.model");
    const creatorIds = [...new Set(conversations.map((c) => c.created_by))];
    const creators = await Employee.find(
      { employee_id: { $in: creatorIds } },
      "employee_id employee_name image"
    ).lean();

    // Tạo map để tra cứu nhanh
    const creatorMap = {};
    creators.forEach((creator) => {
      creatorMap[creator.employee_id] = creator;
    });

    // Lấy thông tin chi tiết cho mỗi conversation
    const detailedConversations = await Promise.all(
      conversations.map(async (conversation) => {
        // Lấy participants
        const participants = await ParticipantConversation.find({
          conversation_id: conversation.conversation_id,
        })
          .select("employee_id role_id joined_at last_seen")
          .lean();

        // Lấy tin nhắn cuối cùng
        const lastMessage = await Message.findOne({
          conversation_id: conversation.conversation_id,
          is_deleted: false,
        })
          .sort({ createdAt: -1 })
          .select("sender_id content createdAt type")
          .lean();

        const unreadCount = conversation.unread_count?.[employee_id] || 0;

        return {
          ...conversation,
          created_by: creatorMap[conversation.created_by] || {
            employee_id: conversation.created_by,
            employee_name: "Unknown",
            image: "",
          },
          participants,
          lastMessage,
          unreadCount,
          is_default: conversation.is_task_default,
        };
      })
    );

    return detailedConversations;
  }

  /**
   * Admin/Manager tham gia vào conversation của task
   */
  async joinTaskConversation(conversation_id, employee_id, role_id) {
    // Chỉ admin/manager mới có thể tự tham gia
    if (!["admin", "manager"].includes(role_id)) {
      throw new Error("Bạn không có quyền tham gia conversation này");
    }

    const conversation = await Conversation.findOne({
      conversation_id: conversation_id,
      type: "task",
    });

    if (!conversation) {
      throw new Error("Không tìm thấy conversation");
    }

    // Kiểm tra đã tham gia chưa
    const existing = await ParticipantConversation.findOne({
      conversation_id: conversation_id,
      employee_id: employee_id,
    });

    if (existing) {
      throw new Error("Bạn đã là thành viên của conversation này");
    }

    // Thêm vào conversation
    await ParticipantConversation.create({
      conversation_id: conversation_id,
      employee_id: employee_id,
      role_conversation_id: "owner",
      joined_at: new Date(),
      last_seen: new Date(),
    });

    // Khởi tạo unread_count
    conversation.unread_count.set(employee_id, 0);
    await conversation.save();

    return {
      success: true,
      message: "Đã tham gia conversation",
    };
  }

  // ===================== HELPER FUNCTIONS =====================

  /**
   * Tìm private conversation trong task
   */
  async findPrivateTaskConversation(task_id, user1, user2) {
    // Tìm các conversation của user1 trong task
    const user1Conversations = await ParticipantConversation.find({
      employee_id: user1,
    }).select("conversation_id");

    const conversationIds1 = user1Conversations.map((p) => p.conversation_id);

    // Tìm conversation chung trong task
    const conversations = await Conversation.find({
      conversation_id: { $in: conversationIds1 },
      task_id: task_id,
      type: "task",
      is_task_default: false,
    });

    for (const conversation of conversations) {
      const participants = await ParticipantConversation.find({
        conversation_id: conversation.conversation_id,
      }).select("employee_id");

      const participantIds = participants.map((p) => p.employee_id);

      // Kiểm tra có đúng 2 người và bao gồm cả user1 và user2
      if (
        participantIds.length === 2 &&
        participantIds.includes(user1) &&
        participantIds.includes(user2)
      ) {
        return await this.getConversationDetails(
          conversation.conversation_id,
          user1
        );
      }
    }

    return null;
  }

  // ===================== EXISTING FUNCTIONS (giữ nguyên) =====================

  async createConversation(data) {
    const { created_by, type = "private", name, participants } = data;

    if (!participants || participants.length === 0) {
      throw new Error("Cần ít nhất 1 người tham gia");
    }

    // Nếu là private chat, kiểm tra đã tồn tại chưa
    if (type === "private" && participants.length === 1) {
      const existingConversation = await this.findPrivateConversation(
        created_by,
        participants[0]
      );
      if (existingConversation) {
        return existingConversation;
      }
    }

    if (type === "group" && !name) {
      throw new Error("Group chat phải có tên");
    }

    const conversation_id = uuidv4();

    const conversation = await Conversation.create({
      conversation_id,
      name: type === "group" ? name : "",
      type,
      created_by,
      last_message_at: new Date(),
      unread_count: {},
    });

    const allParticipants = [created_by, ...participants];
    const uniqueParticipants = [...new Set(allParticipants)];

    const participantPromises = uniqueParticipants.map((employee_id) =>
      ParticipantConversation.create({
        conversation_id,
        employee_id,
        role_conversation_id: employee_id === created_by ? "owner" : "member",
        joined_at: new Date(),
        last_seen: new Date(),
      })
    );

    await Promise.all(participantPromises);

    uniqueParticipants.forEach((employee_id) => {
      conversation.unread_count.set(employee_id, 0);
    });
    await conversation.save();

    return await this.getConversationDetails(conversation_id, created_by);
  }

  async findPrivateConversation(user1, user2) {
    const user1Conversations = await ParticipantConversation.find({
      employee_id: user1,
    }).select("conversation_id");

    const user2Conversations = await ParticipantConversation.find({
      employee_id: user2,
    }).select("conversation_id");

    const conversationIds1 = user1Conversations.map((p) => p.conversation_id);
    const conversationIds2 = user2Conversations.map((p) => p.conversation_id);

    const commonConversationIds = conversationIds1.filter((id) =>
      conversationIds2.includes(id)
    );

    if (commonConversationIds.length === 0) {
      return null;
    }

    for (const convId of commonConversationIds) {
      const conversation = await Conversation.findOne({
        conversation_id: convId,
        type: "private",
      });

      if (conversation) {
        const participantCount = await ParticipantConversation.countDocuments({
          conversation_id: convId,
        });

        if (participantCount === 2) {
          return await this.getConversationDetails(convId, user1);
        }
      }
    }

    return null;
  }

  async getConversations(employee_id, options = {}) {
    const { page = 1, limit = 20, type } = options;
    const skip = (page - 1) * limit;

    const participantRecords = await ParticipantConversation.find({
      employee_id: employee_id,
    }).select("conversation_id");

    const conversationIds = participantRecords.map((p) => p.conversation_id);

    const filter = { conversation_id: { $in: conversationIds } };
    if (type) {
      filter.type = type;
    }

    const conversations = await Conversation.find(filter)
      .sort({ last_message_at: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    // Lấy thông tin Employee cho tất cả participants
    const Employee = require("../models/employee.model");

    const detailedConversations = await Promise.all(
      conversations.map(async (conversation) => {
        const participants = await ParticipantConversation.find({
          conversation_id: conversation.conversation_id,
        })
          .select("employee_id role_conversation_id joined_at last_seen")
          .lean();

        // Lấy thông tin chi tiết của participants
        const participantIds = participants.map((p) => p.employee_id);
        const employeeDetails = await Employee.find({
          employee_id: { $in: participantIds },
        })
          .select("employee_id employee_name email image")
          .lean();

        const employeeMap = {};
        employeeDetails.forEach((emp) => {
          employeeMap[emp.employee_id] = emp;
        });

        // Gắn thông tin employee vào participants
        const detailedParticipants = participants.map((p) => ({
          ...p,
          ...employeeMap[p.employee_id],
        }));

        const lastMessage = await Message.findOne({
          conversation_id: conversation.conversation_id,
          is_deleted: false,
        })
          .sort({ createdAt: -1 })
          .select("sender_id content createdAt type")
          .lean();

        const unreadCount = conversation.unread_count?.[employee_id] || 0;

        let otherEmployee = null;
        if (conversation.type === "private") {
          const otherParticipant = detailedParticipants.find(
            (p) => p.employee_id !== employee_id
          );
          if (otherParticipant) {
            otherEmployee = {
              employee_id: otherParticipant.employee_id,
              employee_name: otherParticipant.employee_name || "Unknown",
              email: otherParticipant.email || "",
              image: otherParticipant.image || null,
            };
          }
        }

        return {
          conversation_id: conversation.conversation_id,
          name: conversation.name || "",
          type: conversation.type,
          task_id: conversation.task_id || null,
          created_by: conversation.created_by,
          last_message_at: conversation.last_message_at,
          is_task_default: conversation.is_task_default || false,
          participants: detailedParticipants,
          lastMessage: lastMessage || null,
          unreadCount,
          otherEmployee,
        };
      })
    );

    const total = await Conversation.countDocuments(filter);

    return {
      conversations: detailedConversations,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getConversationDetails(conversation_id, employee_id) {
    const conversation = await Conversation.findOne({
      conversation_id: conversation_id,
    }).lean();

    if (!conversation) {
      throw new Error("Không tìm thấy cuộc trò chuyện");
    }

    const hasAccess = await this.checkAccess(conversation_id, employee_id);
    if (!hasAccess) {
      throw new Error("Bạn không có quyền truy cập cuộc trò chuyện này");
    }

    const participants = await ParticipantConversation.find({
      conversation_id: conversation_id,
    })
      .select("employee_id role_conversation_id joined_at last_seen")
      .lean();

    const lastMessage = await Message.findOne({
      conversation_id: conversation_id,
      is_deleted: false,
    })
      .sort({ createdAt: -1 })
      .select("sender_id content createdAt type")
      .lean();

    const unreadCount = conversation.unread_count?.[employee_id] || 0;

    let otherUser = null;
    if (conversation.type === "private") {
      const otherParticipant = participants.find(
        (p) => p.employee_id !== employee_id
      );
      if (otherParticipant) {
        otherUser = {
          employee_id: otherParticipant.employee_id,
        };
      }
    }

    await ParticipantConversation.findOneAndUpdate(
      { conversation_id: conversation_id, employee_id: employee_id },
      { last_seen: new Date() }
    );

    return {
      ...conversation,
      participants,
      lastMessage,
      unreadCount,
      otherUser,
    };
  }

  async updateConversation(conversation_id, employee_id, data) {
    const conversation = await Conversation.findOne({
      conversation_id: conversation_id,
    });

    if (!conversation) {
      throw new Error("Không tìm thấy cuộc trò chuyện");
    }

    if (conversation.type !== "group" && conversation.type !== "task") {
      throw new Error(
        "Chỉ có thể cập nhật thông tin group chat hoặc task chat"
      );
    }

    const participant = await ParticipantConversation.findOne({
      conversation_id: conversation_id,
      employee_id: employee_id,
    });

    if (
      !participant ||
      (participant.role_conversation_id !== "owner" &&
        conversation.created_by !== employee_id)
    ) {
      throw new Error("Bạn không có quyền cập nhật cuộc trò chuyện này");
    }

    const { name } = data;
    if (name) conversation.name = name;

    await conversation.save();

    return await this.getConversationDetails(conversation_id, employee_id);
  }

  async addParticipants(conversation_id, employee_id, newParticipants) {
    const conversation = await Conversation.findOne({
      conversation_id: conversation_id,
    });

    if (!conversation) {
      throw new Error("Không tìm thấy cuộc trò chuyện");
    }

    if (conversation.type !== "group" && conversation.type !== "task") {
      throw new Error(
        "Chỉ có thể thêm thành viên vào group chat hoặc task chat"
      );
    }

    const participant = await ParticipantConversation.findOne({
      conversation_id: conversation_id,
      employee_id: employee_id,
    });

    if (!participant) {
      throw new Error("Bạn không có quyền thêm thành viên");
    }

    const addedParticipants = [];
    for (const newParticipantId of newParticipants) {
      const existing = await ParticipantConversation.findOne({
        conversation_id: conversation_id,
        employee_id: newParticipantId,
      });

      if (!existing) {
        await ParticipantConversation.create({
          conversation_id: conversation_id,
          employee_id: newParticipantId,
          role_conversation_id: "member",
          joined_at: new Date(),
          last_seen: new Date(),
        });

        conversation.unread_count.set(newParticipantId, 0);
        addedParticipants.push(newParticipantId);
      }
    }

    await conversation.save();

    return {
      success: true,
      addedParticipants,
      count: addedParticipants.length,
    };
  }

  async removeParticipant(conversation_id, employee_id, participantToRemove) {
    const conversation = await Conversation.findOne({
      conversation_id: conversation_id,
    });

    if (!conversation) {
      throw new Error("Không tìm thấy cuộc trò chuyện");
    }

    if (conversation.type !== "group" && conversation.type !== "task") {
      throw new Error(
        "Chỉ có thể xóa thành viên khỏi group chat hoặc task chat"
      );
    }

    const requester = await ParticipantConversation.findOne({
      conversation_id: conversation_id,
      employee_id: employee_id,
    });

    if (!requester) {
      throw new Error("Bạn không có quyền thực hiện thao tác này");
    }

    const isAdmin =
      requester.role_conversation_id === "owner" ||
      conversation.created_by === employee_id;
    const isSelfRemoval = employee_id === participantToRemove;

    if (!isAdmin && !isSelfRemoval) {
      throw new Error("Bạn không có quyền xóa thành viên này");
    }

    if (participantToRemove === conversation.created_by) {
      throw new Error("Không thể xóa người tạo nhóm");
    }

    await ParticipantConversation.findOneAndDelete({
      conversation_id: conversation_id,
      employee_id: participantToRemove,
    });

    conversation.unread_count.delete(participantToRemove);
    await conversation.save();

    return {
      success: true,
      removedParticipant: participantToRemove,
    };
  }

  async leaveConversation(conversation_id, employee_id) {
    return await this.removeParticipant(
      conversation_id,
      employee_id,
      employee_id
    );
  }

  async deleteConversation(conversation_id, employee_id) {
    const conversation = await Conversation.findOne({
      conversation_id: conversation_id,
    });

    if (!conversation) {
      throw new Error("Không tìm thấy cuộc trò chuyện");
    }

    if (conversation.created_by !== employee_id) {
      throw new Error("Chỉ người tạo mới có quyền xóa cuộc trò chuyện");
    }

    await ParticipantConversation.deleteMany({
      conversation_id: conversation_id,
    });

    await Message.updateMany(
      { conversation_id: conversation_id },
      { is_deleted: true }
    );

    await Conversation.deleteOne({ conversation_id: conversation_id });

    return { success: true };
  }

  async checkAccess(conversation_id, employee_id) {
    const participant = await ParticipantConversation.findOne({
      conversation_id: conversation_id,
      employee_id: employee_id,
    });

    return !!participant;
  }

  async getTotalUnreadCount(employee_id) {
    const participantRecords = await ParticipantConversation.find({
      employee_id: employee_id,
    }).select("conversation_id");

    const conversationIds = participantRecords.map((p) => p.conversation_id);

    const conversations = await Conversation.find({
      conversation_id: { $in: conversationIds },
    }).lean();

    let totalUnread = 0;
    conversations.forEach((conversation) => {
      totalUnread += conversation.unread_count[employee_id] || 0;
    });

    console.log(`\nTỔNG UNREAD: ${totalUnread}`);

    return totalUnread;
  }
}

module.exports = ConversationService;
