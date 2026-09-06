import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class ManageCrewScreen extends StatefulWidget {
  const ManageCrewScreen({super.key});

  @override
  State<ManageCrewScreen> createState() => _ManageCrewScreenState();
}

class _ManageCrewScreenState extends State<ManageCrewScreen> {
  List<dynamic> _crewList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCrew();
  }

  void _loadCrew() async {
    setState(() => _isLoading = true);
    final data = await UserService().getAllCrew();
    setState(() {
      _crewList = data;
      _isLoading = false;
    });
  }

  void _hapusKaryawan(int id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Karyawan'),
        content: Text('Yakin ingin menghapus akun "$nama"? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await UserService().deleteCrew(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );
    _loadCrew();
  }

  void _bukaFormTambah() {
    final namaController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.person_add, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text('Tambah Karyawan Baru', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (namaController.text.isEmpty ||
                      usernameController.text.isEmpty ||
                      passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Semua field wajib diisi')),
                    );
                    return;
                  }
                  final result = await AuthService().register(
                    usernameController.text,
                    namaController.text,
                    passwordController.text,
                    'crew',
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'])),
                  );
                  _loadCrew();
                },
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Karyawan')),
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaFormTambah,
        child: const Icon(Icons.person_add),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _crewList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        const Text('Belum ada karyawan', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => _loadCrew(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _crewList.length,
                      itemBuilder: (context, index) {
                        final c = _crewList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                c['nama'].toString().substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(c['nama'], style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('@${c['username']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                              onPressed: () => _hapusKaryawan(c['id'], c['nama']),
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