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
      _employees.map((e) => e.employeeName).toList();
  List<String> get employeeIds => _employees.map((e) => e.employeeId).toList();

  Future<void> getAllEmployee({required String token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _employeeService.getAllEmployee(token);
      _employees = data;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getEmployeeById(String employeeId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _employeeService.getEmployeeById(employeeId, token);
      _employees = [data];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEmployee(EmployeeModel employee, String token) async {
    try {
      final newEmployee =
          await _employeeService.createEmployee(employee, token);
      _employees.add(newEmployee);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmployee(
      String employeeId, EmployeeModel updateEmployee, String token) async {
    try {
      final employee = await _employeeService.updateEmployee(
          employeeId, updateEmployee, token);
      final idx = _employees.indexWhere((e) => e.employeeId == employeeId);
      if (idx != -1) {
        _employees[idx] = employee;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmployee(String employeeId, String token) async {
    try {
      await _employeeService.deleteEmployee(employeeId, token);
      _employees.removeWhere((e) => e.employeeId == employeeId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh
  Future<void> refresh(String token) async {
    await getAllEmployee(token: token);
  }
}
