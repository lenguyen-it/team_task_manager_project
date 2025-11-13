import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_team_frontend_mobile/screens/detail_task_screen.dart';

import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/tasktype_provider.dart';

class AllTaskScreen extends StatefulWidget {
  const AllTaskScreen({super.key});

  @override
  State<AllTaskScreen> createState() => _AllTaskScreenState();
}

class _AllTaskScreenState extends State<AllTaskScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _hasLoadedTasks = false;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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

    // Tự động cập nhật status mỗi ngày lúc 8h sáng và 17h chiều
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
        task.getTaskByEmployee(auth.token!, auth.currentEmployee!.employeeId),
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

  // Lọc danh sách theo filter và search
  List<TaskModel> _getDisplayTasks(List<TaskModel> allTasks) {
    var tasks = _isSearchMode ? _searchResults : allTasks;

    if (_selectedFilter == 'Tất cả') return tasks;

    final targetStatus = _statusViToEnum(_selectedFilter);
    return tasks.where((t) => t.status == targetStatus).toList();
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

  // ĐẾM SỐ LƯỢNG THEO TRẠNG THÁI
  int _countTasksByStatus(List<TaskModel> tasks, TaskStatus status) {
    return tasks.where((t) => t.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated || authProvider.currentEmployee == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    final allTasks = taskProvider.tasks;

    final displayTasks = _getDisplayTasks(allTasks);

    final total = allTasks.length;
    final newTasks = _countTasksByStatus(allTasks, TaskStatus.newTask);
    final inProgress = _countTasksByStatus(allTasks, TaskStatus.inProgress);
    final wait = _countTasksByStatus(allTasks, TaskStatus.wait);
    final done = _countTasksByStatus(allTasks, TaskStatus.done);
    final overdue = _countTasksByStatus(allTasks, TaskStatus.overdue);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Công việc',
          style: TextStyle(
              color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEmployeeTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar
              _buildCalendar(taskProvider),
              const SizedBox(height: 24),

              // Thống kê
              _buildStatsSection(
                  total, newTasks, inProgress, wait, done, overdue),
              const SizedBox(height: 16),

              // Header + Search
              _buildHeader(taskProvider),
              const SizedBox(height: 8),

              // Filter Chips
              _buildFilterChips(),

              const SizedBox(height: 16),

              // Danh sách công việc
              _buildTaskList(displayTasks, taskProvider),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(int total, int newTasks, int inProgress, int wait,
      int done, int overdue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.1,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        children: [
          _buildStatCard('Toàn bộ công việc', total, const Color(0xFF6EC1E4)),
          _buildStatCard('Công việc mới', newTasks, const Color(0xFFB2EBF2)),
          _buildStatCard('Đang làm', inProgress, const Color(0xFFFFD54F)),
          _buildStatCard('Chờ xác nhận', wait, const Color(0xFFB0BEC5)),
          _buildStatCard('Hoàn thành', done, const Color(0xFF81C784)),
          _buildStatCard('Quá hạn', overdue, const Color(0xFFE57373)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$count công việc',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
          ),
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
        calendarFormat: CalendarFormat.week,
        availableCalendarFormats: const {CalendarFormat.week: 'Tuần'},
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
        eventLoader: (day) {
          final checkDay = DateTime(day.year, day.month, day.day);
          final hasTask = taskProvider.tasks.any((task) {
            final start = DateTime(
                task.startDate.year, task.startDate.month, task.startDate.day);
            final end = task.endDate != null
                ? DateTime(
                    task.endDate!.year, task.endDate!.month, task.endDate!.day)
                : start;
            return checkDay.isAtSameMomentAs(start) ||
                (checkDay.isAfter(start) && checkDay.isBefore(end)) ||
                checkDay.isAtSameMomentAs(end);
          });
          return hasTask ? [1] : [];
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration:
              const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          todayDecoration:
              const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          markerDecoration:
              const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          markerSize: 6,
          markersMaxCount: 1,
        ),
      ),
    );
  }

  Widget _buildHeader(TaskProvider provider) {
    return Padding(
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
                            _searchResults.clear();
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      if (value.trim().isEmpty) {
                        setState(() {
                          _isSearchMode = false;
                          _searchResults.clear();
                        });
                      } else {
                        final results = provider.tasks
                            .where((t) => t.taskName
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                        setState(() {
                          _isSearchMode = true;
                          _searchResults = results;
                        });
                      }
                    },
                  ),
                )
              : const Text(
                  'Toàn bộ công việc',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
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
          final isSelected = _selectedFilter == option;
          final statusEnum = _statusViToEnum(option);
          final chipColor = _getStatusColor(statusEnum);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                option,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = option),
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

  Widget _buildTaskList(List<TaskModel> tasks, TaskProvider provider) {
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

    if (provider.isLoading && !_hasLoadedTasks) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            _isSearchMode
                ? 'Không tìm thấy công việc nào'
                : 'Chưa có công việc nào',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final color = _getStatusColor(task.status);
    final statusVi = _statusEnumToVi(task.status);
    final priorityVi = _priorityEnumToVi(task.priority);
    final priorityColor = _getPriorityColor(task.priority);
    final dateRange = _formatDateRange(task.startDate, task.endDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailTaskScreen(task: task)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.taskName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getTaskTypeName(task.tasktypeId),
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusVi,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(dateRange,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Độ ưu tiên: ',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        priorityVi,
                        style: TextStyle(
                            fontSize: 12,
                            color: priorityColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Methods ---
  String _statusEnumToVi(TaskStatus status) {
    return switch (status) {
      TaskStatus.newTask => 'Công việc mới',
      TaskStatus.inProgress => 'Đang làm',
      TaskStatus.wait => 'Chờ xác nhận',
      TaskStatus.done => 'Hoàn thành',
      TaskStatus.overdue => 'Quá hạn',
      TaskStatus.pause => 'Tạm dừng',
    };
  }

  String _priorityEnumToVi(String priority) {
    return switch (priority.toLowerCase()) {
      'high' => 'Cao',
      'normal' => 'Trung bình',
      'low' => 'Thấp',
      _ => priority,
    };
  }

  Color _getPriorityColor(String priority) {
    return switch (priority.toLowerCase()) {
      'high' => Colors.red,
      'normal' => Colors.orange,
      'low' => Colors.green,
      _ => Colors.grey,
    };
  }

  Color _getStatusColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.done => Colors.green,
      TaskStatus.inProgress => Colors.orange,
      TaskStatus.wait => Colors.grey.shade500,
      TaskStatus.newTask => Colors.cyan,
      TaskStatus.pause => Colors.redAccent,
      TaskStatus.overdue => Colors.red,
      _ => Colors.blue,
    };
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    f(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${f(start)} - ${f(end ?? start)}';
  }
}
