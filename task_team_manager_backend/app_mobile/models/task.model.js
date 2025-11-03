const mongoose = require("mongoose");

const taskSchema = new mongoose.Schema({
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
});

const Task = mongoose.model("Task", taskSchema);
module.exports = Task;
