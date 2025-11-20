const ActivityLogService = require("../services/activitylog.service");

exports.getLogs = async (req, res) => {
  try {
    const activityLogService = new ActivityLogService();

    const {
      page = 1,
      limit = 20,
      action,
      employee_id,
      target_type,
    } = req.query;

    // Xây dựng filter
    const filter = {};
    if (action) filter.action = action;
    if (employee_id) filter.employee_id = employee_id;
    if (target_type) filter.target_type = target_type;

    const result = await activityLogService.getLogs(
      filter,
      parseInt(page, 10),
      parseInt(limit, 10)
    );

    res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error("Error in getLogs (ActivityLog):", error);
    res.status(500).json({
      success: false,
      message: error.message || "Lỗi server khi lấy nhật ký hoạt động",
    });
  }
};

exports.getMyLogs = async (req, res) => {
  try {
    const activityLogService = new ActivityLogService();

    const currentEmployeeId = req.employee.employee_id;

    const { page = 1, limit = 20, action, target_type } = req.query;

    const filter = {
      employee_id: currentEmployeeId,
    };

    if (action) filter.action = action;
    if (target_type) filter.target_type = target_type;

    const result = await activityLogService.getLogs(
      filter,
      parseInt(page, 10),
      parseInt(limit, 10)
    );

    res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error("Error in getMyLogs:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi khi lấy nhật ký hoạt động của bạn",
    });
  }
};
