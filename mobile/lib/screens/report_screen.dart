import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../services/report_service.dart';
import '../services/periode_service.dart';
import '../theme/app_colors.dart';
import 'manage_periode_screen.dart';
import 'report_detail_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _bulan = DateTime.now().month;
  int _tahun = DateTime.now().year;
  List<dynamic> _summary = [];
  List<dynamic> _detail = [];
  bool _isLoading = true;
  bool _isDownloading = false;

  List<dynamic> _periodeList = [];
  int? _selectedPeriodeId;
  bool _modePeriode = false;

  final List<String> _namaBulan = const [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _loadReport();
    _loadPeriode();
  }

  void _loadPeriode() async {
    final data = await PeriodeService().getAll();
    setState(() => _periodeList = data);
  }

  void _loadReport() async {
    setState(() => _isLoading = true);
    final data = await ReportService().getMonthlyReport(_bulan, _tahun);
    setState(() {
      _summary = data['summary'] ?? [];
      _detail = data['detail'] ?? [];
      _isLoading = false;
    });
  }

  void _loadReportByPeriode() async {
    if (_selectedPeriodeId == null) return;
    setState(() => _isLoading = true);
    final data = await PeriodeService().getReportByPeriode(_selectedPeriodeId!);
    setState(() {
      _summary = data['summary'] ?? [];
      _detail = data['detail'] ?? [];
      _isLoading = false;
    });
  }

  void _bukaExcel() async {
    setState(() => _isDownloading = true);

    final result = await ReportService().downloadMonthlyExcel(_bulan, _tahun);

    setState(() => _isDownloading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Laporan berhasil diunduh: ${result['fileName']}')),
      );
      await OpenFile.open(result['path']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Bulan Kalender'),
                      selected: !_modePeriode,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: !_modePeriode ? Colors.white : Colors.black87),
                      onSelected: (_) {
                        setState(() => _modePeriode = false);
                        _loadReport();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Periode Kerja'),
                      selected: _modePeriode,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: _modePeriode ? Colors.white : Colors.black87),
                      onSelected: (_) => setState(() => _modePeriode = true),
                    ),
                  ),
                ],
              ),
            ),
            if (!_modePeriode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          _loadReport();
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
                          _loadReport();
                        },
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedPeriodeId,
                        decoration: const InputDecoration(labelText: 'Pilih Periode', border: OutlineInputBorder()),
                        items: _periodeList
                            .map<DropdownMenuItem<int>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['nama'])))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedPeriodeId = value);
                          _loadReportByPeriode();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: AppColors.primary),
                      tooltip: 'Kelola Periode',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManagePeriodeScreen()),
                        ).then((_) => _loadPeriode());
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isDownloading ? null : _bukaExcel,
                  icon: _isDownloading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.file_download),
                  label: Text(_isDownloading ? 'Mengunduh...' : 'Export ke Excel'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _summary.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              const Text('Belum ada data untuk periode ini', style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _summary.length,
                          itemBuilder: (context, index) {
                            final s = _summary[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  final userDetail = _detail.where((d) => d['user_id'] == s['user_id']).toList();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReportDetailScreen(nama: s['nama'], detail: userDetail),
                                    ),
                                  );
                                },
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
                                            s['nama'].toString().substring(0, 1).toUpperCase(),
                                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(s['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _StatItem(label: 'Hadir', value: '${s['total_hari_masuk'] ?? 0} hari'),
                                        _StatItem(label: 'Telat', value: '${s['total_telat'] ?? 0} kali'),
                                        _StatItem(label: 'Menit Telat', value: '${s['total_menit_telat'] ?? 0}'),
                                        _StatItem(label: 'Lupa Pulang', value: '${s['total_lupa_pulang'] ?? 0} kali'),
                                      ],
                                    ),
                                  ],
                                ),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}