const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const Message = require("../models/message.model");
const Conversation = require("../models/conversation.model");
const MessageService = require("../services/message.service");
const messageService = new MessageService();

let io;
const userSockets = new Map();

const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
    },
  });

  // FIX: Middleware để authenticate socket connection
  io.use((socket, next) => {
    // Thử lấy token từ nhiều nguồn
    const token =
      socket.handshake.auth.token ||
      socket.handshake.headers.authorization?.split(" ")[1] ||
      socket.handshake.query.token;

    console.log("🔐 Checking auth...");
    console.log("Auth object:", socket.handshake.auth);
    console.log(
      "Headers Authorization:",
      socket.handshake.headers.authorization
    );
    console.log("Query token:", socket.handshake.query.token);
    console.log(
      "Extracted token:",
      token ? `${token.substring(0, 20)}...` : "null"
    );

    if (!token) {
      console.log("❌ No token provided in any location");
      return next(new Error("Authentication error: No token provided"));
    }

    try {
      const decoded = jwt.verify(
        token,
        process.env.JWT_SECRET || "your_jwt_secret_key"
      );
      socket.employee_id = decoded.employee_id;
      socket.employeeData = decoded;

      console.log("✅ Auth success:", {
        employee_id: socket.employee_id,
        role_id: decoded.role_id,
      });

      next();
    } catch (error) {
      console.log("❌ Invalid token:", error.message);
      return next(new Error(`Invalid token: ${error.message}`));
    }
  });

  io.on("connection", (socket) => {
    console.log(
      "✅ New client connected:",
      socket.id,
      "Employee:",
      socket.employee_id
    );

    userSockets.set(socket.employee_id, socket.id);

    // User đăng nhập
    socket.on("employee_online", (employee_id) => {
      userSockets.set(employee_id, socket.id);
      socket.employee_id = employee_id;
      console.log(`👤 Employee ${employee_id} is online`);
    });

    // Tham gia room
    socket.on("join_conversation", (conversationId) => {
      socket.join(conversationId);
      console.log(
        `🚪 Employee ${socket.employee_id} joined conversation: ${conversationId}`
      );
    });

    // Gửi tin nhắn
    // socket.on("send_message", async (data) => {
    //   try {
    //     const {
    //       conversation_id,
    //       content,
    //       receiver_id,
    //       type = "text",
    //       temp_id,
    //     } = data;
    //     const sender_id = socket.employee_id;

    //     if (!sender_id || !conversation_id || !content) {
    //       socket.emit("error", { message: "Thiếu thông tin bắt buộc" });
    //       return;
    //     }

    //     console.log(`📤 Message from ${sender_id} in ${conversation_id}`);

    //     const newMessage = await Message.create({
    //       sender_id,
    //       receiver_id,
    //       conversation_id,
    //       content,
    //       type,
    //       status: "sent",
    //     });

    //     await Conversation.findOneAndUpdate(
    //       { conversation_id },
    //       { last_message_at: new Date() }
    //     );

    //     // FIX: Chuyển message thành plain object
    //     const messageObj = newMessage.toObject
    //       ? newMessage.toObject()
    //       : newMessage;

    //     // Emit tin nhắn mới đến TẤT CẢ clients trong room (bao gồm cả người gửi)
    //     io.to(conversation_id).emit("new_message", {
    //       message: {
    //         ...messageObj,
    //         _id: messageObj._id.toString(),
    //       },
    //       temp_id,
    //     });

    //     console.log(`✅ Message sent successfully: ${newMessage._id}`);
    //   } catch (error) {
    //     console.error("❌ Error sending message:", error);
    //     socket.emit("error", { message: "Không thể gửi tin nhắn" });
    //   }
    // });

    socket.on("send_message", async (data) => {
      try {
        const {
          conversation_id,
          content,
          receiver_id,
          type = "text",
          temp_id,
        } = data;
        const sender_id = socket.employee_id;

        if (!sender_id || !conversation_id || !content) {
          socket.emit("error", { message: "Thiếu thông tin bắt buộc" });
          return;
        }

        console.log(`Message from ${sender_id} in ${conversation_id}`);

        // DÙNG INSTANCE ĐÃ TẠO SẴN (không new mỗi lần)
        const newMessage = await messageService.createMessage({
          sender_id,
          receiver_id,
          conversation_id,
          content,
          type,
        });

        // Chuyển thành plain object để emit an toàn
        const messageObj = newMessage.toObject
          ? newMessage.toObject()
          : { ...newMessage };
        if (messageObj._id) messageObj._id = messageObj._id.toString();

        // Emit realtime cho tất cả trong room
        io.to(conversation_id).emit("new_message", {
          message: messageObj,
          temp_id,
        });

        // Gửi ack cho người gửi (nếu dùng temp_id)
        if (temp_id) {
          socket.emit("message_ack", {
            temp_id,
            message: messageObj,
          });
        }

        console.log(`Message sent + unread tăng: ${newMessage._id}`);
      } catch (error) {
        console.error("Error sending message:", error);
        socket.emit("error", { message: "Không thể gửi tin nhắn" });
      }
    });

    // Người dùng đang nhập
    socket.on("typing", (data) => {
      const { conversation_id, employee_id } = data;

      // Emit đến TẤT CẢ trong room NGOẠI TRỪ người gửi
      socket.to(conversation_id).emit("typing", {
        conversation_id,
        employee_id,
      });

      console.log(`⌨️ ${employee_id} is typing in ${conversation_id}`);
    });

    // Người dùng ngừng nhập
    socket.on("stop_typing", (data) => {
      const { conversation_id, employee_id } = data;

      socket.to(conversation_id).emit("stop_typing", {
        conversation_id,
        employee_id,
      });

      console.log(`⌨️ ${employee_id} stopped typing in ${conversation_id}`);
    });

    // Rời conversation
    socket.on("leave_conversation", (data) => {
      const conversationId =
        typeof data === "string" ? data : data.conversation_id;
      socket.leave(conversationId);
      console.log(
        `👋 Employee ${socket.employee_id} left conversation: ${conversationId}`
      );
    });

    // Mark messages as read
    socket.on("mark_messages_read", async (data) => {
      try {
        const { conversation_id } = data;

        if (!conversation_id) {
          console.log("❌ Missing conversation_id");
          return;
        }

        const employee_id = socket.employee_id;

        console.log(
          `👁️ Marking messages as read in ${conversation_id} by ${employee_id}`
        );

        // Cập nhật tất cả tin nhắn chưa đọc thành đã đọc
        const result = await Message.updateMany(
          {
            conversation_id,
            sender_id: { $ne: employee_id }, // Chỉ update tin nhắn từ người khác
            status: { $in: ["sent", "delivered"] }, // Chưa seen
          },
          { status: "seen" }
        );

        console.log(
          `✅ Updated ${result.modifiedCount} messages to seen in ${conversation_id}`
        );

        // Emit event đến TẤT CẢ clients trong conversation
        io.to(conversation_id).emit("all_messages_read", {
          conversation_id: conversation_id,
          employee_id: employee_id,
          timestamp: new Date(),
          count: result.modifiedCount,
        });
      } catch (error) {
        console.error("❌ Error marking messages as read:", error);
        socket.emit("error", {
          message: "Không thể đánh dấu tin nhắn đã đọc",
        });
      }
    });

    // Xử lý ngắt kết nối
    socket.on("disconnect", () => {
      console.log(
        `❌ Client disconnected: ${socket.id}, User: ${socket.employee_id}`
      );

      for (let [employee_id, socketId] of userSockets.entries()) {
        if (socketId === socket.id) {
          userSockets.delete(employee_id);
          console.log(`👤 User ${employee_id} went offline`);
          break;
        }
      }
    });
  });

  console.log("✅ Socket.IO initialized successfully");
};

const getIO = () => {
  if (!io) {
    throw new Error("Socket.IO not initialized!");
  }
  return io;
};

module.exports = { initSocket, getIO };
