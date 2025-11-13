import 'dart:io';
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
      // Tự động cập nhật status sau khi load
      updateAllTaskStatus();
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
      // Tự động cập nhật status
      updateAllTaskStatus();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm lọc theo ngày
  List<TaskModel> getTaskByDate(DateTime selectedDate) {
    final selected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    return _tasks.where((task) {
      final start = DateTime(
        task.startDate.year,
        task.startDate.month,
        task.startDate.day,
      );

      final end = task.endDate != null
          ? DateTime(
              task.endDate!.year,
              task.endDate!.month,
              task.endDate!.day,
            )
          : start;

      final isAfterOrSameStart =
          selected.isAtSameMomentAs(start) || selected.isAfter(start);
      final isBeforeOrSameEnd =
          selected.isAtSameMomentAs(end) || selected.isBefore(end);

      return isAfterOrSameStart && isBeforeOrSameEnd;
    }).toList();
  }

  // Lấy task theo nhân viên
  Future<void> getTaskByEmployee(String token, String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _taskService.getTaskByEmployee(employeeId, token);
      _tasks = data;
      // Tự động cập nhật status sau khi load
      updateAllTaskStatus();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search task theo tên
  Future<void> getTaskByName(String token, String taskName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _taskService.getTaskByName(taskName, token);
      _tasks = data;
      // Tự động cập nhật status
      updateAllTaskStatus();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTask(TaskModel task, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTask = await _taskService.createTask(task, token);
      _tasks.add(newTask);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật task (có thể kèm files hoặc không)
  Future<bool> updateTask({
    required String taskId,
    required String token,
    Map<String, dynamic>? taskData,
    List<File>? files,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _taskService.updateTask(
        taskId: taskId,
        token: token,
        taskData: taskData,
        files: files,
      );

      // Parse response và cập nhật task trong list
      if (response['data'] != null) {
        final updatedTask = TaskModel.fromJson(response['data']);
        final idx = _tasks.indexWhere((e) => e.taskId == taskId);
        if (idx != -1) {
          _tasks[idx] = updatedTask;
        }
      }

      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Chỉ upload files cho task (không cập nhật thông tin)
  Future<bool> uploadFilesForTask({
    required String taskId,
    required String token,
    required List<File> files,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _taskService.uploadFilesForTask(
        taskId: taskId,
        token: token,
        files: files,
      );

      // Parse response và cập nhật task trong list
      if (response['data'] != null) {
        final updatedTask = TaskModel.fromJson(response['data']);
        final idx = _tasks.indexWhere((e) => e.taskId == taskId);
        if (idx != -1) {
          _tasks[idx] = updatedTask;
        }
      }

      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xóa một file attachment
  Future<bool> deleteAttachment({
    required String taskId,
    required String attachmentId,
    required String token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _taskService.deleteAttachment(
        taskId: taskId,
        attachmentId: attachmentId,
        token: token,
      );

      // Parse response và cập nhật task trong list
      if (response['data'] != null) {
        final updatedTask = TaskModel.fromJson(response['data']);
        final idx = _tasks.indexWhere((e) => e.taskId == taskId);
        if (idx != -1) {
          _tasks[idx] = updatedTask;
        }
      }

      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTask(String taskId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _taskService.deleteTask(taskId, token);
      _tasks.removeWhere((e) => e.taskId == taskId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAllTask(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _taskService.deleteAllTask(token);
      _tasks.clear();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TaskModel> getTasksByStatus(TaskStatus status) {
    return _tasks.where((t) => t.status == status).toList();
  }

  void updateAllTaskStatus() {
    _tasks = _tasks.map((task) {
      final updated = task.updateStatus();
      return updated;
    }).toList();
    notifyListeners();
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
