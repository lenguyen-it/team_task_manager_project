const ApiError = require("../api-error");
const RoleService = require("../services/role.service");
const NotificationHelper = require("../helpers/notification.helper");

exports.create = async (req, res, next) => {
  if (!req.body?.role_name && !req.body?.role_id) {
    return next(new ApiError(400, "Role name và role id cannot be empty"));
  }

  try {
    const roleService = new RoleService();
    const role = await roleService.create(req.body);

    // Gửi thông báo nếu role được gán cho employee
    if (role.assigned_to && role.assigned_to.length > 0) {
      await NotificationHelper.sendRoleNotification({
        type: "role_assigned",
        role: role,
        actor: NotificationHelper.getActor(req),
        recipients: role.assigned_to,
      });
    }

    res.status(201).json({
      success: true,
      message: "Tạo role thành công",
      data: role,
    });
  } catch (error) {
    return next(new ApiError(500, "Error creating role: " + error.message));
  }
};

exports.update = async (req, res, next) => {
  if (Object.keys(req.body).length === 0) {
    return next(new ApiError(400, "Data to update cannot be empty"));
  }

  try {
    const roleService = new RoleService();
    const updated = await roleService.update(req.params.id, req.body);

    if (!updated.value) {
      return next(new ApiError(404, "Role not found"));
    }

    // Gửi thông báo khi cập nhật role
    if (updated.value.assigned_to && updated.value.assigned_to.length > 0) {
      await NotificationHelper.sendRoleNotification({
        type: "role_update",
        role: updated.value,
        actor: NotificationHelper.getActor(req),
        recipients: updated.value.assigned_to,
      });
    }

    res.json({
      success: true,
      message: "Cập nhật role thành công",
      data: updated.value,
    });
  } catch (error) {
    return next(
      new ApiError(
        500,
        `Error updating role id=${req.params.id} with: ` + error.message
      )
    );
  }
};

exports.updateByRoleId = async (req, res, next) => {
  if (Object.keys(req.body).length === 0) {
    return next(new ApiError(400, "Data to update cannot be empty"));
  }

  try {
    const roleService = new RoleService();
    const updated = await roleService.updateByRoleId(
      req.params.role_id,
      req.body
    );

    if (!updated) {
      return next(new ApiError(404, "Role not found"));
    }

    // Gửi thông báo khi cập nhật role
    if (updated.assigned_to && updated.assigned_to.length > 0) {
      await NotificationHelper.sendRoleNotification({
        type: "role_update",
        role: updated,
        actor: NotificationHelper.getActor(req),
        recipients: updated.assigned_to,
      });
    }

    res.json({
      success: true,
      message: "Cập nhật role thành công",
      data: updated,
    });
  } catch (error) {
    return next(
      new ApiError(
        500,
        `Error updating role id=${req.params.role_id}: ` + error.message
      )
    );
  }
};

exports.findAll = async (req, res, next) => {
  let data = [];
  try {
    const roleService = new RoleService();
    const { role_name } = req.query;
    if (role_name) {
      data = await roleService.findByRoleName(role_name);
    } else {
      data = await roleService.find({});
    }
  } catch (error) {
    return next(new ApiError(500, "Error retrieving roles: " + error.message));
  }
  return res.send(data);
};

exports.findOne = async (req, res, next) => {
  try {
    const roleService = new RoleService();
    const role = await roleService.findById(req.params.id);
    if (!role) {
      return next(new ApiError(404, "Role not found"));
    }
    return res.send(role);
  } catch (error) {
    return next(new ApiError(500, "Error retrieving role: " + error.message));
  }
};

exports.findByRoleId = async (req, res, next) => {
  try {
    const roleService = new RoleService();
    const role = await roleService.findByRoleId(req.params.role_id);
    if (!role) {
      return next(new ApiError(404, "Role not found"));
    }
    res.json(role);
  } catch (error) {
    return next(new ApiError(500, "Error retrieving role: " + error.message));
  }
};

exports.delete = async (req, res, next) => {
  try {
    const roleService = new RoleService();
    const deleted = await roleService.delete(req.params.id);
    if (!deleted.value) {
      return next(new ApiError(404, "Role not found"));
    }
    res.json({ message: "Role deleted successfully" });
  } catch (error) {
    return next(new ApiError(500, "Error deleting role: " + error.message));
  }
};

exports.deleteByRoleId = async (req, res, next) => {
  try {
    const roleService = new RoleService();
    const deleted = await roleService.deleteByRoleId(req.params.role_id);
    if (!deleted) {
      return next(new ApiError(404, "Role not found"));
    }
    res.json({ message: "Role deleted successfully" });
  } catch (error) {
    return next(new ApiError(500, "Error deleting role: " + error.message));
  }
};

exports.deleteAll = async (req, res, next) => {
  try {
    const roleService = new RoleService();
    const deletedCount = await roleService.deleteAll();
    res.json({ message: `${deletedCount} roles deleted successfully` });
  } catch (error) {
    return next(
      new ApiError(500, "Error deleting all roles: " + error.message)
    );
  }
};
