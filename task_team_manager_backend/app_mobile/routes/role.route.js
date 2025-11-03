const express = require("express");
const RoleController = require("../controllers/role.controller");

const router = express.Router();

router
  .route("/")
  .get(RoleController.findAll)
  .post(RoleController.create)
  .delete(RoleController.deleteAll);

router
  .route("/:role_id")
  .get(RoleController.findByRoleId)
  .put(RoleController.updateByRoleId)
  .delete(RoleController.deleteByRoleId);

router
  .route("/:id")
  .get(RoleController.findOne)
  .put(RoleController.update)
  .delete(RoleController.delete);
