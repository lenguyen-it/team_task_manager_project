class TasktypeModel {
  final String? id;
  final String tasktypeId;
  final String tasktypeName;
  final String? description;

  TasktypeModel({
    this.id,
    required this.tasktypeId,
    required this.tasktypeName,
    this.description,
  });

  TasktypeModel copyWith({
    String? id,
    String? tasktypeId,
    String? tasktypeName,
    String? description,
  }) {
    return TasktypeModel(
      id: id ?? this.id,
      tasktypeId: tasktypeId ?? this.tasktypeId,
      tasktypeName: tasktypeName ?? this.tasktypeName,
      description: description ?? this.description,
    );
  }

  factory TasktypeModel.fromJson(Map<String, dynamic> json) {
    return TasktypeModel(
      id: json['_id']?.toString(),
      tasktypeId: json['task_type_id'].toString(),
      tasktypeName: json['task_type_name'].toString(),
      description: json['description'] as String? ?? 'Không có mô tả',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'task_type_id': tasktypeId,
      'task_type_name': tasktypeName,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'TaskTypeModel(id: $id, tasktypeId: $tasktypeId, tasktypeName: $tasktypeName, description: $description)';
  }
}
