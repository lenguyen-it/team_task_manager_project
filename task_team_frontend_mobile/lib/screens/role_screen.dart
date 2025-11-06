import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/providers/role_provider.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final authProvider = context.read<AuthProvider>();
      final roleProvider = context.read<RoleProvider>();

      final token = authProvider.token;
      if (token != null && token.isNotEmpty) {
        roleProvider.getAllRole(token: token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách vai trò'),
      ),
      body: roleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : roleProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lỗi: ${roleProvider.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final token = context.read<AuthProvider>().token;
                          if (token != null) {
                            context
                                .read<RoleProvider>()
                                .getAllRole(token: token);
                          }
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : roleProvider.roles.isEmpty
                  ? const Center(child: Text('Không có vai trò nào'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: roleProvider.roles.length,
                      itemBuilder: (context, index) {
                        final role = roleProvider.roles[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              role.roleName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Mã: ${role.roleId}\nMô tả: ${role.description ?? 'Không có'}',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // TODO: Xem chi tiết / chỉnh sửa role
                            },
                          ),
                        );
                      },
                    ),
      floatingActionButton: Provider.of<AuthProvider>(context)
              .hasPermission(['R01']) // Ví dụ: chỉ Admin mới thêm role
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Mở form tạo role mới
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
