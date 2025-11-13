class Attachment {
  final String? attachmentId;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final int? size;
  final DateTime uploadedAt;
  final String? uploadedBy;

  Attachment({
    this.attachmentId,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.size,
    DateTime? uploadedAt,
    this.uploadedBy,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      attachmentId: json['attachment_id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      fileType: json['file_type'],
      size: json['size'] is num ? json['size'].toInt() : null,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : DateTime.now(),
      uploadedBy: json['uploaded_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attachment_id': attachmentId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'size': size,
      'uploaded_at': uploadedAt.toIso8601String(),
      'uploaded_by': uploadedBy,
    };
  }

  @override
  String toString() {
    return 'Attachment(fileName:$attachmentId $fileName, fileUrl: $fileUrl)';
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
  final String status;
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
    this.status = 'new_task',
    this.parentTaskId,
    required this.projectId,
    required this.tasktypeId,
    required this.assignedTo,
    List<Attachment>? attachments,
    this.projectName,
  })  : startDate = startDate ?? DateTime.now(),
        attachments = attachments ?? [];

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
      status: json['status'] ?? 'new_task',
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
      projectName: json['projectName'],
    );
  }

  static List<String> _parseAssignedTo(dynamic assignedTo) {
    if (assignedTo == null) return [];
    if (assignedTo is List) {
      return assignedTo.map((e) {
        if (e is Map) {
          return e['employee_id']?.toString() ?? '';
        }
        return e.toString();
      }).toList();
    }
    if (assignedTo is String) return [assignedTo];
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
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, taskId: $taskId, taskName: $taskName, '
        'priority: $priority, status: $status, '
        'startDate: $startDate, endDate: $endDate, '
        'projectId: $projectId, tasktypeId: $tasktypeId, '
        'assignedTo: ${assignedTo.join(', ')}, '
        'attachments: ${attachments.length} file(s))';
  }
}
