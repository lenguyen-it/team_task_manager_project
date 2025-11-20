const ApiError = require("../api-error");
const ProjectService = require("../services/project.service");
const NotificationHelper = require("../helpers/notification.helper");
const activityLogger = require("../helpers/activitylog.helper");

exports.create = async (req, res, next) => {
  if (!req.body?.project_name || !req.body?.project_id) {
    return next(new ApiError(400, "Project name and Project id are required"));
  }

  try {
    const projectService = new ProjectService();
    const project = await projectService.create(req.body);

    // Log tạo project
    await activityLogger.createProject(
      req.employee?.employee_id || req.body.created_by,
      req.employee?.role_id,
      project.project_id,
      {
        name: project.project_name,
        status: project.status,
        start_date: project.start_date,
        end_date: project.end_date,
      }
    );

    // Gửi thông báo nếu project được gán cho manager/team
    if (project.assigned_to && project.assigned_to.length > 0) {
      await NotificationHelper.sendProjectNotification({
        type: "project_assigned",
        project: project,
        actor: NotificationHelper.getActor(req),
        recipients: project.assigned_to,
      });
    }

    res.status(201).json({
      success: true,
      message: "Tạo project thành công",
      data: project,
    });
  } catch (error) {
    return next(new ApiError(500, "Error creating project: " + error.message));
  }
};

exports.update = async (req, res, next) => {
  if (Object.keys(req.body).length === 0) {
    return next(new ApiError(400, "Data to update cannot be empty"));
  }

  try {
    const projectService = new ProjectService();

    // Lấy project cũ để so sánh thay đổi
    const oldProject = await projectService.findById(req.params.id);
    if (!oldProject) {
      return next(new ApiError(404, "Project not found"));
    }

    const updated = await projectService.update(req.params.id, req.body);

    if (!updated.value) {
      return next(new ApiError(404, "Project not found"));
    }

    // Track changes
    const changes = [];
    if (
      req.body.project_name &&
      req.body.project_name !== oldProject.project_name
    ) {
      changes.push({
        field: "project_name",
        old_value: oldProject.project_name,
        new_value: req.body.project_name,
      });
    }
    if (req.body.status && req.body.status !== oldProject.status) {
      changes.push({
        field: "status",
        old_value: oldProject.status,
        new_value: req.body.status,
      });
    }
    if (
      req.body.description &&
      req.body.description !== oldProject.description
    ) {
      changes.push({
        field: "description",
        old_value: oldProject.description?.substring(0, 50) + "...",
        new_value: req.body.description?.substring(0, 50) + "...",
      });
    }
    if (req.body.start_date && req.body.start_date !== oldProject.start_date) {
      changes.push({
        field: "start_date",
        old_value: oldProject.start_date,
        new_value: req.body.start_date,
      });
    }
    if (req.body.end_date && req.body.end_date !== oldProject.end_date) {
      changes.push({
        field: "end_date",
        old_value: oldProject.end_date,
        new_value: req.body.end_date,
      });
    }

    // Log update project
    if (changes.length > 0) {
      await activityLogger.updateProject(
        req.employee?.employee_id,
        req.employee?.role_id,
        updated.value.project_id,
        changes,
        `Updated project: ${updated.value.project_name}`
      );
    }

    // Gửi thông báo khi cập nhật project
    if (updated.value.assigned_to && updated.value.assigned_to.length > 0) {
      await NotificationHelper.sendProjectNotification({
        type: "project_updated",
        project: updated.value,
        actor: NotificationHelper.getActor(req),
        recipients: updated.value.assigned_to,
      });
    }

    res.json({
      success: true,
      message: "Cập nhật project thành công",
      data: updated.value,
    });
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
    const projectService = new ProjectService();

    // Lấy project cũ để so sánh
    const oldProject = await projectService.findByProjectId(
      req.params.project_id
    );
    if (!oldProject) {
      return next(new ApiError(404, "Project not found"));
    }

    const updated = await projectService.updateByProjectId(
      req.params.project_id,
      req.body
    );

    if (!updated) {
      return next(new ApiError(404, "Project not found"));
    }

    // Track changes
    const changes = [];
    if (
      req.body.project_name &&
      req.body.project_name !== oldProject.project_name
    ) {
      changes.push({
        field: "project_name",
        old_value: oldProject.project_name,
        new_value: req.body.project_name,
      });
    }
    if (req.body.status && req.body.status !== oldProject.status) {
      changes.push({
        field: "status",
        old_value: oldProject.status,
        new_value: req.body.status,
      });
    }
    if (
      req.body.description &&
      req.body.description !== oldProject.description
    ) {
      changes.push({
        field: "description",
        old_value: oldProject.description?.substring(0, 50) + "...",
        new_value: req.body.description?.substring(0, 50) + "...",
      });
    }
    if (req.body.start_date && req.body.start_date !== oldProject.start_date) {
      changes.push({
        field: "start_date",
        old_value: oldProject.start_date,
        new_value: req.body.start_date,
      });
    }
    if (req.body.end_date && req.body.end_date !== oldProject.end_date) {
      changes.push({
        field: "end_date",
        old_value: oldProject.end_date,
        new_value: req.body.end_date,
      });
    }

    // Log update project
    if (changes.length > 0) {
      await activityLogger.updateProject(
        req.employee?.employee_id,
        req.employee?.role_id,
        updated.project_id,
        changes,
        `Updated project: ${updated.project_name}`
      );
    }

    // Gửi thông báo khi cập nhật project
    if (updated.assigned_to && updated.assigned_to.length > 0) {
      await NotificationHelper.sendProjectNotification({
        type: "project_updated",
        project: updated,
        actor: NotificationHelper.getActor(req),
        recipients: updated.assigned_to,
      });
    }

    res.json({
      success: true,
      message: "Cập nhật project thành công",
      data: updated,
    });
  } catch (error) {
    return next(
      new ApiError(
        500,
        `Error updating project id=${req.params.project_id}: ` + error.message
      )
    );
  }
};

exports.findAll = async (req, res, next) => {
  let data = [];
  try {
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
    const projectService = new ProjectService();
    const project = await projectService.findByProjectName(
      req.query.project_name || ""
    );
    res.json(project);
  } catch (error) {
    return next(new ApiError(500, "Error searching project: " + error.message));
  }
};

exports.delete = async (req, res, next) => {
  try {
    const projectService = new ProjectService();

    // Lấy thông tin project trước khi xóa
    const project = await projectService.findById(req.params.id);
    if (!project) {
      return next(new ApiError(404, "Project not found"));
    }

    const deleted = await projectService.delete(req.params.id);

    if (!deleted.value) {
      return next(new ApiError(404, "Project not found"));
    }

    // Log delete project
    await activityLogger.deleteProject(
      req.employee?.employee_id,
      req.employee?.role_id,
      project.project_id,
      project.project_name
    );

    res.json({
      success: true,
      message: "Project deleted successfully",
    });
  } catch (error) {
    return next(new ApiError(500, "Error deleting project: " + error.message));
  }
};

exports.deleteByProjectId = async (req, res, next) => {
  try {
    const projectService = new ProjectService();

    // Lấy thông tin project trước khi xóa
    const project = await projectService.findByProjectId(req.params.project_id);
    if (!project) {
      return next(new ApiError(404, "Project not found"));
    }

    const deleted = await projectService.deleteByProjectId(
      req.params.project_id
    );

    if (!deleted) {
      return next(new ApiError(404, "Project not found"));
    }

    // Log delete project
    await activityLogger.deleteProject(
      req.employee?.employee_id,
      req.employee?.role_id,
      project.project_id,
      project.project_name
    );

    res.json({
      success: true,
      message: "Project deleted successfully",
    });
  } catch (error) {
    return next(new ApiError(500, "Error deleting project: " + error.message));
  }
};

exports.deleteAll = async (req, res, next) => {
  try {
    const projectService = new ProjectService();
    const deletedCount = await projectService.deleteAll();

    // Log bulk delete (action cực kỳ nguy hiểm)
    if (deletedCount > 0) {
      await activityLogger.custom({
        employee_id: req.employee?.employee_id || "system",
        role_id: req.employee?.role_id || "admin",
        action: "delete_project",
        target_type: "project",
        description: `⚠️ BULK DELETE: Deleted all projects (${deletedCount} projects)`,
        status: "success",
      });
    }

    res.json({
      success: true,
      message: `${deletedCount} projects deleted successfully`,
    });
  } catch (error) {
    return next(
      new ApiError(500, "Error deleting all projects: " + error.message)
    );
  }
};
