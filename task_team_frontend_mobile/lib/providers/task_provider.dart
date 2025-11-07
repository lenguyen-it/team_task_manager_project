import 'package:flutter/material.dart';
import 'package:task_team_frontend_mobile/models/task_model.dart';
import 'package:task_team_frontend_mobile/services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<String> get taskNames => _tasks.map((t) => t.taskName).toList();
  List<String> get taskIds => _tasks.map((t) => t.taskId).toList();

  Future<void> getAllTask({required String token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _taskService.getAllTask(token);
      _tasks = data;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getTaskById(String taskId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _taskService.getTaskById(taskId, token);
      _tasks = [data];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm lọc theo ngày
  List<TaskModel> getTaskByDate(DateTime selectedDate) {
    return _tasks.where((task) {
      final start = task.startDate;
      final end = task.endDate ?? task.startDate;
      return selectedDate.isAfter(start.subtract(const Duration(days: 1))) &&
          selectedDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<bool> createTask(TaskModel task, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTask = await _taskService.createTask(task, token);
      _tasks.add(newTask);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(
      String taskId, TaskModel updateTask, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final task = await _taskService.updateTask(taskId, updateTask, token);
      final idx = _tasks.indexWhere((e) => e.taskId == taskId);
      if (idx != -1) {
        _tasks[idx] = task;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String taskId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _taskService.deleteTassk(taskId, token);
      _tasks.removeWhere((e) => e.taskId == taskId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAllTask(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _taskService.deleteAllTask(token);

      _tasks.clear();

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
    await getAllTask(token: token);
  }
}
