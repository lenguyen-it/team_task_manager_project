import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/providers/project_provider.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/employee_provider.dart';
import 'package:task_team_frontend_mobile/screens/manager/add_project_screen.dart';
import 'package:task_team_frontend_mobile/screens/manager/detail_project_screen.dart';

import '../../models/employee_model.dart';

class ListProjectScreen extends StatefulWidget {
  const ListProjectScreen({super.key});

  @override
  State<ListProjectScreen> createState() => _ListProjectScreenState();
}

class _ListProjectScreenState extends State<ListProjectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      if (token != null) {
        // Load dự án
        Provider.of<ProjectProvider>(context, listen: false)
            .getAllProject(token: token);

        // Load danh sách nhân viên để tra tên quản lý
        final employeeProvider =
            Provider.of<EmployeeProvider>(context, listen: false);
        if (employeeProvider.employees.isEmpty) {
          employeeProvider.getAllEmployee(token: token);
        }
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa xác định';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'planning':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return 'Hoàn thành';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'planning':
        return 'Lập kế hoạch';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _getManagerName(String managerId, List<EmployeeModel> employees) {
    if (managerId.isEmpty) return 'Không xác định';
    final employee = employees.firstWhere(
      (e) => e.employeeId == managerId,
      orElse: () => EmployeeModel(
        employeeId: '',
        employeeName: 'Không tìm thấy',
        employeePassword: '',
        email: '',
        phone: '',
        roleId: '',
      ),
    );
    return employee.employeeName;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Dự án'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_photos),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProjectScreen(
                    token: token!,
                  ),
                ),
              );

              if (result == true && mounted) {
                final projectProvider =
                    Provider.of<ProjectProvider>(context, listen: false);
                projectProvider.getAllProject(token: token!);
              }
            },
          ),
        ],
      ),
      body: Consumer2<ProjectProvider, EmployeeProvider>(
        builder: (context, projectProvider, employeeProvider, child) {
          // Load nhân viên nếu chưa có
          if (employeeProvider.employees.isEmpty &&
              !employeeProvider.isLoading) {
            final token =
                Provider.of<AuthProvider>(context, listen: false).token;
            if (token != null) {
              employeeProvider.getAllEmployee(token: token);
            }
          }

          if (projectProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (projectProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Lỗi tải dự án', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(projectProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => projectProvider.refresh(context),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (projectProvider.projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Chưa có dự án nào',
                      style: TextStyle(fontSize: 18)),
                  const Text('Dự án mới sẽ xuất hiện tại đây'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final token =
                  Provider.of<AuthProvider>(context, listen: false).token;
              if (token != null) {
                await Future.wait([
                  projectProvider.refresh(context),
                  employeeProvider.refresh(token),
                ]);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: projectProvider.projects.length,
              itemBuilder: (context, index) {
                final project = projectProvider.projects[index];
                final managerName = _getManagerName(
                    project.projectManagerId, employeeProvider.employees);

                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailProjectScreen(
                            token: Provider.of<AuthProvider>(context,
                                    listen: false)
                                .token!,
                            projectId: project.projectId,
                          ),
                        ),
                      );
                      if (result == true) {
                        final token =
                            Provider.of<AuthProvider>(context, listen: false)
                                .token;
                        if (token != null) {
                          Provider.of<ProjectProvider>(context, listen: false)
                              .getAllProject(token: token);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên dự án
                          Text(
                            project.projectName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                          const SizedBox(height: 12),

                          // Người quản lý
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blueGrey),
                              const SizedBox(width: 8),
                              Text(
                                'Quản lý: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700),
                              ),
                              Expanded(
                                child: employeeProvider.isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : Text(
                                        managerName,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Thời gian
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.blueGrey),
                              const SizedBox(width: 8),
                              Text(
                                'Thời gian: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700),
                              ),
                              Text(
                                '${_formatDate(project.startDate)} - ${_formatDate(project.endDate)}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Trạng thái
                          Row(
                            children: [
                              const Icon(Icons.flag, color: Colors.blueGrey),
                              const SizedBox(width: 8),
                              Text(
                                'Trạng thái: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700),
                              ),
                              Chip(
                                label: Text(
                                  _getStatusText(project.status),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                                backgroundColor:
                                    _getStatusColor(project.status),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
