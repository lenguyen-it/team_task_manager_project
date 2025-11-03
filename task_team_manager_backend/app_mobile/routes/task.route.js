const express = require("express");
const TaskController = require("../controllers/task.controller");

const router = express.Router();

router
  .route("/")
  .get(TaskController.findAll)
  .post(TaskController.create)
  .delete(TaskController.deleteAll);

router
  .route("/:task_id")
  .get(TaskController.findByTaskId)
  .put(TaskController.updateByTaskId)
  .delete(TaskController.deleteByTaskId);

router
  .route("/:id")
  .get(TaskController.findOne)
  .put(TaskController.update)
  .delete(TaskController.delete);

module.exports = router;
