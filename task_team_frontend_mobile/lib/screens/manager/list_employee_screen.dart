import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/config/api_config.dart';
import 'package:task_team_frontend_mobile/models/role_model.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/employee_provider.dart';
import 'package:task_team_frontend_mobile/providers/role_provider.dart';
import 'package:task_team_frontend_mobile/screens/manager/add_employee_screen.dart';
import 'package:task_team_frontend_mobile/screens/manager/detail_employee_screen.dart';

class ListEmployeeScreen extends StatefulWidget {
  const ListEmployeeScreen({super.key});

  @override
  State<ListEmployeeScreen> createState() => _ListEmployeeScreenState();
}

class _ListEmployeeScreenState extends State<ListEmployeeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      if (token != null) {
        final employeeProvider =
            Provider.of<EmployeeProvider>(context, listen: false);
        final roleProvider = Provider.of<RoleProvider>(context, listen: false);

        if (employeeProvider.employees.isEmpty) {
          employeeProvider.getAllEmployee(token: token);
        }
        if (roleProvider.roles.isEmpty) {
          roleProvider.getAllRole(token: token);
        }
      }
    });
  }

  // Lấy tên role từ roleId
  String getRoleName(String roleId, List<RoleModel> roles) {
    if (roleId.isEmpty) return 'Chưa xác định';
    try {
      final role = roles.firstWhere((r) => r.roleId == roleId);
      return role.roleName;
    } catch (e) {
      return 'Không tìm thấy';
    }
  }

  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final path = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '${ApiConfig.getUrl}/$path';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Nhân viên'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_photos),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEmployeeScreen(token: token!),
                ),
              );

              if (result == true && mounted) {
                final employeeProvider =
                    Provider.of<EmployeeProvider>(context, listen: false);
                await employeeProvider.getAllEmployee(token: token!);
              }
            },
          ),
        ],
      ),
      body: Consumer2<EmployeeProvider, RoleProvider>(
        builder: (context, employeeProvider, roleProvider, child) {
          // Tự động load nếu chưa có dữ liệu
          if (employeeProvider.employees.isEmpty &&
              !employeeProvider.isLoading) {
            final token =
                Provider.of<AuthProvider>(context, listen: false).token;
            if (token != null) {
              employeeProvider.getAllEmployee(token: token);
            }
          }

          if (employeeProvider.isLoading || roleProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (employeeProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Lỗi tải dữ liệu', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(employeeProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final token =
                          Provider.of<AuthProvider>(context, listen: false)
                              .token;
                      if (token != null) {
                        employeeProvider.getAllEmployee(token: token);
                        roleProvider.getAllRole(token: token);
                      }
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (employeeProvider.employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_alt_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Chưa có nhân viên nào',
                      style: TextStyle(fontSize: 18)),
                  const Text('Danh sách sẽ được cập nhật khi có nhân viên mới'),
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
                  employeeProvider.getAllEmployee(token: token),
                  roleProvider.getAllRole(token: token),
                ]);
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: employeeProvider.employees.length,
              itemBuilder: (context, index) {
                final employee = employeeProvider.employees[index];
                final roleName =
                    getRoleName(employee.roleId, roleProvider.roles);
                final avatarUrl = _getFullImageUrl(employee.image);

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                      backgroundImage:
                          avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty
                          ? Text(
                              employee.employeeName.isNotEmpty
                                  ? employee.employeeName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      employee.employeeName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.badge,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('Mã NV: ${employee.employeeId}',
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.work,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'Vai trò: $roleName',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: roleName.contains('Không tìm thấy')
                                    ? Colors.red
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailEmployeeScreen(
                            token: token!,
                            employeeId: employee.employeeId,
                          ),
                        ),
                      );
                    },
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
