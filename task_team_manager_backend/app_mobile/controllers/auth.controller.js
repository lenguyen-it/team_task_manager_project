const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const ApiError = require("../api-error");
const MongoDB = require("../utils/mongodb.util");
const EmployeeService = require("../services/employee.service");
const activityLogger = require("../helpers/activitylog.helper");

const secret = process.env.JWT_SECRET || "your_jwt_secret_key";
const expiresIn = process.env.JWT_EXPIRES_IN || "24h";

// Đăng nhập: Sử dụng employee_id và password
exports.login = async (req, res, next) => {
  const { employee_id, employee_password } = req.body;

  if (!employee_id || !employee_password) {
    return next(new ApiError(400, "Employee ID and password are required"));
  }

  try {
    const employeeService = new EmployeeService();
    const employee = await employeeService.findByEmployeeId(employee_id);

    if (!employee) {
      await activityLogger.loginFailed(
        req,
        employee_id,
        "unknown",
        "Employee not found"
      );
      return next(new ApiError(404, "Employee not found"));
    }

    const isMatch = await bcrypt.compare(
      employee_password,
      employee.employee_password
    );

    if (!isMatch) {
      await activityLogger.loginFailed(
        req,
        employee.employee_id,
        employee.role_id,
        "Incorrect password"
      );
      return next(new ApiError(401, "Password is incorrect"));
    }

    // Tạo JWT chứa employee_id và role_id
    const token = jwt.sign(
      {
        employee_id: employee.employee_id,
        employee_name: employee.employee_name,
        role_id: employee.role_id,
      },
      secret,
      { expiresIn }
    );

    // Log login success
    await activityLogger.login(
      req,
      employee.employee_id,
      employee.role_id,
      `${employee.employee_name} logged in successfully`
    );

    res.json({
      token,
      employee: {
        employee_id: employee.employee_id,
        employee_name: employee.employee_name,
        role_id: employee.role_id,
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    return next(new ApiError(500, "Error logging in: " + error.message));
  }
};

// Đăng xuất
exports.logout = async (req, res, next) => {
  try {
    const { employee_id, role_id, employee_name } = req.employee;

    await activityLogger.logout(
      req,
      employee_id,
      role_id,
      `${employee_name} logout successfully`
    );

    res.json({
      success: true,
      message: "Logged out successfully",
    });
  } catch (error) {
    console.error("Logout error:", error);
    return next(new ApiError(500, "Error logging out: " + error.message));
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
    const employeeService = new EmployeeService();

    const image = req.file ? `/uploads/${req.file.filename}` : null;
    const employee = await employeeService.create(req.body, image);

    await activityLogger.createEmployee(
      employee.employee_id,
      employee.role_id,
      employee.employee_id,
      {
        name: employee.employee_name,
        email: employee.email,
        role: employee.role_id,
      }
    );

    res.status(201).json({
      success: true,
      message: "Employee registered successfully",
      employee: {
        employee_id: employee.employee_id,
        employee_name: employee.employee_name,
        email: employee.email,
        role_id: employee.role_id,
      },
    });
  } catch (error) {
    console.error("Registration error:", error);
    return next(
      new ApiError(500, "Error registering employee: " + error.message)
    );
  }
};
