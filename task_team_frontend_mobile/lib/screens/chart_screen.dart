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
  late ScrollController _weeklyChartScrollController;
  late ScrollController _monthlyChartScrollController;

  // Cấu hình hiển thị
  static const int visibleDaysCount = 5;
  static const double dayWidth = 55.0;
  static const double headerHeight = 60.0;
  static const int maxVisibleRows = 3;

  // Cấu hình biểu đồ
  static const int visibleBarsCount = 10;
  static const double barWidth = 35;

  DateTime? selectedDate;
  DateTime? selectedMonth;
  int? selectedYear;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _verticalScrollController = ScrollController();
    _weeklyChartScrollController = ScrollController();
    _monthlyChartScrollController = ScrollController();
    _initializeTimeline();

    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
    selectedYear = now.year;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialScroll();
      _scrollToCurrentWeek();
      _scrollToCurrentMonth();
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

  void _scrollToCurrentWeek() {
    final now = DateTime.now();
    final weekKey = now.year * 100 + now.weekOfYear;
    final index = _getWeekIndex(weekKey);
    if (index >= 0 && _weeklyChartScrollController.hasClients) {
      final target =
          index * barWidth - (visibleBarsCount * barWidth / 2) + barWidth / 2;
      final safe = target.clamp(
          0.0, _weeklyChartScrollController.position.maxScrollExtent);
      _weeklyChartScrollController.animateTo(
        safe,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToCurrentMonth() {
    final now = DateTime.now();

    final viewYear = selectedYear ?? now.year;
    final currentIndexInView = now.year == viewYear ? now.month - 1 : -1;

    if (currentIndexInView >= 0 && _monthlyChartScrollController.hasClients) {
      final target = currentIndexInView * barWidth -
          (visibleBarsCount * barWidth / 2) +
          barWidth / 2;

      final maxScroll = _monthlyChartScrollController.position.maxScrollExtent;
      final safeOffset = target.clamp(0.0, maxScroll);

      _monthlyChartScrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  int _getWeekIndex(int weekKey) {
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: startOfView,
      lastDate: startOfView.add(Duration(days: totalDaysInView - 1)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );

    if (picked != null && picked != selectedDate) {
      setState(
          () => selectedDate = DateTime(picked.year, picked.month, picked.day));
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
              authProvider.token!, authProvider.currentEmployee!.employeeId)
          .then((_) {
        if (mounted) _updateTimelineRange(taskProvider.tasks);
      });
    } else if (taskProvider.tasks.isNotEmpty) {
      _updateTimelineRange(taskProvider.tasks);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _verticalScrollController.dispose();
    _weeklyChartScrollController.dispose();
    _monthlyChartScrollController.dispose();
    super.dispose();
  }

  // ==================== BIỂU ĐỒ TUẦN ====================
  Widget _buildWeeklyChart(List<TaskModel> tasks) {
    final DateTime viewMonth = selectedMonth ?? DateTime.now();
    final int year = viewMonth.year;
    final int month = viewMonth.month;

    final List<int> allWeekKeys = [];
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    DateTime lastDayOfMonth = DateTime(year, month + 1, 0);

    // Tuần đầu tiên của tháng
    DateTime weekStart =
        firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    while (weekStart.isBefore(lastDayOfMonth.add(const Duration(days: 7)))) {
      if (weekStart.month == month ||
          (weekStart.add(const Duration(days: 6)).month == month) ||
          (weekStart.month <= month && weekStart.year == year)) {
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

      if (taskEnd.year < year || taskStart.year > year) continue;
      if (taskEnd.month < month && taskStart.month < month) continue;
      if (taskStart.month > month && taskEnd.month > month) continue;

      DateTime currentWeek =
          taskStart.subtract(Duration(days: taskStart.weekday - 1));
      final endWeek = taskEnd.subtract(Duration(days: taskEnd.weekday - 1));

      while (currentWeek.isBefore(endWeek) ||
          currentWeek.isAtSameMomentAs(endWeek)) {
        final key = currentWeek.year * 100 + currentWeek.weekOfYear;
        if (weekCount.containsKey(key)) {
          weekCount[key] = (weekCount[key] ?? 0) + 1;
        }
        currentWeek = currentWeek.add(const Duration(days: 7));
      }
    }

    final sortedKeys = allWeekKeys..sort();
    final data = sortedKeys
        .map((key) => BarChartGroupData(
              x: key,
              barRods: [
                BarChartRodData(
                  toY: weekCount[key]!.toDouble(),
                  color: Colors.blueAccent,
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            ))
        .toList();

    final currentWeekKey =
        DateTime.now().year * 100 + DateTime.now().weekOfYear;

    return _buildScrollableBarChart(
      title: 'Biểu đồ tuần',
      data: data,
      scrollController: _weeklyChartScrollController,
      currentHighlightKey: currentWeekKey,
      filterText: DateFormat('MM/yyyy').format(viewMonth),
      onFilterPressed: () => _selectMonthForWeeklyChart(context),
      getTitle: (value, _) {
        final key = value.toInt();
        final weekDate = _getMondayOfWeek(key);
        return DateFormat('dd/MM').format(weekDate);
      },
    );
  }

  Future<void> _selectMonthForWeeklyChart(BuildContext context) async {
    final DateTime now = DateTime.now();
    int displayYear = selectedMonth?.year ?? now.year;
    // final int currentMonth = selectedMonth?.month ?? now.month;

    final int? pickedValue = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              titlePadding: const EdgeInsets.only(top: 8, left: 16, right: 8),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tiêu đề "Chọn tháng"
                  const Text(
                    'Chọn tháng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Nút đóng X
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                height: 250,
                child: Column(
                  children: [
                    // Điều khiển năm (trái, giữa, phải)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setStateDialog(() {
                              displayYear--;
                            });
                          },
                        ),
                        InkWell(
                          onTap: () async {
                            final y = await showDialog<int>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Chọn năm',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    // Nút đóng X
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                content: SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: YearPicker(
                                    firstDate:
                                        DateTime(DateTime.now().year - 20),
                                    lastDate:
                                        DateTime(DateTime.now().year + 10),
                                    selectedDate: DateTime(displayYear),
                                    onChanged: (d) =>
                                        Navigator.pop(context, d.year),
                                  ),
                                ),
                              ),
                            );
                            if (y != null) {
                              setStateDialog(() {
                                displayYear = y;
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '$displayYear',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setStateDialog(() {
                              displayYear++;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    // Lưới chọn tháng
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
                            onTap: () {
                              Navigator.pop(context, displayYear * 100 + month);
                            },
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
      final y = pickedValue ~/ 100;
      final m = pickedValue % 100;
      setState(() {
        selectedMonth = DateTime(y, m);
      });
      _scrollToCurrentWeek();
    }
  }

  DateTime _getMondayOfWeek(int weekKey) {
    final year = weekKey ~/ 100;
    final week = weekKey % 100;
    final jan4 = DateTime(year, 1, 4);
    final firstMonday = jan4.subtract(Duration(days: jan4.weekday - 1));
    return firstMonday.add(Duration(days: (week - 1) * 7));
  }

  // ==================== BIỂU ĐỒ THÁNG ====================
  Widget _buildMonthlyChart(List<TaskModel> tasks) {
    final int viewYear = selectedYear ?? DateTime.now().year;

    final List<int> allMonthKeys = List.generate(12, (i) {
      return viewYear * 100 + (i + 1);
    });

    final Map<int, int> monthCount = {};
    for (int key in allMonthKeys) {
      monthCount[key] = 0;
    }

    for (var task in tasks) {
      final taskStart = task.startDate;
      final taskEnd = task.endDate ?? task.startDate;

      if (taskStart.year != viewYear && taskEnd.year != viewYear) continue;

      var current = DateTime(taskStart.year, taskStart.month, 1);
      final endMonth = DateTime(taskEnd.year, taskEnd.month, 1);

      while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
        if (current.year == viewYear) {
          final key = current.year * 100 + current.month;
          monthCount[key] = (monthCount[key] ?? 0) + 1;
        }
        current = DateTime(
          current.month == 12 ? current.year + 1 : current.year,
          current.month == 12 ? 1 : current.month + 1,
          1,
        );
      }
    }

    final data = allMonthKeys
        .map((key) => BarChartGroupData(
              x: key,
              barRods: [
                BarChartRodData(
                  toY: monthCount[key]!.toDouble(),
                  color: Colors.green,
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            ))
        .toList();

    final currentMonthKey = DateTime.now().year * 100 + DateTime.now().month;

    return _buildScrollableBarChart(
      title: 'Biểu đồ tháng',
      data: data,
      scrollController: _monthlyChartScrollController,
      currentHighlightKey: currentMonthKey,
      filterText: viewYear.toString(),
      onFilterPressed: () => _selectYearForMonthlyChart(context),
      getTitle: (value, _) {
        final month = value.toInt() % 100;
        return DateFormat('MM').format(DateTime(viewYear, month));
      },
    );
  }

  Future<void> _selectYearForMonthlyChart(BuildContext context) async {
    final int currentYear = selectedYear ?? DateTime.now().year;
    final int currentMonth = DateTime.now().month;

    final int startYear = DateTime.now().year - 20;
    final int endYear = DateTime.now().year + 10;

    int rangeStart = (currentYear ~/ 10) * 10;
    int rangeEnd = rangeStart + 9;

    final int? picked = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final List<int> years = List.generate(10, (i) => rangeStart + i)
                .where((y) => y <= endYear)
                .toList();

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chọn năm',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                height: 230, // tăng chiều cao để thêm dòng tháng/năm hiện tại
                child: Column(
                  children: [
                    // --- Thanh điều hướng nhóm năm ---
                    const Divider(height: 2),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setStateDialog(() {
                              rangeStart = (rangeStart - 10)
                                  .clamp(startYear, endYear - 9);
                              rangeEnd = rangeStart + 9;
                            });
                          },
                        ),
                        Text(
                          '$rangeStart - $rangeEnd',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            if (rangeEnd < endYear) {
                              setStateDialog(() {
                                rangeStart = (rangeStart + 10)
                                    .clamp(startYear, endYear - 9);
                                rangeEnd = rangeStart + 9;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tháng $currentMonth - Năm $currentYear',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    // --- Lưới chọn năm trong khoảng ---
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: years.length,
                        itemBuilder: (context, index) {
                          final year = years[index];
                          final isSelected = year == currentYear;
                          return InkWell(
                            onTap: () => Navigator.pop(context, year),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$year',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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

    if (picked != null && picked != selectedYear) {
      setState(() {
        selectedYear = picked;
      });
      _scrollToCurrentMonth();
    }
  }

  Widget _buildScrollableBarChart({
    required String title,
    required List<BarChartGroupData> data,
    required ScrollController scrollController,
    required int currentHighlightKey,
    required String filterText,
    required VoidCallback onFilterPressed,
    required String Function(double, TitleMeta) getTitle,
  }) {
    if (data.isEmpty) {
      return Container(
          padding: const EdgeInsets.all(16),
          child:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)));
    }

    final totalBars = data.length;
    final chartWidth = totalBars * barWidth;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
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
                // Trục Y
                SizedBox(
                  width: 20,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.start,
                      barGroups: [],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            interval: 1,
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
                      maxY: data
                              .map((e) => e.barRods.first.toY)
                              .reduce((a, b) => a > b ? a : b) +
                          1,
                    ),
                  ),
                ),
                // Biểu đồ cuộn ngang
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: chartWidth > MediaQuery.of(context).size.width
                          ? chartWidth
                          : MediaQuery.of(context).size.width,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceEvenly,
                          barGroups: data,
                          titlesData: FlTitlesData(
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
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
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
                          borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                  bottom: BorderSide(
                                      color: Colors.black, width: 1))),
                          gridData: FlGridData(
                            show: true,
                            drawHorizontalLine: false,
                            drawVerticalLine: true,
                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: Colors.black38,
                                strokeWidth: 1,
                                dashArray: null,
                              );
                            },
                          ),
                          minY: 0,
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

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;

    final allDays = List.generate(
        totalDaysInView, (i) => startOfView.add(Duration(days: i)));

    final result = _buildTaskBars(tasks, startOfView);
    final List<Widget> taskWidgets = result['widgets'];
    // final int maxRows = result['maxRows'];
    final double visibleTaskHeight = maxVisibleRows * 45.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Biểu đồ',
            style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
      ),
      body: taskProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(child: Text('Không có task nào để hiển thị'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header ngày
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.grey.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Biểu đồ ngày',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(
                                icon: const Icon(Icons.calendar_today,
                                    color: Colors.blueAccent),
                                onPressed: () => _selectDate(context)),
                          ],
                        ),
                      ),
                      Container(height: 2, color: Colors.grey.shade400),

                      // Lịch chính
                      SizedBox(
                        height: headerHeight + visibleTaskHeight + 20,
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: totalDaysInView * dayWidth,
                              child: Column(
                                children: [
                                  _buildDayHeaders(allDays),
                                  SizedBox(
                                    height: 150,
                                    child: Scrollbar(
                                      controller: _verticalScrollController,
                                      thumbVisibility: false,
                                      child: SingleChildScrollView(
                                        controller: _verticalScrollController,
                                        child: SizedBox(
                                          height:
                                              headerHeight + visibleTaskHeight,
                                          child: Stack(
                                            children: [
                                              _buildVerticalColumns(
                                                  allDays,
                                                  totalDaysInView * 45.0 +
                                                      headerHeight),
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
                      ),
                      Container(height: 2, color: Colors.grey.shade400),

                      // 2 biểu đồ nhỏ
                      if (tasks.isNotEmpty) ...[
                        SizedBox(height: 220, child: _buildWeeklyChart(tasks)),
                        SizedBox(height: 220, child: _buildMonthlyChart(tasks)),
                        const Divider(height: 1, color: Colors.grey),
                      ],
                    ],
                  ),
                ),
    );
  }

  // ==================== CÁC HÀM PHỤ ====================
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
                Text(DateFormat('EEE').format(day),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected
                            ? Colors.orange.shade800
                            : isToday
                                ? Colors.blueAccent
                                : Colors.black87)),
                const SizedBox(height: 2),
                Text(DateFormat('M/d').format(day),
                    style: TextStyle(
                        fontWeight:
                            isSelected || isToday ? FontWeight.bold : null,
                        fontSize: 11,
                        color: isSelected
                            ? Colors.orange.shade800
                            : isToday
                                ? Colors.blueAccent
                                : Colors.black54)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _buildTaskBars(
      List<TaskModel> tasks, DateTime viewStart) {
    if (tasks.isEmpty) return {'widgets': <Widget>[], 'maxRows': 0};

    final colors = [
      Colors.blue.shade200,
      Colors.green.shade200,
      Colors.orange.shade200,
      Colors.yellow.shade200,
      Colors.purple.shade200,
      Colors.pink.shade200,
      Colors.teal.shade200,
      Colors.indigo.shade200
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
      bool placed = false;
      for (int r = 0; r < rows.length; r++) {
        bool canPlace = true;
        for (final occ in rows[r]) {
          if (!(visibleEnd < occ['start']! || visibleStart > occ['end']!)) {
            canPlace = false;
            break;
          }
        }
        if (canPlace) {
          assignedRow = r;
          placed = true;
          rows[r].add({'start': visibleStart, 'end': visibleEnd});
          break;
        }
      }
      if (!placed) {
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
                    offset: const Offset(0, 1))
              ],
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(task.taskName,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
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

// Extension lấy tuần trong năm
extension DateTimeExtension on DateTime {
  int get weekOfYear {
    final firstDay = DateTime(year, 1, 1);
    final days = difference(firstDay).inDays + firstDay.weekday - 1;
    return days ~/ 7 + 1;
  }
}
