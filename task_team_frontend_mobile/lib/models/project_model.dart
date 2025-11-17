class ProjectModel {
  final String? id;
  final String projectId;
  final String projectName;
  final String projectManagerId;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;

  ProjectModel({
    this.id,
    required this.projectId,
    required this.projectName,
    required this.projectManagerId,
    this.description,
    DateTime? startDate,
    this.endDate,
    required this.status,
  }) : startDate = startDate ?? DateTime.now();

  ProjectModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? projectManagerId,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      projectManagerId: projectManagerId ?? this.projectManagerId,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['_id']?.toString(),
      projectId: json['project_id'].toString(),
      projectName: json['project_name'].toString(),
      projectManagerId: json['project_manager_id'].toString(),
      description: json['description'] as String? ?? 'Không có mô tả',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      status: json['status'] ?? 'planning',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'project_id': projectId,
      'project_name': projectName,
      'project_manager_id': projectManagerId,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
    };
  }

  @override
  String toString() {
    return 'ProjectModel(id: $id, projectId: $projectId, projectName: $projectName, projectManagerId: $projectManagerId, '
        'description: $description, startDate: $startDate, endDate: $endDate, status: $status)';
  }
}
