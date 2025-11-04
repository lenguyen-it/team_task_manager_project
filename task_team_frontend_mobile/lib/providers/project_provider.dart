import 'package:flutter/material.dart';
import 'package:task_team_frontend_mobile/models/project_model.dart';
import 'package:task_team_frontend_mobile/services/project_service.dart';

class ProjectProvider with ChangeNotifier {
  final ProjectService _projectService = ProjectService();

  List<ProjectModel> _projects = [];
  List<ProjectModel> get projects => _projects;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<String> get projectNames => _projects.map((e) => e.projectName).toList();

  Future<void> getAllProject() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _projectService.getAllProject();
      _projects = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
