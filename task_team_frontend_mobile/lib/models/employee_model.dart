class EmployeeModel {
  final String? id;
  final String employeeId;
  final String employeeName;
  final String email;
  final String phone;
  final String? image;
  final DateTime? birth;
  final String? address;
  final String roleId;

  EmployeeModel({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.email,
    required this.phone,
    this.image,
    this.birth,
    this.address,
    required this.roleId,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    print('═══════════════════════════════════════');
    print('Full JSON: $json');
    print('═══════════════════════════════════════');

    return EmployeeModel(
      id: json['_id']?.toString(),
      employeeId: json['employee_id'].toString(),
      employeeName: json['employee_name'].toString(),
      email: json['email'].toString(),
      phone: json['phone'].toString(),
      image: json['image'],
      birth: json['birth'] != null ? DateTime.parse(json['birth']) : null,
      address: json['address'],
      roleId: json['role_id'] is Map
          ? json['role_id']['role_id'].toString()
          : json['role_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'email': email,
      'phone': phone,
      'image': image,
      'birth': birth?.toIso8601String(),
      'address': address,
      'role_id': roleId,
    };
  }

  EmployeeModel copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? email,
    String? phone,
    String? image,
    String? address,
    DateTime? birth,
    String? roleId,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      birth: birth ?? this.birth,
      address: address ?? this.address,
      roleId: roleId ?? this.roleId,
    );
  }

  @override
  String toString() {
    return 'EmployeeModel(id: $id, employeeId: $employeeId, employeeName: $employeeName, '
        'email: $email, phone: $phone, birth: $birth, address: $address, image: $image, roleId: $roleId)';
  }
}
