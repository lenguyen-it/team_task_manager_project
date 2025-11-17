const express = require("express");
const ProjectController = require("../controllers/project.controller");
const { verifyToken, authorize } = require("../middlewares/auth.middleware");

const router = express.Router();

router
  .route("/")
  .get(verifyToken, ProjectController.findAll)
  .post(verifyToken, authorize(["admin", "manager"]), ProjectController.create)
  .delete(
    verifyToken,
    authorize(["admin", "manager"]),
    ProjectController.deleteAll
  );

router
  .route("/:project_id")
  .get(verifyToken, ProjectController.findByProjectId)
  .put(
    verifyToken,
    authorize(["admin", "manager"]),
    ProjectController.updateByProjectId
  )
  .delete(
    verifyToken,
    authorize(["admin", "manager"]),
    ProjectController.deleteByProjectId
  );

router
  .route("/:id")
  .get(verifyToken, ProjectController.findOne)
  .put(verifyToken, authorize(["admin", "manager"]), ProjectController.update)
  .delete(
    verifyToken,
    authorize(["admin", "manager"]),
    ProjectController.delete
  );

module.exports = router;
