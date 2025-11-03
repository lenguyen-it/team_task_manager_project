const ApiError = require("../api-error");
const MongoDB = require("../utils/mongodb.util");
const TaskTypeService = require("../services/tasktype.service");

exports.create = async (req, res, next) => {
  if (!req.body?.task_type_id && !req.body?.task_type_id) {
    return next(
      new ApiError(400, "Task Type name và Task Type id cannot be empty")
    );
  }

  try {
    const taskTypeService = new TaskTypeService(MongoDB.client);
    const taskType = await taskTypeService.create(req.body);
    res.status(201).json(taskType);
  } catch (error) {
    return next(
      new ApiError(500, "Error creating task type: " + error.message)
    );
  }
};

exports.findAll = async (req, res, next) => {
  let data = [];
  try {
    const taskTypeService = new TaskTypeService(MongoDB.client);
    const { task_type_name } = req.query;

    if (task_type_name) {
      data = await taskTypeService.findByTaskTypeName(task_type_name);
    } else {
      data = await taskTypeService.find({});
    }
  } catch (error) {
    return next(
      new ApiError(500, "Error retrieving task type: " + error.message)
    );
  }

  return res.send(data);
};

exports.findByTaskTypeId = async (req, res, next) => {
  try {
    const taskTypeService = new TaskTypeService(MongoDB.client);
    const taskType = await taskTypeService.findByTaskTypeId(
      req.params.task_type_id
    );

    if (!taskType) {
      return next(new ApiError(404, "Task type not found"));
    }

    res.json(taskType);
  } catch (error) {
    return next(
      new ApiError(500, "Error retrieving task type: " + error.message)
    );
  }
};

exports.findByTaskTypeName = async (req, res, next) => {
  try {
    const taskTypeService = new TaskTypeService(MongoDB.client);
    const taskTypes = await taskTypeService.findByTaskTypeName(
      req.query.task_type_name || ""
    );
    res.json(taskTypes);
  } catch (error) {
    return next(
      new ApiError(500, "Error searching task types: " + error.message)
    );
  }
};

exports.update = async (req, res, next) => {
  if (Object.keys(req.body).length === 0) {
    return next(new ApiError(400, "Data to update cannot be empty"));
  }

  try {
    const taskTypeService = new TaskTypeService(MongoDB.client);
    const updated = await taskTypeService.update(req.params.id, req.body);
    if (!updated.value) {
      return next(new ApiError(404, "Task type not found"));
    }
    res.json(updated.value);
  } catch (error) {
    return next(
      new ApiError(500, "Error updating task type: " + error.message)
    );
  }
};

exports.updateByTaskTypeId = async (req, res, next) => {
  if (Object.keys(req.body).length === 0) {
    return next(new ApiError(400, "Data to update cannot be empty"));
  }

  try {
    const taskTypeService = new TaskTypeService(MongoDB.client);
    const updated = await taskTypeService.updateByTaskTypeId(
      req.params.task_type_id,
      req.body
    );
    if (!updated) {
      return next(new ApiError(404, "Task type not found"));
    }
    res.json(updated);
  } catch (error) {
    return next(
      new ApiError(500, "Error updating task type: " + error.message)
    );
  }
};

exports.delete = async (req, res, next) => {
  try {
    const taskTypeService = new TaskTypeService(MongoDB.client);
    const deleted = await taskTypeService.delete(req.params.id);

    if (!deleted.value) {
      return next(new ApiError(404, "Task type not found"));
    }

    res.json({ message: "Task type deleted successfully" });
  } catch (error) {
    return next(
      new ApiError(500, "Error deleting task type: " + error.message)
    );
  }
};

exports.deleteByTaskTypeId = async (req, res, next) => {
  try {
    const taskTypeService = new TaskTypeService(MongoDB.client);
    const deleted = await taskTypeService.deleteByTaskTypeId(
      req.params.task_type_id
    );

    if (!deleted) {
      return next(new ApiError(404, "Task type not found"));
    }

    res.json({ message: "Task type deleted successfully" });
  } catch (error) {
    return next(
      new ApiError(500, "Error deleting task type: " + error.message)
    );
  }
};

exports.deleteAll = async (req, res, next) => {
  try {
    const taskTypeService = new TaskTypeService(MongoDB.client);
    const deletedCount = await taskTypeService.deleteAll();
    res.json({ message: `${deletedCount} task types deleted successfully` });
  } catch (error) {
    return next(
      new ApiError(500, "Error deleting all task types: " + error.message)
    );
  }
};
