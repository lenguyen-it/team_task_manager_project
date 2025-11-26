const mongoose = require("mongoose");

const conversationSchema = new mongoose.Schema(
  {
    conversation_id: {
      type: String,
      unique: true,
      required: true,
    },

    name: {
      type: String,
      required: false,
      default: "",
    },

    task_id: {
      type: String,
      ref: "Task",
      sparse: true,
      unique: true,
    },

    type: {
      type: String,
      enum: ["private", "group", "task"],
      default: "private",
    },

    created_by: {
      type: String,
      ref: "Employee",
      required: true,
    },

    is_task_default: {
      type: Boolean,
      default: false,
    },

    last_message_at: {
      type: Date,
      default: Date.now,
    },

    unread_count: {
      type: Map,
      of: Number,
      default: {},
    },
  },
  { timestamps: true }
);

const Conversation = mongoose.model("Conversation", conversationSchema);
module.exports = Conversation;
