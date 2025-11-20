// auth.route.js
const express = require("express");
const authController = require("../controllers/auth.controller");
const { verifyToken, authorize } = require("../middlewares/auth.middleware");
const { uploadAvatar } = require("../middlewares/upload.middleware");

const router = express.Router();

router.post("/login", authController.login);

router.post("/logout", verifyToken, authController.logout);

router.post(
  "/register",
  verifyToken,
  authorize(["admin", "manager"]),
  uploadAvatar,
  authController.register
);

// Có thể thêm endpoint khác nếu cần, ví dụ: /me để lấy info user hiện tại
// router.get("/me", verifyToken, (req, res) => res.json(req.user));

module.exports = router;
