import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/tasktype_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _hasLoadedTasks = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    Future.delayed(Duration.zero, () {
      _loadEmployeeTasks();
    });
  }

  // Gọi API lấy task của nhân viên
  Future<void> _loadEmployeeTasks() async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final task = Provider.of<TaskProvider>(context, listen: false);
    final tasktype = Provider.of<TasktypeProvider>(context, listen: false);

    if (auth.isAuthenticated &&
        auth.currentEmployee != null &&
        auth.token != null) {
      // await task.getTaskByEmployee(
      //   auth.token!,
      //   auth.currentEmployee!.employeeId,
      // );

      await Future.wait([
        task.getTaskByEmployee(
          auth.token!,
          auth.currentEmployee!.employeeId,
        ),
        tasktype.getAllTaskType(token: auth.token!),
      ]);
      if (mounted) {
        setState(() {
          _hasLoadedTasks = true;
        });
      }
    }
  }

  String _getTaskTypeName(String tasktypeId) {
    final tasktypeProvider =
        Provider.of<TasktypeProvider>(context, listen: false);
    return tasktypeProvider.getTasktypeNameById(tasktypeId) ?? 'Không xác định';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final employeeName =
        authProvider.currentEmployee?.employeeName ?? 'Nhân viên';

    // Lọc task theo ngày đã chọn
    final tasksInSelectedDay =
        taskProvider.getTaskByDate(_selectedDay ?? DateTime.now());

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───── Greeting ─────
            _buildGreeting(employeeName),

            // ───── Calendar ─────
            _buildCalendar(taskProvider),

            const SizedBox(height: 24),

            // ───── Task trong ngày ─────
            _buildTodaySection(tasksInSelectedDay, taskProvider.isLoading),

            const SizedBox(height: 24),

            // ───── Toàn bộ công việc ─────
            _buildAllTasksSection(taskProvider),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(String name) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xin chào!!!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(name, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCalendar(TaskProvider taskProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TableCalendar(
        locale: 'vi_VN',
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        eventLoader: (day) {
          final checkDay = DateTime(day.year, day.month, day.day);

          final hasTasks = taskProvider.tasks.any((task) {
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

            return (checkDay.isAtSameMomentAs(start) ||
                    checkDay.isAfter(start)) &&
                (checkDay.isAtSameMomentAs(end) || checkDay.isBefore(end));
          });

          return hasTasks ? [1] : [];
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          todayDecoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          markerSize: 7,
          markersMaxCount: 1,
        ),
      ),
    );
  }

  Widget _buildTodaySection(List<TaskModel> tasks, bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Công việc ngày ${_selectedDay?.day}/${_selectedDay?.month}/${_selectedDay?.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: loading && !_hasLoadedTasks
              ? const Center(child: CircularProgressIndicator())
              : tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'Không có công việc nào trong ngày này',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: tasks.length,
                      itemBuilder: (_, i) {
                        final task = tasks[i];
                        final color = _getStatusColor(task.status);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildTaskChip(
                            task.taskName,
                            task.description ?? '',
                            color,
                            task.status,
                            task.tasktypeId,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAllTasksSection(TaskProvider provider) {
    // Hiển thị lỗi nếu có
    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Lỗi: ${provider.error}',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadEmployeeTasks,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toàn bộ công việc',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
        const SizedBox(height: 8),
        provider.isLoading && provider.tasks.isEmpty && !_hasLoadedTasks
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            : provider.tasks.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Chưa có công việc nào',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.tasks.length,
                    itemBuilder: (_, i) {
                      final task = provider.tasks[i];
                      final color = _getStatusColor(task.status);
                      final range =
                          _formatDateRange(task.startDate, task.endDate);
                      return _buildTaskItem(
                        task.taskName,
                        task.status,
                        color,
                        range,
                        task.tasktypeId,
                      );
                    },
                  ),
      ],
    );
  }

  Widget _buildTaskChip(
    String taskName,
    String desc,
    Color color,
    String status,
    String tasktypeId,
  ) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            taskName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (desc.isNotEmpty)
            Text(
              desc,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Text(
            _getTaskTypeName(tasktypeId),
            style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    String taskName,
    String status,
    Color color,
    String date,
    String tasktypeId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTaskTypeName(tasktypeId),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
      case 'hoàn thành':
        return Colors.green;
      case 'in_progress':
      case 'đang thực hiện':
        return Colors.orange;
      case 'pending':
      case 'chưa bắt đầu':
        return Colors.grey;
      case 'new_task':
      case 'công việc mới':
        return Colors.cyan;
      case 'pause':
      case 'tạm dừng':
        return Colors.redAccent;
      case 'overdue':
      case 'quá hạn':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    f(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${f(start)} - ${f(end ?? start)}';
  }
}
