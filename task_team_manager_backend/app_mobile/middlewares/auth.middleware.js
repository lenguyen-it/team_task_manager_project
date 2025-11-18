const jwt = require("jsonwebtoken");
const ApiError = require("../api-error");
const MongoDB = require("../utils/mongodb.util");
const EmployeeService = require("../services/employee.service");
const RoleService = require("../services/role.service");

const secret = process.env.JWT_SECRET || "your_jwt_secret_key";

// Middleware xác thực JWT
const verifyToken = async (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];

  if (!token) {
    return next(new ApiError(401, "No token provided"));
  }

  try {
    const decoded = jwt.verify(token, secret);
    req.employee = decoded;
    next();
  } catch (error) {
    return next(new ApiError(403, "Invalid token"));
  }
};

// Middleware phân quyền dựa trên role
const authorize = (roles = []) => {
  return async (req, res, next) => {
    // const employeeService = new EmployeeService(MongoDB.client);
    // const roleService = new RoleService(MongoDB.client);

    const employeeService = new EmployeeService();
    const roleService = new RoleService();

    try {
      const employee = await employeeService.findByEmployeeId(
        req.employee.employee_id
      );
      if (!employee) {
        return next(new ApiError(404, "Employee not found"));
      }

      const role = await roleService.findByRoleId(employee.role_id);
      if (!role) {
        return next(new ApiError(404, "Role not found"));
      }

      if (roles.length && !roles.includes(employee.role_id)) {
        return next(
          new ApiError(403, "Access denied: Insufficient permissions")
        );
      }

      req.employee = employee;
      next();
    } catch (error) {
      return next(new ApiError(500, "Error authorizing: " + error.message));
    }
  };
};

module.exports = { verifyToken, authorize };
