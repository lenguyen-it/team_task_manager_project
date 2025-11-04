const express = require("express");
const router = express.Router();

const { login, register } = require("../controllers/auth.controller");
const authMiddleware = require("../middlewares/auth.middleware");
const roleMiddleware = require("../middlewares/role.middleware");

router.post("/login", login);

router.post(
  "/register",
  authMiddleware,
  roleMiddleware(["admin", "manager"]),
  register
);

module.exports = router;
