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

  Future<void> getAllRole() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _tasktypeService.getAllTaskType();
      _tasktypes = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
