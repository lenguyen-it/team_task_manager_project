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

  List<String> get taskNames => _tasks.map((r) => r.taskName).toList();

  Future<void> getAllRole() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _taskService.getAllTask();
      _tasks = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
