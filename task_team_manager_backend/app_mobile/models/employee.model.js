const mongoose = require("mongoose");

const employeeSchema = mongoose.Schema(
  {
    employee_id: {
      type: String,
      unique: true,
      required: [true, "Employee Id is required"],
    },

    employee_name: {
      type: String,
      required: [true, "Employee name is required"],
    },

    role_id: {
      type: String,
      ref: "Role",
      required: [true, "Role for Employee is required"],
    },

    email: {
      type: String,
      unique: true,
      required: [true, "Email is required"],
    },

    phone: {
      type: String,
    },

    birth: {
      type: Date,
    },

    address: {
      type: String,
    },

    image: {
      type: String,
      default: "",
    },

    employee_password: {
      type: String,
      required: [true, "Password is required"],
    },

    // Các trường bổ sung cho đoạn chat
    is_online: {
      type: Boolean,
      default: false,
    },

    last_active: {
      type: Date,
      default: Date.now,
    },

    socket_id: {
      type: String,
      default: "",
    },
  },
  { timestamps: true }
);

const Employee = mongoose.model("Employee", employeeSchema);
module.exports = Employee;
