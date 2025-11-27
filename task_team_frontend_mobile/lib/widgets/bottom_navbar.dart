import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_team_frontend_mobile/screens/manager/add_task_screen.dart';
import 'package:task_team_frontend_mobile/screens/manager/list_screen.dart';
import 'package:task_team_frontend_mobile/screens/manager/manager_chart_screen.dart';
import 'package:task_team_frontend_mobile/screens/manager/manager_home_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/all_task_screen.dart';
import '../screens/chart_screen.dart';
import '../screens/home_screen.dart';
import '../screens/setting_screen.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int _selectedScreenIndex = 0;

  final Map<String, RoleNavConfig> _roleConfigs = {
    'manager': RoleNavConfig(
      widgets: const [
        ManagerHomeScreen(),
        ManagerChartScreen(),
        ListScreen(),
        SettingScreen(),
      ],
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Biểu đồ'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Danh sách'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      hasFloatingButton: true,
      floatingButtonIndex: null,
    ),
    'admin': RoleNavConfig(
      widgets: const [
        ManagerHomeScreen(),
        ManagerChartScreen(),
        ListScreen(),
        SettingScreen(),
      ],
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Biểu đồ'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Danh sách'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      hasFloatingButton: true,
      floatingButtonIndex: null,
    ),
    'staff': RoleNavConfig(
      widgets: const [
        HomeScreen(),
        AllTaskScreen(),
        ChartScreen(),
        SettingScreen(),
      ],
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Công việc'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Biểu đồ'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      hasFloatingButton: false,
    ),
  };

  RoleNavConfig _getNavConfig(String? roleId) {
    String? searchKey = roleId;

    if (searchKey == null || searchKey.isEmpty) {
      return _roleConfigs['staff']!;
    }

    final normalizedRole = searchKey.trim().toLowerCase();

    if (_roleConfigs.containsKey(normalizedRole)) {
      return _roleConfigs[normalizedRole]!;
    }

    for (var entry in _roleConfigs.entries) {
      if (entry.key.toLowerCase() == normalizedRole) {
        return entry.value;
      }
    }

    return _roleConfigs['staff']!;
  }

  void _onPageTapped(int index, RoleNavConfig config) {
    setState(() {
      _selectedScreenIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final roleId = authProvider.currentEmployee?.roleId;
    final config = _getNavConfig(roleId);

    if (_selectedScreenIndex >= config.widgets.length) {
      _selectedScreenIndex = 0;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: config.widgets[_selectedScreenIndex],
      // Wrap BottomNavigationBar và FAB trong một Builder để cô lập khỏi SnackBar
      bottomNavigationBar: Builder(
        builder: (context) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Bottom Navigation Bar
              _buildBottomNav(config),

              // FAB positioned above the bottom bar
              if (config.hasFloatingButton)
                Positioned(
                  bottom: 75, // Vị trí để FAB nổi lên trên BottomAppBar
                  child: _buildFloatingButton(config),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(RoleNavConfig config) {
    if (config.hasFloatingButton) {
      return BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(config.items.length, (index) {
              if (index == config.floatingButtonIndex) {
                return const SizedBox(width: 48);
              }

              final item = config.items[index];
              final isSelected = _selectedScreenIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => _onPageTapped(index, config),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        (item.icon as Icon).icon,
                        color:
                            isSelected ? const Color(0xFF5DADE2) : Colors.grey,
                        size: 24,
                      ),
                      if (item.label != null && item.label!.isNotEmpty)
                        Text(
                          item.label!,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF5DADE2)
                                : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      );
    }

    // Navbar thông thường cho staff
    return BottomNavigationBar(
      currentIndex: _selectedScreenIndex,
      onTap: (index) => _onPageTapped(index, config),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF5DADE2),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: config.items,
    );
  }

  Widget _buildFloatingButton(RoleNavConfig config) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AddTaskScreen(),
          ),
        );
      },
      backgroundColor: const Color(0xFF5DADE2),
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 32, color: Colors.white),
    );
  }
}

// Class config cho từng role
class RoleNavConfig {
  final List<Widget> widgets;
  final List<BottomNavigationBarItem> items;
  final bool hasFloatingButton;
  final int? floatingButtonIndex;

  RoleNavConfig({
    required this.widgets,
    required this.items,
    this.hasFloatingButton = false,
    this.floatingButtonIndex,
  });
}
