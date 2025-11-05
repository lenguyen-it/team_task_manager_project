const mongoose = require("mongoose");

const roleSchema = new mongoose.Schema({
  role_id: {
    type: String,
    unique: true,
    required: [true, "Role Id is required"],
  },

  role_name: {
    type: String,
    required: [true, "Role name is required"],
  },

  description: {
    type: String,
    default: "No description yet ",
  },
});

const Role = mongoose.model("Role", roleSchema);
module.exports = Role;
