const Notification = require("../models/notification.model");

class NotificationService {
  async createNotification({
    employee_id,
    actor_id,
    task_id,
    type,
    message,
    metadata = {},
  }) {
    const notification = new Notification({
      employee_id,
      actor_id,
      task_id,
      type,
      message,
      metadata,
      create_at: new Date(),
    });

    return await notification.save();
  }

  async getNotifications(
    employee_id,
    { page = 1, limit = 20, unreadOnly = false }
  ) {
    const skip = (page - 1) * limit;
    const filter = { employee_id };
    if (unreadOnly) filter.isRead = false;

    const notifications = await Notification.find(filter)
      .populate({
        path: "actor_id",
        foreignField: "employee_id",
        localField: "actor_id",
        select: "employee_name",
        model: "Employee",
      })
      .populate({
        path: "task_id",
        foreignField: "task_id",
        localField: "task_id",
        select: "task_name status",
        model: "Task",
      })
      .sort({ create_at: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await Notification.countDocuments(filter);
    const unreadCount = await Notification.countDocuments({
      employee_id,
      isRead: false,
    });

    return {
      data: notifications,
      unreadCount,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async getAllNotifications({
    page = 1,
    limit = 20,
    unreadOnly = false,
    employee_id = null,
  }) {
    const skip = (page - 1) * limit;
    const filter = {};

    if (unreadOnly) filter.isRead = false;
    if (employee_id) filter.employee_id = employee_id;

    const notifications = await Notification.find(filter)
      .populate({
        path: "employee_id",
        foreignField: "employee_id",
        localField: "employee_id",
        select: "employee_name email",
        model: "Employee",
      })
      .populate({
        path: "actor_id",
        foreignField: "employee_id",
        localField: "actor_id",
        select: "employee_name",
        model: "Employee",
      })
      .populate({
        path: "task_id",
        foreignField: "task_id",
        localField: "task_id",
        select: "task_name status",
        model: "Task",
      })
      .sort({ create_at: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await Notification.countDocuments(filter);

    return {
      data: notifications,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async markAsRead(notificationId, requesterEmployeeId, requesterRole) {
    const filter = { _id: notificationId };
    if (requesterRole !== "admin") {
      filter.employee_id = requesterEmployeeId;
    }

    const result = await Notification.findOneAndUpdate(
      filter,
      { isRead: true, read_at: new Date() },
      { new: true }
    );

    if (!result) {
      throw new Error("Notification not found or unauthorized");
    }
    return result;
  }

  async markAllAsRead(requesterEmployeeId, requesterRole) {
    const filter =
      requesterRole === "admin"
        ? { isRead: false }
        : { employee_id: requesterEmployeeId, isRead: false };

    return await Notification.updateMany(filter, {
      isRead: true,
      read_at: new Date(),
    });
  }
}

module.exports = NotificationService;
