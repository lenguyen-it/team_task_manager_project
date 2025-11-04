class RoleModel {
  final String? id;
  final String roleId;
  final String roleName;
  final String? description;

  RoleModel({
    this.id,
    required this.roleId,
    required this.roleName,
    this.description,
  });

  RoleModel copyWith({
    String? id,
    String? roleId,
    String? roleName,
    String? description,
  }) {
    return RoleModel(
      id: id ?? this.id,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
    );
  }

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['_id']?.toString(),
      roleId: json['role_id'].toString(),
      roleName: json['role_name'].toString(),
      description: json['description'] as String? ?? 'Không có mô tả',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role_id': roleId,
      'role_name': roleName,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'RoleModel(id: $id, roleId: $roleId, roleName: $roleName, description: $description)';
  }
}
