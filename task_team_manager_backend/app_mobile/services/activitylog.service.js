const ActivityLog = require("../models/activitylog.model");

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
  }) {
    const log = new this.ActivityLog({
      employee_id,
      role_id,
      action,
      target_type,
      target_id,
      changes,
      description,
      status,
      timestamp: new Date(),
    });

    return await log.save();
  }

  async getLogs(filter = {}, page = 1, limit = 20, sort = { timestamp: -1 }) {
    const skip = (page - 1) * limit;
    const logs = await ActivityLog.find(filter)
      .populate("employee_id", "name email avatar")
      .populate("role_id", "name")
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await ActivityLog.countDocuments(filter);

    return {
      data: logs,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async getLogById(id) {
    return await ActivityLog.findById(id)
      .populate("employee_id", "name email")
      .populate("role_id", "name");
  }
}

module.exports = ActivityLogService;
