const express = require("express");

const EmployeeController = require("../controllers/employee.controller");
const { verifyToken, authorize } = require("../middlewares/auth.middleware");
const { uploadAvatar } = require("../middlewares/upload.middleware");

const router = express.Router();

router
  .route("/")
  .get(verifyToken, authorize(["admin", "manager"]), EmployeeController.findAll)
  .post(
    verifyToken,
    authorize(["admin", "manager"]),
    uploadAvatar,
    EmployeeController.create
  )
  .delete(
    verifyToken,
    authorize(["admin", "manager"]),
    EmployeeController.deleteAll
  );

router
  .route("/:employee_id")
  .get(verifyToken, EmployeeController.findByEmployeeId)
  .put(verifyToken, uploadAvatar, EmployeeController.updateByEmployeeId)
  .delete(verifyToken, EmployeeController.deleteByEmployeeId);

router
  .route("/:id")
  .get(verifyToken, EmployeeController.findOne)
  .put(verifyToken, uploadAvatar, EmployeeController.update)
  .delete(verifyToken, EmployeeController.delete);

module.exports = router;
