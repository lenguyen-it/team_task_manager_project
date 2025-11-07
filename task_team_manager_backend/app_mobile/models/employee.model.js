const mongoose = require("mongoose");

const employeeSchema = mongoose.Schema({
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
    type: Number,
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
});

const Employee = mongoose.model("Employee", employeeSchema);
module.exports = Employee;
