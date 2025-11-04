const jwt = require("jsonwebtoken");
const Employee = require("../models/employee.model");
const Role = require("../models/role.model");

const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers["authorization"];
    const token = authHeader && authHeader.split(" ")[1];

    if (!token) {
      return res
        .status(401)
        .json({ message: "Không có token, truy cập bị từ chối." });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const employee = await Employee.findOne({
      employee_id: decoded.employee_id,
    });
    if (!employee) {
      return res.status(404).json({ message: "Không tìm thấy nhân viên." });
    }

    const role = await Role.findOne({ role_id: employee.role_id });
    employee.role_info = role;

    req.employee = employee;
    next();
  } catch (error) {
    console.error("Auth middleware error:", error);
    res.status(403).json({ message: "Token không hợp lệ hoặc đã hết hạn." });
  }
};

module.exports = authMiddleware;
