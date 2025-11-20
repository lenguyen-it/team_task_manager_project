const mongoose = require("mongoose");

const projectSchema = new mongoose.Schema(
  {
    project_id: {
      type: String,
      unique: true,
      required: [true, "ID project is required"],
    },

    parent_project_id: {
      type: String,
      ref: "Project",
      default: null,
    },

    project_name: {
      type: String,
      required: [true, "Name project is required"],
    },

    project_manager_id: {
      type: String,
      ref: "Employee",
      required: [true, "Manager project is required"],
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
      enum: ["planning", "in_progress", "done", "cancelled"],
      default: "planning",
    },
  },
  { timestamps: true }
);

const Project = mongoose.model("Project", projectSchema);
module.exports = Project;
