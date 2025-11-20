import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/task_model.dart';
import '../../models/project_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/tasktype_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/employee_provider.dart';

class ManagerDetailTaskScreen extends StatefulWidget {
  final TaskModel task;

  const ManagerDetailTaskScreen({
    super.key,
    required this.task,
  });

  @override
  State<ManagerDetailTaskScreen> createState() =>
      _ManagerDetailTaskScreenState();
}

class _ManagerDetailTaskScreenState extends State<ManagerDetailTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _taskNameController;
  late TextEditingController _taskIdController;
  late TextEditingController _descriptionController;

  // Selected values
  ProjectModel? _selectedProject;
  String? _selectedTasktypeId;
  late String _selectedStatus;
  late String _selectedPriority;
  late DateTime _startDate;
  DateTime? _endDate;
  List<String> _selectedEmployees = [];

  // Files
  List<File> _selectedFiles = [];
  TaskModel? _currentTask;

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
  ];

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() => _loadData());

    _taskNameController = TextEditingController(text: widget.task.taskName);
    _taskIdController = TextEditingController(text: widget.task.taskId);
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _selectedStatus = widget.task.status.value;
    _selectedPriority = widget.task.priority;
    _startDate = widget.task.startDate;
    _endDate = widget.task.endDate;
    _selectedEmployees = List.from(widget.task.assignedTo);
    _selectedTasktypeId = widget.task.tasktypeId;
    _currentTask = widget.task;
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

      // Set selected project
      final projects = projectProvider.projects;
      _selectedProject = projects.firstWhere(
        (p) => p.projectId == widget.task.projectId,
        orElse: () =>
            projects.isNotEmpty ? projects.first : null as ProjectModel,
      );
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
                        backgroundColor:
                            const Color.fromARGB(255, 107, 202, 88),
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

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'pdf',
          'doc',
          'docx',
          'xlsx',
          'xls',
          'txt',
        ],
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.paths.map((path) => File(path!)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chọn tệp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeSelectedFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _deleteAttachment(String attachmentId, String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa tệp "$fileName"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) throw Exception('Token không tồn tại');

      final provider = Provider.of<TaskProvider>(context, listen: false);
      final success = await provider.deleteAttachment(
        taskId: widget.task.taskId,
        attachmentId: attachmentId,
        token: token,
      );

      if (success) {
        await provider.getTaskById(widget.task.taskId, token);
        setState(() {
          _currentTask = provider.tasks.first;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Xóa tệp thành công'),
              backgroundColor: Colors.green),
        );
      } else {
        _showError(provider.error);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message ?? 'Lỗi không xác định'),
          backgroundColor: Colors.red),
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

    if (token == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phiên đăng nhập hết hạn')),
        );
      }
      return;
    }

    try {
      TaskModel updatedTask = widget.task.copyWith(
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

      Map<String, dynamic> taskData = updatedTask.toJson();
      taskData.removeWhere((key, value) => value == null);

      final success = await taskProvider.updateTask(
        taskId: widget.task.taskId,
        token: token,
        taskData: taskData,
        files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_selectedFiles.isNotEmpty
                  ? 'Cập nhật thông tin và tải lên ${_selectedFiles.length} tệp thành công'
                  : 'Cập nhật thông tin thành công'),
              backgroundColor: Colors.green,
            ),
          );
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
                              'Chi tiết công việc',
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
                                        _buildLabel('Loại công việc: *'),
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

                              // Nhân viên tham gia
                              _buildLabel('Nhân viên tham gia: *'),
                              const SizedBox(height: 8),
                              _buildEmployeeSelectionField(),
                              const SizedBox(height: 16),

                              // Nội dung công việc
                              _buildLabel('Nội dung công việc:'),
                              const SizedBox(height: 8),
                              _buildMultilineField(),
                              const SizedBox(height: 16),

                              // Tệp đính kèm
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildLabel('Tệp đính kèm:'),
                                  TextButton.icon(
                                    onPressed: _pickFiles,
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Thêm tệp',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Hiển thị files đã chọn (chưa upload)
                              if (_selectedFiles.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tệp mới (chưa lưu):',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...List.generate(_selectedFiles.length,
                                          (index) {
                                        final file = _selectedFiles[index];
                                        final fileName =
                                            file.path.split('/').last;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.insert_drive_file,
                                                  size: 16,
                                                  color: Colors.blue),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  fileName,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    size: 18),
                                                color: Colors.red,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () =>
                                                    _removeSelectedFile(index),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),
                              _buildAttachmentSection(),
                              const SizedBox(height: 24),

                              // Nút Hủy và Lưu
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        side: const BorderSide(
                                          color: Colors.grey,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Hủy',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _saveTask,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255, 89, 182, 109),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        disabledBackgroundColor:
                                            Colors.grey.shade300,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Lưu công việc',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
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
              'Không có loại công việc',
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

  Widget _buildAttachmentSection() {
    if (_currentTask!.attachments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Chưa có tệp đính kèm',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black45,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          _currentTask!.attachments.length,
          (index) {
            final attachment = _currentTask!.attachments[index];
            return Column(
              children: [
                if (index > 0) const Divider(height: 24),
                _buildAttachmentItem(
                  attachment.fileName,
                  attachment.attachmentId ?? '',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(String fileName, String attachmentId) {
    return Row(
      children: [
        const Icon(Icons.attach_file, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            fileName,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          color: Colors.red,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => _deleteAttachment(attachmentId, fileName),
        ),
      ],
    );
  }
}
