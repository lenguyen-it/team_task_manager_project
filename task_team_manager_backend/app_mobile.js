const express = require("express");
const path = require("path");
const cors = require("cors");

const ApiError = require("./app_mobile/api-error");
const notificationScheduler = require("./app_mobile/services/notification.scheduler.service");

const app = express();

const ProjectRoute = require("./app_mobile/routes/project.route");
const TaskRoute = require("./app_mobile/routes/task.route");
const TaskTypeRoute = require("./app_mobile/routes/tasktype.route");
const EmployeeRoute = require("./app_mobile/routes/employee.route");
const RoleRoute = require("./app_mobile/routes/role.route");
const AuthRoute = require("./app_mobile/routes/auth.route");
const NotificationRoute = require("./app_mobile/routes/notification.route");
const ActivityLogRoute = require("./app_mobile/routes/activitylog.route");
const MessageRoutes = require("./app_mobile/routes/message.route");
const ConversationRoutes = require("./app_mobile/routes/conversation.route");

app.use(cors());
app.use(express.json());

app.use("/api/uploads", express.static(path.join(__dirname, "uploads")));
app.use("/api/projects", ProjectRoute);
app.use("/api/employees", EmployeeRoute);
app.use("/api/tasks", TaskRoute);
app.use("/api/tasktypes", TaskTypeRoute);
app.use("/api/roles", RoleRoute);
app.use("/api/auth", AuthRoute);
app.use("/api/notifications", NotificationRoute);
app.use("/api/activitylogs", ActivityLogRoute);
app.use("/api/messages", MessageRoutes);
app.use("/api/conversations", ConversationRoutes);

notificationScheduler.start();

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
