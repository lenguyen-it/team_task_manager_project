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
      final existingProject = _projects.firstWhere(
        (p) => p.projectId == projectId,
        orElse: () => ProjectModel(
          projectId: '',
          projectName: '',
          projectManagerId: '',
          description: '',
          status: 'planning',
        ),
      );

      if (existingProject.projectId.isNotEmpty) {
        return existingProject.projectName;
      }

      final projectName =
          await _projectService.getProjectNameById(projectId, token);
      return projectName;
    } catch (e) {
      _error = e.toString();
      return 'Không tìm thấy ($projectId)';
    }
  }

  Future<bool> createProject(ProjectModel project, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newProject = await _projectService.createProject(project, token);
      _projects.add(newProject);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false; // ✅ Added: ensure loading is reset
    }
  }

  Future<bool> updateProject(
      String projectId, ProjectModel updateProject, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final project =
          await _projectService.updateProject(projectId, updateProject, token);
      final idx = _projects.indexWhere((e) => e.projectId == projectId);
      if (idx != -1) {
        _projects[idx] = project;
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

  Future<bool> deleteProject(String projectId, String token) async {
    _isLoading = true; // ✅ Added
    _error = null; // ✅ Added
    notifyListeners();

    try {
      await _projectService.deleteProject(projectId, token);
      _projects.removeWhere((e) => e.projectId == projectId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false; // ✅ Added
      notifyListeners(); // ✅ Fixed: always notify
    }
  }

  Future<bool> deleteAllProject(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _projectService.deleteAllProject(token);
      _projects.clear();
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
    await getAllProject(token: token);
  }
}
