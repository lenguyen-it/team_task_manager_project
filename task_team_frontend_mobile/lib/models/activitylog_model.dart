class ActivityLogModel {
  final String? id;
  final String employeeId;
  final String roleId;
  final String action;
  final String? targetType;
  final String? targetId;
  final List<ActivityChange>? changes;
  final String status;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityLogModel({
    this.id,
    required this.employeeId,
    required this.roleId,
    required this.action,
    this.targetType,
    this.targetId,
    this.changes,
    required this.status,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['_id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      roleId: json['role_id'] ?? '',
      action: json['action'] ?? '',
      targetType: json['target_type'],
      targetId: json['target_id'],
      changes: json['changes'] != null
          ? List<ActivityChange>.from(
              (json['changes'] as List).map((e) => ActivityChange.fromJson(e)))
          : null,
      status: json['status'] ?? 'success',
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employee_id': employeeId,
      'role_id': roleId,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'changes': changes?.map((e) => e.toJson()).toList(),
      'status': status,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Thêm copyWith ở đây
  ActivityLogModel copyWith({
    String? id,
    String? employeeId,
    String? roleId,
    String? action,
    String? targetType,
    String? targetId,
    List<ActivityChange>? changes,
    String? status,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityLogModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      roleId: roleId ?? this.roleId,
      action: action ?? this.action,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      changes: changes ?? this.changes,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ActivityChange {
  final String? field;
  final dynamic oldValue;
  final dynamic newValue;

  ActivityChange({this.field, this.oldValue, this.newValue});

  factory ActivityChange.fromJson(Map<String, dynamic> json) {
    return ActivityChange(
      field: json['field'],
      oldValue: json['old_value'],
      newValue: json['new_value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'old_value': oldValue,
      'new_value': newValue,
    };
  }
}
