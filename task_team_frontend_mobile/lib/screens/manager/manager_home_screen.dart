import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/tasktype_provider.dart';
import '../../utils/task_helper.dart';
import '../../widgets/task_widget.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _hasLoadedTasks = false;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  List<TaskModel> _searchResults = [];
  bool _isSearchMode = false;

  Timer? _statusUpdateTimer;

  String _selectedFilter = 'Tất cả';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRefreshIfNeeded();
    });
  }

  Future<void> _checkAndRefreshIfNeeded() async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final task = Provider.of<TaskProvider>(context, listen: false);

    if (auth.isAuthenticated && auth.token != null && _hasLoadedTasks) {
      await task.getAllTask(token: auth.token!);
    }
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
        task.getAllTask(token: auth.token!),
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

  List<TaskModel> _getDisplayTasks(TaskProvider taskProvider) {
    final baseTasks = _isSearchMode ? _searchResults : taskProvider.tasks;
    return TaskHelpers.filterTasksByStatus(baseTasks, _selectedFilter);
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
      _isSearching = false;
      _isSearchMode = false;
      _searchController.clear();
      _searchResults = [];
    });
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final tasksInSelectedDay =
        taskProvider.getTaskByDate(_selectedDay ?? DateTime.now());

    final allTasks = taskProvider.tasks;
    final displayTasks = _getDisplayTasks(taskProvider);

    // Tính toán số lượng task theo status
    final total = allTasks.length;
    final newTasks =
        TaskHelpers.countTasksByStatus(allTasks, TaskStatus.newTask);
    final inProgress =
        TaskHelpers.countTasksByStatus(allTasks, TaskStatus.inProgress);
    final wait = TaskHelpers.countTasksByStatus(allTasks, TaskStatus.wait);
    final done = TaskHelpers.countTasksByStatus(allTasks, TaskStatus.done);
    final overdue =
        TaskHelpers.countTasksByStatus(allTasks, TaskStatus.overdue);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar
            TaskCalendarWidget(
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              calendarFormat: CalendarFormat.week,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
              taskProvider: taskProvider,
            ),

            const SizedBox(height: 24),

            // Today section
            TodaySectionWidget(
              selectedDay: _selectedDay,
              tasks: tasksInSelectedDay,
              isLoading: taskProvider.isLoading,
              hasLoadedTasks: _hasLoadedTasks,
            ),

            const SizedBox(height: 24),
            _buildLabel('Thông kê công việc:'),
            const SizedBox(height: 8),
            // Stats Section
            StatsSectionWidget(
              total: total,
              newTasks: newTasks,
              inProgress: inProgress,
              wait: wait,
              done: done,
              overdue: overdue,
            ),

            const SizedBox(height: 16),

            // All tasks section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + Search
                TaskHeaderWidget(
                  isSearching: _isSearching,
                  searchController: _searchController,
                  onSearchPressed: () => setState(() => _isSearching = true),
                  onSearchClosed: _handleSearchClosed,
                  onSearchChanged: (value) =>
                      _handleSearchChanged(value, taskProvider),
                ),

                // Filter Chips
                FilterChipsWidget(
                  selectedFilter: _selectedFilter,
                  filterOptions: TaskHelpers.filterOptions,
                  onFilterSelected: (option) {
                    setState(() => _selectedFilter = option);
                  },
                ),

                const SizedBox(height: 16),

                // Task List
                TaskListWidget(
                  tasks: displayTasks,
                  taskProvider: taskProvider,
                  isSearchMode: _isSearchMode,
                  hasLoadedTasks: _hasLoadedTasks,
                  onRetry: _loadEmployeeTasks,
                ),
              ],
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
