import 'package:flutter/material.dart';
import '../models/task_model.dart';

/// Class chứa các helper methods dùng chung cho task
class TaskHelpers {
  // Chuyển đổi từ TaskStatus enum sang tiếng Việt
  static String statusEnumToVi(TaskStatus status) {
    return switch (status) {
      TaskStatus.newTask => 'Công việc mới',
      TaskStatus.inProgress => 'Đang làm',
      TaskStatus.wait => 'Chờ xác nhận',
      TaskStatus.done => 'Hoàn thành',
      TaskStatus.overdue => 'Quá hạn',
      TaskStatus.pause => 'Tạm dừng',
    };
  }

  // Chuyển đổi từ tiếng Việt sang TaskStatus enum
  static TaskStatus statusViToEnum(String vi) {
    return switch (vi) {
      'Công việc mới' => TaskStatus.newTask,
      'Đang làm' => TaskStatus.inProgress,
      'Chờ xác nhận' => TaskStatus.wait,
      'Hoàn thành' => TaskStatus.done,
      'Quá hạn' => TaskStatus.overdue,
      'Tạm dừng' => TaskStatus.pause,
      _ => TaskStatus.newTask,
    };
  }

  // Chuyển đổi priority từ tiếng Anh sang tiếng Việt
  static String priorityEnToVi(String priority) {
    return switch (priority.toLowerCase()) {
      'high' => 'Cao',
      'normal' => 'Trung bình',
      'low' => 'Thấp',
      _ => priority,
    };
  }

  // Lấy màu theo priority
  static Color getPriorityColor(String priority) {
    return switch (priority.toLowerCase()) {
      'high' => Colors.red,
      'normal' => Colors.orange,
      'low' => Colors.green,
      _ => Colors.grey,
    };
  }

  // Lấy màu theo TaskStatus
  static Color getStatusColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.done => Colors.green,
      TaskStatus.inProgress => Colors.orange,
      TaskStatus.wait => Colors.grey.shade500,
      TaskStatus.newTask => Colors.cyan,
      TaskStatus.pause => Colors.redAccent,
      TaskStatus.overdue => Colors.red,
    };
  }

  // Format date range
  static String formatDateRange(DateTime start, DateTime? end) {
    String f(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${f(start)} - ${f(end ?? start)}';
  }

  // Đếm số lượng task theo status
  static int countTasksByStatus(List<TaskModel> tasks, TaskStatus status) {
    return tasks.where((t) => t.status == status).length;
  }

  // Lọc task theo status
  static List<TaskModel> filterTasksByStatus(
      List<TaskModel> tasks, String filterOption) {
    if (filterOption == 'Tất cả') return tasks;

    final targetStatus = statusViToEnum(filterOption);
    return tasks.where((t) => t.status == targetStatus).toList();
  }

  // Tìm kiếm task theo tên
  static List<TaskModel> searchTasks(List<TaskModel> tasks, String query) {
    if (query.trim().isEmpty) return [];
    return tasks
        .where((t) => t.taskName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Danh sách các filter options
  static const List<String> filterOptions = [
    'Tất cả',
    'Công việc mới',
    'Đang làm',
    'Chờ xác nhận',
    'Hoàn thành',
    'Quá hạn',
  ];
}
