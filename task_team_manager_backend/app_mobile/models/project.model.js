const mongoose = require("mongoose");

const projectSchema = new mongoose.Schema({
  project_id: {
    type: String,
    required: [true, "ID project is required"],
  },

  project_name: {
    type: String,
    required: [true, "Name project is required"],
  },

  description: {
    type: String,
    default: "No description yet ",
  },

  start_date: {
    type: Date,
    default: Date.now,
  },

  end_date: {
    type: Date,
  },

  status: {
    type: String,
    enum: ["planning", "on_process", "done"],
  },
});

const Project = mongoose.model("Project", projectSchema);
module.exports = Project;
