import 'package:flutter/material.dart';
import 'crew_dashboard_tab.dart';
import 'my_history_screen.dart';
import 'my_schedule_screen.dart';
import '../theme/app_colors.dart';

class CrewHomeScreen extends StatefulWidget {
  const CrewHomeScreen({super.key});

  @override
  State<CrewHomeScreen> createState() => _CrewHomeScreenState();
}

class _CrewHomeScreenState extends State<CrewHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CrewDashboardTab(),
    MyHistoryScreen(embedded: true),
    MyScheduleScreen(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Jadwal'),
        ],
      ),
    );
  }
}