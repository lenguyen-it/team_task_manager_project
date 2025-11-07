const express = require("express");
const TaskTypeController = require("../controllers/tasktype.controller");
const { verifyToken, authorize } = require("../middlewares/auth.middleware");

const router = express.Router();

router
  .route("/")
  .get(verifyToken, TaskTypeController.findAll)
  .post(verifyToken, authorize(["admin", "manager"]), TaskTypeController.create)
  .delete(
    verifyToken,
    authorize(["admin", "manager"]),
    TaskTypeController.deleteAll
  );

router
  .route("/:task_type_id")
  .get(verifyToken, TaskTypeController.findByTaskTypeId)
  .put(
    verifyToken,
    authorize(["admin", "manager"]),
    TaskTypeController.updateByTaskTypeId
  )
  .delete(
    verifyToken,
    authorize(["admin", "manager"]),
    TaskTypeController.deleteByTaskTypeId
  );

router
  .route("/:id")
  .get(verifyToken, TaskTypeController.findOne)
  .put(verifyToken, authorize(["admin", "manager"]), TaskTypeController.update)
  .delete(
    verifyToken,
    authorize(["admin", "manager"]),
    TaskTypeController.delete
  );

module.exports = router;
