import 'package:task_team_frontend_mobile/config/env.dart';

class ApiConfig {
  // static String getUrl = Env.baseUrl;

  static String getUrl = Env.localUrl;

  //=====API TASK=======
  static String get createTask {
    return '$getUrl/api/tasks';
  }

  static String get getAllTask {
    return '$getUrl/api/tasks';
  }

  static String getTaskById(String taskId) {
    return '$getUrl/api/tasks/$taskId';
  }

  static String getTaskByEmployee(String employeeId) {
    return '$getUrl/api/tasks/employee/$employeeId';
  }

  static String getTaskByName(String taskName) {
    return '$getUrl/api/tasks/search/$taskName';
  }

  static String updateTask(String taskId) {
    return '$getUrl/api/tasks/$taskId';
  }

  //Chỉ cập nhật file
  static String updateOnlyFileforTask(String taskId) {
    return '$getUrl/api/tasks/$taskId/attachments';
  }

  static String deleteTask(String taskId) {
    return '$getUrl/api/tasks/$taskId';
  }

  static String get deleteAllTask {
    return '$getUrl/api/tasks';
  }

  //========API TASK TYPE ============
  static String get createTaskType {
    return '$getUrl/api/tasktypes';
  }

  static String get getAllTaskType {
    return '$getUrl/api/tasktypes';
  }

  static String getTaskTypeById(String tasktypeId) {
    return '$getUrl/api/tasktypes/$tasktypeId';
  }

  static String updateTaskType(String tasktypeId) {
    return '$getUrl/api/tasktypes/$tasktypeId';
  }

  static String deleteTaskType(String tasktypeId) {
    return '$getUrl/api/tasktypes/$tasktypeId';
  }

  static String get deleteAllTaskType {
    return '$getUrl/api/tasktypes';
  }

  //========API EMPLOYEE=============
  static String get createEmployee {
    return '$getUrl/api/employees';
  }

  static String get getAllEmployee {
    return '$getUrl/api/employees';
  }

  static String getEmployeeById(String employeeId) {
    return '$getUrl/api/employees/$employeeId';
  }

  static String updateEmployee(String employeeId) {
    return '$getUrl/api/employees/$employeeId';
  }

  static String deleteEmployee(String employeeId) {
    return '$getUrl/api/employees/$employeeId';
  }

  static String get deleteAllEmployee {
    return '$getUrl/api/employees';
  }

  //========API PROJECT==============
  static String get createProject {
    return '$getUrl/api/projects';
  }

  static String get getAllProject {
    return '$getUrl/api/projects';
  }

  static String getProjectById(String projectId) {
    return '$getUrl/api/projects/$projectId';
  }

  static String updateProject(String projectId) {
    return '$getUrl/api/projects/$projectId';
  }

  static String deleteProject(String projectId) {
    return '$getUrl/api/projects/$projectId';
  }

  static String get deleteAllProject {
    return '$getUrl/api/projects';
  }

  //========API ROLE=================
  static String get createRole {
    return '$getUrl/api/roles';
  }

  static String get getAllRole {
    return '$getUrl/api/roles';
  }

  static String getRoleById(String roleId) {
    return '$getUrl/api/roles/$roleId';
  }

  static String updateRole(String roleId) {
    return '$getUrl/api/roles/$roleId';
  }

  static String deleteRole(String roleId) {
    return '$getUrl/api/roles/$roleId';
  }

  static String get deleteAllRole {
    return '$getUrl/api/roles';
  }

  //========Login và các quyền aip khác ==============

  static String get login {
    return '$getUrl/api/auth/login';
  }

  static String get logout {
    return '$getUrl/api/auth/logout';
  }

  static String get resgiter {
    return '$getUrl/api/auth/resgister';
  }

  //========================API Activity Logs=======================

  static String get getAllActivityLogs {
    return '$getUrl/api/activitylogs';
  }

  static String get getMyLogs {
    return '$getUrl/api/activitylogs/me';
  }

  //========================API NOTIFICATION=======================

  static String get getAllNotifications {
    return '$getUrl/api/notifications';
  }

  static String get getMyNotifications {
    return '$getUrl/api/notifications/my';
  }

  static String get markAllAsRead {
    return '$getUrl/api/notifications/readall';
  }

  static String markAsRead(String id) {
    return '$getUrl/api/notifications/$id/read';
  }

  //=====================API CONVERSATION=============================

  //Lấy danh sách conversations|| GET
  static String get getConversations {
    return '$getUrl/api/conversations';
  }

  //Tạo conversation|| POST
  static String get createConversation {
    return '$getUrl/api/conversations';
  }

  //Lấy chi tiết conversation|| GET
  static String getConversationDetails(String conversationId) {
    return '$getUrl/api/conversations/$conversationId';
  }

  //Cập nhật conversation|| PUT
  static String updateConversation(String conversationId) {
    return '$getUrl/api/conversations/$conversationId';
  }

  //Xóa conversation|| DELETE
  static String deleteConversation(String conversationId) {
    return '$getUrl/api/conversations/$conversationId';
  }

  //Thêm participants vào conversation|| POST
  static String addParticipants(String conversationId) {
    return '$getUrl/api/conversations/$conversationId/participants';
  }

  //Xóa participant khỏi conversation|| DELETE
  static String removeParticipant(String conversationId, String participantId) {
    return '$getUrl/api/conversations/$conversationId/participants/$participantId';
  }

  //Rời khỏi conversation|| POST
  static String leaveConversation(String conversationId) {
    return '$getUrl/api/conversations/$conversationId/leave';
  }

  //Lấy tất cả conversations của một task
  static String getTaskConversations(String taskId) {
    return '$getUrl/api/conversations/task/$taskId/conversations';
  }

  //Tạo conversation mới trong task
  static String createTaskConversation(String taskId) {
    return '$getUrl/api/conversations/task/$taskId/conversations';
  }

  /// Admin/Manager tham gia vào conversation của task
  static String joinTaskConversation(String taskId, String conversationId) {
    return '$getUrl/api/conversations/tasks/$taskId/conversations/$conversationId/join';
  }

  //Lấy tổng số tin nhắn chưa đọc
  static String get getTotalUnreadCount {
    return '$getUrl/api/conversations/unread/total';
  }

  //==========================API MESSAGE================================

  //Tạo message|| POST
  static String get createMessage {
    return '$getUrl/api/messages';
  }

  //Lấy danh sách tin nhắn theo đoạn chat || GET
  static String getMessages(String conversationId) {
    return '$getUrl/api/messages/conversation/$conversationId';
  }

  // Đánh dấu tin nhắn đã đọc
  static String markMessageAsRead(String messageId) {
    return '$getUrl/api/messages/$messageId/read';
  }

  // Đánh dấu tất cả đã đọc
  static String markAllMessagesAsRead(String conversationId) {
    return '$getUrl/api/messages/$conversationId/readall';
  }

  // Xóa tin nhắn
  static String deleteMessage(String messageId) {
    return '$getUrl/api/messages/$messageId';
  }

  // Tìm kiếm tin nhắn
  static String searchMessages(String conversationId) {
    return '$getUrl/api/messages/$conversationId/search';
  }

  // Lấy số tin nhắn chưa đọc
  static String getUnreadMessageCount(String conversationId) {
    return '$getUrl/api/messages/$conversationId/unreadcount';
  }

  // Upload file đính kèm
  static String uploadMessageFile() {
    return '$getUrl/api/messages/upload';
  }
}
