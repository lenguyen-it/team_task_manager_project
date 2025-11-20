import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/models/project_model.dart';
import 'package:task_team_frontend_mobile/models/task_model.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/employee_provider.dart';
import 'package:task_team_frontend_mobile/providers/project_provider.dart';
import 'package:task_team_frontend_mobile/providers/task_provider.dart';
import 'package:task_team_frontend_mobile/providers/tasktype_provider.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _taskNameController;
  late TextEditingController _taskIdController;
  late TextEditingController _descriptionController;

  // Selected values
  ProjectModel? _selectedProject;
  String? _selectedTasktypeId;
  String _selectedStatus = 'new_task';
  String _selectedPriority = 'low';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<String> _selectedEmployees = [];

  final List<Map<String, String>> _statusOptions = [
    {'value': 'wait_confirm', 'label': 'Chờ xác nhận'},
    {'value': 'in_progress', 'label': 'Đang thực hiện'},
    {'value': 'done', 'label': 'Hoàn thành'},
    {'value': 'pause', 'label': 'Tạm dừng'},
    {'value': 'new_task', 'label': 'Công việc mới'},
    {'value': 'overdue', 'label': 'Quá hạn'},
  ];

  final List<Map<String, String>> _priorityOptions = [
    {'value': 'high', 'label': 'Cao'},
    {'value': 'normal', 'label': 'Bình thường'},
    {'value': 'low', 'label': 'Thấp'},
    // {'value': 'urgent', 'label': 'Khẩn cấp'},
  ];

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());

    _taskNameController = TextEditingController();
    _taskIdController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final tasktypeProvider =
        Provider.of<TasktypeProvider>(context, listen: false);
    final employeeProvider =
        Provider.of<EmployeeProvider>(context, listen: false);

    final token = authProvider.token;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await Future.wait([
        projectProvider.getAllProject(token: token),
        tasktypeProvider.getAllTaskType(token: token),
        employeeProvider.getAllEmployee(token: token),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple.shade400,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showEmployeeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<EmployeeProvider>(
          builder: (context, employeeProvider, _) {
            final employees = employeeProvider.employees;

            List<String> tempSelected = List.from(_selectedEmployees);

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text(
                    'Chọn nhân viên tham gia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: employees.isEmpty
                        ? const Center(
                            child: Text('Không có nhân viên nào'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: employees.length,
                            itemBuilder: (context, index) {
                              final employee = employees[index];
                              final isSelected =
                                  tempSelected.contains(employee.employeeId);

                              return CheckboxListTile(
                                title: Text(
                                  employee.employeeName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  employee.employeeId,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                value: isSelected,
                                activeColor: Colors.purple.shade400,
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      tempSelected.add(employee.employeeId);
                                    } else {
                                      tempSelected.remove(employee.employeeId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Hủy',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedEmployees = tempSelected;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B59B6),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Xác nhận'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn dự án')),
      );
      return;
    }

    if (_selectedTasktypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại công việc')),
      );
      return;
    }

    if (_selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một nhân viên')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    final token = authProvider.token;
    final currentEmployeeId = authProvider.currentEmployee?.employeeId;

    if (token == null || currentEmployeeId == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phiên đăng nhập hết hạn')),
        );
      }
      return;
    }

    try {
      final newTask = TaskModel(
        taskId: _taskIdController.text.trim(),
        taskName: _taskNameController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        priority: _selectedPriority,
        status: TaskStatus.fromString(_selectedStatus),
        projectId: _selectedProject!.projectId,
        tasktypeId: _selectedTasktypeId!,
        assignedTo: _selectedEmployees,
      );

      final success = await taskProvider.createTask(newTask, token);

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // resizeToAvoidBottomInset: false,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Tạo công việc',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),

                    // Body - Scrollable
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                        },
                        behavior: HitTestBehavior.translucent,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dự án
                              _buildLabel('Dự án: *'),
                              const SizedBox(height: 8),
                              _buildProjectDropdown(),
                              const SizedBox(height: 16),

                              // Mã dự án (read-only)
                              _buildLabel('Mã dự án:'),
                              const SizedBox(height: 8),
                              _buildReadOnlyField(
                                _selectedProject?.projectId ??
                                    'Chọn dự án trước',
                              ),
                              const SizedBox(height: 16),

                              // Tên công việc
                              _buildLabel('Tên công việc: *'),
                              const SizedBox(height: 8),
                              _buildEditableField(
                                controller: _taskNameController,
                                hint: 'Nhập tên công việc',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập tên công việc';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Mã công việc
                              _buildLabel('Mã công việc: *'),
                              const SizedBox(height: 8),
                              _buildEditableField(
                                controller: _taskIdController,
                                hint: 'Nhập mã công việc',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Vui lòng nhập mã công việc';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Row: Trạng thái + Loại công việc
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Trạng thái: *'),
                                        const SizedBox(height: 8),
                                        _buildDropdownField(
                                          selectedValue: _selectedStatus,
                                          options: _statusOptions,
                                          onChanged: (newValue) {
                                            setState(() {
                                              _selectedStatus = newValue;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Loại CV: *'),
                                        const SizedBox(height: 8),
                                        _buildTasktypeDropdown(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Độ ưu tiên
                              _buildLabel('Độ ưu tiên: *'),
                              const SizedBox(height: 8),
                              _buildDropdownField(
                                selectedValue: _selectedPriority,
                                options: _priorityOptions,
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedPriority = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Row: Ngày bắt đầu + Ngày kết thúc
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Ngày bắt đầu: *'),
                                        const SizedBox(height: 8),
                                        _buildDateField(
                                          DateFormat('dd/MM/yyyy')
                                              .format(_startDate),
                                          color: Colors.blue.shade500,
                                          onTap: () =>
                                              _selectDate(context, true),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Ngày kết thúc:'),
                                        const SizedBox(height: 8),
                                        _buildDateField(
                                          _endDate != null
                                              ? DateFormat('dd/MM/yyyy')
                                                  .format(_endDate!)
                                              : 'Chọn ngày',
                                          color: _endDate != null
                                              ? Colors.red.shade500
                                              : Colors.black38,
                                          onTap: () =>
                                              _selectDate(context, false),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Nhân viên tham gia (Mới thêm)
                              _buildLabel('Nhân viên tham gia: *'),
                              const SizedBox(height: 8),
                              _buildEmployeeSelectionField(),
                              const SizedBox(height: 16),

                              // Nội dung công việc
                              _buildLabel('Nội dung công việc:'),
                              const SizedBox(height: 8),
                              _buildMultilineField(),

                              // Thêm spacing để nút không bị che bởi bàn phím
                              const SizedBox(height: 24),

                              // Nút Lưu - Đặt ở CUỐI form, TRONG ScrollView
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveTask,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9B59B6),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                    disabledBackgroundColor:
                                        Colors.grey.shade300,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Lưu công việc',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
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
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildReadOnlyField(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.purple[300]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildProjectDropdown() {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, _) {
        final projects = projectProvider.projects;

        if (projects.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Không có dự án nào',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<ProjectModel>(
              value: _selectedProject,
              hint: const Text('Chọn dự án'),
              isExpanded: true,
              iconStyleData: IconStyleData(
                icon: Icon(Icons.keyboard_arrow_down,
                    color: Colors.grey.shade700),
              ),
              buttonStyleData: ButtonStyleData(
                height: 50,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black54),
                  color: Colors.grey.shade200,
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 250,
                offset: const Offset(0, 6),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  color: Colors.grey.shade200,
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(height: 48),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              items: projects.map((project) {
                return DropdownMenuItem<ProjectModel>(
                  value: project,
                  child: Text(
                    project.projectName,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (ProjectModel? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedProject = newValue;
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasktypeDropdown() {
    return Consumer<TasktypeProvider>(
      builder: (context, tasktypeProvider, _) {
        final tasktypes = tasktypeProvider.tasktypes;

        if (tasktypes.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Không có loại CV',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              value: _selectedTasktypeId,
              hint: const Text('Chọn loại'),
              isExpanded: true,
              iconStyleData: IconStyleData(
                icon: Icon(Icons.keyboard_arrow_down,
                    color: Colors.grey.shade700),
              ),
              buttonStyleData: ButtonStyleData(
                height: 50,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black54),
                  color: Colors.grey.shade200,
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 200,
                offset: const Offset(0, 6),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  color: Colors.grey.shade200,
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(height: 48),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              items: tasktypes.map((tasktype) {
                return DropdownMenuItem<String>(
                  value: tasktype.tasktypeId,
                  child: Text(
                    tasktype.tasktypeName,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTasktypeId = newValue;
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownField({
    required String selectedValue,
    required List<Map<String, String>> options,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: double.infinity,
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          value: selectedValue,
          isExpanded: true,
          iconStyleData: IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700),
          ),
          buttonStyleData: ButtonStyleData(
            height: 50,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black54),
              color: Colors.grey.shade200,
            ),
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 200,
            offset: const Offset(0, 6),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              color: Colors.grey.shade200,
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(height: 48),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateField(String text,
      {Color color = Colors.black54, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black54),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeSelectionField() {
    return Consumer<EmployeeProvider>(
      builder: (context, employeeProvider, _) {
        final employees = employeeProvider.employees;

        String displayText;
        if (_selectedEmployees.isEmpty) {
          displayText = 'Chọn nhân viên';
        } else if (_selectedEmployees.length == 1) {
          final employee = employees.firstWhere(
            (e) => e.employeeId == _selectedEmployees[0],
            orElse: () => employees.first,
          );
          displayText = employee.employeeName;
        } else {
          displayText = '${_selectedEmployees.length} nhân viên được chọn';
        }

        return GestureDetector(
          onTap: _showEmployeeSelectionDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black54),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedEmployees.isEmpty
                          ? Colors.black38
                          : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.people,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMultilineField() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 5,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
          hintText: 'Nhập nội dung công việc...',
          hintStyle: TextStyle(
            color: Colors.black38,
          ),
        ),
      ),
    );
  }
}
