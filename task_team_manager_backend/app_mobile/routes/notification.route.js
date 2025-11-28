const express = require("express");
const NotificationController = require("../controllers/notification.controller");
const { verifyToken, authorize } = require("../middlewares/auth.middleware");

const router = express.Router();

// ✅ FIX: Put specific routes BEFORE generic ones
router
  .route("/readall")
  .patch(verifyToken, NotificationController.markAllAsRead);

router.route("/:id/read").patch(verifyToken, NotificationController.markAsRead);

router.route("/my").get(verifyToken, NotificationController.getMyNotifications);

router
  .route("/")
  .get(
    verifyToken,
    authorize(["admin", "manager"]),
    NotificationController.getAllNotifications
  );

module.exports = router;
