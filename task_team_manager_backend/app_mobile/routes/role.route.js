const express = require("express");
const RoleController = require("../controllers/role.controller");
const { verifyToken, authorize } = require("../middlewares/auth.middleware");

const router = express.Router();

router
  .route("/")
  .get(verifyToken, authorize(["admin", "manager"]), RoleController.findAll)
  .post(verifyToken, authorize(["admin", "manager"]), RoleController.create)
  .delete(
    verifyToken,
    authorize(["admin", "manager"]),
    RoleController.deleteAll
  );

router
  .route("/:role_id")
  .get(verifyToken, RoleController.findByRoleId)
  .put(verifyToken, RoleController.updateByRoleId)
  .delete(verifyToken, RoleController.deleteByRoleId);

router
  .route("/:id")
  .get(verifyToken, RoleController.findOne)
  .put(verifyToken, RoleController.update)
  .delete(verifyToken, RoleController.delete);

module.exports = router;
