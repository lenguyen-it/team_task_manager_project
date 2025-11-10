import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:task_team_frontend_mobile/models/task_model.dart';
import 'package:task_team_frontend_mobile/providers/task_provider.dart';
import '../providers/auth_provider.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late DateTime startOfView;
  late int totalDaysInView;
  late ScrollController _scrollController;
  late ScrollController _verticalScrollController;

  // Cấu hình hiển thị
  static const int visibleDaysCount = 5;
  static const double dayWidth = 55.0;
  static const double headerHeight = 60.0;
  static const int maxVisibleRows = 3;

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _verticalScrollController = ScrollController();
    _initializeTimeline();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialScroll();
    });
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

    if (now.isBefore(earliest)) earliest = now;
    if (now.isAfter(latest)) latest = now;

    earliest = DateTime(earliest.year, earliest.month - 1, 1);
    latest = DateTime(latest.year, latest.month + 2, 0);

    final newStart = earliest;
    final newDays = latest.difference(newStart).inDays + 1;

    setState(() {
      startOfView = newStart;
      totalDaysInView = newDays.clamp(90, 730);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialScroll();
    });
  }

  void _setInitialScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final today = DateTime.now();
    final todayIndex = today.difference(startOfView).inDays;
    final viewWidth = visibleDaysCount * dayWidth;
    final targetOffset =
        (todayIndex * dayWidth) - (viewWidth / 2) + (dayWidth / 2);

    final maxScroll = _scrollController.position.maxScrollExtent;
    final safeOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.jumpTo(safeOffset);
  }

  void _scrollToDate(DateTime date) {
    if (!_scrollController.hasClients) return;

    final index = date.difference(startOfView).inDays;
    if (index < 0 || index >= totalDaysInView) return;

    final viewWidth = visibleDaysCount * dayWidth;
    final targetOffset = (index * dayWidth) - (viewWidth / 2) + (dayWidth / 2);

    final maxScroll = _scrollController.position.maxScrollExtent;
    final safeOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      safeOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: startOfView,
      lastDate: startOfView.add(Duration(days: totalDaysInView - 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
      _scrollToDate(selectedDate!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final taskProvider = Provider.of<TaskProvider>(context);
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isAuthenticated &&
        authProvider.currentEmployee != null &&
        authProvider.token != null &&
        taskProvider.tasks.isEmpty &&
        !taskProvider.isLoading) {
      taskProvider
          .getTaskByEmployee(
        authProvider.token!,
        authProvider.currentEmployee!.employeeId,
      )
          .then((_) {
        if (mounted) {
          _updateTimelineRange(taskProvider.tasks);
        }
      });
    } else if (taskProvider.tasks.isNotEmpty) {
      _updateTimelineRange(taskProvider.tasks);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  // === BIỂU ĐỒ THEO TUẦN ===
  Widget _buildWeeklyChart(List<TaskModel> tasks) {
    final Map<int, int> weekCount = {};

    for (var task in tasks) {
      final weekStart =
          task.startDate.subtract(Duration(days: task.startDate.weekday - 1));
      final weekKey = weekStart.year * 100 + weekStart.weekOfYear;
      weekCount[weekKey] = (weekCount[weekKey] ?? 0) + 1;
    }

    final sortedWeeks = weekCount.keys.toList()..sort();
    final data = sortedWeeks.map((key) {
      final year = key ~/ 100;
      final week = key % 100;
      DateTime(year).add(Duration(days: (week - 1) * 7));
      return BarChartGroupData(
        x: key,
        barRods: [
          BarChartRodData(
            toY: weekCount[key]!.toDouble(),
            color: Colors.blueAccent,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return _buildBarChart(
      title: 'Task theo tuần',
      data: data,
      getTitle: (value, _) {
        final key = value.toInt();
        final week = key % 100;
        return 'T$week';
      },
    );
  }

  // === BIỂU ĐỒ THEO THÁNG ===
  Widget _buildMonthlyChart(List<TaskModel> tasks) {
    final Map<String, int> monthCount = {};

    for (var task in tasks) {
      final key = DateFormat('yyyy-MM').format(task.startDate);
      monthCount[key] = (monthCount[key] ?? 0) + 1;
    }

    final sortedMonths = monthCount.keys.toList()..sort();
    final data = sortedMonths.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: monthCount[e.value]!.toDouble(),
            color: Colors.green,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return _buildBarChart(
      title: 'Task theo tháng',
      data: data,
      getTitle: (value, _) {
        final index = value.toInt();
        if (index >= sortedMonths.length) return '';
        return DateFormat('MM/yyyy')
            .format(DateTime.parse('${sortedMonths[index]}-01'));
      },
    );
  }

  Widget _buildBarChart({
    required String title,
    required List<BarChartGroupData> data,
    required String Function(double, TitleMeta) getTitle,
  }) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: data,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(getTitle(value, meta),
                            style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;

    final allDays = List.generate(
      totalDaysInView,
      (i) => startOfView.add(Duration(days: i)),
    );

    final result = _buildTaskBars(tasks, startOfView);
    final List<Widget> taskWidgets = result['widgets'];
    final int maxRows = result['maxRows'];

    final double visibleTaskHeight = maxVisibleRows * 45.0;
    final double totalTaskHeight = maxRows * 45.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Biểu đồ',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: taskProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(child: Text('Không có task nào để hiển thị'))
              : Column(
                  children: [
                    // === TIÊU ĐỀ + ICON ===
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.grey.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Biểu đồ ngày',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today,
                                color: Colors.blueAccent),
                            onPressed: () => _selectDate(context),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 2, color: Colors.grey.shade400),
                    // === PHẦN LỊCH CHÍNH ===
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: totalDaysInView * dayWidth,
                              child: Column(
                                children: [
                                  _buildDayHeaders(allDays),
                                  SizedBox(
                                    height: visibleTaskHeight,
                                    child: Scrollbar(
                                      controller: _verticalScrollController,
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        controller: _verticalScrollController,
                                        child: SizedBox(
                                          height: totalTaskHeight >
                                                  visibleTaskHeight
                                              ? totalTaskHeight
                                              : visibleTaskHeight,
                                          child: Stack(
                                            children: [
                                              _buildVerticalColumns(
                                                  allDays,
                                                  totalTaskHeight +
                                                      headerHeight),
                                              ...taskWidgets,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                      height: 2, color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // === 2 BIỂU ĐỒ NHỎ ===
                    if (tasks.isNotEmpty) ...[
                      _buildWeeklyChart(tasks),
                      _buildMonthlyChart(tasks),
                      const Divider(height: 1, color: Colors.grey),
                    ],
                  ],
                ),
    );
  }

  // === CÁC HÀM PHỤ ===
  Widget _buildVerticalColumns(List<DateTime> days, double height) {
    final now = DateTime.now();
    return Row(
      children: days.map((day) {
        final isToday = now.year == day.year &&
            now.month == day.month &&
            now.day == day.day;
        final isSelected = selectedDate != null &&
            selectedDate!.year == day.year &&
            selectedDate!.month == day.month &&
            selectedDate!.day == day.day;

        return Container(
          width: dayWidth,
          height: height,
          decoration: BoxDecoration(
            border: Border(
                right: BorderSide(color: Colors.grey.shade300, width: 1)),
            color: isSelected
                ? Colors.orange.shade100
                : isToday
                    ? Colors.blue.shade50
                    : Colors.white,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayHeaders(List<DateTime> days) {
    final now = DateTime.now();
    return Container(
      height: headerHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(
                color: Color.fromARGB(255, 190, 188, 188), width: 2)),
      ),
      child: Row(
        children: days.map((day) {
          final isToday = now.year == day.year &&
              now.month == day.month &&
              now.day == day.day;
          final isSelected = selectedDate != null &&
              selectedDate!.year == day.year &&
              selectedDate!.month == day.month &&
              selectedDate!.day == day.day;

          return Container(
            width: dayWidth,
            height: headerHeight,
            decoration: BoxDecoration(
              border:
                  const Border(right: BorderSide(color: Colors.grey, width: 1)),
              color: isSelected
                  ? Colors.orange.shade100
                  : isToday
                      ? Colors.blue.shade50
                      : Colors.white,
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(day),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSelected
                        ? Colors.orange.shade800
                        : isToday
                            ? Colors.blueAccent
                            : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('M/d').format(day),
                  style: TextStyle(
                    fontWeight: isSelected || isToday ? FontWeight.bold : null,
                    fontSize: 11,
                    color: isSelected
                        ? Colors.orange.shade800
                        : isToday
                            ? Colors.blueAccent
                            : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _buildTaskBars(
      List<TaskModel> tasks, DateTime viewStart) {
    if (tasks.isEmpty) {
      return {'widgets': <Widget>[], 'maxRows': 0};
    }

    final colors = [
      Colors.blue.shade200,
      Colors.green.shade200,
      Colors.orange.shade200,
      Colors.purple.shade200,
      Colors.pink.shade200,
      Colors.teal.shade200,
      Colors.indigo.shade200,
    ];

    final List<List<Map<String, int>>> rows = [];
    final List<Widget> taskWidgets = [];

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final start = task.startDate;
      final end = task.endDate ?? task.startDate;

      final startIndex = start.difference(viewStart).inDays;
      final endIndex = end.difference(viewStart).inDays;

      if (endIndex < 0 || startIndex >= totalDaysInView) continue;

      final visibleStart = startIndex.clamp(0, totalDaysInView - 1);
      final visibleEnd = endIndex.clamp(0, totalDaysInView - 1);
      final taskWidth = (visibleEnd - visibleStart + 1) * dayWidth;

      int assignedRow = 0;
      bool rowFound = false;

      for (int row = 0; row < rows.length; row++) {
        bool canPlace = true;
        for (final occupied in rows[row]) {
          final occStart = occupied['start']!;
          final occEnd = occupied['end']!;
          if (!(visibleEnd < occStart || visibleStart > occEnd)) {
            canPlace = false;
            break;
          }
        }
        if (canPlace) {
          assignedRow = row;
          rowFound = true;
          rows[row].add({'start': visibleStart, 'end': visibleEnd});
          break;
        }
      }

      if (!rowFound) {
        assignedRow = rows.length;
        rows.add([
          {'start': visibleStart, 'end': visibleEnd}
        ]);
      }

      final color = colors[i % colors.length];
      taskWidgets.add(
        Positioned(
          left: visibleStart * dayWidth,
          top: 10 + assignedRow * 45,
          child: Container(
            width: taskWidth,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade400),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              task.taskName,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      );
    }

    return {
      'widgets': taskWidgets,
      'maxRows': rows.length,
    };
  }
}

// Extension để lấy tuần trong năm
extension DateTimeExtension on DateTime {
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysSinceFirstDay = difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay + firstDayOfYear.weekday - 1) ~/ 7 + 1;
  }
}
