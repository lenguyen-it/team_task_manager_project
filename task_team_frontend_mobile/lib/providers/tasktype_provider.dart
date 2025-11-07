import 'package:flutter/material.dart';
import 'package:task_team_frontend_mobile/models/tasktype_model.dart';
import 'package:task_team_frontend_mobile/services/tasktype_service.dart';

class TasktypeProvider with ChangeNotifier {
  final TasktypeService _tasktypeService = TasktypeService();

  List<TasktypeModel> _tasktypes = [];
  List<TasktypeModel> get tasktypes => _tasktypes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<String> get tasktypeNames =>
      _tasktypes.map((r) => r.tasktypeName).toList();

  Future<void> getAllTaskType({required String token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _tasktypeService.getAllTaskType(token);
      _tasktypes = data;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getTaskTypeById(String tasktypeId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _tasktypeService.getTaskTypeById(tasktypeId, token);
      _tasktypes = [data];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTaskType(TasktypeModel tasktype, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTaskType =
          await _tasktypeService.createTaskType(tasktype, token);
      _tasktypes.add(newTaskType);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTaskType(
      String tasktypeId, TasktypeModel updateTaskType, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final tasktype = await _tasktypeService.updateTaskType(
          tasktypeId, updateTaskType, token);
      final idx = _tasktypes.indexWhere((e) => e.tasktypeId == tasktypeId);
      if (idx != -1) {
        _tasktypes[idx] = tasktype;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTaskType(String tasktypeId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _tasktypeService.deleteTaskType(tasktypeId, token);
      _tasktypes.removeWhere((e) => e.tasktypeId == tasktypeId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAllTaskType(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _tasktypeService.deleteAllTaskType(token);

      _tasktypes.clear();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
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
    await getAllTaskType(token: token);
  }
}
