const mongoose = require("mongoose");

const attachmentSchema = new mongoose.Schema({
  file_name: String,
  file_url: String,
  file_type: String,
  size: Number,
  uploaded_at: { type: Date, default: Date.now },
  uploaded_by: { type: String, ref: "Employee" },
});

const taskSchema = new mongoose.Schema(
  {
    task_id: {
      type: String,
      unique: true,
      required: [true, "Task Id is required"],
    },

    task_name: {
      type: String,
      required: [true, "Task name is required"],
    },

    project_id: {
      type: String,
      ref: "Project",
      required: [true, "Project id required"],
    },

    task_type_id: {
      type: String,
      ref: "TaskType",
      required: [true, "Task type id is required"],
    },

    parent_task_id: {
      type: String,
      ref: "Task",
      default: null,
    },

    assigned_to: [
      {
        type: String,
        ref: "Employee",
      },
    ],

    description: {
      type: String,
      default: "No description task type yet",
    },

    start_date: { type: Date, default: Date.now },

    end_date: { type: Date },

    priority: { type: String, enum: ["high", "normal", "low"] },

    status: {
      type: String,
      enum: ["in_progress", "new_task", "pause", "done", "wait"],
    },

    attachments: [attachmentSchema],
  },
  { timestamps: true }
);

const Task = mongoose.model("Task", taskSchema);
module.exports = Task;
