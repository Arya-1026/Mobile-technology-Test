import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'permission_screen.dart';
import 'admin_dashboard_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int index = 0;
  bool? isAdmin;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final result = await AuthService.isAdmin();
    if (mounted) {
      setState(() => isAdmin = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isAdmin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      const HomeScreen(),
      const SearchScreen(),
      if (isAdmin!) const AdminDashboardScreen(showAppBarLogout: false),
      if (!isAdmin!) const PermissionScreen(),
      const ProfileScreen(),
    ];

    final navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Нүүр',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Хайх'),
      if (isAdmin!)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          label: 'Админ',
        ),
      if (!isAdmin!)
        const BottomNavigationBarItem(
          icon: Icon(Icons.verified_user_outlined),
          label: 'Эрх',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Профайл',
      ),
    ];

    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFF5C400),
        unselectedItemColor: Colors.grey,
        onTap: (value) => setState(() => index = value),
        items: navItems,
      ),
    );
  }
}
