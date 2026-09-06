import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../theme/app_colors.dart';

class MyHistoryScreen extends StatefulWidget {
  final bool embedded;
  const MyHistoryScreen({super.key, this.embedded = false});

  @override
  State<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends State<MyHistoryScreen> {
  int _bulan = DateTime.now().month;
  int _tahun = DateTime.now().year;
  Map<String, dynamic> _summary = {};
  List<dynamic> _detail = [];
  bool _isLoading = true;

  final List<String> _namaBulan = const [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    setState(() => _isLoading = true);
    final data = await ReportService().getMyReport(_bulan, _tahun);
    setState(() {
      _summary = data['summary'] ?? {};
      _detail = data['detail'] ?? [];
      _isLoading = false;
    });
  }

  String _fmtJam(String? datetime) {
    if (datetime == null) return '-';
    try {
      final parts = datetime.split(' ');
      return parts.length > 1 ? parts[1].substring(0, 5) : datetime.substring(0, 5);
    } catch (_) {
      return '-';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'telat':
      case 'lewat_batas':
        return AppColors.danger;
      case 'lebih_awal':
        return AppColors.warning;
      case 'tepat_waktu':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'telat':
        return 'TERLAMBAT';
      case 'tepat_waktu':
        return 'TEPAT WAKTU';
      case 'lebih_awal':
        return 'LEBIH AWAL';
      case 'lewat_batas':
        return 'LEWAT BATAS';
      case 'belum_absen':
      case null:
        return 'BELUM ABSEN';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalJam = _summary['total_menit_kerja'] != null
        ? (int.tryParse(_summary['total_menit_kerja'].toString()) ?? 0) ~/ 60
        : 0;
    final totalHadir = _summary['total_hari_masuk'] ?? 0;
    final totalTelat = _summary['total_telat'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Absensi'), automaticallyImplyLeading: !widget.embedded),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _bulan,
                      decoration: const InputDecoration(labelText: 'Bulan', border: OutlineInputBorder()),
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(value: m, child: Text(_namaBulan[m - 1])))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _bulan = value!);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _tahun,
                      decoration: const InputDecoration(labelText: 'Tahun', border: OutlineInputBorder()),
                      items: [_tahun - 1, _tahun, _tahun + 1]
                          .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _tahun = value!);
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _RingkasanItem(label: 'Total Jam', value: '$totalJam Jam'),
                        _RingkasanItem(label: 'Kehadiran', value: '$totalHadir Hari'),
                        _RingkasanItem(label: 'Terlambat', value: '$totalTelat Kali'),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _detail.isEmpty
                      ? const Center(child: Text('Belum ada riwayat untuk periode ini'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _detail.length,
                          itemBuilder: (context, index) {
                            final d = _detail[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(d['tanggal'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Wrap(
                                          spacing: 4,
                                          children: [
                                            Chip(
                                              label: Text(
                                                'Masuk: ${_statusLabel(d['status_masuk'])}',
                                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                              ),
                                              backgroundColor: _statusColor(d['status_masuk']),
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            if (d['jam_pulang_aktual'] != null)
                                              Chip(
                                                label: Text(
                                                  'Pulang: ${_statusLabel(d['status_pulang'])}',
                                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                                ),
                                                backgroundColor: _statusColor(d['status_pulang']),
                                                padding: EdgeInsets.zero,
                                                visualDensity: VisualDensity.compact,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Jadwal: ${d['jadwal_jam_mulai'].toString().substring(0, 5)} - ${d['jadwal_jam_selesai'].toString().substring(0, 5)}'),
                                    Text('Absen: ${_fmtJam(d['jam_masuk_aktual'])} - ${_fmtJam(d['jam_pulang_aktual'])}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingkasanItem extends StatelessWidget {
  final String label;
  final String value;
  const _RingkasanItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}