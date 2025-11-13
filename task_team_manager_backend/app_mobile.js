const express = require("express");
const path = require("path");
const cors = require("cors");

const ApiError = require("./app_mobile/api-error");

const app = express();

const ProjectRoute = require("./app_mobile/routes/project.route");
const TaskRoute = require("./app_mobile/routes/task.route");
const TaskTypeRoute = require("./app_mobile/routes/tasktype.route");
const EmployeeRoute = require("./app_mobile/routes/employee.route");
const RoleRoute = require("./app_mobile/routes/role.route");
const AuthRoutes = require("./app_mobile/routes/auth.route");

app.use(cors());
app.use(express.json());

app.use("/api/uploads", express.static(path.join(__dirname, "uploads")));
app.use("/api/projects", ProjectRoute);
app.use("/api/employees", EmployeeRoute);
app.use("/api/tasks", TaskRoute);
app.use("/api/tasktypes", TaskTypeRoute);
app.use("/api/roles", RoleRoute);
app.use("/api/auth", AuthRoutes);

app.use((req, res, next) => {
  return next(new ApiError(404, "Resource not found"));
});

app.use((err, req, res, next) => {
  return res.status(err.statusCode || 500).json({
    message: err.message || "Internal Server Error",
  });
});

app.get("/", (req, res) => {
  res.json({ message: "Welcome to connect Server" });
});

module.exports = app;
