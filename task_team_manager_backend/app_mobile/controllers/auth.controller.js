const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const Employee = require("../models/employee.model");
const Role = require("../models/role.model");

// ✅ Đăng nhập bằng employee_id
exports.login = async (req, res) => {
  try {
    const { employee_id, password } = req.body;

    const employee = await Employee.findOne({ employee_id });
    if (!employee) {
      return res.status(404).json({ message: "Không tìm thấy tài khoản." });
    }

    const isMatch = await bcrypt.compare(password, employee.employee_password);
    if (!isMatch) {
      return res.status(400).json({ message: "Sai mật khẩu." });
    }

    // Tìm Role theo role_id (string)
    const role = await Role.findOne({ role_id: employee.role_id });

    // Tạo token
    const token = jwt.sign(
      { employee_id: employee.employee_id },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    return res.status(200).json({
      message: "Đăng nhập thành công.",
      token,
      employee: {
        employee_id: employee.employee_id,
        name: employee.employee_name,
        role: role?.role_name || "Unknown",
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ message: "Lỗi máy chủ." });
  }
};

// ✅ Đăng ký (chỉ role cao được phép)
exports.register = async (req, res) => {
  try {
    const { employee_id, employee_name, role_id, email, phone, password } =
      req.body;

    // Kiểm tra role người tạo tài khoản (Admin/Manager)
    const creator = req.employee;
    const creatorRole = creator?.role_info?.role_id;

    if (!["admin", "manager"].includes(creatorRole)) {
      return res
        .status(403)
        .json({ message: "Bạn không có quyền tạo tài khoản mới." });
    }

    // Kiểm tra trùng employee_id
    const existing = await Employee.findOne({ employee_id });
    if (existing) {
      return res.status(400).json({ message: "employee_id đã tồn tại." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newEmployee = new Employee({
      employee_id,
      employee_name,
      role_id,
      email,
      phone,
      employee_password: hashedPassword,
    });

    await newEmployee.save();

    res.status(201).json({
      message: "Tạo tài khoản thành công.",
      employee_id: newEmployee.employee_id,
    });
  } catch (error) {
    console.error("Register error:", error);
    res.status(500).json({ message: "Lỗi máy chủ." });
  }
};
