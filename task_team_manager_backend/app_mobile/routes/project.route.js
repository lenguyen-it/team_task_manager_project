const express = require("express");
const ProjectController = require("../controllers/project.controller");

const router = express.Router();

router
  .route("/")
  .get(ProjectController.findAll)
  .post(ProjectController.create)
  .delete(ProjectController.deleteAll);

router
  .route("/:project_id")
  .get(ProjectController.findByProjectId)
  .put(ProjectController.updateByProjectId)
  .delete(ProjectController.deleteByProjectId);

router
  .route("/:id")
  .get(ProjectController.findOne)
  .put(ProjectController.update)
  .delete(ProjectController.delete);
