import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';
import 'package:task_team_frontend_mobile/providers/task_provider.dart';
import 'package:task_team_frontend_mobile/providers/project_provider.dart';

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
      final projectProvider = context.read<ProjectProvider>();

      final token = authProvider.token;
      if (token != null && token.isNotEmpty) {
        projectProvider.getAllProject(token: token).then((_) {
          taskProvider.getAllTask(token: token);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final projectProvider =
        Provider.of<ProjectProvider>(context, listen: false);
    final token = context.read<AuthProvider>().token ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
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
                          if (token.isNotEmpty) {
                            taskProvider.getAllTask(token: token);
                          }
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : taskProvider.tasks.isEmpty
                  ? const Center(child: Text('Không có công việc nào'))
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mã: ${task.taskId}'),
                                Text(
                                    'Mô tả: ${task.description ?? 'Không có'}'),
                                const SizedBox(height: 4),
                                FutureBuilder<String>(
                                  future: projectProvider.getProjectNameById(
                                    task.projectId,
                                    token,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text(
                                        'Đang tải tên dự án...',
                                        style: TextStyle(color: Colors.grey),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Text(
                                        'Lỗi khi lấy tên dự án',
                                        style:
                                            const TextStyle(color: Colors.red),
                                      );
                                    } else {
                                      return Text(
                                        'Dự án: ${snapshot.data ?? 'Không xác định'}',
                                        style: const TextStyle(
                                          color: Colors.blueAccent,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                          ),
                        );
                      },
                    ),
    );
  }
}
