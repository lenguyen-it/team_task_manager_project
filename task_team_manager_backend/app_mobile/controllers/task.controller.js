const ApiError = require("../api-error");
const MongoDB = require("../utils/mongodb.util");
const TaskService = require("../services/task.service");

exports.create = async (req, res, next) => {
  if (!req.body?.task_name && !req.body?.task_id) {
    return next(new ApiError(400, "Task name và task id cannot be empty"));
  }

  try {
    const taskService = new TaskService(MongoDB.client);
    const task = await taskService.create(req.body);
    res.status(201).json(task);
  } catch (error) {
    return next(new ApiError(500, "Error creating task: " + error.message));
  }
};

exports.findAll = async (req, res, next) => {
  let data = [];
  try {
    const taskService = new TaskService(MongoDB.client);
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
    const taskService = new TaskService(MongoDB.client);
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
    const taskService = new TaskService(MongoDB.client);
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
    const taskService = new TaskService(MongoDB.client);
    const tasks = await taskService.findByTaskName(req.params.task_name || "");
    res.json(tasks);
  } catch (error) {
    return next(new ApiError(500, "Error searching tasks: " + error.message));
  }
};

exports.findTaskByEmployee = async (req, res, next) => {
  const taskService = new TaskService(MongoDB.client);

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
    const taskService = new TaskService(MongoDB.client);

    const employeeId =
      req.employee?.employee_id || req.body.employee_id || "unknown";

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

    res.json({
      message: "Task updated successfully",
      data: updated,
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
    const taskService = new TaskService(MongoDB.client);

    const employeeId =
      req.employee?.employee_id || req.body.employee_id || "unknown";

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

    res.json({
      message: "Task updated successfully",
      data: updated,
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
    const taskService = new TaskService(MongoDB.client);
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

    res.json({
      message: "Attachments added successfully",
      data: updatedTask,
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
    const taskService = new TaskService(MongoDB.client);
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

    res.json({
      message: "Attachments added successfully",
      data: updatedTask,
    });
  } catch (error) {
    return next(
      new ApiError(500, "Error adding attachments: " + error.message)
    );
  }
};

exports.removeAttachment = async (req, res, next) => {
  try {
    const taskService = new TaskService(MongoDB.client);
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

    res.json({
      message: "Attachment removed successfully",
      data: updatedTask,
    });
  } catch (error) {
    return next(
      new ApiError(500, "Error removing attachment: " + error.message)
    );
  }
};

exports.removeMultipleAttachments = async (req, res, next) => {
  try {
    const taskService = new TaskService(MongoDB.client);
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

    res.json({
      message: "Attachments removed successfully",
      removed_count: attachment_ids.length,
      removed_ids: attachment_ids,
      data: updatedTask,
    });
  } catch (error) {
    return next(
      new ApiError(500, "Error removing attachments: " + error.message)
    );
  }
};

exports.delete = async (req, res, next) => {
  try {
    const taskService = new TaskService(MongoDB.client);
    const deleted = await taskService.delete(req.params.id);
    if (!deleted.value) {
      return next(new ApiError(404, "Task not found"));
    }
    res.json({ message: "Task deleted successfully" });
  } catch (error) {
    return next(new ApiError(500, "Error deleting task: " + error.message));
  }
};

exports.deleteByTaskId = async (req, res, next) => {
  try {
    const taskService = new TaskService(MongoDB.client);
    const deleted = await taskService.deleteByTaskId(req.params.task_id);
    if (!deleted) {
      return next(new ApiError(404, "Task not found"));
    }
    res.json({ message: "Task deleted successfully" });
  } catch (error) {
    return next(new ApiError(500, "Error deleting task: " + error.message));
  }
};

exports.deleteAll = async (req, res, next) => {
  try {
    const taskService = new TaskService(MongoDB.client);
    const deletedCount = await taskService.deleteAll();
    res.json({ message: `${deletedCount} tasks deleted successfully` });
  } catch (error) {
    return next(
      new ApiError(500, "Error deleting all tasks: " + error.message)
    );
  }
};
