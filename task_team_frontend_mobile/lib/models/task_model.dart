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
  final String projectId;
  final String tasktypeId;
  final List<String> assignedTo;
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
    String? projectId,
    String? tasktypeId,
    List<String>? assignedTo,
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

      // Xử lý project_id - lấy ID dạng String
      projectId: json['project_id'] is Map
          ? json['project_id']['project_id'].toString()
          : json['project_id'].toString(),

      // Xử lý task_type_id - lấy ID dạng String
      tasktypeId: json['task_type_id'] is Map
          ? json['task_type_id']['task_type_id'].toString()
          : json['task_type_id'].toString(),

      // Xử lý assigned_to - chuyển thành List<String>
      assignedTo: _parseAssignedTo(json['assigned_to']),

      projectName: json['projectName'],
    );
  }

  // Helper method để parse assigned_to thành List<String>
  static List<String> _parseAssignedTo(dynamic assignedTo) {
    if (assignedTo == null) return [];

    // Nếu là List
    if (assignedTo is List) {
      return assignedTo.map((e) {
        if (e is Map) {
          // Nếu là Map, lấy employee_id
          return e['employee_id'].toString();
        } else {
          // Nếu đã là String ID
          return e.toString();
        }
      }).toList();
    }

    // Nếu là String đơn lẻ
    if (assignedTo is String) {
      return [assignedTo];
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
      'project_id': projectId,
      'task_type_id': tasktypeId,
      'assigned_to': assignedTo,
    };
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, taskId: $taskId, taskName: $taskName, '
        'priority: $priority, status: $status, '
        'startDate: $startDate, endDate: $endDate, '
        'projectId: $projectId, tasktypeId: $tasktypeId, '
        'assignedTo: ${assignedTo.join(', ')})';
  }
}
