import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/models/employee_model.dart';
import 'package:task_team_frontend_mobile/models/project_model.dart';
import 'package:task_team_frontend_mobile/providers/employee_provider.dart';
import 'package:task_team_frontend_mobile/providers/project_provider.dart';

class DetailProjectScreen extends StatefulWidget {
  final String token;
  final String projectId;

  const DetailProjectScreen({
    super.key,
    required this.token,
    required this.projectId,
  });

  @override
  State<DetailProjectScreen> createState() => _DetailProjectScreenState();
}

class _DetailProjectScreenState extends State<DetailProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _projectIdController;
  late TextEditingController _projectNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  ProjectModel? _project;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedManagerId;
  String _selectedStatus = 'planning';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Map<String, String>> _statusOptions = [
    {'value': 'planning', 'label': 'Lập kế hoạch'},
    {'value': 'in_progress', 'label': 'Đang thực hiện'},
    {'value': 'done', 'label': 'Hoàn thành'},
    {'value': 'cancelled', 'label': 'Đã hủy'},
  ];

  @override
  void initState() {
    super.initState();
    _projectIdController = TextEditingController();
    _projectNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjectData();
      // Load nhân viên nếu chưa có
      final employeeProvider =
          Provider.of<EmployeeProvider>(context, listen: false);
      if (employeeProvider.employees.isEmpty) {
        employeeProvider.getAllEmployee(token: widget.token);
      }
    });
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    _projectNameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<ProjectProvider>(context, listen: false);

    // Tìm project trong danh sách hiện có trước
    final existingProject = provider.projects.firstWhere(
      (p) => p.projectId == widget.projectId,
      orElse: () => ProjectModel(
        projectId: '',
        projectName: '',
        projectManagerId: '',
        status: 'planning',
      ),
    );

    if (existingProject.projectId.isNotEmpty) {
      setState(() {
        _project = existingProject;
        _populateFields();
        _isLoading = false;
      });
    } else {
      await provider.getProjectById(widget.projectId, widget.token);

      if (!mounted) return;

      if (provider.projects.isNotEmpty) {
        setState(() {
          _project = provider.projects.first;
          _populateFields();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _populateFields() {
    if (_project == null) return;

    _projectIdController.text = _project!.projectId;
    _projectNameController.text = _project!.projectName;
    _descriptionController.text = _project!.description ?? '';
    _selectedManagerId = _project!.projectManagerId;
    _selectedStatus = _project!.status;
    _startDate = _project!.startDate;
    _endDate = _project!.endDate;

    _startDateController.text =
        DateFormat('dd/MM/yyyy').format(_project!.startDate);
    if (_project!.endDate != null) {
      _endDateController.text =
          DateFormat('dd/MM/yyyy').format(_project!.endDate!);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
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
          _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          // Reset end date nếu nó trước start date
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
            _endDateController.clear();
          }
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedManagerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn người quản lý'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày bắt đầu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProject = ProjectModel(
        id: _project!.id,
        projectId: _projectIdController.text.trim(),
        projectName: _projectNameController.text.trim(),
        projectManagerId: _selectedManagerId!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate,
        status: _selectedStatus,
      );

      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      final success = await projectProvider.updateProject(
        widget.projectId,
        updatedProject,
        widget.token,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật dự án thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(projectProvider.error ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa dự án "${_project?.projectName}"?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      final success = await projectProvider.deleteProject(
        widget.projectId,
        widget.token,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa dự án thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(projectProvider.error ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chỉnh sửa dự án',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _project == null
              ? const Center(child: Text('Không tìm thấy thông tin dự án'))
              : GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mã dự án (không cho sửa)
                          _buildTextField(
                            controller: _projectIdController,
                            label: 'Mã dự án',
                            icon: Icons.tag,
                            enabled: false,
                          ),
                          const SizedBox(height: 16),

                          // Tên dự án
                          _buildTextField(
                            controller: _projectNameController,
                            label: 'Tên dự án',
                            icon: Icons.work,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập tên dự án';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Người quản lý
                          Consumer<EmployeeProvider>(
                            builder: (context, employeeProvider, child) {
                              if (employeeProvider.isLoading) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (employeeProvider.employees.isEmpty) {
                                return const Text(
                                    'Không có nhân viên nào để chọn');
                              }

                              // Đảm bảo value luôn hợp lệ
                              final String? currentValue = _selectedManagerId !=
                                          null &&
                                      employeeProvider.employees.any((e) =>
                                          e.employeeId == _selectedManagerId)
                                  ? _selectedManagerId
                                  : null;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Người quản lý',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey[400]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: currentValue,
                                        hint: const Text('Chọn người quản lý'),
                                        items:
                                            employeeProvider.employees.map((e) {
                                          return DropdownMenuItem<String>(
                                            value: e.employeeId,
                                            child: Text(
                                                '${e.employeeName} (${e.employeeId})'),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedManagerId = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Ngày bắt đầu
                          _buildTextField(
                            controller: _startDateController,
                            label: 'Ngày bắt đầu',
                            icon: Icons.calendar_today,
                            readOnly: true,
                            onTap: () => _selectDate(context, true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng chọn ngày bắt đầu';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Ngày kết thúc
                          _buildTextField(
                            controller: _endDateController,
                            label: 'Ngày kết thúc (tùy chọn)',
                            icon: Icons.event,
                            readOnly: true,
                            onTap: () => _selectDate(context, false),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  _startDate != null &&
                                  _endDate != null &&
                                  _endDate!.isBefore(_startDate!)) {
                                return 'Ngày kết thúc phải sau ngày bắt đầu';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Trạng thái
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Trạng thái',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _selectedStatus,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    items: _statusOptions.map((status) {
                                      return DropdownMenuItem<String>(
                                        value: status['value'],
                                        child: Row(
                                          children: [
                                            const Icon(Icons.flag,
                                                size: 20, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(status['label']!),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedStatus = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Mô tả
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mô tả',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'Nhập mô tả dự án...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[400]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[400]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Colors.blue, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Nút Lưu
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Lưu thay đổi',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
