import 'package:flutter/material.dart';
import '../services/leave_service.dart';
import '../theme/app_colors.dart';

class ManageLeaveScreen extends StatefulWidget {
  const ManageLeaveScreen({super.key});

  @override
  State<ManageLeaveScreen> createState() => _ManageLeaveScreenState();
}

class _ManageLeaveScreenState extends State<ManageLeaveScreen> {
  List<dynamic> _leaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeave();
  }

  void _loadLeave() async {
    setState(() => _isLoading = true);
    final data = await LeaveService().getAllLeave();
    setState(() {
      _leaves = data;
      _isLoading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'disetujui':
        return AppColors.success;
      case 'ditolak':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      default:
        return 'Menunggu';
    }
  }

  void _prosesIzin(int id, String status) async {
    final result = await LeaveService().updateStatus(id, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );
    _loadLeave();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Izin')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _leaves.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text('Belum ada pengajuan izin', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _loadLeave(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _leaves.length,
                      itemBuilder: (context, index) {
                        final l = _leaves[index];
                        final isPending = l['status'] == 'pending';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        l['nama'].toString().substring(0, 1).toUpperCase(),
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(l['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(l['status']),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _statusLabel(l['status']),
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l['jenis'] == 'sakit' ? 'Sakit' : 'Keperluan Pribadi',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text('${l['tanggal_mulai']} s/d ${l['tanggal_selesai']}', style: const TextStyle(fontSize: 13)),
                                if (l['alasan'] != null && l['alasan'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('"${l['alasan']}"', style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
                                ],
                                if (isPending)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _prosesIzin(l['id'], 'ditolak'),
                                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                                            child: const Text('Tolak'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _prosesIzin(l['id'], 'disetujui'),
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                            child: const Text('Setujui'),
                                          ),
                                        ),
                                      ],
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
    );
  }
}