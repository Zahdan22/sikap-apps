import 'package:flutter/material.dart';
import '../services/schedule_service.dart';
import '../services/user_service.dart';
import 'manage_jamkerja_screen.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  List<dynamic> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  void _loadSchedule() async {
    setState(() => _isLoading = true);
    final data = await ScheduleService().getAllSchedule();
    setState(() {
      _schedules = data;
      _isLoading = false;
    });
  }

  void _hapusJadwal(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: const Text('Yakin ingin menghapus jadwal ini? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ScheduleService().deleteSchedule(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );
    _loadSchedule();
  }

 void _bukaFormTambah() async {
  final crewList = await UserService().getAllCrew();

  if (!mounted) return;

  if (crewList.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Belum ada karyawan, tambahkan dulu di menu Karyawan')),
    );
    return;
  }

  int? selectedUserId = crewList[0]['id'];
  final tanggalController = TextEditingController();
  final jamMulaiController = TextEditingController();
  final jamSelesaiController = TextEditingController();
  final durasiController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tambah Jadwal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: selectedUserId,
              decoration: const InputDecoration(labelText: 'Karyawan', border: OutlineInputBorder()),
              items: crewList
                  .map<DropdownMenuItem<int>>(
                    (c) => DropdownMenuItem(value: c['id'], child: Text(c['nama'])),
                  )
                  .toList(),
              onChanged: (value) => setModalState(() => selectedUserId = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tanggalController,
              decoration: const InputDecoration(
                labelText: 'Tanggal (YYYY-MM-DD)',
                hintText: 'contoh: 2026-08-25',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: jamMulaiController,
              decoration: const InputDecoration(
                labelText: 'Jam Mulai (HH:MM)',
                hintText: 'contoh: 15:00',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: jamSelesaiController,
              decoration: const InputDecoration(
                labelText: 'Jam Selesai (HH:MM)',
                hintText: 'contoh: 21:00',
                border: OutlineInputBorder(),
              ),
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
                final result = await ScheduleService().createSchedule(
                  userId: selectedUserId ?? 0,
                  tanggal: tanggalController.text,
                  jamMulai: jamMulaiController.text,
                  jamSelesai: jamSelesaiController.text,
                  durasiJam: double.tryParse(durasiController.text) ?? 0,
                );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'])),
                );
                _loadSchedule();
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
        appBar: AppBar(
          title: const Text('Kelola Jadwal'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Opsi Jam Kerja',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageJamKerjaScreen()),
                );
              },
            ),
          ],
        ),      
        floatingActionButton: FloatingActionButton(
        onPressed: _bukaFormTambah,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? const Center(child: Text('Belum ada jadwal'))
              : RefreshIndicator(
                  onRefresh: () async => _loadSchedule(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) {
                      final s = _schedules[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.blue),
                          title: Text('${s['nama']} - ${s['tanggal']}'),
                          subtitle: Text('${s['jam_mulai']} - ${s['jam_selesai']} (${s['durasi_jam']} jam)'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _hapusJadwal(s['id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}