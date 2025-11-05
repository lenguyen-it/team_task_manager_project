const mongoose = require("mongoose");

const tasktypeSchema = new mongoose.Schema({
  task_type_id: {
    type: String,
    unique: true,
    required: [true, "Task Type id is required"],
  },

  task_type_name: {
    type: String,
    required: [true, "Task type name is required"],
  },

  description: {
    type: String,
    default: "No description task type yet",
  },
});

const TaskType = mongoose.model("TaskType", tasktypeSchema);
module.exports = TaskType;
