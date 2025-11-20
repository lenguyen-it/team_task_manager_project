const NotificationService = require("../services/notification.service");

exports.getMyNotifications = async (req, res) => {
  try {
    const notificationService = new NotificationService();
    const employee_id = req.employee.employee_id;

    const { page = 1, limit = 20, unread } = req.query;

    const result = await notificationService.getNotifications(employee_id, {
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      unreadOnly: unread === "true",
    });

    res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error("Error in getMyNotifications:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Lỗi server khi lấy thông báo",
    });
  }
};

exports.getAllNotifications = async (req, res) => {
  try {
    const notificationService = new NotificationService();
    const { page = 1, limit = 20, unread, employee_id } = req.query;

    const result = await notificationService.getAllNotifications({
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      unreadOnly: unread === "true",
      employee_id: employee_id,
    });

    res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error) {
    console.error("Error in getAllNotifications:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Lỗi server khi lấy thông báo",
    });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const employee_id = req.employee.employee_id;

    const notificationService = new NotificationService();

    const notification = await notificationService.markAsRead(id, employee_id);

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: "Không tìm thấy thông báo hoặc bạn không có quyền truy cập",
      });
    }

    res.status(200).json({
      success: true,
      data: notification,
    });
  } catch (error) {
    console.error("Error in markAsRead:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Lỗi khi đánh dấu đã đọc",
    });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    const employee_id = req.employee.employee_id;

    const notificationService = new NotificationService();

    await notificationService.markAllAsRead(employee_id);

    res.status(200).json({
      success: true,
      message: "Đã đánh dấu tất cả thông báo là đã đọc",
    });
  } catch (error) {
    console.error("Error in markAllAsRead:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Lỗi khi đánh dấu tất cả đã đọc",
    });
  }
};
