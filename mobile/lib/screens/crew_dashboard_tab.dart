import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../services/report_service.dart';
import '../theme/app_colors.dart';
import 'role_selection_screen.dart';
import 'attendance_screen.dart';
import 'my_leave_screen.dart';
import 'my_swap_screen.dart';

class CrewDashboardTab extends StatefulWidget {
  const CrewDashboardTab({super.key});

  @override
  State<CrewDashboardTab> createState() => _CrewDashboardTabState();
}

class _CrewDashboardTabState extends State<CrewDashboardTab> {
  String _nama = '';
  Map<String, dynamic> _todayStatus = {};
  Map<String, dynamic> _monthSummary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final status = await AttendanceService().getTodayStatus();
    final now = DateTime.now();
    final report = await ReportService().getMyReport(now.month, now.year);
    setState(() {
      _nama = prefs.getString('nama') ?? '';
      _todayStatus = status;
      _monthSummary = report['summary'] ?? {};
      _isLoading = false;
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
    final adaJadwal = _todayStatus['ada_jadwal'] == true;
    final sudahMasuk = _todayStatus['sudah_masuk'] == true;
    final sudahPulang = _todayStatus['sudah_pulang'] == true;

    final totalJam = _monthSummary['total_menit_kerja'] != null
        ? (int.tryParse(_monthSummary['total_menit_kerja'].toString()) ?? 0) ~/ 60
        : 0;
    final totalHadir = _monthSummary['total_hari_masuk'] ?? 0;
    final totalTelat = _monthSummary['total_telat'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, $_nama'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadAll(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Kartu status hari ini
                  Card(
                    color: AppColors.primary,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Status Hari Ini', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              if (adaJadwal && !sudahMasuk)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('ACTION REQUIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            !adaJadwal
                                ? 'Tidak Ada Jadwal'
                                : sudahPulang
                                    ? 'Selesai Bekerja'
                                    : sudahMasuk
                                        ? 'Sudah Absen Masuk'
                                        : 'Belum Absen',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (adaJadwal) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Jadwal: ${_todayStatus['jam_mulai'].toString().substring(0, 5)} - ${_todayStatus['jam_selesai'].toString().substring(0, 5)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (adaJadwal)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: sudahMasuk
                                        ? null
                                        : () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const AttendanceScreen(isMasuk: true)),
                                            );
                                            _loadAll();
                                          },
                                    icon: const Icon(Icons.login, color: Colors.white),
                                    label: const Text('CHECK-IN', style: TextStyle(color: Colors.white)),
                                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: (!sudahMasuk || sudahPulang)
                                        ? null
                                        : () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const AttendanceScreen(isMasuk: false)),
                                            );
                                            _loadAll();
                                          },
                                    icon: const Icon(Icons.logout, color: Colors.white),
                                    label: const Text('CHECK-OUT', style: TextStyle(color: Colors.white)),
                                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Ringkasan bulan ini
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bulan Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(label: 'Total Hours', value: '${totalJam}h'),
                              _StatItem(label: 'Days Present', value: '$totalHadir'),
                              _StatItem(label: 'Late Arrivals', value: '$totalTelat'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Menu tambahan
                  Row(
                    children: [
                      Expanded(
                        child: _QuickMenu(
                          icon: Icons.edit_note,
                          label: 'Ajukan Izin',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyLeaveScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickMenu(
                          icon: Icons.swap_horiz,
                          label: 'Tukar Shift',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MySwapScreen())),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}

class _QuickMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickMenu({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}