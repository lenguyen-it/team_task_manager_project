const express = require("express");
const EmployeeController = require("../controllers/employee.controller");

const router = express.Router();

router
  .route("/")
  .get(EmployeeController.findAll)
  .post(EmployeeController.create)
  .delete(EmployeeController.deleteAll);

router
  .route("/:employee_id")
  .get(EmployeeController.findByEmployeeId)
  .put(EmployeeController.updateByEmployeeId)
  .delete(EmployeeController.deleteByEmployeeId);

router
  .route("/:id")
  .get(EmployeeController.findOne)
  .put(EmployeeController.update)
  .delete(EmployeeController.delete);

module.exports = router;
