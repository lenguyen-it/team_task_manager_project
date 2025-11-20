const Notification = require("../models/notification.model");

class NotificationHelper {
  static getActor(req) {
    return {
      id: req.employee?.employee_id || req.employee?._id || "unknown",
      name: req.employee?.employee_name || "Ai đó",
    };
  }

  // Gửi thông báo cho Task
  static async sendTaskNotification({
    type,
    task,
    actor,
    recipients,
    customMessage = null,
  }) {
    const recipientIds = Array.isArray(recipients) ? recipients : [recipients];
    if (recipientIds.length === 0) return [];

    const messageTemplates = {
      task_assigned: `{actorName} đã giao cho bạn nhiệm vụ: "{taskName}"`,
      task_updated: `{actorName} đã cập nhật nhiệm vụ: "{taskName}"`,
      task_completed: `{actorName} đã hoàn thành nhiệm vụ: "{taskName}"`,
      task_confirmed: `{actorName} đã xác nhận nhiệm vụ: "{taskName}"`,
      task_comment: `{actorName} đã bình luận về nhiệm vụ: "{taskName}"`,
      task_deadline_near: `Nhiệm vụ sắp đến hạn "{taskName}"`,
      task_overdue: `Nhiệm vụ đã quá hạn "{taskName}"`,
    };

    const message =
      customMessage ||
      messageTemplates[type]
        ?.replace("{actorName}", actor.name)
        .replace("{taskName}", task.task_name);

    const notifications = recipientIds.map((employeeId) => ({
      employee_id: employeeId,
      actor_id: actor.id,
      task_id: task.task_id,
      type,
      message,
      metadata: {
        task_id: task.task_id,
        task_name: task.task_name,
        status: task.status,
        priority: task.priority,
        project_id: task.project_id,
      },
    }));

    return await Notification.insertMany(notifications);
  }

  // Gửi thông báo cho Role
  static async sendRoleNotification({
    type,
    role,
    actor,
    recipients,
    customMessage = null,
  }) {
    const recipientIds = Array.isArray(recipients) ? recipients : [recipients];
    if (recipientIds.length === 0) return [];

    const messageTemplates = {
      role_update: `{actorName} đã cập nhật quyền "{roleName}" cho bạn`,
      role_assigned: `{actorName} đã gán cho bạn vai trò: "{roleName}"`,
    };

    const message =
      customMessage ||
      messageTemplates[type]
        ?.replace("{actorName}", actor.name)
        .replace("{roleName}", role.role_name);

    const notifications = recipientIds.map((employeeId) => ({
      employee_id: employeeId,
      actor_id: actor.id,
      task_id: role.role_id, // Dùng role_id thay vì task_id
      type,
      message,
      metadata: {
        role_id: role.role_id,
        role_name: role.role_name,
        permissions: role.permissions || [],
      },
    }));

    return await Notification.insertMany(notifications);
  }

  // Gửi thông báo cho Project
  static async sendProjectNotification({
    type,
    project,
    actor,
    recipients,
    customMessage = null,
  }) {
    const recipientIds = Array.isArray(recipients) ? recipients : [recipients];
    if (recipientIds.length === 0) return [];

    const messageTemplates = {
      project_assigned: `{actorName} đã giao cho bạn quản lý dự án: "{projectName}"`,
      project_updated: `{actorName} đã cập nhật dự án: "{projectName}"`,
      project_completed: `Dự án "{projectName}" đã hoàn thành`,
      project_deadline_near: `Dự án "{projectName}" sắp đến hạn`,
    };

    const message =
      customMessage ||
      messageTemplates[type]
        ?.replace("{actorName}", actor.name)
        .replace("{projectName}", project.project_name);

    const notifications = recipientIds.map((employeeId) => ({
      employee_id: employeeId,
      actor_id: actor.id,
      task_id: project.project_id,
      type,
      message,
      metadata: {
        project_id: project.project_id,
        project_name: project.project_name,
        status: project.status,
        deadline: project.deadline,
      },
    }));

    return await Notification.insertMany(notifications);
  }

  // Gửi thông báo cho Employee
  static async sendEmployeeNotification({
    type,
    employee,
    actor,
    recipients,
    customMessage = null,
  }) {
    const recipientIds = Array.isArray(recipients) ? recipients : [recipients];
    if (recipientIds.length === 0) return [];

    const messageTemplates = {
      employee_created: `Chào mừng {employeeName}! Tài khoản của bạn đã được {actorName} tạo thành công`,
      employee_updated: `{actorName} đã cập nhật thông tin của bạn`,
      employee_role_changed: `{actorName} đã thay đổi quyền của bạn`,
      employee_deleted: `{actorName} đã xóa tài khoản của bạn khỏi hệ thống`,
    };

    const message =
      customMessage ||
      messageTemplates[type]
        ?.replace("{actorName}", actor.name)
        .replace("{employeeName}", employee.employee_name);

    const notifications = recipientIds.map((employeeId) => ({
      employee_id: employeeId,
      actor_id: actor.id,
      task_id: employee.employee_id,
      type,
      message,
      metadata: {
        employee_id: employee.employee_id,
        employee_name: employee.employee_name,
        email: employee.email,
        role_id: employee.role_id,
      },
    }));

    return await Notification.insertMany(notifications);
  }
}

module.exports = NotificationHelper;
