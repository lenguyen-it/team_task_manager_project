// services/activitylog.service.js
const ActivityLog = require("../models/activitylog.model");
const Employee = require("../models/employee.model");
const Role = require("../models/role.model");

class ActivityLogService {
  async log({
    employee_id,
    role_id,
    action,
    target_type = null,
    target_id = null,
    changes = null,
    description = null,
    status = "success",
    ip_address,
    user_agent,
  }) {
    const log = new ActivityLog({
      employee_id,
      role_id,
      action,
      target_type,
      target_id,
      changes,
      description,
      status,
      timestamp: new Date(),
      ip_address,
      user_agent,
    });

    return await log.save();
  }

  async _populateLogs(logs) {
    if (logs.length === 0) return logs;

    const employeeIds = [...new Set(logs.map((log) => log.employee_id))];
    const roleIds = [...new Set(logs.map((log) => log.role_id))];

    const [employees, roles] = await Promise.all([
      Employee.find({ employee_id: { $in: employeeIds } })
        .select("employee_id employee_name email image")
        .lean(),
      Role.find({ role_id: { $in: roleIds } })
        .select("role_id role_name")
        .lean(),
    ]);

    const employeeMap = Object.fromEntries(
      employees.map((e) => [
        e.employee_id,
        {
          name: e.employee_name,
          email: e.email,
          avatar: e.image || "",
        },
      ])
    );

    const roleMap = Object.fromEntries(
      roles.map((r) => [r.role_id, { name: r.role_name }])
    );

    return logs.map((log) => ({
      ...log,
      employee: employeeMap[log.employee_id] || {
        name: "Đã xóa",
        email: "",
        avatar: "",
      },
      role: roleMap[log.role_id] || { name: "Không xác định" },
    }));
  }

  async getLogs(filter = {}, page = 1, limit = 20, sort = { timestamp: -1 }) {
    const skip = (page - 1) * limit;

    const logs = await ActivityLog.find(filter)
      .sort({ _id: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const populatedLogs = await this._populateLogs(logs);

    const total = await ActivityLog.countDocuments(filter);

    return {
      data: populatedLogs,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async getLogById(id) {
    const log = await ActivityLog.findById(id).lean();
    if (!log) return null;

    const populated = await this._populateLogs([log]);
    return populated[0];
  }

  async getMyLogs(employee_id, filter = {}, page = 1, limit = 20) {
    const fullFilter = { employee_id, ...filter };
    return this.getLogs(fullFilter, page, limit);
  }
}

module.exports = ActivityLogService;
