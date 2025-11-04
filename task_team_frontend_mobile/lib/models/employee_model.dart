import 'package:task_team_frontend_mobile/models/role_model.dart';

class EmployeeModel {
  final String? id;
  final String employeeId;
  final String employeeName;
  final String email;
  final String phone;
  final String? image;
  final RoleModel roleId;

  EmployeeModel({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.email,
    required this.phone,
    this.image,
    required this.roleId,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['_id']?.toString(),
      employeeId: json['employee_id'].toString(),
      employeeName: json['employee_name'].toString(),
      email: json['email'].toString(),
      phone: json['phone'].toString(),
      image: json['image'],
      roleId: json['role_id'] is Map
          ? RoleModel.fromJson(json['role_id'])
          : RoleModel(
              roleId: json['role_id'] ?? '',
              roleName: '',
              description: '',
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'email': email,
      'phone': phone,
      'image': image,
      'role_id': roleId.toJson(),
    };
  }

  EmployeeModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? email,
    String? phone,
    String? image,
    RoleModel? roleId,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      roleId: roleId ?? this.roleId,
    );
  }

  @override
  String toString() {
    return 'EmployeeModel(id: $id, employeeId: $employeeId, employeeName: $employeeName, '
        'email: $email, phone: $phone, image: $image, roleId: ${roleId.roleId})';
  }
}
