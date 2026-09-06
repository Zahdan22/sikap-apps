import 'package:flutter/material.dart';
import '../services/leave_service.dart';
import '../theme/app_colors.dart';

class MyLeaveScreen extends StatefulWidget {
  const MyLeaveScreen({super.key});

  @override
  State<MyLeaveScreen> createState() => _MyLeaveScreenState();
}

class _MyLeaveScreenState extends State<MyLeaveScreen> {
  List<dynamic> _leaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeave();
  }

  void _loadLeave() async {
    setState(() => _isLoading = true);
    final data = await LeaveService().getMyLeave();
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

  void _bukaFormAjukan() {
    String jenis = 'sakit';
    DateTime? tanggalMulai;
    DateTime? tanggalSelesai;
    final alasanController = TextEditingController();

    String fmt(DateTime? d) => d == null ? 'Pilih tanggal' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.edit_note, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text('Ajukan Izin', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: jenis,
                decoration: const InputDecoration(labelText: 'Jenis Izin', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                  DropdownMenuItem(value: 'keperluan_pribadi', child: Text('Keperluan Pribadi')),
                ],
                onChanged: (value) => setModalState(() => jenis = value!),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text('Mulai: ${fmt(tanggalMulai)}'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46), alignment: Alignment.centerLeft),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setModalState(() => tanggalMulai = picked);
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text('Selesai: ${fmt(tanggalSelesai)}'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46), alignment: Alignment.centerLeft),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setModalState(() => tanggalSelesai = picked);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alasanController,
                decoration: const InputDecoration(labelText: 'Alasan', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (tanggalMulai == null || tanggalSelesai == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lengkapi tanggal mulai dan selesai')),
                      );
                      return;
                    }
                    final result = await LeaveService().ajukanIzin(
                      jenis: jenis,
                      tanggalMulai: fmt(tanggalMulai),
                      tanggalSelesai: fmt(tanggalSelesai),
                      alasan: alasanController.text,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                    _loadLeave();
                  },
                  child: const Text('Ajukan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Izin Saya')),
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaFormAjukan,
        child: const Icon(Icons.add),
      ),
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
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l['jenis'] == 'sakit' ? 'Sakit' : 'Keperluan Pribadi',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text('${l['tanggal_mulai']} s/d ${l['tanggal_selesai']}', style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                                if (l['alasan'] != null && l['alasan'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('"${l['alasan']}"', style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
                                ],
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