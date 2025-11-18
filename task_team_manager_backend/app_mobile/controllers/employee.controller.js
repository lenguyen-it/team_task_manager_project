const ApiError = require("../api-error");
const MongoDB = require("../utils/mongodb.util");
const EmployeeService = require("../services/employee.service");

exports.create = async (req, res, next) => {
  console.log("req.body: ", req.body);
  console.log("req.file:", req.file);

  if (!req.body?.employee_id && !req.body.employee_name) {
    return next(new ApiError(400, "Employee id and name cannot be empty"));
  }

  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const image = req.file ? `/uploads/images/${req.file.filename}` : null;
    const employee = await employeeService.create(req.body, image);

    res.status(201).json(employee);
  } catch (error) {
    return next(new ApiError(500, "Error creating employee: " + error.message));
  }
};

exports.findAll = async (req, res, next) => {
  let data = [];

  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const { employee_name } = req.query;

    if (employee_name) {
      data = await employeeService.findByEmployeeName(employee_name);
    } else {
      data = await employeeService.find({});
    }
  } catch (error) {
    return next(
      new ApiError(500, "Error retrieving employees: " + error.message)
    );
  }

  return res.send(data);
};

exports.findOne = async (req, res, next) => {
  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const employee = await employeeService.findById(req.params.id);

    if (!employee) {
      return next(new ApiError(404, "Employee not found"));
    }

    return res.send(employee);
  } catch (error) {
    return next(
      new ApiError(500, "Error retrieving employee: " + error.message)
    );
  }
};

exports.findByEmployeeId = async (req, res, next) => {
  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const employee = await employeeService.findByEmployeeId(
      req.params.employee_id
    );
    if (!employee) {
      return next(new ApiError(404, "Employee not found"));
    }
    res.json(employee);
  } catch (error) {
    return next(
      new ApiError(500, "Error retrieving employee: " + error.message)
    );
  }
};

exports.findByEmployeeName = async (req, res, next) => {
  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const employees = await employeeService.findByEmployeeName(
      req.query.employee_name || ""
    );
    res.json(employees);
  } catch (error) {
    return next(
      new ApiError(500, "Error searching employees: " + error.message)
    );
  }
};

exports.update = async (req, res, next) => {
  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const image = req.file
      ? `/uploads/images/${req.file.filename}`
      : req.body.image || null;

    const updated = await employeeService.update(
      req.params.id,
      req.body,
      image
    );

    if (!updated.value) {
      return next(new ApiError(404, "Employee not found"));
    }

    res.json(updated.value);
  } catch (error) {
    return next(new ApiError(500, "Error updating employee: " + error.message));
  }
};

exports.updateByEmployeeId = async (req, res, next) => {
  console.log("req.body:", req.body);
  console.log("req.file:", req.file);

  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const image = req.file
      ? `/uploads/images/${req.file.filename}`
      : req.body.image || null;

    console.log("Image path to save:", image);

    const updated = await employeeService.updateByEmployeeId(
      req.params.employee_id,
      req.body,
      image
    );

    if (!updated) {
      return next(new ApiError(404, "Employee not found"));
    }

    console.log("Updated employee:", updated);
    res.json(updated);
  } catch (error) {
    return next(new ApiError(500, "Error updating employee: " + error.message));
  }
};

exports.delete = async (req, res, next) => {
  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const deleted = await employeeService.delete(req.params.id);

    if (!deleted.value) {
      return next(new ApiError(404, "Employee not found"));
    }

    res.json({ message: "Employee deleted successfully" });
  } catch (error) {
    return next(new ApiError(500, "Error deleting employee: " + error.message));
  }
};

exports.deleteByEmployeeId = async (req, res, next) => {
  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const deleted = await employeeService.deleteByEmployeeId(
      req.params.employee_id
    );

    if (!deleted) {
      return next(new ApiError(404, "Employee not found"));
    }

    res.json({ message: "Employee deleted successfully" });
  } catch (error) {
    return next(new ApiError(500, "Error deleting employee: " + error.message));
  }
};

exports.deleteAll = async (req, res, next) => {
  try {
    // const employeeService = new EmployeeService(MongoDB.client);
    const employeeService = new EmployeeService();

    const deletedCount = await employeeService.deleteAll();

    res.json({ message: `${deletedCount} employees deleted successfully` });
  } catch (error) {
    return next(
      new ApiError(500, "Error deleting all employees: " + error.message)
    );
  }
};
