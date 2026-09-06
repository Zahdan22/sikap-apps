import 'package:flutter/material.dart';
import '../services/swap_service.dart';
import '../theme/app_colors.dart';

class ManageSwapScreen extends StatefulWidget {
  const ManageSwapScreen({super.key});

  @override
  State<ManageSwapScreen> createState() => _ManageSwapScreenState();
}

class _ManageSwapScreenState extends State<ManageSwapScreen> {
  List<dynamic> _swapList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSwap();
  }

  void _loadSwap() async {
    setState(() => _isLoading = true);
    final data = await SwapService().getAllSwap();
    setState(() {
      _swapList = data;
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

  void _prosesSwap(int id, String status) async {
    final result = await SwapService().updateStatus(id, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    _loadSwap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Tukar Shift')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _swapList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text('Belum ada pengajuan tukar shift', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _loadSwap(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _swapList.length,
                      itemBuilder: (context, index) {
                        final s = _swapList[index];
                        final isPending = s['status'] == 'pending';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(child: Text(s['requester_nama'], style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 6),
                                            child: Icon(Icons.swap_horiz, size: 16, color: AppColors.primary),
                                          ),
                                          Flexible(child: Text(s['target_nama'], style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(s['status']),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _statusLabel(s['status']),
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text('Tanggal: ${s['tanggal']}', style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                                if (s['alasan'] != null && s['alasan'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('"${s['alasan']}"', style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
                                ],
                                if (isPending)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _prosesSwap(s['id'], 'ditolak'),
                                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                                            child: const Text('Tolak'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _prosesSwap(s['id'], 'disetujui'),
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