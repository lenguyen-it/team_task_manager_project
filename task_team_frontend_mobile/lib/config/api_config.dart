import 'package:task_team_frontend_mobile/config/env.dart';

class ApiConfig {
  static String baseUrl = Env.baseUrl;

  //=====API TASK=======
  static String get createTask {
    return '$baseUrl/tasks';
  }

  static String get getAllTask {
    return '$baseUrl/tasks';
  }

  static String getTaskById(String taskId) {
    return '$baseUrl/tasks/$taskId';
  }

  static String updateTask(String taskId) {
    return '$baseUrl/tasks/$taskId';
  }

  static String deleteTask(String taskId) {
    return '$baseUrl/tasks/$taskId';
  }

  static String get deleteAllTask {
    return '$baseUrl/tasks';
  }

  //========API TASK TYPE ============
  static String get createTaskType {
    return '$baseUrl/tasktypes';
  }

  static String get getAllTaskType {
    return '$baseUrl/tasktypes';
  }

  static String getTaskTypeById(String tasktypeId) {
    return '$baseUrl/tasktypes/$tasktypeId';
  }

  static String updateTaskType(String tasktypeId) {
    return '$baseUrl/tasktypes/$tasktypeId';
  }

  static String deleteTaskType(String tasktypeId) {
    return '$baseUrl/tasktypes/$tasktypeId';
  }

  static String get deleteAllTaskType {
    return '$baseUrl/tasktypes';
  }

  //========API EMPLOYEE=============
  static String get createEmployee {
    return '$baseUrl/employees';
  }

  static String get getAllEmployee {
    return '$baseUrl/employees';
  }

  static String getEmployeeById(String employeeId) {
    return '$baseUrl/employees/$employeeId';
  }

  static String updateEmployee(String employeeId) {
    return '$baseUrl/employees/$employeeId';
  }

  static String deleteEmployee(String employeeId) {
    return '$baseUrl/employees/$employeeId';
  }

  static String get deleteAllEmployee {
    return '$baseUrl/employees';
  }

  //========API PROJECT==============
  static String get createProject {
    return '$baseUrl/projects';
  }

  static String get getAllProject {
    return '$baseUrl/projects';
  }

  static String getProjectById(String projectId) {
    return '$baseUrl/projects/$projectId';
  }

  static String updateProject(String projectId) {
    return '$baseUrl/projects/$projectId';
  }

  static String deleteProject(String projectId) {
    return '$baseUrl/projects/$projectId';
  }

  static String get deleteAllProject {
    return '$baseUrl/projects';
  }

  //========API ROLE=================
  static String get createRole {
    return '$baseUrl/roles';
  }

  static String get getAllRole {
    return '$baseUrl/roles';
  }

  static String getRoleById(String roleId) {
    return '$baseUrl/roles/$roleId';
  }

  static String updateRole(String roleId) {
    return '$baseUrl/roles/$roleId';
  }

  static String deleteRole(String roleId) {
    return '$baseUrl/roles/$roleId';
  }

  static String get deleteAllRole {
    return '$baseUrl/roles';
  }
}
