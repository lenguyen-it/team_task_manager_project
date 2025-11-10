const express = require("express");
const TaskController = require("../controllers/task.controller");
const { verifyToken, authorize } = require("../middlewares/auth.middleware");

const router = express.Router();

router
  .route("/")
  .get(verifyToken, authorize(["admin", "manager"]), TaskController.findAll)
  .post(verifyToken, authorize(["admin", "manager"]), TaskController.create)
  .delete(
    verifyToken,
    authorize(["admin", "manager"]),
    TaskController.deleteAll
  );

router
  .route("/search/:task_name")
  .get(verifyToken, TaskController.findByTaskName);

router
  .route("/:task_id")
  .get(verifyToken, TaskController.findByTaskId)
  .put(verifyToken, TaskController.updateByTaskId)
  .delete(
    verifyToken,
    authorize(["admin", "manager"]),
    TaskController.deleteByTaskId
  );

router
  .route("/:id")
  .get(verifyToken, TaskController.findOne)
  .put(verifyToken, TaskController.update)
  .delete(verifyToken, authorize(["admin", "manager"]), TaskController.delete);

router
  .route("/employee/:employee_id")
  .get(verifyToken, TaskController.findTaskByEmployee);

module.exports = router;
