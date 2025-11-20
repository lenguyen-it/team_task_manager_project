// activitylog.route.js
const express = require("express");
const router = express.Router();
const ActivityLogController = require("../controllers/activitylog.controller");
const { verifyToken, authorize } = require("../middlewares/auth.middleware");

// Route: Chỉ Admin + Manager mới được xem toàn bộ log
router.route("/").get(
  verifyToken,
  authorize(["admin", "manager"]), // Chỉ admin và manager
  ActivityLogController.getLogs
);

// Route mới: Nhân viên xem log của chính mình
router.route("/me").get(
  verifyToken,
  // Không cần authorize vì tất cả role đều được xem log của mình
  ActivityLogController.getMyLogs // Controller mới sẽ viết bên dưới
);

module.exports = router;
