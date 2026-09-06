import 'package:flutter/material.dart';
import '../services/swap_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';

class MySwapScreen extends StatefulWidget {
  const MySwapScreen({super.key});

  @override
  State<MySwapScreen> createState() => _MySwapScreenState();
}

class _MySwapScreenState extends State<MySwapScreen> {
  List<dynamic> _swapList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSwap();
  }

  void _loadSwap() async {
    setState(() => _isLoading = true);
    final data = await SwapService().getMySwap();
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

  void _bukaFormAjukan() async {
    final crewList = await UserService().getCrewListSimple();
    if (!mounted) return;

    if (crewList.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada rekan kerja lain untuk tukar shift')),
      );
      return;
    }

    DateTime? selectedDate;
    int? selectedTargetId;
    final alasanController = TextEditingController();

    String fmtDate(DateTime? d) => d == null ? 'Pilih tanggal' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
                    child: const Icon(Icons.swap_horiz, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text('Ajukan Tukar Shift', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(fmtDate(selectedDate)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46), alignment: Alignment.centerLeft),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) setModalState(() => selectedDate = picked);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedTargetId,
                decoration: const InputDecoration(labelText: 'Tukar dengan', border: OutlineInputBorder()),
                items: crewList
                    .map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c['id'], child: Text(c['nama'])))
                    .toList(),
                onChanged: (value) => setModalState(() => selectedTargetId = value),
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
                    if (selectedDate == null || selectedTargetId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lengkapi tanggal dan pilih rekan kerja')),
                      );
                      return;
                    }
                    final result = await SwapService().ajukanSwap(
                      fmtDate(selectedDate),
                      selectedTargetId!,
                      alasanController.text,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
                    _loadSwap();
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
      appBar: AppBar(title: const Text('Tukar Shift')),
      floatingActionButton: FloatingActionButton(onPressed: _bukaFormAjukan, child: const Icon(Icons.swap_horiz)),
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