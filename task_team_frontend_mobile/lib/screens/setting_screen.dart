import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/screens/activitylog_screen.dart';
import 'package:task_team_frontend_mobile/screens/login_screen.dart';
import 'package:task_team_frontend_mobile/screens/profile_screen.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final path = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '${ApiConfig.getUrl}/$path';
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  void _navigateToProfile() {
    final authProvider = context.read<AuthProvider>();
    final employee = authProvider.currentEmployee;
    final token = authProvider.token;

    if (employee != null && token != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            token: token,
            employeeId: employee.employeeId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final employee = authProvider.currentEmployee;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cài đặt',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Thông tin người dùng
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.purple[100],
                    child: ClipOval(
                      child: employee?.image != null &&
                              employee!.image!.isNotEmpty
                          ? Image.network(
                              _getFullImageUrl(employee.image),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  employee.employeeName.isNotEmpty
                                      ? employee.employeeName[0].toUpperCase()
                                      : '',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple),
                                );
                              },
                            )
                          : Text(
                              employee?.employeeName.isNotEmpty == true
                                  ? employee!.employeeName[0].toUpperCase()
                                  : '',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee?.employeeName ?? 'Người dùng',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          employee?.employeeId ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Các tùy chọn cài đặt + nút đăng xuất
            Expanded(
              child: ListView(
                children: [
                  _buildSettingItem(
                    icon: Icons.person_outline,
                    title: 'Thông tin cá nhân',
                    subtitle: 'Xem và chỉnh sửa thông tin',
                    onTap: _navigateToProfile,
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.lock_outline,
                    title: 'Đổi mật khẩu',
                    subtitle: 'Thay đổi mật khẩu của bạn',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Chức năng đang phát triển')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.notifications_outlined,
                    title: 'Thông báo',
                    subtitle: 'Quản lý thông báo',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Chức năng đang phát triển')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.language_outlined,
                    title: 'Ngôn ngữ',
                    subtitle: 'Tiếng Việt',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Chức năng đang phát triển')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.history,
                    title: 'Nhật ký hoạt động',
                    subtitle: 'Xem lịch sử hoạt động của bạn',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivityLogScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.help_outline,
                    title: 'Trợ giúp & Hỗ trợ',
                    subtitle: 'Câu hỏi thường gặp',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Chức năng đang phát triển')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingItem(
                    icon: Icons.info_outline,
                    title: 'Về ứng dụng',
                    subtitle: 'Phiên bản 1.0.0',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Chức năng đang phát triển')),
                      );
                    },
                  ),

                  // Nút đăng xuất
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF5DADE2).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF5DADE2),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
