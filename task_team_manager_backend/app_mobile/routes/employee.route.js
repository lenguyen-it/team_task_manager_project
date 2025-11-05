const express = require("express");
const EmployeeController = require("../controllers/employee.controller");
const {
  EmployeeService,
  uploadImage,
} = require("../services/employee.service");

const { verifyToken, authorize } = require("../middlewares/auth.middleware");

const router = express.Router();

router
  .route("/")
  .get(verifyToken, authorize(["admin", "manager"]), EmployeeController.findAll)
  .post(
    verifyToken,
    authorize(["admin", "manager"]),
    EmployeeService.uploadImage.single("image"),
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
  .put(
    verifyToken,
    EmployeeService.uploadImage.single("image"),
    EmployeeController.updateByEmployeeId
  )
  .delete(verifyToken, EmployeeController.deleteByEmployeeId);

router
  .route("/:id")
  .get(verifyToken, EmployeeController.findOne)
  .put(
    verifyToken,
    EmployeeService.uploadImage.single("image"),
    EmployeeController.update
  )
  .delete(verifyToken, EmployeeController.delete);

module.exports = router;
