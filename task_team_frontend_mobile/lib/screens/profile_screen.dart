import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/providers/employee_provider.dart';
import 'package:task_team_frontend_mobile/models/employee_model.dart';
import 'package:task_team_frontend_mobile/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;
  final String employeeId;

  const ProfileScreen({
    super.key,
    required this.token,
    required this.employeeId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  EmployeeModel? _employee;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    final provider = Provider.of<EmployeeProvider>(context, listen: false);
    await provider.getEmployeeById(widget.employeeId, widget.token);

    if (provider.employees.isNotEmpty) {
      setState(() {
        _employee = provider.employees.first;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
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
          'HỒ SƠ',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () async {
              if (_employee != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      token: widget.token,
                      employee: _employee!,
                    ),
                  ),
                );
                // Reload data if update was successful
                if (result == true) {
                  _loadEmployeeData();
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employee == null
              ? const Center(child: Text('Không tìm thấy thông tin nhân viên'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.purple[300],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        _employee!.employeeName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Employee ID
                      _buildInfoField(
                        label: 'Mã nhân viên:',
                        value: _employee!.employeeId,
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      _buildInfoField(
                        label: 'Số điện thoại:',
                        value: _employee!.phone,
                      ),
                      const SizedBox(height: 16),

                      // Address (placeholder - not in model)
                      _buildInfoField(
                        label: 'Địa chỉ:',
                        value: _employee!.address ?? 'Chưa cập nhật',
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _buildInfoField(
                        label: 'Email:',
                        value: _employee!.email,
                      ),
                      const SizedBox(height: 16),

                      // Date of birth (placeholder - not in model)
                      _buildInfoField(
                        label: 'Ngày sinh:',
                        value: _employee!.birth != null
                            ? '${_employee!.birth!.day}/${_employee!.birth!.month}/${_employee!.birth!.year}'
                            : 'Chưa cập nhật',
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoField({required String label, required String value}) {
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
