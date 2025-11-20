const ApiError = require("../api-error");
const EmployeeService = require("../services/employee.service");
const activityLogger = require("../helpers/activitylog.helper");
const NotificationHelper = require("../helpers/notification.helper");

exports.create = async (req, res, next) => {
  console.log("req.body: ", req.body);
  console.log("req.file:", req.file);

  if (!req.body?.employee_id && !req.body.employee_name) {
    return next(new ApiError(400, "Employee id and name cannot be empty"));
  }

  try {
    const employeeService = new EmployeeService();

    const image = req.file ? `/uploads/images/${req.file.filename}` : null;
    const employee = await employeeService.create(req.body, image);

    // Log tạo employee mới
    await activityLogger.createEmployee(
      req.employee?.employee_id || employee.employee_id,
      req.employee?.role_id || employee.role_id,
      employee.employee_id,
      {
        name: employee.employee_name,
        email: employee.email,
        role: employee.role_id,
        phone: employee.phone,
      }
    );

    // Gửi thông báo cho nhân viên mới được tạo
    if (req.employee?.employee_id !== employee.employee_id) {
      await NotificationHelper.sendEmployeeNotification({
        type: "employee_created",
        employee: employee,
        actor: NotificationHelper.getActor(req),
        recipients: [employee.employee_id],
      });
    }

    res.status(201).json({
      success: true,
      message: "Employee created successfully",
      data: employee,
    });
  } catch (error) {
    return next(new ApiError(500, "Error creating employee: " + error.message));
  }
};

exports.findAll = async (req, res, next) => {
  let data = [];

  try {
    const employeeService = new EmployeeService();
    const { employee_name } = req.query;

    if (employee_name) {
      data = await employeeService.findByEmployeeName(employee_name);
    } else {
      data = await employeeService.find({});
    }
  } catch (error) {
    return next(
      new ApiError(500, "Error retrieving employees: " + error.message)
    );
  }

  return res.send(data);
};

exports.findOne = async (req, res, next) => {
  try {
    const employeeService = new EmployeeService();
    const employee = await employeeService.findById(req.params.id);

    if (!employee) {
      return next(new ApiError(404, "Employee not found"));
    }

    return res.send(employee);
  } catch (error) {
    return next(
      new ApiError(500, "Error retrieving employee: " + error.message)
    );
  }
};

exports.findByEmployeeId = async (req, res, next) => {
  try {
    const employeeService = new EmployeeService();
    const employee = await employeeService.findByEmployeeId(
      req.params.employee_id
    );
    if (!employee) {
      return next(new ApiError(404, "Employee not found"));
    }
    res.json(employee);
  } catch (error) {
    return next(
      new ApiError(500, "Error retrieving employee: " + error.message)
    );
  }
};

exports.findByEmployeeName = async (req, res, next) => {
  try {
    const employeeService = new EmployeeService();
    const employees = await employeeService.findByEmployeeName(
      req.query.employee_name || ""
    );
    res.json(employees);
  } catch (error) {
    return next(
      new ApiError(500, "Error searching employees: " + error.message)
    );
  }
};

exports.update = async (req, res, next) => {
  try {
    const employeeService = new EmployeeService();

    // Lấy employee cũ để so sánh thay đổi
    const oldEmployee = await employeeService.findById(req.params.id);
    if (!oldEmployee) {
      return next(new ApiError(404, "Employee not found"));
    }

    const image = req.file
      ? `/uploads/images/${req.file.filename}`
      : req.body.image || null;

    const updated = await employeeService.update(
      req.params.id,
      req.body,
      image
    );

    if (!updated.value) {
      return next(new ApiError(404, "Employee not found"));
    }

    // Track changes
    const changes = [];
    const notificationChanges = []; // Để hiển thị trong thông báo

    if (
      req.body.employee_name &&
      req.body.employee_name !== oldEmployee.employee_name
    ) {
      changes.push({
        field: "employee_name",
        old_value: oldEmployee.employee_name,
        new_value: req.body.employee_name,
      });
      notificationChanges.push(`Tên: ${req.body.employee_name}`);
    }
    if (req.body.email && req.body.email !== oldEmployee.email) {
      changes.push({
        field: "email",
        old_value: oldEmployee.email,
        new_value: req.body.email,
      });
      notificationChanges.push(`Email: ${req.body.email}`);
    }
    if (req.body.phone && req.body.phone !== oldEmployee.phone) {
      changes.push({
        field: "phone",
        old_value: oldEmployee.phone,
        new_value: req.body.phone,
      });
      notificationChanges.push(`SĐT: ${req.body.phone}`);
    }
    if (req.body.role_id && req.body.role_id !== oldEmployee.role_id) {
      // Log change role riêng
      await activityLogger.changeRole(
        req.employee?.employee_id,
        req.employee?.role_id,
        oldEmployee.employee_id,
        oldEmployee.role_id,
        req.body.role_id
      );

      // Gửi thông báo thay đổi quyền
      await NotificationHelper.sendEmployeeNotification({
        type: "employee_role_changed",
        employee: updated.value,
        actor: NotificationHelper.getActor(req),
        recipients: [oldEmployee.employee_id],
        customMessage: `${
          NotificationHelper.getActor(req).name
        } đã thay đổi quyền của bạn từ "${oldEmployee.role_id}" sang "${
          req.body.role_id
        }"`,
      });
    }
    if (image && image !== oldEmployee.image) {
      changes.push({
        field: "image",
        old_value: "Updated",
        new_value: "New image",
      });
      notificationChanges.push("Ảnh đại diện");
    }

    // Log update employee nếu có thay đổi (không tính role_id vì đã log riêng)
    if (changes.length > 0) {
      await activityLogger.updateEmployee(
        req.employee?.employee_id,
        req.employee?.role_id,
        oldEmployee.employee_id,
        changes,
        `Updated employee: ${updated.value.employee_name}`
      );

      // Gửi thông báo cập nhật thông tin (không tính role vì đã gửi riêng)
      if (
        notificationChanges.length > 0 &&
        req.employee?.employee_id !== oldEmployee.employee_id
      ) {
        await NotificationHelper.sendEmployeeNotification({
          type: "employee_updated",
          employee: updated.value,
          actor: NotificationHelper.getActor(req),
          recipients: [oldEmployee.employee_id],
          customMessage: `${
            NotificationHelper.getActor(req).name
          } đã cập nhật thông tin của bạn: ${notificationChanges.join(", ")}`,
        });
      }
    }

    res.json({
      success: true,
      message: "Employee updated successfully",
      data: updated.value,
    });
  } catch (error) {
    return next(new ApiError(500, "Error updating employee: " + error.message));
  }
};

exports.updateByEmployeeId = async (req, res, next) => {
  console.log("req.body:", req.body);
  console.log("req.file:", req.file);

  try {
    const employeeService = new EmployeeService();

    // Lấy employee cũ để so sánh
    const oldEmployee = await employeeService.findByEmployeeId(
      req.params.employee_id
    );
    if (!oldEmployee) {
      return next(new ApiError(404, "Employee not found"));
    }

    const image = req.file
      ? `/uploads/images/${req.file.filename}`
      : req.body.image || null;

    console.log("Image path to save:", image);

    const updated = await employeeService.updateByEmployeeId(
      req.params.employee_id,
      req.body,
      image
    );

    if (!updated) {
      return next(new ApiError(404, "Employee not found"));
    }

    // Track changes
    const changes = [];
    const notificationChanges = [];

    if (
      req.body.employee_name &&
      req.body.employee_name !== oldEmployee.employee_name
    ) {
      changes.push({
        field: "employee_name",
        old_value: oldEmployee.employee_name,
        new_value: req.body.employee_name,
      });
      notificationChanges.push(`Tên: ${req.body.employee_name}`);
    }
    if (req.body.email && req.body.email !== oldEmployee.email) {
      changes.push({
        field: "email",
        old_value: oldEmployee.email,
        new_value: req.body.email,
      });
      notificationChanges.push(`Email: ${req.body.email}`);
    }
    if (req.body.phone && req.body.phone !== oldEmployee.phone) {
      changes.push({
        field: "phone",
        old_value: oldEmployee.phone,
        new_value: req.body.phone,
      });
      notificationChanges.push(`SĐT: ${req.body.phone}`);
    }
    if (req.body.role_id && req.body.role_id !== oldEmployee.role_id) {
      // Log change role riêng
      await activityLogger.changeRole(
        req.employee?.employee_id,
        req.employee?.role_id,
        oldEmployee.employee_id,
        oldEmployee.role_id,
        req.body.role_id
      );

      // Gửi thông báo thay đổi quyền
      await NotificationHelper.sendEmployeeNotification({
        type: "employee_role_changed",
        employee: updated,
        actor: NotificationHelper.getActor(req),
        recipients: [oldEmployee.employee_id],
        customMessage: `${
          NotificationHelper.getActor(req).name
        } đã thay đổi quyền của bạn từ "${oldEmployee.role_id}" sang "${
          req.body.role_id
        }"`,
      });
    }
    if (image && image !== oldEmployee.image) {
      changes.push({
        field: "image",
        old_value: "Updated",
        new_value: "New image",
      });
      notificationChanges.push("Ảnh đại diện");
    }

    // Log update employee
    if (changes.length > 0) {
      await activityLogger.updateEmployee(
        req.employee?.employee_id,
        req.employee?.role_id,
        oldEmployee.employee_id,
        changes,
        `Updated employee: ${updated.employee_name}`
      );

      // Gửi thông báo cập nhật thông tin
      if (
        notificationChanges.length > 0 &&
        req.employee?.employee_id !== oldEmployee.employee_id
      ) {
        await NotificationHelper.sendEmployeeNotification({
          type: "employee_updated",
          employee: updated,
          actor: NotificationHelper.getActor(req),
          recipients: [oldEmployee.employee_id],
          customMessage: `${
            NotificationHelper.getActor(req).name
          } đã cập nhật thông tin của bạn: ${notificationChanges.join(", ")}`,
        });
      }
    }

    console.log("Updated employee:", updated);
    res.json({
      success: true,
      message: "Employee updated successfully",
      data: updated,
    });
  } catch (error) {
    return next(new ApiError(500, "Error updating employee: " + error.message));
  }
};

exports.delete = async (req, res, next) => {
  try {
    const employeeService = new EmployeeService();

    // Lấy thông tin employee trước khi xóa
    const employee = await employeeService.findById(req.params.id);
    if (!employee) {
      return next(new ApiError(404, "Employee not found"));
    }

    // Gửi thông báo trước khi xóa
    if (req.employee?.employee_id !== employee.employee_id) {
      await NotificationHelper.sendEmployeeNotification({
        type: "employee_deleted",
        employee: employee,
        actor: NotificationHelper.getActor(req),
        recipients: [employee.employee_id],
        customMessage: `${
          NotificationHelper.getActor(req).name
        } đã xóa tài khoản của bạn khỏi hệ thống`,
      });
    }

    const deleted = await employeeService.delete(req.params.id);

    if (!deleted.value) {
      return next(new ApiError(404, "Employee not found"));
    }

    // Log delete employee
    await activityLogger.deleteEmployee(
      req.employee?.employee_id,
      req.employee?.role_id,
      employee.employee_id,
      employee.employee_name
    );

    res.json({
      success: true,
      message: "Employee deleted successfully",
    });
  } catch (error) {
    return next(new ApiError(500, "Error deleting employee: " + error.message));
  }
};

exports.deleteByEmployeeId = async (req, res, next) => {
  try {
    const employeeService = new EmployeeService();

    // Lấy thông tin employee trước khi xóa
    const employee = await employeeService.findByEmployeeId(
      req.params.employee_id
    );
    if (!employee) {
      return next(new ApiError(404, "Employee not found"));
    }

    // Gửi thông báo trước khi xóa
    if (req.employee?.employee_id !== employee.employee_id) {
      await NotificationHelper.sendEmployeeNotification({
        type: "employee_deleted",
        employee: employee,
        actor: NotificationHelper.getActor(req),
        recipients: [employee.employee_id],
        customMessage: `${
          NotificationHelper.getActor(req).name
        } đã xóa tài khoản của bạn khỏi hệ thống`,
      });
    }

    const deleted = await employeeService.deleteByEmployeeId(
      req.params.employee_id
    );

    if (!deleted) {
      return next(new ApiError(404, "Employee not found"));
    }

    // Log delete employee
    await activityLogger.deleteEmployee(
      req.employee?.employee_id,
      req.employee?.role_id,
      employee.employee_id,
      employee.employee_name
    );

    res.json({
      success: true,
      message: "Employee deleted successfully",
    });
  } catch (error) {
    return next(new ApiError(500, "Error deleting employee: " + error.message));
  }
};

exports.deleteAll = async (req, res, next) => {
  try {
    const employeeService = new EmployeeService();
    const deletedCount = await employeeService.deleteAll();

    // Log bulk delete (action cực kỳ nguy hiểm)
    if (deletedCount > 0) {
      await activityLogger.custom({
        employee_id: req.employee?.employee_id || "system",
        role_id: req.employee?.role_id || "admin",
        action: "delete_employee",
        target_type: "employee",
        description: `⚠️ BULK DELETE: Deleted all employees (${deletedCount} employees)`,
        status: "success",
      });
    }

    res.json({
      success: true,
      message: `${deletedCount} employees deleted successfully`,
    });
  } catch (error) {
    return next(
      new ApiError(500, "Error deleting all employees: " + error.message)
    );
  }
};
