import 'package:task_team_frontend_mobile/models/employee_model.dart';
import 'package:task_team_frontend_mobile/models/project_model.dart';
import 'package:task_team_frontend_mobile/models/tasktype_model.dart';
import 'package:task_team_frontend_mobile/models/role_model.dart';

class TaskModel {
  final String? id;
  final String taskId;
  final String taskName;
  final String? description;

  final DateTime startDate;
  final DateTime? endDate;

  final String priority;
  final String status;

  final String? parentTaskId;
  final ProjectModel projectId;
  final TasktypeModel tasktypeId;
  final List<EmployeeModel> assignedTo;
  String? projectName;

  TaskModel({
    this.id,
    required this.taskId,
    required this.taskName,
    this.description,
    DateTime? startDate,
    this.endDate,
    this.priority = 'low',
    this.status = 'new_task',
    this.parentTaskId,
    required this.projectId,
    required this.tasktypeId,
    required this.assignedTo,
    this.projectName,
  }) : startDate = startDate ?? DateTime.now();

  TaskModel copyWith({
    String? id,
    String? taskId,
    String? taskName,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? priority,
    String? status,
    String? parentTaskId,
    ProjectModel? projectId,
    TasktypeModel? tasktypeId,
    List<EmployeeModel>? assignedTo,
    String? projectName,
  }) {
    return TaskModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      projectId: projectId ?? this.projectId,
      tasktypeId: tasktypeId ?? this.tasktypeId,
      assignedTo: assignedTo ?? this.assignedTo,
      projectName: projectName ?? this.projectName,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id']?.toString(),
      taskId: json['task_id'].toString(),
      taskName: json['task_name'].toString(),
      description: json['description'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      priority: json['priority'] ?? 'low',
      status: json['status'] ?? 'new_task',
      parentTaskId: json['parent_task_id'],

      // Xử lý project_id - nếu là String thì tạo object dummy
      projectId: json['project_id'] is Map
          ? ProjectModel.fromJson(Map<String, dynamic>.from(json['project_id']))
          : ProjectModel(
              projectId: json['project_id']?.toString() ?? '',
              projectName: '',
              description: '',
              status: '',
            ),

      // Xử lý task_type_id - nếu là String thì tạo object dummy
      tasktypeId: json['task_type_id'] is Map
          ? TasktypeModel.fromJson(
              Map<String, dynamic>.from(json['task_type_id']))
          : TasktypeModel(
              tasktypeId: json['task_type_id']?.toString() ?? '',
              tasktypeName: '',
              description: '',
            ),

      // Xử lý assigned_to - parse cả Map và String
      assignedTo: _parseAssignedTo(json['assigned_to']),

      projectName: json['projectName'],
    );
  }

  // Helper method để parse assigned_to
  static List<EmployeeModel> _parseAssignedTo(dynamic assignedTo) {
    if (assignedTo == null) return [];

    // Nếu là List
    if (assignedTo is List) {
      return assignedTo.map((e) {
        if (e is Map) {
          // Cast Map<dynamic, dynamic> thành Map<String, dynamic>
          return EmployeeModel.fromJson(Map<String, dynamic>.from(e));
        } else {
          // Nếu chỉ là String ID, tạo object dummy
          return EmployeeModel(
            employeeId: e.toString(),
            employeeName: '',
            email: '',
            phone: '',
            roleId: RoleModel(
              roleId: '',
              roleName: '',
              description: '',
            ),
          );
        }
      }).toList();
    }

    // Nếu là String đơn lẻ
    if (assignedTo is String) {
      return [
        EmployeeModel(
          employeeId: assignedTo,
          employeeName: '',
          email: '',
          phone: '',
          roleId: RoleModel(
            roleId: '',
            roleName: '',
            description: '',
          ),
        )
      ];
    }

    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'task_id': taskId,
      'task_name': taskName,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'priority': priority,
      'status': status,
      'parent_task_id': parentTaskId,
      'project_id': projectId.toJson(),
      'task_type_id': tasktypeId.toJson(),
      'assigned_to': assignedTo.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, taskId: $taskId, taskName: $taskName, '
        'priority: $priority, status: $status, '
        'startDate: $startDate, endDate: $endDate, '
        'assignedTo: ${assignedTo.map((e) => e.employeeName).join(', ')})';
  }
}
