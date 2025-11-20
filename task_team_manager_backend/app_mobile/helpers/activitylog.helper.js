const ActivityLogService = require("../services/activitylog.service");

class ActivityLogger {
  constructor() {
    this.service = new ActivityLogService();
  }

  _getRequestMetadata(req) {
    return {
      ip_address: req.ip || req.connection?.remoteAddress,
      user_agent: req.headers?.["user-agent"],
    };
  }

  async _log(data, req = null) {
    try {
      const logData = {
        ...data,
        ...(req ? this._getRequestMetadata(req) : {}),
      };
      return await this.service.log(logData);
    } catch (error) {
      console.error("ActivityLogger Error:", error);
      return null;
    }
  }

  // ==================== AUTH ACTIONS ====================
  async login(req, employee_id, role_id, description = null) {
    return this._log(
      {
        employee_id,
        role_id,
        action: "login",
        target_type: "system",
        description: description || "User logged in successfully",
        status: "success",
      },
      req
    );
  }

  async loginFailed(req, employee_id, role_id, description = null) {
    return this._log(
      {
        employee_id,
        role_id,
        action: "login_failed",
        target_type: "system",
        description: description || "Login failed",
        status: "failed",
      },
      req
    );
  }

  async logout(req, employee_id, role_id, description = null) {
    return this._log(
      {
        employee_id,
        role_id,
        action: "logout",
        target_type: "system",
        description: description || "User logged out",
        status: "success",
      },
      req
    );
  }

  // ==================== TASK ACTIONS ====================
  async createTask(employee_id, role_id, task_id, taskData = {}) {
    return this._log({
      employee_id,
      role_id,
      action: "create_task",
      target_type: "task",
      target_id: task_id,
      description: `Created task: ${taskData.title || task_id}`,
      changes: [
        {
          field: "created",
          old_value: null,
          new_value: taskData,
        },
      ],
    });
  }

  async updateTask(employee_id, role_id, task_id, changes, description = null) {
    return this._log({
      employee_id,
      role_id,
      action: "update_task",
      target_type: "task",
      target_id: task_id,
      changes: Array.isArray(changes) ? changes : [changes],
      description: description || "Updated task",
    });
  }

  async deleteTask(employee_id, role_id, task_id, taskTitle = null) {
    return this._log({
      employee_id,
      role_id,
      action: "delete_task",
      target_type: "task",
      target_id: task_id,
      description: `Deleted task: ${taskTitle || task_id}`,
    });
  }

  async assignTask(
    employee_id,
    role_id,
    task_id,
    assignee_id,
    assignee_name = null
  ) {
    return this._log({
      employee_id,
      role_id,
      action: "assign_task",
      target_type: "task",
      target_id: task_id,
      description: `Assigned task to ${assignee_name || assignee_id}`,
      changes: [
        {
          field: "assignee",
          old_value: null,
          new_value: assignee_id,
        },
      ],
    });
  }

  async completeTask(employee_id, role_id, task_id, taskTitle = null) {
    return this._log({
      employee_id,
      role_id,
      action: "complete_task",
      target_type: "task",
      target_id: task_id,
      description: `Completed task: ${taskTitle || task_id}`,
      changes: [
        {
          field: "status",
          old_value: "in_progress",
          new_value: "wait_comfirm",
        },
      ],
    });
  }

  async confirmTask(employee_id, role_id, task_id, taskTitle = null) {
    return this._log({
      employee_id,
      role_id,
      action: "confirm_task",
      target_type: "task",
      target_id: task_id,
      description: `Confirmed task: ${taskTitle || task_id}`,
      changes: [
        {
          field: "status",
          old_value: "wait_comfirm",
          new_value: "done",
        },
      ],
    });
  }

  // ==================== EMPLOYEE ACTIONS ====================
  async createEmployee(
    employee_id,
    role_id,
    new_employee_id,
    employeeData = {}
  ) {
    return this._log({
      employee_id,
      role_id,
      action: "create_employee",
      target_type: "employee",
      target_id: new_employee_id,
      description: `Created employee: ${employeeData.name || new_employee_id}`,
      changes: [
        {
          field: "created",
          old_value: null,
          new_value: employeeData,
        },
      ],
    });
  }

  async updateEmployee(
    employee_id,
    role_id,
    target_employee_id,
    changes,
    description = null
  ) {
    return this._log({
      employee_id,
      role_id,
      action: "update_employee",
      target_type: "employee",
      target_id: target_employee_id,
      changes: Array.isArray(changes) ? changes : [changes],
      description: description || "Updated employee information",
    });
  }

  async deleteEmployee(
    employee_id,
    role_id,
    target_employee_id,
    employeeName = null
  ) {
    return this._log({
      employee_id,
      role_id,
      action: "delete_employee",
      target_type: "employee",
      target_id: target_employee_id,
      description: `Deleted employee: ${employeeName || target_employee_id}`,
    });
  }

  async changeRole(
    employee_id,
    role_id,
    target_employee_id,
    old_role,
    new_role
  ) {
    return this._log({
      employee_id,
      role_id,
      action: "change_role",
      target_type: "employee",
      target_id: target_employee_id,
      description: `Changed role from ${old_role} to ${new_role}`,
      changes: [
        {
          field: "role",
          old_value: old_role,
          new_value: new_role,
        },
      ],
    });
  }

  // ==================== PROJECT ACTIONS ====================
  async createProject(employee_id, role_id, project_id, projectData = {}) {
    return this._log({
      employee_id,
      role_id,
      action: "create_project",
      target_type: "project",
      target_id: project_id,
      description: `Created project: ${projectData.name || project_id}`,
      changes: [
        {
          field: "created",
          old_value: null,
          new_value: projectData,
        },
      ],
    });
  }

  async updateProject(
    employee_id,
    role_id,
    project_id,
    changes,
    description = null
  ) {
    return this._log({
      employee_id,
      role_id,
      action: "update_project",
      target_type: "project",
      target_id: project_id,
      changes: Array.isArray(changes) ? changes : [changes],
      description: description || "Updated project",
    });
  }

  async deleteProject(employee_id, role_id, project_id, projectName = null) {
    return this._log({
      employee_id,
      role_id,
      action: "delete_project",
      target_type: "project",
      target_id: project_id,
      description: `Deleted project: ${projectName || project_id}`,
    });
  }

  // ==================== OTHER ACTIONS ====================
  async exportData(employee_id, role_id, dataType, description = null) {
    return this._log({
      employee_id,
      role_id,
      action: "export_data",
      target_type: "system",
      description: description || `Exported ${dataType} data`,
    });
  }

  async viewReport(employee_id, role_id, reportType, description = null) {
    return this._log({
      employee_id,
      role_id,
      action: "view_report",
      target_type: "system",
      description: description || `Viewed ${reportType} report`,
    });
  }

  // ==================== CUSTOM ACTION ====================
  async custom(data, req = null) {
    return this._log(data, req);
  }

  // ==================== BATCH LOGGING ====================
  async logBatch(activities) {
    const promises = activities.map((activity) => this._log(activity));
    return Promise.allSettled(promises);
  }
}

// Export singleton instance
const activityLogger = new ActivityLogger();
module.exports = activityLogger;

module.exports.ActivityLogger = ActivityLogger;
