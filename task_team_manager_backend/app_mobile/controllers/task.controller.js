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
  if (Object.keys(req.body).length === 0) {
    return next(new ApiError(400, "Data to update cannot be empty"));
  }

  try {
    const taskService = new TaskService(MongoDB.client);
    const updated = await taskService.update(req.params.id, req.body);
    if (!updated) {
      return next(new ApiError(404, "Task not found"));
    }
    res.json(updated);
  } catch (error) {
    return next(new ApiError(500, "Error updating task: " + error.message));
  }
};

exports.updateByTaskId = async (req, res, next) => {
  if (Object.keys(req.body).length === 0) {
    return next(new ApiError(400, "Data to update cannot be empty"));
  }

  try {
    const taskService = new TaskService(MongoDB.client);
    const updated = await taskService.updateByTaskId(
      req.params.task_id,
      req.body
    );
    if (!updated) {
      return next(new ApiError(404, "Task not found"));
    }
    res.json(updated);
  } catch (error) {
    return next(new ApiError(500, "Error updating task: " + error.message));
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
