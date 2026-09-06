import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'role_selection_screen.dart';
import 'weekly_schedule_screen.dart';
import 'manage_leave_screen.dart';
import 'report_screen.dart';
import 'manage_crew_screen.dart';
import 'manage_swap_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  String _nama = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final prefs = await AuthService().getPrefs();
    setState(() {
      _nama = prefs.getString('nama') ?? '';
    });
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirm != true) return;

    await AuthService().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, $_nama'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.primary,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.storefront, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Panel Manajer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Kelola operasional kedai dari sini', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Operasional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.calendar_month,
              label: 'Kelola Jadwal',
              subtitle: 'Atur jadwal & jobdesk karyawan',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyScheduleScreen())),
            ),
            _MenuTile(
              icon: Icons.swap_horiz,
              label: 'Tukar Shift',
              subtitle: 'Setujui pengajuan tukar shift',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSwapScreen())),
            ),
            _MenuTile(
              icon: Icons.fact_check,
              label: 'Pengajuan Izin',
              subtitle: 'Setujui atau tolak izin karyawan',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageLeaveScreen())),
            ),
            const SizedBox(height: 20),
            const Text('Laporan & Karyawan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.bar_chart,
              label: 'Laporan',
              subtitle: 'Rekap kehadiran & export Excel',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen())),
            ),
            _MenuTile(
              icon: Icons.people,
              label: 'Karyawan',
              subtitle: 'Tambah atau hapus akun crew',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageCrewScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }
}