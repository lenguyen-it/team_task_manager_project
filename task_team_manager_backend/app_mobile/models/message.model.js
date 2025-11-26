const mongoose = require("mongoose");

const messageSchema = new mongoose.Schema(
  {
    sender_id: {
      type: String,
      ref: "Employee",
      required: true,
    },

    receiver_id: {
      type: String,
      ref: "Employee",
      required: false,
    },

    conversation_id: {
      type: String,
      ref: "Conversation",
      required: true,
    },

    content: {
      type: String,
      required: true,
    },

    status: {
      type: String,
      enum: ["sent", "delivered", "seen"],
      default: "sent",
    },

    type: { type: String },

    is_deleted: {
      type: Boolean,
      default: false,
    },

    seen_by: [
      {
        employee_id: String,
        seen_at: Date,
      },
    ],
  },
  { timestamps: true }
);

const Message = mongoose.model("Message", messageSchema);
module.exports = Message;
