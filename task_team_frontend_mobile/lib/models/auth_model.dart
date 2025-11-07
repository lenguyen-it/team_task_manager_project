import 'package:task_team_frontend_mobile/models/employee_model.dart';

class LoginRequest {
  final String employeeId;
  final String employeePassword;

  LoginRequest({
    required this.employeeId,
    required this.employeePassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_password': employeePassword,
    };
  }
}

class RegisterRequest {
  final String employeeId;
  final String employeeName;
  final String employeePassword;
  final String roleId;
  final String email;
  final String? phone;
  final String? image;

  RegisterRequest({
    required this.employeeId,
    required this.employeeName,
    required this.employeePassword,
    required this.roleId,
    required this.email,
    this.phone,
    this.image,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'employee_password': employeePassword,
      'role_id': roleId,
      'email': email,
      'phone': phone,
      'image': image,
    };
  }
}

class LoginResponse {
  final String token;
  final EmployeeInfo employee;

  LoginResponse({
    required this.token,
    required this.employee,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      employee: EmployeeInfo.fromJson(json['employee']),
    );
  }
}

class EmployeeInfo {
  final String employeeId;
  final String roleId;

  EmployeeInfo({
    required this.employeeId,
    required this.roleId,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      employeeId: json['employee_id'],
      roleId: json['role_id'] is Map
          ? json['role_id']['role_id']
          : json['role_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'role_id': roleId,
    };
  }
}

class RegisterResponse {
  final String message;
  final String employeeName;
  final EmployeeModel employee;

  RegisterResponse({
    required this.message,
    required this.employeeName,
    required this.employee,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'],
      employeeName: json['employee_name'],
      employee: EmployeeModel.fromJson(json['employee']),
    );
  }
}
