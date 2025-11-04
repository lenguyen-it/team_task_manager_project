import 'package:flutter/material.dart';
import 'package:task_team_frontend_mobile/models/employee_model.dart';
import 'package:task_team_frontend_mobile/services/employee_service.dart';

class EmployeeProvider with ChangeNotifier {
  final EmployeeService _employeeService = EmployeeService();

  List<EmployeeModel> _employees = [];
  List<EmployeeModel> get employees => _employees;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<String> get employeeNames =>
      _employees.map((r) => r.employeeName).toList();

  Future<void> getAllRole() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _employeeService.getAllEmployee();
      _employees = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
