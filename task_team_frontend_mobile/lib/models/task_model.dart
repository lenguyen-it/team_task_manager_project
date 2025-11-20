import 'attachment.dart';

enum TaskStatus {
  newTask,
  inProgress,
  overdue,
  done,
  pause,
  waitConfirm;

  String get value => _statusToString(this);

  static TaskStatus fromString(String value) {
    return switch (value) {
      'new_task' => TaskStatus.newTask,
      'in_progress' => TaskStatus.inProgress,
      'overdue' => TaskStatus.overdue,
      'done' => TaskStatus.done,
      'pause' => TaskStatus.pause,
      'wait_comfirm' => TaskStatus.waitConfirm,
      _ => TaskStatus.newTask,
    };
  }

  static String _statusToString(TaskStatus status) {
    return switch (status) {
      TaskStatus.newTask => 'new_task',
      TaskStatus.inProgress => 'in_progress',
      TaskStatus.overdue => 'overdue',
      TaskStatus.done => 'done',
      TaskStatus.pause => 'pause',
      TaskStatus.waitConfirm => 'wait_comfirm',
    };
  }
}

class TaskModel {
  final String? id;
  final String taskId;
  final String taskName;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String priority;
  final TaskStatus status;
  final String? parentTaskId;
  final String projectId;
  final String tasktypeId;
  final List<String> assignedTo;
  final List<Attachment> attachments;
  final String? projectName;

  TaskModel({
    this.id,
    required this.taskId,
    required this.taskName,
    this.description,
    DateTime? startDate,
    this.endDate,
    this.priority = 'low',
    TaskStatus? status,
    this.parentTaskId,
    required this.projectId,
    required this.tasktypeId,
    required this.assignedTo,
    List<Attachment>? attachments,
    this.projectName,
  })  : startDate = startDate ?? DateTime.now(),
        status = status ??
            _calculateInitialStatus(startDate ?? DateTime.now(), endDate),
        attachments = attachments ?? [];

  static TaskStatus _calculateInitialStatus(DateTime start, DateTime? end) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = end != null ? DateTime(end.year, end.month, end.day) : null;

    if (today.isBefore(startDay)) {
      return TaskStatus.newTask;
    }
    if (endDay != null && today.isAfter(endDay)) {
      return TaskStatus.overdue;
    }
    return TaskStatus.inProgress;
  }

  TaskModel copyWith({
    String? id,
    String? taskId,
    String? taskName,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? priority,
    TaskStatus? status,
    String? parentTaskId,
    String? projectId,
    String? tasktypeId,
    List<String>? assignedTo,
    List<Attachment>? attachments,
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
      attachments: attachments ?? this.attachments,
      projectName: projectName ?? this.projectName,
    );
  }

  /// Tự động cập nhật status dựa trên ngày
  /// Chỉ cập nhật nếu status KHÔNG phải là done, pause, hoặc wait
  TaskModel updateStatus() {
    // Giữ nguyên status nếu là done, pause, hoặc wait
    if (status == TaskStatus.done ||
        status == TaskStatus.pause ||
        status == TaskStatus.waitConfirm) {
      return this;
    }

    final newStatus = _calculateInitialStatus(startDate, endDate);
    if (status == newStatus) return this;
    return copyWith(status: newStatus);
  }

  /// Parse từ JSON (API/DB)
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id']?.toString(),
      taskId: json['task_id']?.toString() ?? '',
      taskName: json['task_name']?.toString() ?? '',
      description: json['description'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      priority: json['priority'] ?? 'normal',
      status: TaskStatus.fromString(json['status'] ?? 'new_task'),
      parentTaskId: json['parent_task_id']?.toString(),
      projectId: json['project_id'] is Map
          ? json['project_id']['project_id'].toString()
          : json['project_id'].toString(),
      tasktypeId: json['task_type_id'] is Map
          ? json['task_type_id']['task_type_id'].toString()
          : json['task_type_id'].toString(),
      assignedTo: _parseAssignedTo(json['assigned_to']),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      projectName: json['project_name'],
    );
  }

  static List<String> _parseAssignedTo(dynamic assignedTo) {
    if (assignedTo == null) return [];
    if (assignedTo is List) {
      return assignedTo
          .map((e) {
            if (e is Map) {
              return e['employee_id']?.toString() ?? '';
            }
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (assignedTo is String && assignedTo.isNotEmpty) return [assignedTo];
    return [];
  }

  /// Chuyển sang JSON để gửi API
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'task_id': taskId,
      'task_name': taskName,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'priority': priority,
      'status': status.value,
      'parent_task_id': parentTaskId,
      'project_id': projectId,
      'task_type_id': tasktypeId,
      'assigned_to': assignedTo,
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, taskId: $taskId, taskName: $taskName, '
        'status: $status, priority: $priority, '
        'startDate: $startDate, endDate: $endDate, '
        'assignedTo: ${assignedTo.join(', ')})';
  }
}
