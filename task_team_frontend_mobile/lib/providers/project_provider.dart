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

  Future<void> getAllProject({required String token}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _projectService.getAllProject(token);
      _projects = data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getProjectById(String projectId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _projectService.getProjectById(projectId, token);
      _projects = [data];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> getProjectNameById(String projectId, String token) async {
    try {
      // Nếu trong cache (_projects) đã có dự án → trả nhanh
      final existingProject = _projects.firstWhere(
        (p) => p.projectId == projectId,
        orElse: () => ProjectModel(
          projectId: '',
          projectName: '',
          description: '',
          status: 'plannign',
        ),
      );

      if (existingProject.projectId.isNotEmpty) {
        return existingProject.projectName;
      }

      // Nếu chưa có thì gọi API
      final projectName =
          await _projectService.getProjectNameById(projectId, token);
      return projectName;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 'Không tìm thấy ($projectId)';
    }
  }
}
