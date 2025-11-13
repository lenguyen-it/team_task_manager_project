import 'dart:io';

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

  Future<bool> createEmployee(EmployeeModel employee, String token,
      {File? imageFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newEmployee = await _employeeService.createEmployee(
        employee,
        token,
        imageFile: imageFile,
      );
      _employees.add(newEmployee);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEmployee(
      String employeeId, EmployeeModel updateEmployee, String token,
      {File? imageFile}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final employee = await _employeeService.updateEmployee(
        employeeId,
        updateEmployee,
        token,
        imageFile: imageFile,
      );

      final idx = _employees.indexWhere((e) => e.employeeId == employeeId);
      if (idx != -1) {
        _employees[idx] = employee;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEmployee(String employeeId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _employeeService.deleteEmployee(employeeId, token);
      _employees.removeWhere((e) => e.employeeId == employeeId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAllEmployee(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _employeeService.deleteAllEmployee(token);
      _employees.clear();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
