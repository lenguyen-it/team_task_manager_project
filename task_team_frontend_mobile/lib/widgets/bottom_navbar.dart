import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/calendar_screen.dart';
import '../screens/chart_screen.dart';
import '../screens/home_screen.dart';
import '../screens/role_screen.dart';
import '../screens/setting_screen.dart';
import '../screens/task_screen.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int _selectedScreenIndex = 0;

  // Config cho từng role - hoàn toàn độc lập
  final Map<String, RoleNavConfig> _roleConfigs = {
    'manager': RoleNavConfig(
      widgets: const [
        HomeScreen(),
        CalendarScreen(), Center(child: Text('Add Task Screen')), // Placeholder
        Center(child: Text('Detail Screen')), // Placeholder
        SettingScreen(),
      ],
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Calendar'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 40), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Danh sách'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      hasFloatingButton: true,
      floatingButtonIndex: 2,
    ),
    'staff': RoleNavConfig(
      widgets: const [
        HomeScreen(),
        CalendarScreen(), // Placeholder
        ChartScreen(), // Placeholder
        SettingScreen(),
      ],
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Calendar'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Biểu đồ'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      hasFloatingButton: false,
    ),
    'admin': RoleNavConfig(
      widgets: const [
        HomeScreen(),
        // RoleScreen(),
        // EmployeeScreen(),
        TaskScreen(),
        // Center(child: Text('Admin Dashboard')), // Placeholder
        Center(child: Text('Calendar Screen')), // Placeholder
        SettingScreen(),
      ],
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: 'Calendar'),
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
      body: config.widgets[_selectedScreenIndex],
      bottomNavigationBar: _buildBottomNav(config),
      floatingActionButton:
          config.hasFloatingButton ? _buildFloatingButton(config) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                            fontSize: 11,
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

    // Navbar thông thường
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
      onPressed: () => _onPageTapped(config.floatingButtonIndex!, config),
      backgroundColor: const Color(0xFF5DADE2),
      elevation: 4,
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
