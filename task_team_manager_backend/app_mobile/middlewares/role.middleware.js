// ✅ Kiểm tra quyền truy cập dựa trên role_id + hiển thị cả role_name
module.exports = (roles = []) => {
  if (typeof roles === "string") {
    roles = [roles];
  }

  return (req, res, next) => {
    try {
      const employee = req.employee;

      if (!employee || !employee.role_info) {
        return res.status(403).json({ message: "Không có quyền truy cập." });
      }

      const { role_id: roleId, role_name: roleName } = employee.role_info;

      if (!roles.includes(roleId)) {
        return res.status(403).json({
          message: `Quyền truy cập bị từ chối. Role hiện tại: '${roleName}' (ID: ${roleId}) không đủ để truy cập tài nguyên này.`,
        });
      }

      next();
    } catch (error) {
      console.error("Role middleware error:", error);
      res.status(500).json({ message: "Lỗi xác thực phân quyền." });
    }
  };
};
