class ParticipantConversationModel {
  final String employeeId;
  final String? employeeName;
  final String? email;
  final String? image;
  final String roleConversationId;
  final DateTime joinedAt;
  final DateTime lastSeen;

  ParticipantConversationModel({
    required this.employeeId,
    this.employeeName,
    this.email,
    this.image,
    required this.roleConversationId,
    required this.joinedAt,
    required this.lastSeen,
  });

  factory ParticipantConversationModel.fromJson(Map<String, dynamic> json) {
    return ParticipantConversationModel(
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString(),
      email: json['email']?.toString(),
      image: json['image']?.toString().isNotEmpty == true
          ? json['image'].toString()
          : null,
      roleConversationId: json['role_conversation_id']?.toString() ?? 'member',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'].toString())
          : DateTime.now(),
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'email': email,
      'image': image,
      'role_conversation_id': roleConversationId,
      'joined_at': joinedAt.toIso8601String(),
      'last_seen': lastSeen.toIso8601String(),
    };
  }
}

class OtherEmployee {
  final String employeeId;
  final String employeeName;
  final String? image;

  OtherEmployee({
    required this.employeeId,
    required this.employeeName,
    this.image,
  });

  factory OtherEmployee.fromJson(Map<String, dynamic> json) {
    return OtherEmployee(
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? 'Unknown',
      image: json['image']?.toString().isNotEmpty == true
          ? json['image'].toString()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'image': image,
    };
  }
}
