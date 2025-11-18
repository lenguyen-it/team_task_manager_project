const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const ApiError = require("../api-error");
const MongoDB = require("../utils/mongodb.util");
const EmployeeService = require("../services/employee.service");

const secret = process.env.JWT_SECRET || "your_jwt_secret_key";
const expiresIn = process.env.JWT_EXPIRES_IN || "24h";

// Đăng nhập: Sử dụng employee_id và password
exports.login = async (req, res, next) => {
  const { employee_id, employee_password } = req.body;

  if (!employee_id || !employee_password) {
    return next(new ApiError(400, "Employee ID and password are required"));
  }

  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const employee = await employeeService.findByEmployeeId(employee_id);

    if (!employee) {
      return next(new ApiError(404, "Employee not found"));
    }

    const isMatch = await bcrypt.compare(
      employee_password,
      employee.employee_password
    );
    if (!isMatch) {
      return next(new ApiError(401, "Password is incorrect"));
    }

    // Tạo JWT chứa employee_id và role_id
    const token = jwt.sign(
      { employee_id: employee.employee_id, role_id: employee.role_id },
      secret,
      { expiresIn }
    );

    res.json({
      token,
      employee: {
        employee_id: employee.employee_id,
        role_id: employee.role_id,
      },
    });
  } catch (error) {
    return next(new ApiError(500, "Error logging in: " + error.message));
  }
};

// Đăng ký tài khoản mới (tạo employee mới)
exports.register = async (req, res, next) => {
  if (
    !req.body?.employee_id ||
    !req.body?.employee_name ||
    !req.body?.employee_password ||
    !req.body?.role_id ||
    !req.body?.email
  ) {
    return next(new ApiError(400, "Required fields cannot be empty"));
  }

  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const image = req.file ? `/uploads/${req.file.filename}` : null;
    const employee = await employeeService.create(req.body, image);

    res.status(201).json({
      message: "Employee registered successfully",
      employee_name: employee.employee_name,
      employee,
    });
  } catch (error) {
    return next(
      new ApiError(500, "Error registering employee: " + error.message)
    );
  }
};
