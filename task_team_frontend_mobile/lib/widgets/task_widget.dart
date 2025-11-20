import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/tasktype_provider.dart';
import '../screens/detail_task_screen.dart';
import '../screens/manager/manager_detail_task_screen.dart';
import '../utils/task_helper.dart';

/// Widget hiển thị lời chào (dành cho Home Screen)
class GreetingWidget extends StatelessWidget {
  final String employeeName;

  const GreetingWidget({
    super.key,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xin chào!!!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(employeeName, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

/// Widget hiển thị lịch (dùng chung cho cả 2 màn hình)
class TaskCalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final TaskProvider taskProvider;

  const TaskCalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.taskProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TableCalendar(
        locale: 'vi_VN',
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: focusedDay,
        calendarFormat: calendarFormat,
        availableCalendarFormats: calendarFormat == CalendarFormat.week
            ? const {CalendarFormat.week: 'Tuần'}
            : const {},
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
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
}

/// Widget hiển thị công việc trong ngày (dành cho Home Screen)
class TodaySectionWidget extends StatelessWidget {
  final DateTime? selectedDay;
  final List<TaskModel> tasks;
  final bool isLoading;
  final bool hasLoadedTasks;

  const TodaySectionWidget({
    super.key,
    required this.selectedDay,
    required this.tasks,
    required this.isLoading,
    required this.hasLoadedTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Công việc ngày ${selectedDay?.day}/${selectedDay?.month}/${selectedDay?.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: isLoading && !hasLoadedTasks
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
                      itemBuilder: (context, i) {
                        final task = tasks[i];
                        return _TaskChipCard(task: task);
                      },
                    ),
        ),
      ],
    );
  }
}

/// Widget hiển thị thống kê (dành cho All Task Screen)
class StatsSectionWidget extends StatelessWidget {
  final int total;
  final int newTasks;
  final int inProgress;
  final int waitConfirm;
  final int done;
  final int overdue;

  const StatsSectionWidget({
    super.key,
    required this.total,
    required this.newTasks,
    required this.inProgress,
    required this.waitConfirm,
    required this.done,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
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
          _StatCard('Toàn bộ công việc', total, const Color(0xFF6EC1E4)),
          _StatCard('Công việc mới', newTasks, const Color(0xFFB2EBF2)),
          _StatCard('Đang làm', inProgress, const Color(0xFFFFD54F)),
          _StatCard('Chờ xác nhận', waitConfirm, const Color(0xFFB0BEC5)),
          _StatCard('Hoàn thành', done, const Color(0xFF81C784)),
          _StatCard('Quá hạn', overdue, const Color(0xFFE57373)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color backgroundColor;

  const _StatCard(this.title, this.count, this.backgroundColor);

  @override
  Widget build(BuildContext context) {
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
}

/// Widget header với search (dùng chung cho cả 2 màn hình)
class TaskHeaderWidget extends StatelessWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onSearchPressed;
  final VoidCallback onSearchClosed;
  final Function(String) onSearchChanged;
  final String title;

  const TaskHeaderWidget({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.onSearchPressed,
    required this.onSearchClosed,
    required this.onSearchChanged,
    this.title = 'Toàn bộ công việc',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isSearching
              ? Expanded(
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm công việc...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onSearchClosed,
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: onSearchChanged,
                  ),
                )
              : Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
          if (!isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: onSearchPressed,
            ),
        ],
      ),
    );
  }
}

/// Widget filter chips (dùng chung cho cả 2 màn hình)
class FilterChipsWidget extends StatelessWidget {
  final String selectedFilter;
  final List<String> filterOptions;
  final Function(String) onFilterSelected;

  const FilterChipsWidget({
    super.key,
    required this.selectedFilter,
    required this.filterOptions,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filterOptions.length,
        itemBuilder: (context, index) {
          final option = filterOptions[index];
          final isSelected = selectedFilter == option;
          final statusEnum = TaskHelpers.statusViToEnum(option);
          final chipColor = TaskHelpers.getStatusColor(statusEnum);

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
              onSelected: (_) => onFilterSelected(option),
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
}

/// Widget danh sách công việc (dùng chung cho cả 2 màn hình)
class TaskListWidget extends StatelessWidget {
  final List<TaskModel> tasks;
  final TaskProvider taskProvider;
  final bool isSearchMode;
  final bool hasLoadedTasks;
  final VoidCallback onRetry;

  const TaskListWidget({
    super.key,
    required this.tasks,
    required this.taskProvider,
    required this.isSearchMode,
    required this.hasLoadedTasks,
    required this.onRetry,
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
                : 'Chưa có công việc nào',
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
        return _TaskItemCard(task: tasks[index]);
      },
    );
  }
}

/// Card hiển thị task dạng chip (cho Today Section)
class _TaskChipCard extends StatelessWidget {
  final TaskModel task;

  const _TaskChipCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = TaskHelpers.getStatusColor(task.status);
    final statusVi = TaskHelpers.statusEnumToVi(task.status);
    final tasktypeProvider =
        Provider.of<TasktypeProvider>(context, listen: false);
    final taskTypeName =
        tasktypeProvider.getTasktypeNameById(task.tasktypeId) ??
            'Không xác định';

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentEmployee?.roleId ?? '';

    return Padding(
      padding: const EdgeInsets.only(right: 12),
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
                task.taskName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                taskTypeName,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusVi,
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
}

/// Card hiển thị task dạng list item
class _TaskItemCard extends StatelessWidget {
  final TaskModel task;

  const _TaskItemCard({required this.task});

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
          child: Row(
            children: [
              Expanded(
                child: Column(
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
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusVi,
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
}
