const express = require("express");
const TaskController = require("../controllers/task.controller");
const { verifyToken, authorize } = require("../middlewares/auth.middleware");
const { uploadFile } = require("../middlewares/upload.middleware");

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

// Route để thêm attachments vào task
router
  .route("/:task_id/attachments")
  .post(
    verifyToken,
    uploadFile.array("files", 5),
    TaskController.addAttachmentsByTaskId
  );

// Route để xóa một attachment
router
  .route("/:task_id/attachments/:attachment_id")
  .delete(verifyToken, TaskController.removeAttachment);

// Route cập nhật task theo task_id (có thể kèm files)
router
  .route("/:task_id")
  .get(verifyToken, TaskController.findByTaskId)
  .put(verifyToken, uploadFile.array("files", 5), TaskController.updateByTaskId)
  .delete(
    verifyToken,
    authorize(["admin", "manager"]),
    TaskController.deleteByTaskId
  );

router
  .route("/:id")
  .get(verifyToken, TaskController.findOne)
  .put(verifyToken, uploadFile.array("files", 5), TaskController.update)
  .delete(verifyToken, authorize(["admin", "manager"]), TaskController.delete);

router
  .route("/employee/:employee_id")
  .get(verifyToken, TaskController.findTaskByEmployee);

module.exports = router;
