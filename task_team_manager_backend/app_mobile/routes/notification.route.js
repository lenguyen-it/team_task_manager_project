const express = require("express");
const NotificationController = require("../controllers/notification.controller");
const { verifyToken, authorize } = require("../middlewares/auth.middleware");

const router = express.Router();

router
  .route("/")
  .get(
    verifyToken,
    authorize(["admin"]),
    NotificationController.getAllNotifications
  );

router
  .route("/readall")
  .patch(verifyToken, NotificationController.markAllAsRead);

router.route("/:id/read").patch(verifyToken, NotificationController.markAsRead);

router.route("/my").get(verifyToken, NotificationController.getMyNotifications);

module.exports = router;
