import 'package:task_team_frontend_mobile/models/employee_model.dart';
import 'package:task_team_frontend_mobile/models/project_model.dart';
import 'package:task_team_frontend_mobile/models/tasktype_model.dart';

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
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id']?.toString(),
      taskId: json['task_id'] ?? '',
      taskName: json['task_name'] ?? '',
      description: json['description'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      priority: json['priority'] ?? 'low',
      status: json['status'] ?? 'new_task',
      parentTaskId: json['parent_task_id'],
      projectId: ProjectModel.fromJson(json['project_id']),
      tasktypeId: TasktypeModel.fromJson(json['tasktype_id']),
      assignedTo: (json['assigned_to'] as List?)
              ?.map((e) => EmployeeModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'task_name': taskName,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'priority': priority,
      'status': status,
      'parent_task_id': parentTaskId,
      'project_id': projectId.toJson(),
      'tasktype_id': tasktypeId.toJson(),
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
