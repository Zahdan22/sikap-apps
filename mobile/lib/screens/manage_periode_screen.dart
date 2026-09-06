import 'package:flutter/material.dart';
import '../services/periode_service.dart';
import '../theme/app_colors.dart';

class ManagePeriodeScreen extends StatefulWidget {
  const ManagePeriodeScreen({super.key});

  @override
  State<ManagePeriodeScreen> createState() => _ManagePeriodeScreenState();
}

class _ManagePeriodeScreenState extends State<ManagePeriodeScreen> {
  List<dynamic> _periodeList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    setState(() => _isLoading = true);
    final data = await PeriodeService().getAll();
    setState(() {
      _periodeList = data;
      _isLoading = false;
    });
  }

  void _hapus(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Periode'),
        content: const Text('Yakin ingin menghapus periode ini? Laporan yang terkait tidak akan bisa diakses lagi lewat periode ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await PeriodeService().delete(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    _load();
  }

  void _bukaFormTambah() {
    final namaController = TextEditingController();
    DateTime? tanggalMulai;
    DateTime? tanggalSelesai;

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
              const Text('Tambah Periode Kerja', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Periode',
                  hintText: 'contoh: GC Agustus',
                  border: OutlineInputBorder(),
                ),
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
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
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
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setModalState(() => tanggalSelesai = picked);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (namaController.text.isEmpty || tanggalMulai == null || tanggalSelesai == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lengkapi semua field')),
                      );
                      return;
                    }
                    final result = await PeriodeService().create(
                      namaController.text,
                      fmt(tanggalMulai),
                      fmt(tanggalSelesai),
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
                    _load();
                  },
                  child: const Text('Simpan'),
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
      appBar: AppBar(title: const Text('Kelola Periode Kerja')),
      floatingActionButton: FloatingActionButton(onPressed: _bukaFormTambah, child: const Icon(Icons.add)),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _periodeList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.date_range_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text('Belum ada periode kerja', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _periodeList.length,
                    itemBuilder: (context, index) {
                      final p = _periodeList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.date_range, color: AppColors.primary),
                          ),
                          title: Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${p['tanggal_mulai']} s/d ${p['tanggal_selesai']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () => _hapus(p['id']),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}