const ApiError = require("../api-error");
const TaskService = require("../services/task.service");
const NotificationHelper = require("../helpers/notification.helper");
const activityLogger = require("../helpers/activitylog.helper");

exports.create = async (req, res, next) => {
  try {
    if (!req.body?.task_name || !req.body?.task_id) {
      return next(new ApiError(400, "Task name và task_id là bắt buộc"));
    }

    const taskService = new TaskService();
    const createdTask = await taskService.create(req.body);

    // Log tạo task
    await activityLogger.createTask(
      req.employee?.employee_id || req.body.created_by,
      req.employee?.role_id,
      createdTask.task_id,
      {
        title: createdTask.task_name,
        priority: createdTask.priority,
        status: createdTask.status,
      }
    );

    // Gửi thông báo khi tạo task
    if (createdTask.assigned_to?.length > 0) {
      await NotificationHelper.sendTaskNotification({
        type: "task_assigned",
        task: createdTask,
        actor: NotificationHelper.getActor(req),
        recipients: createdTask.assigned_to,
      });

      // Log assign task cho từng người được giao
      for (const assignee_id of createdTask.assigned_to) {
        await activityLogger.assignTask(
          req.employee?.employee_id || req.body.created_by,
          req.employee?.role_id,
          createdTask.task_id,
          assignee_id
        );
      }
    }

    return res.status(201).json({
      success: true,
      message: "Tạo nhiệm vụ thành công",
      data: createdTask,
      notification_sent_to: createdTask.assigned_to || [],
    });
  } catch (error) {
    console.error("Error creating task:", error);
    return next(new ApiError(500, "Không thể tạo nhiệm vụ: " + error.message));
  }
};

exports.findAll = async (req, res, next) => {
  let data = [];
  try {
    const taskService = new TaskService();
    const { task_name } = req.query;

    if (task_name) {
      data = await taskService.findByTaskName(task_name);
    } else {
      data = await taskService.find({});
    }
  } catch (error) {
    return next(new ApiError(500, "Error retrieving tasks: " + error.message));
  }
  return res.send(data);
};

exports.findByTaskId = async (req, res, next) => {
  try {
    const taskService = new TaskService();
    const task = await taskService.findByTaskId(req.params.task_id);
    if (!task) {
      return next(new ApiError(404, "Task not found"));
    }
    res.json(task);
  } catch (error) {
    return next(new ApiError(500, "Error retrieving task: " + error.message));
  }
};

exports.findOne = async (req, res, next) => {
  try {
    const taskService = new TaskService();
    const task = await taskService.findById(req.params.id);

    if (!task) {
      return next(new ApiError(404, "Task not found"));
    }

    return res.send(task);
  } catch (error) {
    return next(new ApiError(500, "Error retrieving task: " + error.message));
  }
};

exports.findByTaskName = async (req, res, next) => {
  try {
    const taskService = new TaskService();
    const tasks = await taskService.findByTaskName(req.params.task_name || "");
    res.json(tasks);
  } catch (error) {
    return next(new ApiError(500, "Error searching tasks: " + error.message));
  }
};

exports.findTaskByEmployee = async (req, res, next) => {
  const taskService = new TaskService();

  try {
    const { employee_id } = req.params;
    const tasks = await taskService.findTaskByEmployee(employee_id);
    res.status(200).json(tasks);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.update = async (req, res, next) => {
  if (
    Object.keys(req.body).length === 0 &&
    (!req.files || req.files.length === 0)
  ) {
    return next(new ApiError(400, "Data to update cannot be empty"));
  }

  try {
    const taskService = new TaskService();
    const employeeId =
      req.employee?.employee_id || req.body.employee_id || "unknown";

    // Lấy task cũ để so sánh thay đổi
    const oldTask = await taskService.findById(req.params.id);

    let updated = await taskService.update(req.params.id, req.body);

    if (req.files && req.files.length > 0) {
      updated = await taskService.addAttachments(
        req.params.id,
        req.files,
        employeeId
      );
    }

    if (!updated) {
      return next(new ApiError(404, "Task not found"));
    }

    // Log changes
    const changes = [];
    if (req.body.task_name && req.body.task_name !== oldTask.task_name) {
      changes.push({
        field: "task_name",
        old_value: oldTask.task_name,
        new_value: req.body.task_name,
      });
    }
    if (req.body.status && req.body.status !== oldTask.status) {
      changes.push({
        field: "status",
        old_value: oldTask.status,
        new_value: req.body.status,
      });
    }
    if (req.body.priority && req.body.priority !== oldTask.priority) {
      changes.push({
        field: "priority",
        old_value: oldTask.priority,
        new_value: req.body.priority,
      });
    }

    if (changes.length > 0) {
      await activityLogger.updateTask(
        employeeId,
        req.employee?.role_id,
        updated.task_id,
        changes,
        `Updated task: ${updated.task_name}`
      );
    }

    // Gửi thông báo khi cập nhật task
    if (updated.assigned_to?.length > 0) {
      await NotificationHelper.sendTaskNotification({
        type: "task_updated",
        task: updated,
        actor: NotificationHelper.getActor(req),
        recipients: updated.assigned_to,
      });
    }

    res.json({
      success: true,
      message: "Task updated successfully",
      data: updated,
      notification_sent_to: updated.assigned_to || [],
    });
  } catch (error) {
    return next(new ApiError(500, "Error updating task: " + error.message));
  }
};

exports.updateByTaskId = async (req, res, next) => {
  if (
    Object.keys(req.body).length === 0 &&
    (!req.files || req.files.length === 0)
  ) {
    return next(new ApiError(400, "Data to update cannot be empty"));
  }

  try {
    const taskService = new TaskService();
    const employeeId =
      req.employee?.employee_id || req.body.employee_id || "unknown";

    // Lấy task cũ để so sánh
    const oldTask = await taskService.findByTaskId(req.params.task_id);

    let updated = null;

    // Cập nhật thông tin task nếu có dữ liệu trong body
    if (Object.keys(req.body).length > 0) {
      updated = await taskService.updateByTaskId(req.params.task_id, req.body);
    }

    // Thêm attachments nếu có files
    if (req.files && req.files.length > 0) {
      updated = await taskService.addAttachmentsByTaskId(
        req.params.task_id,
        req.files,
        employeeId
      );
    }

    // Nếu chỉ có files mà không có body, lấy task hiện tại
    if (!updated) {
      updated = await taskService.findByTaskId(req.params.task_id);
    }

    if (!updated) {
      return next(new ApiError(404, "Task not found"));
    }

    // Log changes
    const changes = [];
    if (req.body.task_name && req.body.task_name !== oldTask.task_name) {
      changes.push({
        field: "task_name",
        old_value: oldTask.task_name,
        new_value: req.body.task_name,
      });
    }
    if (req.body.status && req.body.status !== oldTask.status) {
      changes.push({
        field: "status",
        old_value: oldTask.status,
        new_value: req.body.status,
      });
    }
    if (req.body.priority && req.body.priority !== oldTask.priority) {
      changes.push({
        field: "priority",
        old_value: oldTask.priority,
        new_value: req.body.priority,
      });
    }

    if (changes.length > 0) {
      await activityLogger.updateTask(
        employeeId,
        req.employee?.role_id,
        updated.task_id,
        changes
      );
    }

    // Gửi thông báo khi cập nhật task
    if (updated.assigned_to?.length > 0) {
      await NotificationHelper.sendTaskNotification({
        type: "task_updated",
        task: updated,
        actor: NotificationHelper.getActor(req),
        recipients: updated.assigned_to,
      });
    }

    res.json({
      success: true,
      message: "Task updated successfully",
      data: updated,
      notification_sent_to: updated.assigned_to || [],
    });
  } catch (error) {
    return next(new ApiError(500, "Error updating task: " + error.message));
  }
};

exports.addAttachments = async (req, res, next) => {
  if (!req.files || req.files.length === 0) {
    return next(new ApiError(400, "No files uploaded"));
  }

  try {
    const taskService = new TaskService();
    const employeeId =
      req.employee?.employee_id || req.body.uploadedBy || "unknown";
    const updatedTask = await taskService.addAttachments(
      req.params.id,
      req.files,
      employeeId
    );

    if (!updatedTask) {
      return next(new ApiError(404, "Task not found"));
    }

    // Log thêm attachments
    await activityLogger.updateTask(
      employeeId,
      req.employee?.role_id,
      updatedTask.task_id,
      [
        {
          field: "attachments",
          old_value: null,
          new_value: `Added ${req.files.length} file(s)`,
        },
      ],
      `Added ${req.files.length} attachment(s) to task`
    );

    // Gửi thông báo khi thêm attachments (coi như update)
    if (updatedTask.assigned_to?.length > 0) {
      await NotificationHelper.sendTaskNotification({
        type: "task_updated",
        task: updatedTask,
        actor: NotificationHelper.getActor(req),
        recipients: updatedTask.assigned_to,
        customMessage: `${
          NotificationHelper.getActor(req).name
        } đã thêm tệp đính kèm vào nhiệm vụ: "${updatedTask.task_name}"`,
      });
    }

    res.json({
      success: true,
      message: "Attachments added successfully",
      data: updatedTask,
      notification_sent_to: updatedTask.assigned_to || [],
    });
  } catch (error) {
    return next(
      new ApiError(500, "Error adding attachments: " + error.message)
    );
  }
};

exports.addAttachmentsByTaskId = async (req, res, next) => {
  if (!req.files || req.files.length === 0) {
    return next(new ApiError(400, "No files uploaded"));
  }

  try {
    const taskService = new TaskService();
    const employeeId =
      req.employee?.employee_id || req.body.uploadedBy || "unknown";
    const updatedTask = await taskService.addAttachmentsByTaskId(
      req.params.task_id,
      req.files,
      employeeId
    );

    if (!updatedTask) {
      return next(new ApiError(404, "Task not found"));
    }

    // Log thêm attachments
    await activityLogger.updateTask(
      employeeId,
      req.employee?.role_id,
      updatedTask.task_id,
      [
        {
          field: "attachments",
          old_value: null,
          new_value: `Added ${req.files.length} file(s)`,
        },
      ],
      `Added ${req.files.length} attachment(s) to task`
    );

    // Gửi thông báo khi thêm attachments
    if (updatedTask.assigned_to?.length > 0) {
      await NotificationHelper.sendTaskNotification({
        type: "task_updated",
        task: updatedTask,
        actor: NotificationHelper.getActor(req),
        recipients: updatedTask.assigned_to,
        customMessage: `${
          NotificationHelper.getActor(req).name
        } đã thêm tệp đính kèm vào nhiệm vụ: "${updatedTask.task_name}"`,
      });
    }

    res.json({
      success: true,
      message: "Attachments added successfully",
      data: updatedTask,
      notification_sent_to: updatedTask.assigned_to || [],
    });
  } catch (error) {
    return next(
      new ApiError(500, "Error adding attachments: " + error.message)
    );
  }
};

exports.removeAttachment = async (req, res, next) => {
  try {
    const taskService = new TaskService();
    const { task_id, attachment_id } = req.params;

    const task = await taskService.findByTaskId(task_id);
    if (!task) {
      return next(new ApiError(404, "Task not found"));
    }

    const attachmentExists = task.attachments?.some(
      (att) => att.attachment_id === attachment_id
    );

    if (!attachmentExists) {
      return next(new ApiError(404, "Attachment not found or already deleted"));
    }

    const updatedTask = await taskService.removeAttachment(
      task_id,
      attachment_id
    );

    // Log xóa attachment
    await activityLogger.updateTask(
      req.employee?.employee_id,
      req.employee?.role_id,
      task_id,
      [
        {
          field: "attachments",
          old_value: attachment_id,
          new_value: null,
        },
      ],
      `Removed attachment from task`
    );

    // Gửi thông báo khi xóa attachment
    if (updatedTask.assigned_to?.length > 0) {
      await NotificationHelper.sendTaskNotification({
        type: "task_updated",
        task: updatedTask,
        actor: NotificationHelper.getActor(req),
        recipients: updatedTask.assigned_to,
        customMessage: `${
          NotificationHelper.getActor(req).name
        } đã xóa tệp đính kèm khỏi nhiệm vụ: "${updatedTask.task_name}"`,
      });
    }

    res.json({
      success: true,
      message: "Attachment removed successfully",
      data: updatedTask,
      notification_sent_to: updatedTask.assigned_to || [],
    });
  } catch (error) {
    return next(
      new ApiError(500, "Error removing attachment: " + error.message)
    );
  }
};

exports.removeMultipleAttachments = async (req, res, next) => {
  try {
    const taskService = new TaskService();
    const { task_id } = req.params;
    const { attachment_ids } = req.body;

    if (
      !attachment_ids ||
      !Array.isArray(attachment_ids) ||
      attachment_ids.length === 0
    ) {
      return next(
        new ApiError(400, "attachment_ids must be a non-empty array")
      );
    }

    const task = await taskService.findByTaskId(task_id);
    if (!task) {
      return next(new ApiError(404, "Task not found"));
    }

    const existingAttachmentIds =
      task.attachments?.map((att) => att.attachment_id) || [];
    const invalidIds = attachment_ids.filter(
      (id) => !existingAttachmentIds.includes(id)
    );

    if (invalidIds.length > 0) {
      return next(
        new ApiError(
          404,
          `Attachments not found or already deleted: ${invalidIds.join(", ")}`
        )
      );
    }

    const updatedTask = await taskService.removeMultipleAttachments(
      task_id,
      attachment_ids
    );

    if (!updatedTask) {
      return next(new ApiError(500, "Failed to remove attachments"));
    }

    // Log xóa nhiều attachments
    await activityLogger.updateTask(
      req.employee?.employee_id,
      req.employee?.role_id,
      task_id,
      [
        {
          field: "attachments",
          old_value: `${attachment_ids.length} files`,
          new_value: null,
        },
      ],
      `Removed ${attachment_ids.length} attachment(s) from task`
    );

    // Gửi thông báo khi xóa nhiều attachments
    if (updatedTask.assigned_to?.length > 0) {
      await NotificationHelper.sendTaskNotification({
        type: "task_updated",
        task: updatedTask,
        actor: NotificationHelper.getActor(req),
        recipients: updatedTask.assigned_to,
        customMessage: `${NotificationHelper.getActor(req).name} đã xóa ${
          attachment_ids.length
        } tệp đính kèm khỏi nhiệm vụ: "${updatedTask.task_name}"`,
      });
    }

    res.json({
      success: true,
      message: "Attachments removed successfully",
      removed_count: attachment_ids.length,
      removed_ids: attachment_ids,
      data: updatedTask,
      notification_sent_to: updatedTask.assigned_to || [],
    });
  } catch (error) {
    return next(
      new ApiError(500, "Error removing attachments: " + error.message)
    );
  }
};

// Thêm method mới cho hoàn thành task
exports.completeTask = async (req, res, next) => {
  try {
    const taskService = new TaskService();
    const task = await taskService.updateByTaskId(req.params.task_id, {
      status: "wait_comfirm",
      completed_at: new Date(),
    });

    if (!task) {
      return next(new ApiError(404, "Task not found"));
    }

    // Log complete task
    await activityLogger.completeTask(
      req.employee?.employee_id,
      req.employee?.role_id,
      task.task_id,
      task.task_name
    );

    if (task.created_by) {
      await NotificationHelper.sendTaskNotification({
        type: "task_completed",
        task: task,
        actor: NotificationHelper.getActor(req),
        recipients: [task.created_by],
      });
    }

    res.json({
      success: true,
      message: "Task completed successfully",
      data: task,
      notification_sent_to: [task.created_by] || [],
    });
  } catch (error) {
    return next(new ApiError(500, "Error completing task: " + error.message));
  }
};

exports.confirmTask = async (req, res, next) => {
  try {
    const taskService = new TaskService();
    const task = await taskService.updateByTaskId(req.params.task_id, {
      status: "done",
      confirmed_at: new Date(),
      confirmed_by: req.employee?.employee_id,
    });

    if (!task) {
      return next(new ApiError(404, "Task not found"));
    }

    // Log confirm task
    await activityLogger.confirmTask(
      req.employee?.employee_id,
      req.employee?.role_id,
      task.task_id,
      task.task_name
    );

    // Gửi thông báo cho người được giao task
    if (task.assigned_to?.length > 0) {
      await NotificationHelper.sendTaskNotification({
        type: "task_confirmed",
        task: task,
        actor: NotificationHelper.getActor(req),
        recipients: task.assigned_to,
      });
    }

    res.json({
      success: true,
      message: "Task confirmed successfully",
      data: task,
      notification_sent_to: task.assigned_to || [],
    });
  } catch (error) {
    return next(new ApiError(500, "Error confirming task: " + error.message));
  }
};

// Thêm method mới cho comment task
exports.addComment = async (req, res, next) => {
  try {
    const { comment } = req.body;
    if (!comment) {
      return next(new ApiError(400, "Comment is required"));
    }

    const taskService = new TaskService();
    const task = await taskService.findByTaskId(req.params.task_id);

    if (!task) {
      return next(new ApiError(404, "Task not found"));
    }

    const updatedTask = await taskService.addComment(req.params.task_id, {
      employee_id: req.employee?.employee_id,
      employee_name: req.employee?.employee_name,
      comment: comment,
      created_at: new Date(),
    });

    // Log comment
    await activityLogger.updateTask(
      req.employee?.employee_id,
      req.employee?.role_id,
      task.task_id,
      [
        {
          field: "comments",
          old_value: null,
          new_value: comment.substring(0, 50) + "...",
        },
      ],
      "Added comment to task"
    );

    const recipients = [...(task.assigned_to || []), task.created_by].filter(
      (id) => id !== req.employee?.employee_id
    );

    if (recipients.length > 0) {
      await NotificationHelper.sendTaskNotification({
        type: "task_comment",
        task: task,
        actor: NotificationHelper.getActor(req),
        recipients: [...new Set(recipients)],
      });
    }

    res.json({
      success: true,
      message: "Comment added successfully",
      data: updatedTask,
      notification_sent_to: [...new Set(recipients)],
    });
  } catch (error) {
    return next(new ApiError(500, "Error adding comment: " + error.message));
  }
};

exports.delete = async (req, res, next) => {
  try {
    const taskService = new TaskService();
    const task = await taskService.findById(req.params.id);

    if (!task) {
      return next(new ApiError(404, "Task not found"));
    }

    const deleted = await taskService.delete(req.params.id);

    if (!deleted.value) {
      return next(new ApiError(404, "Task not found"));
    }

    // Log delete task
    await activityLogger.deleteTask(
      req.employee?.employee_id,
      req.employee?.role_id,
      task.task_id,
      task.task_name
    );

    res.json({
      success: true,
      message: "Task deleted successfully",
    });
  } catch (error) {
    return next(new ApiError(500, "Error deleting task: " + error.message));
  }
};

exports.deleteByTaskId = async (req, res, next) => {
  try {
    const taskService = new TaskService();
    const task = await taskService.findByTaskId(req.params.task_id);

    if (!task) {
      return next(new ApiError(404, "Task not found"));
    }

    const deleted = await taskService.deleteByTaskId(req.params.task_id);

    if (!deleted) {
      return next(new ApiError(404, "Task not found"));
    }

    // Log delete task
    await activityLogger.deleteTask(
      req.employee?.employee_id,
      req.employee?.role_id,
      task.task_id,
      task.task_name
    );

    res.json({
      success: true,
      message: "Task deleted successfully",
    });
  } catch (error) {
    return next(new ApiError(500, "Error deleting task: " + error.message));
  }
};

exports.deleteAll = async (req, res, next) => {
  try {
    const taskService = new TaskService();
    const deletedCount = await taskService.deleteAll();

    // Log bulk delete (nếu cần - có thể bỏ qua vì đây là action nguy hiểm)
    if (deletedCount > 0) {
      await activityLogger.custom({
        employee_id: req.employee?.employee_id,
        role_id: req.employee?.role_id,
        action: "delete_task",
        target_type: "task",
        description: `Deleted all tasks (${deletedCount} tasks)`,
        status: "success",
      });
    }

    res.json({
      success: true,
      message: `${deletedCount} tasks deleted successfully`,
    });
  } catch (error) {
    return next(
      new ApiError(500, "Error deleting all tasks: " + error.message)
    );
  }
};
