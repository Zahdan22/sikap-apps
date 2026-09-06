import 'package:flutter/material.dart';
import '../services/jamkerja_service.dart';

class ManageJamKerjaScreen extends StatefulWidget {
  const ManageJamKerjaScreen({super.key});

  @override
  State<ManageJamKerjaScreen> createState() => _ManageJamKerjaScreenState();
}

class _ManageJamKerjaScreenState extends State<ManageJamKerjaScreen> {
  List<dynamic> _opsiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    setState(() => _isLoading = true);
    final data = await JamKerjaService().getAll();
    setState(() {
      _opsiList = data;
      _isLoading = false;
    });
  }

  void _hapus(int id) async {
    final result = await JamKerjaService().delete(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    _load();
  }

  void _bukaFormTambah() {
    final labelController = TextEditingController();
    TimeOfDay? jamMulai;
    TimeOfDay? jamSelesai;
    final durasiController = TextEditingController();

    String fmt(TimeOfDay? t) => t == null ? 'Pilih jam' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tambah Opsi Jam Kerja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Nama (contoh: Opening)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(fmt(jamMulai)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setModalState(() => jamMulai = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('s/d'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(fmt(jamSelesai)),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) setModalState(() => jamSelesai = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durasiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Durasi (jam)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (labelController.text.isEmpty || jamMulai == null || jamSelesai == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lengkapi semua field')),
                    );
                    return;
                  }
                  final result = await JamKerjaService().create(
                    labelController.text,
                    fmt(jamMulai),
                    fmt(jamSelesai),
                    double.tryParse(durasiController.text) ?? 0,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
                  _load();
                },
                child: const Text('Simpan'),
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
      appBar: AppBar(title: const Text('Opsi Jam Kerja')),
      floatingActionButton: FloatingActionButton(onPressed: _bukaFormTambah, child: const Icon(Icons.add)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _opsiList.isEmpty
              ? const Center(child: Text('Belum ada opsi jam kerja'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _opsiList.length,
                  itemBuilder: (context, index) {
                    final o = _opsiList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(o['label']),
                        subtitle: Text('${o['jam_mulai'].toString().substring(0,5)} - ${o['jam_selesai'].toString().substring(0,5)} (${o['durasi_jam']} jam)'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _hapus(o['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}