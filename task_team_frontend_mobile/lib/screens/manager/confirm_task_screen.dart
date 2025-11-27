import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/models/task_model.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/task_provider.dart';
import 'package:task_team_frontend_mobile/providers/tasktype_provider.dart';
import 'package:task_team_frontend_mobile/utils/task_helper.dart';
import 'package:task_team_frontend_mobile/screens/detail_task_screen.dart';
import 'package:task_team_frontend_mobile/screens/manager/manager_detail_task_screen.dart';

class ConfirmTaskScreen extends StatefulWidget {
  const ConfirmTaskScreen({super.key});

  @override
  State<ConfirmTaskScreen> createState() => _ConfirmTaskScreenState();
}

class _ConfirmTaskScreenState extends State<ConfirmTaskScreen> {
  bool _hasLoadedTasks = false;
  final TextEditingController _searchController = TextEditingController();

  List<TaskModel> _searchResults = [];
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _loadTasks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final task = Provider.of<TaskProvider>(context, listen: false);

    if (auth.isAuthenticated && auth.token != null) {
      await task.getAllTask(token: auth.token!);

      if (mounted) {
        setState(() => _hasLoadedTasks = true);
      }
    }
  }

  List<TaskModel> _getDisplayTasks(TaskProvider taskProvider) {
    final baseTasks = _isSearchMode ? _searchResults : taskProvider.tasks;

    final waitConfirmTasks = baseTasks
        .where((task) => task.status == TaskStatus.waitConfirm)
        .toList();

    return TaskHelpers.sortTasksByPriority(waitConfirmTasks);
  }

  void _handleSearchChanged(String value, TaskProvider provider) {
    if (value.isEmpty) {
      setState(() {
        _isSearchMode = false;
        _searchResults = [];
      });
    } else {
      final results = TaskHelpers.searchTasks(provider.tasks, value);
      setState(() {
        _isSearchMode = true;
        _searchResults = results;
      });
    }
  }

  void _handleSearchClosed() {
    setState(() {
      _isSearchMode = false;
      _searchController.clear();
      _searchResults = [];
    });
  }

  Future<void> _confirmTask(TaskModel task) async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: Text(
          'Bạn có chắc chắn muốn xác nhận công việc "${task.taskName}" đã hoàn thành?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Thực hiện cập nhật trạng thái
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phiên đăng nhập hết hạn')),
        );
      }
      return;
    }

    try {
      // Cập nhật task với trạng thái done
      final updatedTask = task.copyWith(
        status: TaskStatus.done,
      );

      Map<String, dynamic> taskData = updatedTask.toJson();
      taskData.removeWhere((key, value) => value == null);

      final success = await taskProvider.updateTask(
        taskId: task.taskId,
        token: token,
        taskData: taskData,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xác nhận hoàn thành công việc thành công'),
              backgroundColor: Colors.green,
            ),
          );
          // Tải lại danh sách task
          await _loadTasks();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${taskProvider.error ?? "Không xác định"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận công việc'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            final displayTasks = _getDisplayTasks(taskProvider);

            return Column(
              children: [
                const SizedBox(height: 16),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm công việc...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _handleSearchClosed,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) =>
                        _handleSearchChanged(value, taskProvider),
                  ),
                ),

                const SizedBox(height: 12),

                // Hiển thị số lượng task cần duyệt
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 24,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Có ${displayTasks.length} công việc cần duyệt',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Danh sách task có thể cuộn
                Expanded(
                  child: SingleChildScrollView(
                    child: _ConfirmTaskListWidget(
                      tasks: displayTasks,
                      taskProvider: taskProvider,
                      isSearchMode: _isSearchMode,
                      hasLoadedTasks: _hasLoadedTasks,
                      onRetry: _loadTasks,
                      onConfirm: _confirmTask,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Widget danh sách công việc chờ xác nhận
class _ConfirmTaskListWidget extends StatelessWidget {
  final List<TaskModel> tasks;
  final TaskProvider taskProvider;
  final bool isSearchMode;
  final bool hasLoadedTasks;
  final VoidCallback onRetry;
  final Function(TaskModel) onConfirm;

  const _ConfirmTaskListWidget({
    required this.tasks,
    required this.taskProvider,
    required this.isSearchMode,
    required this.hasLoadedTasks,
    required this.onRetry,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // Xử lý lỗi
    if (taskProvider.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Lỗi: ${taskProvider.error}',
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    // Đang tải
    if (taskProvider.isLoading &&
        taskProvider.tasks.isEmpty &&
        !hasLoadedTasks) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Không có dữ liệu
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            isSearchMode
                ? 'Không tìm thấy công việc nào'
                : 'Không có công việc chờ xác nhận',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Hiển thị danh sách
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _ConfirmTaskCard(
          task: tasks[index],
          onConfirm: onConfirm,
        );
      },
    );
  }
}

/// Card hiển thị task với nút xác nhận
class _ConfirmTaskCard extends StatelessWidget {
  final TaskModel task;
  final Function(TaskModel) onConfirm;

  const _ConfirmTaskCard({
    required this.task,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final color = TaskHelpers.getStatusColor(task.status);
    final statusVi = TaskHelpers.statusEnumToVi(task.status);
    final priorityVi = TaskHelpers.priorityEnToVi(task.priority);
    final priorityColor = TaskHelpers.getPriorityColor(task.priority);
    final dateRange = TaskHelpers.formatDateRange(task.startDate, task.endDate);
    final tasktypeProvider =
        Provider.of<TasktypeProvider>(context, listen: false);
    final taskTypeName =
        tasktypeProvider.getTasktypeNameById(task.tasktypeId) ??
            'Không xác định';

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentEmployee?.roleId ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (role == 'staff') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailTaskScreen(task: task),
              ),
            );
          } else if (role == 'admin' || role == 'manager') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManagerDetailTaskScreen(task: task),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.taskName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    taskTypeName,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateRange,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Độ ưu tiên: ',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black87)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(priorityVi,
                            style: TextStyle(
                                fontSize: 12,
                                color: priorityColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Nút xác nhận
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onConfirm(task),
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text(
                    'Xác nhận hoàn thành',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
