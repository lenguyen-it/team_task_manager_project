const express = require("express");
const TaskTypeController = require("../controllers/tasktype.controller");

const router = express.Router();

router
  .route("/")
  .get(TaskTypeController.findAll)
  .post(TaskTypeController.create)
  .delete(TaskTypeController.deleteAll);

router
  .route("/:task_type_id")
  .get(TaskTypeController.findByTaskTypeId)
  .put(TaskTypeController.updateByTaskTypeId)
  .delete(TaskTypeController.deleteByTaskTypeId);

router
  .route("/:id")
  .get(TaskTypeController.findOne)
  .put(TaskTypeController.update)
  .delete(TaskTypeController.delete);
