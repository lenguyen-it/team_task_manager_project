import 'package:task_team_frontend_mobile/config/env.dart';

class ApiConfig {
  // static String getUrl = Env.baseUrl;

  static String getUrl = Env.localUrl;

  //=====API TASK=======
  static String get createTask {
    return '$getUrl/tasks';
  }

  static String get getAllTask {
    return '$getUrl/tasks';
  }

  static String getTaskById(String taskId) {
    return '$getUrl/tasks/$taskId';
  }

  static String updateTask(String taskId) {
    return '$getUrl/tasks/$taskId';
  }

  static String deleteTask(String taskId) {
    return '$getUrl/tasks/$taskId';
  }

  static String get deleteAllTask {
    return '$getUrl/tasks';
  }

  //========API TASK TYPE ============
  static String get createTaskType {
    return '$getUrl/tasktypes';
  }

  static String get getAllTaskType {
    return '$getUrl/tasktypes';
  }

  static String getTaskTypeById(String tasktypeId) {
    return '$getUrl/tasktypes/$tasktypeId';
  }

  static String updateTaskType(String tasktypeId) {
    return '$getUrl/tasktypes/$tasktypeId';
  }

  static String deleteTaskType(String tasktypeId) {
    return '$getUrl/tasktypes/$tasktypeId';
  }

  static String get deleteAllTaskType {
    return '$getUrl/tasktypes';
  }

  //========API EMPLOYEE=============
  static String get createEmployee {
    return '$getUrl/employees';
  }

  static String get getAllEmployee {
    return '$getUrl/employees';
  }

  static String getEmployeeById(String employeeId) {
    return '$getUrl/employees/$employeeId';
  }

  static String updateEmployee(String employeeId) {
    return '$getUrl/employees/$employeeId';
  }

  static String deleteEmployee(String employeeId) {
    return '$getUrl/employees/$employeeId';
  }

  static String get deleteAllEmployee {
    return '$getUrl/employees';
  }

  //========API PROJECT==============
  static String get createProject {
    return '$getUrl/projects';
  }

  static String get getAllProject {
    return '$getUrl/projects';
  }

  static String getProjectById(String projectId) {
    return '$getUrl/projects/$projectId';
  }

  static String updateProject(String projectId) {
    return '$getUrl/projects/$projectId';
  }

  static String deleteProject(String projectId) {
    return '$getUrl/projects/$projectId';
  }

  static String get deleteAllProject {
    return '$getUrl/projects';
  }

  //========API ROLE=================
  static String get createRole {
    return '$getUrl/roles';
  }

  static String get getAllRole {
    return '$getUrl/roles';
  }

  static String getRoleById(String roleId) {
    return '$getUrl/roles/$roleId';
  }

  static String updateRole(String roleId) {
    return '$getUrl/roles/$roleId';
  }

  static String deleteRole(String roleId) {
    return '$getUrl/roles/$roleId';
  }

  static String get deleteAllRole {
    return '$getUrl/roles';
  }
}
