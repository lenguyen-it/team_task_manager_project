import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/employee_provider.dart';
import 'package:task_team_frontend_mobile/providers/task_provider.dart';
import 'package:task_team_frontend_mobile/models/task_model.dart';
import 'package:task_team_frontend_mobile/models/employee_model.dart';

class ManagerChartScreen extends StatefulWidget {
  const ManagerChartScreen({super.key});

  @override
  State<ManagerChartScreen> createState() => _ManagerChartScreenState();
}

class _ManagerChartScreenState extends State<ManagerChartScreen> {
  late DateTime startOfView;
  late int totalDaysInView;
  late ScrollController _dailyTimelineScrollController;
  late ScrollController _verticalScrollController;
  late ScrollController _chartScrollController;

  DateTime? selectedDate;
  DateTime? selectedMonth;
  int? selectedYear;
  String _chartType = 'day';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const double workingDayWidth = 80.0;
  static const double headerHeight = 60.0;
  static const double barWidth = 35;
  static const int visibleBarsCount = 5;

  static const int visibleDaysCount = 1;
  static const double dayWidth = 55.0;

  @override
  void initState() {
    super.initState();
    _initializeTimeline();
    _dailyTimelineScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    _chartScrollController = ScrollController();

    final now = DateTime.now();
    selectedDate = now;
    selectedMonth = DateTime(now.year, now.month);
    selectedYear = now.year;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    if (!mounted) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    if (!mounted) return;

    final employeeProvider =
        Provider.of<EmployeeProvider>(context, listen: false);
    if (!mounted) return;

    if (authProvider.isAuthenticated &&
        authProvider.currentEmployee != null &&
        authProvider.token != null) {
      await taskProvider.getAllTask(token: authProvider.token!);
      if (!mounted) return;

      await employeeProvider.getAllEmployee(token: authProvider.token!);
      if (!mounted) return;

      _updateTimelineRange(taskProvider.tasks);

      // Scroll đến ngày hiện tại sau khi load data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToToday();
        _scrollToDailyChartToday();
      });
    }
  }

  void _initializeTimeline() {
    final now = DateTime.now();
    startOfView = now.subtract(const Duration(days: 2));
    totalDaysInView = 180;
  }

  void _updateTimelineRange(List<TaskModel> tasks) {
    final now = DateTime.now();
    DateTime earliest = now;
    DateTime latest = now;

    if (tasks.isNotEmpty) {
      earliest = tasks.first.startDate;
      latest = tasks.first.endDate ?? tasks.first.startDate;

      for (var task in tasks) {
        if (task.startDate.isBefore(earliest)) earliest = task.startDate;
        final end = task.endDate ?? task.startDate;
        if (end.isAfter(latest)) latest = end;
      }
    }

    earliest = DateTime(earliest.year, earliest.month - 1, 1);
    latest = DateTime(latest.year, latest.month + 2, 0);

    setState(() {
      startOfView = earliest;
      totalDaysInView = latest.difference(earliest).inDays + 1;
    });
  }

  // Scroll Daily Timeline đến ngày hiện tại
  void _scrollToToday() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_dailyTimelineScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToToday();
        });
        return;
      }

      final today = DateTime.now();
      final todayIndex = today.difference(startOfView).inDays;

      final viewWidth = visibleDaysCount * dayWidth;
      final targetOffset =
          (todayIndex * dayWidth) - (viewWidth / 2) + (dayWidth / 2);

      final maxScroll = _dailyTimelineScrollController.position.maxScrollExtent;
      final safeOffset = targetOffset.clamp(0.0, maxScroll);

      _dailyTimelineScrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // Scroll biểu đồ ngày đến ngày hiện tại
  void _scrollToDailyChartToday() {
    if (!mounted || _chartType != 'day') return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chartScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToDailyChartToday();
        });
        return;
      }

      final now = DateTime.now();
      final viewMonth = selectedMonth ?? now;

      if (now.year == viewMonth.year && now.month == viewMonth.month) {
        final currentDay = now.day;
        final targetOffset = (currentDay - 1) * barWidth -
            (visibleBarsCount * barWidth / 2) +
            barWidth / 2;

        final maxScroll = _chartScrollController.position.maxScrollExtent;
        final safeOffset = targetOffset.clamp(0.0, maxScroll);

        _chartScrollController.animateTo(
          safeOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _scrollToCurrentPeriod() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_chartScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToCurrentPeriod();
        });
        return;
      }

      if (_chartType == 'day') {
        _scrollToDailyChartToday();
      } else if (_chartType == 'week') {
        _scrollToCurrentWeek();
      } else if (_chartType == 'month') {
        _scrollToCurrentMonth();
      }
    });
  }

  void _scrollToCurrentWeek() {
    if (!mounted) return;

    final now = DateTime.now();
    final weekKey = now.year * 100 + now.weekOfYear;
    final index = _getWeekIndex(weekKey);

    if (index < 0 || !_chartScrollController.hasClients) return;

    final target =
        index * barWidth - (visibleBarsCount * barWidth / 2) + barWidth / 2;
    final maxScroll = _chartScrollController.position.maxScrollExtent;
    final safe = target.clamp(0.0, maxScroll);

    _chartScrollController.animateTo(
      safe,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToCurrentMonth() {
    if (!mounted) return;

    final now = DateTime.now();
    final viewYear = selectedYear ?? now.year;
    final currentIndexInView = now.year == viewYear ? now.month - 1 : -1;

    if (currentIndexInView < 0 || !_chartScrollController.hasClients) return;

    final target = currentIndexInView * barWidth -
        (visibleBarsCount * barWidth / 2) +
        barWidth / 2;
    final maxScroll = _chartScrollController.position.maxScrollExtent;
    final safeOffset = target.clamp(0.0, maxScroll);

    _chartScrollController.animateTo(
      safeOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  int _getWeekIndex(int weekKey) {
    if (!mounted) return -1;

    final temp = <int, int>{};
    final tasks = Provider.of<TaskProvider>(context, listen: false).tasks;
    for (var task in tasks) {
      final start = task.startDate;
      final end = task.endDate ?? task.startDate;
      var current = start.subtract(Duration(days: start.weekday - 1));
      final endWeek = end.subtract(Duration(days: end.weekday - 1));
      while (current.isBefore(endWeek) || current.isAtSameMomentAs(endWeek)) {
        final key = current.year * 100 + current.weekOfYear;
        temp[key] = 1;
        current = current.add(const Duration(days: 7));
      }
    }
    final sorted = temp.keys.toList()..sort();
    return sorted.indexOf(weekKey);
  }

  @override
  void dispose() {
    _dailyTimelineScrollController.dispose();
    _verticalScrollController.dispose();
    _chartScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey.shade50,
        body: Consumer2<TaskProvider, EmployeeProvider>(
          builder: (context, taskProvider, employeeProvider, child) {
            if (taskProvider.isLoading || employeeProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = taskProvider.tasks;
            final employees = employeeProvider.employees;

            return RefreshIndicator(
              onRefresh: () => _loadData(),
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // 1. Dashboard Cards
                      _buildDashboardSection(tasks),

                      const SizedBox(height: 16),

                      // 2. Daily Timeline
                      _buildDailyTimelineSection(tasks),

                      const SizedBox(height: 16),

                      // 3. Chart
                      _buildChartSection(tasks),

                      const SizedBox(height: 16),

                      // 4. Deadline
                      _buildDeadlineSection(tasks),

                      const SizedBox(height: 16),

                      // 5. WorkLoad
                      _buildWorkLoadSection(tasks, employees),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== 1. DASHBOARD SECTION (4 Cards in Column) ====================
  Widget _buildDashboardSection(List<TaskModel> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final totalTasks = tasks.length;
    final todayTasks = tasks.where((t) {
      final start =
          DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
      final end = t.endDate != null
          ? DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day)
          : start;
      return (today.isAtSameMomentAs(start) || today.isAfter(start)) &&
          (today.isAtSameMomentAs(end) || today.isBefore(end));
    }).length;

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekTasks = tasks.where((t) {
      final start =
          DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
      final end = t.endDate != null
          ? DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day)
          : start;
      return !(end.isBefore(weekStart) || start.isAfter(weekEnd));
    }).length;

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final monthTasks = tasks.where((t) {
      final start =
          DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
      final end = t.endDate != null
          ? DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day)
          : start;
      return !(end.isBefore(monthStart) || start.isAfter(monthEnd));
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 4 cards displayed vertically
          _buildDashboardCard(
            'Tổng số',
            '$totalTasks công việc',
            Icons.assignment,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildDashboardCard(
            'Hôm nay',
            '$todayTasks công việc',
            Icons.today,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildDashboardCard(
            'Tuần này',
            '$weekTasks công việc',
            Icons.calendar_view_week,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildDashboardCard(
            'Tháng này',
            '$monthTasks công việc',
            Icons.calendar_month,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 2. DAILY TIMELINE SECTION ====================
  Widget _buildDailyTimelineSection(List<TaskModel> tasks) {
    final workingDays = <DateTime>[];
    DateTime current = startOfView;
    for (int i = 0; i < totalDaysInView; i++) {
      if (current.weekday >= DateTime.monday &&
          current.weekday <= DateTime.friday) {
        workingDays.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    final result = _buildTaskBars(tasks, workingDays);
    final List<Widget> taskWidgets = result['widgets'];
    final int maxRows = result['maxRows'];
    final double contentHeight = maxRows * 35.0 + 20;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Timeline',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today,
                      color: Colors.blueAccent),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Không có task nào',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: SingleChildScrollView(
                controller: _dailyTimelineScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: workingDays.length * workingDayWidth,
                  child: Column(
                    children: [
                      _buildDayHeaders(workingDays),
                      Expanded(
                        child: Scrollbar(
                          controller: _verticalScrollController,
                          thumbVisibility: false,
                          child: SingleChildScrollView(
                            controller: _verticalScrollController,
                            child: SizedBox(
                              height: contentHeight,
                              child: Stack(
                                children: [
                                  _buildVerticalColumns(
                                      workingDays, contentHeight),
                                  ...taskWidgets,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayHeaders(List<DateTime> workingDays) {
    final now = DateTime.now();
    return Container(
      height: headerHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 2)),
      ),
      child: Row(
        children: workingDays.map((day) {
          final isToday = now.year == day.year &&
              now.month == day.month &&
              now.day == day.day;
          return Container(
            width: workingDayWidth,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
              color: isToday ? Colors.blue.shade50 : Colors.white,
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE', 'vi').format(day),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isToday ? Colors.blueAccent : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d/M').format(day),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : null,
                    color: isToday ? Colors.blueAccent : Colors.black,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerticalColumns(List<DateTime> workingDays, double height) {
    final now = DateTime.now();
    return Row(
      children: workingDays.map((day) {
        final isToday = now.year == day.year &&
            now.month == day.month &&
            now.day == day.day;
        return Container(
          width: workingDayWidth,
          height: height,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
            color: isToday ? Colors.blue.shade50 : Colors.white,
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _buildTaskBars(
      List<TaskModel> tasks, List<DateTime> workingDays) {
    if (tasks.isEmpty || workingDays.isEmpty) {
      return {'widgets': <Widget>[], 'maxRows': 0};
    }

    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.pink.shade300,
      Colors.teal.shade300,
    ];

    final List<List<Map<String, int>>> rows = [];
    final List<Widget> taskWidgets = [];

    final Map<DateTime, int> dateToIndex = {};
    for (int i = 0; i < workingDays.length; i++) {
      dateToIndex[DateTime(
          workingDays[i].year, workingDays[i].month, workingDays[i].day)] = i;
    }

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final start = task.startDate;
      final end = task.endDate ?? task.startDate;

      final startKey = DateTime(start.year, start.month, start.day);
      final endKey = DateTime(end.year, end.month, end.day);

      if (!dateToIndex.containsKey(startKey) &&
          !dateToIndex.containsKey(endKey)) {
        continue;
      }

      final visibleStartIndex = dateToIndex.containsKey(startKey)
          ? dateToIndex[startKey]!
          : dateToIndex.values.firstWhere(
              (idx) => workingDays[idx].isAfter(startKey),
              orElse: () => 0);

      final visibleEndIndex = dateToIndex.containsKey(endKey)
          ? dateToIndex[endKey]!
          : dateToIndex.values.lastWhere(
              (idx) => workingDays[idx]
                  .isBefore(endKey.add(const Duration(days: 1))),
              orElse: () => workingDays.length - 1);

      if (visibleEndIndex < visibleStartIndex) continue;

      final taskWidth =
          (visibleEndIndex - visibleStartIndex + 1) * workingDayWidth;

      int assignedRow = 0;
      bool placed = false;
      for (int r = 0; r < rows.length; r++) {
        bool canPlace = true;
        for (final occ in rows[r]) {
          if (!(visibleEndIndex < occ['start']! ||
              visibleStartIndex > occ['end']!)) {
            canPlace = false;
            break;
          }
        }
        if (canPlace) {
          assignedRow = r;
          placed = true;
          rows[r].add({'start': visibleStartIndex, 'end': visibleEndIndex});
          break;
        }
      }
      if (!placed) {
        assignedRow = rows.length;
        rows.add([
          {'start': visibleStartIndex, 'end': visibleEndIndex}
        ]);
      }

      final color = colors[i % colors.length];
      taskWidgets.add(
        Positioned(
          left: visibleStartIndex * workingDayWidth,
          top: 10 + assignedRow * 35,
          child: Container(
            width: taskWidth,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade400),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              task.taskName,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return {'widgets': taskWidgets, 'maxRows': rows.length};
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: startOfView,
      lastDate: startOfView.add(Duration(days: totalDaysInView - 1)),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);

      if (_dailyTimelineScrollController.hasClients) {
        final index = picked.difference(startOfView).inDays;
        final targetOffset = index * workingDayWidth - 200;
        final maxScroll =
            _dailyTimelineScrollController.position.maxScrollExtent;
        final safeOffset = targetOffset.clamp(0.0, maxScroll);

        _dailyTimelineScrollController.animateTo(
          safeOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // ==================== 3. CHART SECTION ====================
  Widget _buildChartSection(List<TaskModel> tasks) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chart',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Container(
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton2<String>(
                  value: _chartType,
                  underline: const SizedBox(),
                  buttonStyleData: const ButtonStyleData(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    height: 40,
                  ),
                  iconStyleData: const IconStyleData(
                    icon: Icon(Icons.arrow_drop_down, size: 20),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 200,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    height: 40,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Ngày')),
                    DropdownMenuItem(value: 'week', child: Text('Tuần')),
                    DropdownMenuItem(value: 'month', child: Text('Tháng')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _chartType = value);
                      _scrollToCurrentPeriod();
                    }
                  },
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _chartType == 'day'
                ? _buildDailyChart(tasks)
                : _chartType == 'week'
                    ? _buildWeeklyChart(tasks)
                    : _buildMonthlyChart(tasks),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart(List<TaskModel> tasks) {
    final viewMonth = selectedMonth ?? DateTime.now();
    final year = viewMonth.year;
    final month = viewMonth.month;

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final Map<int, int> dayCount = {};

    for (int day = 1; day <= daysInMonth; day++) {
      dayCount[day] = 0;
    }

    for (var task in tasks) {
      final start = task.startDate;
      final end = task.endDate ?? task.startDate;

      for (int day = 1; day <= daysInMonth; day++) {
        final current = DateTime(year, month, day);
        if ((current.isAfter(start) || current.isAtSameMomentAs(start)) &&
            (current.isBefore(end) || current.isAtSameMomentAs(end))) {
          dayCount[day] = dayCount[day]! + 1;
        }
      }
    }

    final data = dayCount.entries
        .map((e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  color: Colors.blue,
                  width: 12,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            ))
        .toList();

    final now = DateTime.now();
    final currentDayKey =
        (now.year == year && now.month == month) ? now.day : -1;

    return _buildScrollableChart(
      data: data,
      currentHighlightKey: currentDayKey,
      filterText: DateFormat('MM/yyyy').format(viewMonth),
      onFilterPressed: () => _selectMonthForChart(context),
      getTitle: (value, _) => value.toInt().toString(),
    );
  }

  Widget _buildWeeklyChart(List<TaskModel> tasks) {
    final viewMonth = selectedMonth ?? DateTime.now();
    final year = viewMonth.year;
    final month = viewMonth.month;

    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    final List<int> allWeekKeys = [];
    DateTime weekStart =
        firstDay.subtract(Duration(days: firstDay.weekday - 1));

    while (weekStart.isBefore(lastDay.add(const Duration(days: 14)))) {
      int workingDaysInMonth = 0;
      for (int i = 0; i < 5; i++) {
        final d = weekStart.add(Duration(days: i));
        if (d.month == month &&
            d.weekday >= DateTime.monday &&
            d.weekday <= DateTime.friday) {
          workingDaysInMonth++;
        }
      }

      if (workingDaysInMonth > 0) {
        allWeekKeys.add(weekStart.year * 100 + weekStart.weekOfYear);
      }

      weekStart = weekStart.add(const Duration(days: 7));
    }

    final Map<int, int> weekCount = {};
    for (int key in allWeekKeys) {
      weekCount[key] = 0;
    }

    for (var task in tasks) {
      final taskStart = task.startDate;
      final taskEnd = task.endDate ?? task.startDate;

      DateTime currentWeek =
          taskStart.subtract(Duration(days: taskStart.weekday - 1));
      final endWeek = taskEnd.subtract(Duration(days: taskEnd.weekday - 1));

      while (currentWeek.isBefore(endWeek) ||
          currentWeek.isAtSameMomentAs(endWeek)) {
        final key = currentWeek.year * 100 + currentWeek.weekOfYear;
        if (weekCount.containsKey(key)) {
          weekCount[key] = weekCount[key]! + 1;
        }
        currentWeek = currentWeek.add(const Duration(days: 7));
      }
    }

    final data = allWeekKeys
        .map((key) => BarChartGroupData(
              x: key,
              barRods: [
                BarChartRodData(
                  toY: weekCount[key]!.toDouble(),
                  color: Colors.green,
                  width: 12,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            ))
        .toList();

    final now = DateTime.now();
    final currentWeekKey = now.year * 100 + now.weekOfYear;

    return _buildScrollableChart(
      data: data,
      currentHighlightKey: currentWeekKey,
      filterText: DateFormat('MM/yyyy').format(viewMonth),
      onFilterPressed: () => _selectMonthForChart(context),
      getTitle: (value, _) {
        final key = value.toInt();
        final monday = _getMondayOfWeek(key);
        final friday = monday.add(const Duration(days: 4));
        return '${DateFormat('dd').format(monday)}-${DateFormat('dd').format(friday)}';
      },
    );
  }

  Widget _buildMonthlyChart(List<TaskModel> tasks) {
    final viewYear = selectedYear ?? DateTime.now().year;

    final Map<int, int> monthCount = {};
    for (int m = 1; m <= 12; m++) {
      monthCount[viewYear * 100 + m] = 0;
    }

    for (var task in tasks) {
      final start = task.startDate;
      final end = task.endDate ?? task.startDate;

      var current = DateTime(start.year, start.month, 1);
      final endMonth = DateTime(end.year, end.month, 1);

      while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
        if (current.year == viewYear) {
          final key = current.year * 100 + current.month;
          monthCount[key] = monthCount[key]! + 1;
        }
        current = DateTime(
          current.month == 12 ? current.year + 1 : current.year,
          current.month == 12 ? 1 : current.month + 1,
          1,
        );
      }
    }

    final data = monthCount.entries
        .map((e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  color: Colors.orange,
                  width: 12,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            ))
        .toList();

    final now = DateTime.now();
    final currentMonthKey = now.year * 100 + now.month;

    return _buildScrollableChart(
      data: data,
      currentHighlightKey: currentMonthKey,
      filterText: viewYear.toString(),
      onFilterPressed: () => _selectYearForChart(context),
      getTitle: (value, _) {
        final month = value.toInt() % 100;
        return DateFormat('MM').format(DateTime(viewYear, month));
      },
    );
  }

  Widget _buildScrollableChart({
    required List<BarChartGroupData> data,
    required int currentHighlightKey,
    required String filterText,
    required VoidCallback onFilterPressed,
    required String Function(double, TitleMeta) getTitle,
  }) {
    if (data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final chartWidth = data.length * barWidth;
    final maxY =
        data.map((e) => e.barRods.first.toY).reduce((a, b) => a > b ? a : b);
    final interval = (maxY / 5).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: onFilterPressed,
                icon: const Icon(Icons.filter_alt, size: 16),
                label: Text(filterText, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.start,
                      barGroups: [],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              if (value % interval != 0) {
                                return const SizedBox();
                              }

                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                          show: true,
                          border: Border(
                              left: BorderSide(color: Colors.black, width: 1))),
                      gridData: FlGridData(show: false),
                      minY: 0,
                      maxY: data.isNotEmpty
                          ? data
                                  .map((e) => e.barRods.first.toY)
                                  .reduce((a, b) => a > b ? a : b) +
                              1
                          : 1,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _chartScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: chartWidth > MediaQuery.of(context).size.width
                          ? chartWidth
                          : MediaQuery.of(context).size.width - 32,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceEvenly,
                          barGroups: data,
                          titlesData: FlTitlesData(
                            // leftTitles: AxisTitles(
                            //   sideTitles: SideTitles(
                            //     showTitles: true,
                            //     reservedSize: 40,
                            //     interval: interval == 0 ? 1 : interval,
                            //   ),
                            // ),
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final isCurrent =
                                      value.toInt() == currentHighlightKey;
                                  return Container(
                                    decoration: isCurrent
                                        ? const BoxDecoration(
                                            border: Border(
                                                bottom: BorderSide(
                                                    color: Colors.orangeAccent,
                                                    width: 2)))
                                        : null,
                                    child: SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        getTitle(value, meta),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isCurrent
                                              ? Colors.orangeAccent
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: true),
                          gridData:
                              FlGridData(show: true, drawVerticalLine: false),
                          minY: 0,
                          maxY: maxY + 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime _getMondayOfWeek(int weekKey) {
    final year = weekKey ~/ 100;
    final week = weekKey % 100;
    final jan4 = DateTime(year, 1, 4);
    final jan4Weekday = jan4.weekday;
    final daysToMonday = (jan4Weekday - 1 + 7) % 7;
    final firstMondayOfWeek1 = jan4.subtract(Duration(days: daysToMonday));
    return firstMondayOfWeek1.add(Duration(days: (week - 1) * 7));
  }

  Future<void> _selectMonthForChart(BuildContext context) async {
    final now = DateTime.now();
    int displayYear = selectedMonth?.year ?? now.year;

    final int? pickedValue = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chọn tháng',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              content: SizedBox(
                width: 300,
                height: 250,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => setStateDialog(() => displayYear--),
                        ),
                        Text('$displayYear',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => setStateDialog(() => displayYear++),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final isSelected = displayYear ==
                                  (selectedMonth?.year ?? now.year) &&
                              month == (selectedMonth?.month ?? now.month);
                          return InkWell(
                            onTap: () => Navigator.pop(
                                context, displayYear * 100 + month),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Tháng $month',
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (pickedValue != null) {
      setState(() {
        selectedMonth = DateTime(pickedValue ~/ 100, pickedValue % 100);
      });
      if (_chartType == 'week') {
        _scrollToCurrentWeek();
      } else if (_chartType == 'day') {
        _scrollToDailyChartToday();
      }
    }
  }

  Future<void> _selectYearForChart(BuildContext context) async {
    final currentYear = selectedYear ?? DateTime.now().year;
    int rangeStart = (currentYear ~/ 10) * 10;
    int rangeEnd = rangeStart + 9;

    final int? picked = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final years = List.generate(10, (i) => rangeStart + i);
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chọn năm',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              content: SizedBox(
                width: 300,
                height: 230,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => setStateDialog(() {
                            rangeStart -= 10;
                            rangeEnd -= 10;
                          }),
                        ),
                        Text('$rangeStart - $rangeEnd',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => setStateDialog(() {
                            rangeStart += 10;
                            rangeEnd += 10;
                          }),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.8,
                        ),
                        itemCount: years.length,
                        itemBuilder: (context, index) {
                          final year = years[index];
                          final isSelected = year == currentYear;
                          return InkWell(
                            onTap: () => Navigator.pop(context, year),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$year',
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() => selectedYear = picked);
      _scrollToCurrentMonth();
    }
  }

  // ==================== 4. DEADLINE SECTION ====================
  Widget _buildDeadlineSection(List<TaskModel> tasks) {
    final now = DateTime.now();
    final upcomingTasks = tasks.where((t) {
      if (t.status == TaskStatus.done ||
          t.status == TaskStatus.waitConfirm ||
          t.status == TaskStatus.pause) {
        return false;
      }

      if (t.endDate == null) return false;
      final daysUntilEnd = t.endDate!.difference(now).inDays;
      return daysUntilEnd >= 0 && daysUntilEnd <= 1;
    }).toList()
      ..sort((a, b) =>
          (a.endDate ?? a.startDate).compareTo(b.endDate ?? b.startDate));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Deadline',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${upcomingTasks.length} task',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Công việc sắp đến hạn trong 1 ngày',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (upcomingTasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 48, color: Colors.green),
                    SizedBox(height: 12),
                    Text('Không có deadline gần',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingTasks.length > 5 ? 5 : upcomingTasks.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final task = upcomingTasks[index];
                final daysLeft = task.endDate!.difference(now).inDays;
                final isUrgent = daysLeft <= 1;

                return ListTile(
                  // leading: Container(
                  //   width: 50,
                  //   height: 50,
                  //   decoration: BoxDecoration(
                  //     color: isUrgent
                  //         ? Colors.red.shade100
                  //         : Colors.orange.shade100,
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Column(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       Text(
                  //         '$daysLeft',
                  //         style: TextStyle(
                  //           fontSize: 20,
                  //           fontWeight: FontWeight.bold,
                  //           color: isUrgent
                  //               ? Colors.red.shade700
                  //               : Colors.orange.shade700,
                  //         ),
                  //       ),
                  //       Text(
                  //         'ngày',
                  //         style: TextStyle(
                  //           fontSize: 10,
                  //           color: isUrgent
                  //               ? Colors.red.shade700
                  //               : Colors.orange.shade700,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  title: Text(
                    task.taskName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Đến hạn: ${DateFormat('dd/MM/yyyy').format(task.endDate!)}',
                    style: TextStyle(
                      color: isUrgent ? Colors.red.shade700 : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(task.status),
                      style: TextStyle(
                        color: _getStatusColor(task.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          // if (upcomingTasks.length > 5)
          //   TextButton(
          //     onPressed: () {},
          //     child: const Text('Xem tất cả'),
          //   ),
        ],
      ),
    );
  }

  // ==================== 5. WORKLOAD SECTION ====================
  Widget _buildWorkLoadSection(
      List<TaskModel> tasks, List<EmployeeModel> employees) {
    // LỌC BỎ ADMIN hoàn toàn khỏi danh sách hiển thị
    final staffEmployees = employees
        .where((emp) => (emp.roleId.toLowerCase() != 'admin'))
        .toList();

    // Đếm số task của từng nhân viên
    final Map<String, int> employeeTaskCount = {};

    for (var task in tasks) {
      for (var empId in task.assignedTo) {
        employeeTaskCount[empId] = (employeeTaskCount[empId] ?? 0) + 1;
      }
    }

    // Tạo danh sách kèm số task + sắp xếp giảm dần
    final sortedEmployees = staffEmployees.map((emp) {
      return {
        'employee': emp,
        'taskCount': employeeTaskCount[emp.employeeId] ?? 0,
      };
    }).toList()
      ..sort(
          (a, b) => (b['taskCount'] as int).compareTo(a['taskCount'] as int));

    // Lọc theo tìm kiếm
    final filteredEmployees = _searchQuery.isEmpty
        ? sortedEmployees
        : sortedEmployees.where((item) {
            final emp = item['employee'] as EmployeeModel;
            return emp.employeeName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
          }).toList();

    // Chỉ hiển thị tối đa 5 người
    final displayEmployees = filteredEmployees.take(10).toList();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WorkLoad',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Phân bổ công việc theo nhân viên',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Ô tìm kiếm
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm nhân viên...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Danh sách hoặc thông báo trống
          if (displayEmployees.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Không tìm thấy nhân viên',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayEmployees.length,
              separatorBuilder: (context, index) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final item = displayEmployees[index];
                final employee = item['employee'] as EmployeeModel;
                final taskCount = item['taskCount'] as int;

                // Tính phần trăm dựa trên người có nhiều task nhất
                final maxTasks = sortedEmployees.isNotEmpty
                    ? (sortedEmployees.first['taskCount'] as int)
                    : 1;
                final percentage = maxTasks > 0 ? (taskCount / maxTasks) : 0.0;

                // Màu thanh tiến độ
                Color barColor;
                if (percentage >= 0.8) {
                  barColor = Colors.red;
                } else if (percentage >= 0.5) {
                  barColor = Colors.orange;
                } else {
                  barColor = Colors.green;
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: barColor.withOpacity(0.2),
                    child: Text(
                      employee.employeeName.isNotEmpty
                          ? employee.employeeName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: barColor,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    employee.employeeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.grey.shade200,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(barColor),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: barColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$taskCount tasks',
                              style: TextStyle(
                                color: barColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.waitConfirm:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.orangeAccent;
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.overdue:
        return Colors.red;
      case TaskStatus.newTask:
        return Colors.blue;
      case TaskStatus.pause:
        return Colors.lightBlueAccent;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.waitConfirm:
        return 'Chờ xác nhận';
      case TaskStatus.inProgress:
        return 'Đang làm';
      case TaskStatus.done:
        return 'Hoàn thành';
      case TaskStatus.overdue:
        return 'Trễ hạn';
      case TaskStatus.newTask:
        return 'Công việc mới';
      case TaskStatus.pause:
        return 'Tạm dừng';
    }
  }
}

// Extension for week of year
extension DateTimeExtension on DateTime {
  int get weekOfYear {
    final jan4 = DateTime(year, 1, 4);
    final jan4Weekday = jan4.weekday;
    final daysToMonday = (jan4Weekday - DateTime.monday + 7) % 7;
    final firstMondayOfYear = jan4.subtract(Duration(days: daysToMonday));
    final daysSinceFirstMonday = difference(firstMondayOfYear).inDays;
    return (daysSinceFirstMonday ~/ 7) + 1;
  }
}
