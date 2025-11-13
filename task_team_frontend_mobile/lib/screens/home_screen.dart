import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/tasktype_provider.dart';
import 'detail_task_screen.dart';

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

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Danh sách riêng cho search
  List<TaskModel> _searchResults = [];
  bool _isSearchMode = false;

  Timer? _statusUpdateTimer;

  // Filter theo status
  String _selectedFilter = 'Tất cả';
  final List<String> _filterOptions = [
    'Tất cả',
    'Công việc mới',
    'Đang làm',
    'Chờ xác nhận',
    'Hoàn thành',
    'Quá hạn',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    Future.delayed(Duration.zero, _loadEmployeeTasks);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        taskProvider.updateAllTaskStatus();
        print('Update status when app opened at: ${DateTime.now()}');
      }
    });

    _scheduleStatusUpdate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEmployeeTasks() async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final task = Provider.of<TaskProvider>(context, listen: false);
    final tasktype = Provider.of<TasktypeProvider>(context, listen: false);

    if (auth.isAuthenticated &&
        auth.currentEmployee != null &&
        auth.token != null) {
      await Future.wait([
        task.getTaskByEmployee(
          auth.token!,
          auth.currentEmployee!.employeeId,
        ),
        tasktype.getAllTaskType(token: auth.token!),
      ]);

      if (mounted) {
        setState(() => _hasLoadedTasks = true);
      }
    }
  }

  void _scheduleStatusUpdate() {
    _statusUpdateTimer?.cancel();

    final now = DateTime.now();
    DateTime nextUpdate;

    if (now.hour < 8) {
      nextUpdate = DateTime(now.year, now.month, now.day, 8, 0, 0);
    } else if (now.hour < 17) {
      nextUpdate = DateTime(now.year, now.month, now.day, 17, 0, 0);
    } else {
      nextUpdate = DateTime(now.year, now.month, now.day + 1, 8, 0, 0);
    }

    final duration = nextUpdate.difference(now);

    _statusUpdateTimer = Timer(duration, () {
      if (mounted) {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        taskProvider.updateAllTaskStatus();
        print('Auto update status at: ${DateTime.now()}');

        _scheduleStatusUpdate();
      }
    });

    print('Next status update scheduled at: $nextUpdate');
  }

  String _getTaskTypeName(String tasktypeId) {
    final tasktypeProvider =
        Provider.of<TasktypeProvider>(context, listen: false);
    return tasktypeProvider.getTasktypeNameById(tasktypeId) ?? 'Không xác định';
  }

  List<TaskModel> _applyFilter(List<TaskModel> source) {
    if (_selectedFilter == 'Tất cả') return source;

    final targetStatus = _statusViToEnum(_selectedFilter);
    return source.where((t) => t.status == targetStatus).toList();
  }

  TaskStatus _statusViToEnum(String vi) {
    return switch (vi) {
      'Công việc mới' => TaskStatus.newTask,
      'Đang làm' => TaskStatus.inProgress,
      'Chờ xác nhận' => TaskStatus.wait,
      'Hoàn thành' => TaskStatus.done,
      'Quá hạn' => TaskStatus.overdue,
      _ => TaskStatus.newTask,
    };
  }

  String _statusViToEn(String vi) {
    switch (vi) {
      case 'Công việc mới':
        return 'new_task';
      case 'Đang làm':
        return 'in_progress';
      case 'Chờ xác nhận':
        return 'wait';
      case 'Hoàn thành':
        return 'done';
      case 'Quá hạn':
        return 'overdue';
      default:
        return vi;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final employeeName =
        authProvider.currentEmployee?.employeeName ?? 'Nhân viên';

    final tasksInSelectedDay =
        taskProvider.getTaskByDate(_selectedDay ?? DateTime.now());

    final baseTasks = _isSearchMode ? _searchResults : taskProvider.tasks;
    final displayTasks = _applyFilter(baseTasks);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            _buildGreeting(employeeName),

            // Calendar
            _buildCalendar(taskProvider),

            const SizedBox(height: 24),

            // Today section
            _buildTodaySection(tasksInSelectedDay, taskProvider.isLoading),

            const SizedBox(height: 24),

            // All tasks + Filter chips (filter chips nằm **trong** section này)
            _buildAllTasksSection(displayTasks, taskProvider),

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
        onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
        eventLoader: (day) {
          final check = DateTime(day.year, day.month, day.day);
          final has = taskProvider.tasks.any((t) {
            final start =
                DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
            final end = t.endDate != null
                ? DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day)
                : start;
            return (check.isAtSameMomentAs(start) || check.isAfter(start)) &&
                (check.isAtSameMomentAs(end) || check.isBefore(end));
          });
          return has ? [1] : [];
        },
        headerStyle:
            const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        calendarStyle: CalendarStyle(
          selectedDecoration:
              const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          todayDecoration:
              const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          markerDecoration:
              const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
                        final statusVi = _statusEnToVi(task.status);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildTaskChip(
                            task.taskName,
                            task.description ?? '',
                            color,
                            statusVi,
                            task.tasktypeId,
                            task,
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAllTasksSection(
      List<TaskModel> displayTasks, TaskProvider provider) {
    // Lỗi API
    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Lỗi: ${provider.error}',
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: _loadEmployeeTasks, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề + Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _isSearching
                  ? Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm công việc...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _isSearching = false;
                                _isSearchMode = false;
                                _searchController.clear();
                                _searchResults = [];
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            setState(() {
                              _isSearchMode = false;
                              _searchResults = [];
                            });
                          } else {
                            final results = provider.tasks.where((t) {
                              return t.taskName
                                  .toLowerCase()
                                  .contains(value.toLowerCase());
                            }).toList();
                            setState(() {
                              _isSearchMode = true;
                              _searchResults = results;
                            });
                          }
                        },
                      ),
                    )
                  : const Text('Toàn bộ công việc',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _isSearching = true),
                ),
            ],
          ),
        ),
        _buildFilterChips(),

        const SizedBox(height: 16),

        // Danh sách
        provider.isLoading && provider.tasks.isEmpty && !_hasLoadedTasks
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            : displayTasks.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        _isSearchMode
                            ? 'Không tìm thấy công việc nào'
                            : 'Chưa có công việc nào',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayTasks.length,
                    itemBuilder: (_, i) {
                      final task = displayTasks[i];
                      final color = _getStatusColor(task.status);
                      final statusVi = _statusEnToVi(task.status);
                      final priorityVi = _priorityEnToVi(task.priority);
                      final priorityColor = _getPriorityColor(task.priority);
                      final range =
                          _formatDateRange(task.startDate, task.endDate);
                      return _buildTaskItem(
                        task.taskName,
                        statusVi,
                        color,
                        range,
                        task.tasktypeId,
                        priorityVi,
                        priorityColor,
                        task,
                      );
                    },
                  ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final selected = _selectedFilter == option;

          final statusEnum = _statusViToEnum(option);
          final chipColor = _getStatusColor(statusEnum);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                option,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedFilter = option);
              },
              backgroundColor: chipColor.withValues(alpha: 0.2),
              selectedColor: chipColor,
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskChip(
    String taskName,
    String desc,
    Color color,
    String status,
    String tasktypeId,
    TaskModel task,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        // hoặc GestureDetector
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailTaskScreen(task: task),
            ),
          );
        },
        child: Container(
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
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // const SizedBox(height: 4),
              // if (desc.isNotEmpty)
              //   Text(
              //     desc,
              //     style: const TextStyle(fontSize: 11, color: Colors.grey),
              //     maxLines: 1,
              //     overflow: TextOverflow.ellipsis,
              //   ),
              const SizedBox(height: 4),
              Text(
                _getTaskTypeName(tasktypeId),
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold),
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
                      fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(
    String taskName,
    String status,
    Color color,
    String date,
    String tasktypeId,
    String priority,
    Color priorityColor,
    TaskModel task, // Thêm tham số task
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailTaskScreen(task: task),
            ),
          );
        },
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
                          fontSize: 14, fontWeight: FontWeight.bold),
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
                          child: Text(priority,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: priorityColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusEnToVi(TaskStatus status) {
    return switch (status) {
      TaskStatus.newTask => 'Công việc mới',
      TaskStatus.inProgress => 'Đang làm',
      TaskStatus.wait => 'Chờ xác nhận',
      TaskStatus.done => 'Hoàn thành',
      TaskStatus.overdue => 'Quá hạn',
      TaskStatus.pause => 'Tạm dừng',
    };
  }

  String _priorityEnToVi(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'Cao';
      case 'normal':
        return 'Trung bình';
      case 'low':
        return 'Thấp';
      default:
        return priority;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'normal':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.done => Colors.green,
      TaskStatus.inProgress => Colors.orange,
      TaskStatus.wait => Colors.grey,
      TaskStatus.newTask => Colors.cyan,
      TaskStatus.pause => Colors.redAccent,
      TaskStatus.overdue => Colors.red,
    };
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    f(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${f(start)} - ${f(end ?? start)}';
  }
}
