const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema({
  employee_id: {
    type: String,
    ref: "Employee",
    required: true,
  },

  actor_id: {
    type: String,
    ref: "Employee",
    required: true,
  },

  task_id: {
    type: String,
    ref: "Task",
    required: true,
  },

  type: {
    type: String,
    required: true,
    enum: [
      "task_assigned",
      "task_updated",
      "task_deadline_near",
      "task_overdue",
      "task_confirmed",
      "task_completed",
      "task_comment",
    ],
  },

  message: {
    type: String,
    required: true,
  },

  isRead: {
    type: Boolean,
    default: false,
  },

  read_at: {
    type: Date,
    default: null,
  },

  create_at: {
    type: Date,
    default: Date.now,
    required: true,
  },

  //Thêm thông tin bổ sung
  metadata: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
});
const Notification = mongoose.model("Notification", notificationSchema);
module.exports = Notification;
