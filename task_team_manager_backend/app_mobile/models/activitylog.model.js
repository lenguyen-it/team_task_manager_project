const mongoose = require("mongoose");

const activitylogSchema = new mongoose.Schema(
  {
    employee_id: {
      type: String,
      ref: "Employee",
      required: true,
    },

    role_id: {
      type: String,
      ref: "Role",
      required: true,
    },

    action: {
      type: String,
      required: true,
      enum: [
        // Auth
        "login",
        "logout",
        "login_failed",

        // Task actions
        "create_task",
        "update_task",
        "delete_task",
        "assign_task",
        "complete_task",
        "confirm_task",

        // User/Employee actions
        "create_employee",
        "update_employee",
        "delete_employee",
        "change_role",

        // Project actions
        "create_project",
        "update_project",
        "delete_project",

        // Other
        "export_data",
        "view_report",
      ],
    },

    // Đối tượng bị tác động
    target_type: {
      type: String,
      enum: ["task", "employee", "project", "role", "system"],
      default: null,
    },

    target_id: {
      type: String,
      default: null,
    },

    // Chi tiết thay đổi
    changes: [
      {
        field: String,
        old_value: mongoose.Schema.Types.Mixed,
        new_value: mongoose.Schema.Types.Mixed,
      },
    ],

    status: {
      type: String,
      enum: ["success", "failed"],
      default: "success",
    },

    description: {
      type: String,
      default: null,
    },
  },
  { timestamps: true }
);

const ActivityLog = mongoose.model("Activity_Log", activitylogSchema);
module.exports = ActivityLog;
