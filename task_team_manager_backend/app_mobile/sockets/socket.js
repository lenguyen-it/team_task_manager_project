const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const Message = require("../models/message.model");
const Conversation = require("../models/conversation.model");

let io;
const userSockets = new Map();

const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
    },
  });

  io.use((socket, next) => {
    const token =
      socket.handshake.auth.token ||
      socket.handshake.headers.authorization?.split(" ")[1];

    console.log("🔐 Checking auth...");
    console.log("Auth object:", socket.handshake.auth);
    console.log("Headers:", socket.handshake.headers.authorization);
    console.log("Token:", token);

    if (!token) {
      console.log("❌ No token provided");
      return next(new Error("Authentication error"));
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
        decoded: decoded,
      });

      next();
    } catch (error) {
      console.log("❌ Invalid token:", error.message);
      return next(new Error("Invalid token"));
    }
  });

  io.on("connection", (socket) => {
    console.log(
      "✅ New client connected:",
      socket.id,
      "Employee:",
      socket.employee_id
    );
    console.log("📋 Employee Data:", socket.employeeData);

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

        console.log(`📤 Message from ${sender_id} in ${conversation_id}`);

        const newMessage = await Message.create({
          sender_id,
          receiver_id,
          conversation_id,
          content,
          type,
          status: "sent",
        });

        await Conversation.findOneAndUpdate(
          { conversation_id },
          { last_message_at: new Date() }
        );

        // Emit tin nhắn mới
        io.to(conversation_id).emit("new_message", {
          message: newMessage.toObject ? newMessage.toObject() : newMessage,
          temp_id,
        });

        console.log(`✅ Message sent successfully: ${newMessage._id}`);
      } catch (error) {
        console.error("❌ Error sending message:", error);
        socket.emit("error", { message: "Không thể gửi tin nhắn" });
      }
    });

    // Người dùng đang nhập
    socket.on("typing", (data) => {
      socket.to(data.conversation_id).emit("employee_typing", {
        employee_id: data.employee_id,
        isTyping: true,
      });
      console.log(
        `⌨️ ${data.employee_id} is typing in ${data.conversation_id}`
      );
    });

    // Người dùng ngừng nhập
    socket.on("stop_typing", (data) => {
      socket.to(data.conversation_id).emit("employee_typing", {
        employee_id: data.employee_id,
        isTyping: false,
      });
      console.log(
        `⌨️ ${data.employee_id} stopped typing in ${data.conversation_id}`
      );
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

    // CÁCH XỬ LÝ MỚI: Mark messages as read
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

        // Emit event đến TẤT CẢ clients trong conversation (bao gồm cả chính mình)
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
