import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:task_team_frontend_mobile/providers/activitylog_provider.dart';
import 'package:task_team_frontend_mobile/providers/auth_provider.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadActivityLogs());
  }

  void _loadActivityLogs() {
    final authProvider = context.read<AuthProvider>();
    final activityProvider = context.read<ActivitylogProvider>();

    if (authProvider.token != null) {
      activityProvider.refresh(
        authProvider.token!,
        roleId: authProvider.currentEmployee?.roleId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        centerTitle: true,
      ),
      body: Consumer<ActivitylogProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadActivityLogs,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.activityLogs.isEmpty) {
            return const Center(
              child: Text('No activity logs found'),
            );
          }

          return Column(
            children: [
              // Pagination Controls - ở trên cùng
              _buildPaginationBar(context, provider),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () {
                    final authProvider = context.read<AuthProvider>();
                    return authProvider.token != null
                        ? context.read<ActivitylogProvider>().refresh(
                              authProvider.token!,
                              roleId: authProvider.currentEmployee?.roleId,
                            )
                        : Future.value();
                  },
                  child: ListView.builder(
                    itemCount: provider.activityLogs.length,
                    itemBuilder: (context, index) {
                      final log = provider.activityLogs[index];
                      final formattedDate =
                          DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timestamp ở trên cùng
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Action và Status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      log.action.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: log.status == 'success'
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      log.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: log.status == 'success'
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Employee ID
                              Text(
                                'Employee ID: ${log.employeeId}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              // Target
                              if (log.targetType != null)
                                Text(
                                  'Target: ${log.targetType} (${log.targetId})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              // Description
                              if (log.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Description: ${log.description}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaginationBar(
      BuildContext context, ActivitylogProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          ElevatedButton.icon(
            onPressed: provider.currentPage > 1
                ? () {
                    final authProvider = context.read<AuthProvider>();
                    context.read<ActivitylogProvider>().previousPage(
                          authProvider.token!,
                          roleId: authProvider.currentEmployee?.roleId,
                        );
                  }
                : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
          ),
          // Page Info
          Column(
            children: [
              Text(
                'Page ${provider.currentPage} of ${provider.totalPages}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Total: ${provider.totalLogs} logs',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          // Next Button
          ElevatedButton.icon(
            onPressed: provider.currentPage < provider.totalPages
                ? () {
                    final authProvider = context.read<AuthProvider>();
                    context.read<ActivitylogProvider>().nextPage(
                          authProvider.token!,
                          roleId: authProvider.currentEmployee?.roleId,
                        );
                  }
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
