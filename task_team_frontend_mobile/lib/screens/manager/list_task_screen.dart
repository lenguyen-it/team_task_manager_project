import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/models/task_model.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/task_provider.dart';
import 'package:task_team_frontend_mobile/utils/task_helper.dart';
import 'package:task_team_frontend_mobile/widgets/task_widget.dart';

class ListTaskScreen extends StatefulWidget {
  const ListTaskScreen({super.key});

  @override
  State<ListTaskScreen> createState() => _ListTaskScreenState();
}

class _ListTaskScreenState extends State<ListTaskScreen> {
  bool _hasLoadedTasks = false;
  final TextEditingController _searchController = TextEditingController();

  List<TaskModel> _searchResults = [];
  bool _isSearchMode = false;

  String _selectedFilter = 'Tất cả';
  String _selectedPriority = 'Tất cả';

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

    // Lọc theo trạng thái
    final filteredByStatus =
        TaskHelpers.filterTasksByStatus(baseTasks, _selectedFilter);

    // Lọc theo độ ưu tiên
    final filteredByPriority = _selectedPriority == 'Tất cả'
        ? filteredByStatus
        : filteredByStatus
            .where((task) =>
                task.priority.toLowerCase() == _selectedPriority.toLowerCase())
            .toList();

    return TaskHelpers.sortTasksByPriority(filteredByPriority);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            final displayTasks = _getDisplayTasks(taskProvider);

            return Column(
              children: [
                const SizedBox(height: 16),

                // Search bar - luôn hiển thị
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

                // Dropdown lọc theo độ ưu tiên
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text(
                        'Độ ưu tiên:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              value: _selectedPriority,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                    value: 'Tất cả', child: Text('Tất cả')),
                                DropdownMenuItem(
                                    value: 'high', child: Text('Cao')),
                                DropdownMenuItem(
                                    value: 'normal', child: Text('Trung bình')),
                                DropdownMenuItem(
                                    value: 'low', child: Text('Thấp')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedPriority = value);
                                }
                              },
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 300,
                                offset: const Offset(0, -1),
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                height: 48,
                              ),
                              buttonStyleData: const ButtonStyleData(
                                padding: EdgeInsets.zero,
                              ),
                              iconStyleData: const IconStyleData(
                                icon: Icon(Icons.arrow_drop_down),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Filter chips theo trạng thái
                FilterChipsWidget(
                  selectedFilter: _selectedFilter,
                  filterOptions: TaskHelpers.filterOptions,
                  onFilterSelected: (option) {
                    setState(() => _selectedFilter = option);
                  },
                ),

                const SizedBox(height: 16),

                // Danh sách task có thể cuộn
                Expanded(
                  child: SingleChildScrollView(
                    child: TaskListWidget(
                      tasks: displayTasks,
                      taskProvider: taskProvider,
                      isSearchMode: _isSearchMode,
                      hasLoadedTasks: _hasLoadedTasks,
                      onRetry: _loadTasks,
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
