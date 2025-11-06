import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/task_provider.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final authProvider = context.read<AuthProvider>();
      final taskProvider = context.read<TaskProvider>();

      final token = authProvider.token;
      if (token != null && token.isNotEmpty) {
        taskProvider.getAllTask(token: token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách vai trò'),
      ),
      body: taskProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : taskProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lỗi: ${taskProvider.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final token = context.read<AuthProvider>().token;
                          if (token != null) {
                            context
                                .read<TaskProvider>()
                                .getAllTask(token: token);
                          }
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : taskProvider.tasks.isEmpty
                  ? const Center(child: Text('Không có vai trò nào'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: taskProvider.tasks.length,
                      itemBuilder: (context, index) {
                        final task = taskProvider.tasks[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              task.taskName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Mã: ${task.taskId}\nMô tả: ${task.description ?? 'Không có'}',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // TODO: Xem chi tiết / chỉnh sửa role
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
