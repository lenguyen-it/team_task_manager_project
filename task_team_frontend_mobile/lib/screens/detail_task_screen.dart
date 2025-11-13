import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';

import 'package:task_team_frontend_mobile/models/task_model.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/project_provider.dart';
import 'package:task_team_frontend_mobile/providers/task_provider.dart';
import 'package:task_team_frontend_mobile/providers/tasktype_provider.dart';
import 'package:intl/intl.dart';

class DetailTaskScreen extends StatefulWidget {
  final TaskModel task;
  const DetailTaskScreen({
    super.key,
    required this.task,
  });

  @override
  State<DetailTaskScreen> createState() => _DetailTaskScreenState();
}

class _DetailTaskScreenState extends State<DetailTaskScreen> {
  String? projectName;
  String? tasktypeName;

  TaskModel? _currentTask;

  // Controllers và state cho chỉnh sửa
  late TextEditingController _descriptionController;

  late String _selectedStatus;

  bool _isLoading = false;

  // Danh sách files được chọn
  List<File> _selectedFiles = [];

  // Danh sách trạng thái
  final List<Map<String, String>> _statusOptions = [
    {'value': 'wait', 'label': 'Chờ xác nhận'},
    {'value': 'in_progress', 'label': 'Đang thực hiện'},
    {'value': 'done', 'label': 'Hoàn thành'},
    {'value': 'pause', 'label': 'Tạm dừng'},
    {'value': 'new_task', 'label': 'Công việc mới'},
    {'value': 'overdue', 'label': 'Quá hạn'},
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _selectedStatus = widget.task.status.value;
    _currentTask = widget.task;
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final tasktypeProvider =
        Provider.of<TasktypeProvider>(context, listen: false);

    if (authProvider.token != null) {
      // Lấy tên dự án
      final pName = await projectProvider.getProjectNameById(
        widget.task.projectId,
        authProvider.token!,
      );
      // Lấy tên loại công việc
      final tName =
          tasktypeProvider.getTasktypeNameById(widget.task.tasktypeId);

      setState(() {
        projectName = pName;
        tasktypeName = tName;
      });
    }
  }

  String _getStatusText(String status) {
    return _statusOptions.firstWhere(
      (s) => s['value'] == status,
      orElse: () => {'value': status, 'label': status},
    )['label']!;
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return priority;
    }
  }

  // Chọn files để upload
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

  // Xóa file khỏi danh sách đã chọn
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

    setState(() {
      _isLoading = true;
    });

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
        // Reload task từ server
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message ?? 'Lỗi không xác định'),
          backgroundColor: Colors.red),
    );
  }

  void _handleSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Không tìm thấy token. Vui lòng đăng nhập lại.');
      }

      final provider = Provider.of<TaskProvider>(context, listen: false);

      // Tạo taskData chỉ với những field cần update
      Map<String, dynamic> taskData = {
        'status': _selectedStatus,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      };

      // Gọi updateTask với named parameters
      final success = await provider.updateTask(
        taskId: widget.task.taskId,
        token: token,
        taskData: taskData,
        files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedFiles.isNotEmpty
                ? 'Cập nhật thông tin và tải lên ${_selectedFiles.length} tệp thành công'
                : 'Cập nhật thông tin thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Quay lại và báo thành công
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Cập nhật thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: $e'),
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
          'Chi tiết công việc',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dự án
              _buildLabel('Dự án:'),
              const SizedBox(height: 8),
              _buildReadOnlyField(projectName ?? 'Đang tải...'),
              const SizedBox(height: 16),

              // Công việc
              _buildLabel('Công việc:'),
              const SizedBox(height: 8),
              _buildReadOnlyField(widget.task.taskName),
              const SizedBox(height: 16),

              _buildLabel('Mã công việc:'),
              const SizedBox(height: 8),
              _buildReadOnlyField(widget.task.taskId),
              const SizedBox(height: 16),

              // Độ ưu tiên và Loại công việc
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Độ ưu tiên:'),
                        const SizedBox(height: 8),
                        _buildReadOnlyField(
                          _getPriorityText(widget.task.priority),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Loại công việc:'),
                        const SizedBox(height: 8),
                        _buildReadOnlyField(tasktypeName ?? 'Đang tải...'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ngày bắt đầu và Ngày kết thúc
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Ngày bắt đầu:'),
                        const SizedBox(height: 8),
                        _buildDateField(
                          DateFormat('dd/MM/yyyy')
                              .format(widget.task.startDate),
                          color: Colors.blue.shade500,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Ngày kết thúc:'),
                        const SizedBox(height: 8),
                        _buildDateField(
                          widget.task.endDate != null
                              ? DateFormat('dd/MM/yyyy')
                                  .format(widget.task.endDate!)
                              : 'N/A',
                          color: Colors.red.shade500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Trạng thái - EDITABLE
              _buildLabel('Trạng thái:'),
              const SizedBox(height: 8),
              _buildDropdownField(),
              const SizedBox(height: 16),

              // Nội dung công việc - EDITABLE
              _buildLabel('Nội dung công việc:'),
              const SizedBox(height: 8),
              _buildMultilineField(),
              const SizedBox(height: 16),

              // Tệp đính kèm
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      ...List.generate(_selectedFiles.length, (index) {
                        final file = _selectedFiles[index];
                        final fileName = file.path.split('/').last;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fileName,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: Colors.red,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _removeSelectedFile(index),
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
              const SizedBox(height: 32),

              // Nút Hủy và Lưu
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Colors.grey,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),
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
                              'Lưu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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

  Widget _buildDropdownField() {
    return SizedBox(
      width: double.infinity,
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          value: _selectedStatus,
          isExpanded: true,
          iconStyleData: IconStyleData(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey.shade700,
            ),
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
          menuItemStyleData: const MenuItemStyleData(
            height: 48,
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          items: _statusOptions.map((status) {
            return DropdownMenuItem<String>(
              value: status['value'],
              child: Text(status['label']!),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedStatus = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDateField(String text, {Color color = Colors.black54}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMultilineField() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.black54),
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
    // Kiểm tra xem task có attachments không
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
          widget.task.attachments.length,
          (index) {
            final attachment = widget.task.attachments[index];
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
