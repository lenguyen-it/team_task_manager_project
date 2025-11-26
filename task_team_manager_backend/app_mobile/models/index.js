const EmployeeModel = require("./employee.model");
const TaskTypeModel = require("./tasktype.model");
const ProjectModel = require("./project.model");
const RoleModel = require("./role.model");
const TaskModel = require("./task.model");
const Notification = require("./notification.model");
const ActivityLog = require("./activitylog.model");
const MessageModel = require("./message.model");
const ConversationModel = require("./conversation.model");
const ParticipantConversationModel = require("./participantconversation.model");

module.export = {
  EmployeeModel,
  TaskModel,
  TaskTypeModel,
  ProjectModel,
  RoleModel,
  Notification,
  ActivityLog,
  MessageModel,
  ConversationModel,
  ParticipantConversationModel,
};
