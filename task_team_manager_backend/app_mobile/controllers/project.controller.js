const ApiError = require("../api-error");
const MongoDB = require("../utils/mongodb.util");
const ProjectService = require("../services/project.service");

exports.create = async (req, res, next) => {
  if (!req.body?.project_name || !req.body?.project_id) {
    return next(new ApiError(400, "Project name and Project id are required"));
  }

  try {
    // const projectService = new ProjectService(MongoDB.client);
    const projectService = new ProjectService();

    const project = await projectService.create(req.body);

    res.status(201).json(project);
  } catch (error) {
    return next(new ApiError(500, "Error creating project: " + error.message));
  }
};

exports.findAll = async (req, res, next) => {
  let data = [];

  try {
    // const projectService = new ProjectService(MongoDB.client);
    const projectService = new ProjectService();

    const { project_name } = req.query;

    if (project_name) {
      data = await projectService.findByProjectName(project_name);
    } else {
      data = await projectService.find({});
    }
  } catch (error) {
    return next(
      new ApiError(500, "Error retrieving projects: " + error.message)
    );
  }

  return res.send(data);
};

exports.findOne = async (req, res, next) => {
  try {
    // const projectService = new ProjectService(MongoDB.client);
    const projectService = new ProjectService();

    const project = await projectService.findById(req.params.id);

    if (!project) {
      return next(new ApiError(404, "Project not found"));
    }

    return res.send(project);
  } catch (error) {
    return next(
      new ApiError(500, "Error retrieving project: " + error.message)
    );
  }
};

exports.findByProjectId = async (req, res, next) => {
  try {
    // const projectService = new ProjectService(MongoDB.client);
    const projectService = new ProjectService();

    const project = await projectService.findByProjectId(req.params.project_id);
    if (!project) {
      return next(new ApiError(404, "project not found"));
    }
    res.json(project);
  } catch (error) {
    return next(
      new ApiError(500, "Error retrieving project: " + error.message)
    );
  }
};

exports.findByProjectName = async (req, res, next) => {
  try {
    // const projectService = new ProjectService(MongoDB.client);
    const projectService = new ProjectService();

    const project = await projectService.findByProjectName(
      req.query.project_name || ""
    );
    res.json(project);
  } catch (error) {
    return next(new ApiError(500, "Error searching project: " + error.message));
  }
};

exports.update = async (req, res, next) => {
  if (Object.keys(req.body).length === 0) {
    return next(new ApiError(400, "Data to update cannot be empty"));
  }

  try {
    // const projectService = new ProjectService(MongoDB.client);
    const projectService = new ProjectService();

    const updated = await projectService.update(req.params.id, req.body);

    if (!updated.value) {
      return next(new ApiError(404, "Project not found"));
    }

    res.json(updated.value);
  } catch (error) {
    return next(
      new ApiError(
        500,
        `Error updating project id=${req.params.id} with: ` + error.message
      )
    );
  }
};

exports.updateByProjectId = async (req, res, next) => {
  if (Object.keys(req.body).length === 0) {
    return next(new ApiError(400, "Data to update cannot be empty"));
  }

  try {
    // const projectService = new ProjectService(MongoDB.client);
    const projectService = new ProjectService();

    const updated = await projectService.updateByProjectId(
      req.params.project_id,
      req.body
    );

    if (!updated) {
      return next(new ApiError(404, "Project not found"));
    }

    res.json(updated);
  } catch (error) {
    return next(
      new ApiError(
        500,
        `Error updating project id=${req.params.project_id}: ` + error.message
      )
    );
  }
};

exports.delete = async (req, res, next) => {
  try {
    // const projectService = new ProjectService(MongoDB.client);
    const projectService = new ProjectService();

    const deleted = await projectService.delete(req.params.id);
    if (!deleted.value) {
      return next(new ApiError(404, "Project not found"));
    }
    res.json({ message: "Project deleted successfully" });
  } catch (error) {
    return next(new ApiError(500, "Error deleting project: " + error.message));
  }
};

exports.deleteByProjectId = async (req, res, next) => {
  try {
    // const projectService = new ProjectService(MongoDB.client);
    const projectService = new ProjectService();

    const deleted = await projectService.deleteByProjectId(
      req.params.project_id
    );

    if (!deleted) {
      return next(new ApiError(404, "Project not found"));
    }

    res.json({ message: "Project deleted successfully" });
  } catch (error) {
    return next(new ApiError(500, "Error deleting project: " + error.message));
  }
};

exports.deleteAll = async (req, res, next) => {
  try {
    // const projectService = new ProjectService(MongoDB.client);
    const projectService = new ProjectService();

    const deletedCount = await projectService.deleteAll();
    res.json({ message: `${deletedCount} projects deleted successfully` });
  } catch (error) {
    return next(
      new ApiError(500, "Error deleting all projects: " + error.message)
    );
  }
};
