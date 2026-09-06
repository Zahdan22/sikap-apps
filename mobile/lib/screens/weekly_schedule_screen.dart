import 'package:flutter/material.dart';
import '../services/schedule_service.dart';
import '../services/jamkerja_service.dart';
import '../services/jobdesk_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import 'manage_jamkerja_screen.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  DateTime _weekStart = _getMonday(DateTime.now());
  DateTime _selectedDay = DateTime.now();
  List<dynamic> _crewList = [];
  List<dynamic> _jamKerjaList = [];
  List<dynamic> _jobdeskList = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<int, int?> _selectedJamKerja = {};
  final Map<int, List<int>> _selectedJobdesk = {};

  static DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final List<String> _hariSingkat = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadInitialData();
  }

  void _loadInitialData() async {
    setState(() => _isLoading = true);
    final crew = await UserService().getAllCrew();
    final jamKerja = await JamKerjaService().getAll();
    final jobdesk = await JobdeskService().getAll();
    setState(() {
      _crewList = crew;
      _jamKerjaList = jamKerja;
      _jobdeskList = jobdesk;
    });
    await _loadScheduleForSelectedDay();
  }

  Future<void> _loadScheduleForSelectedDay() async {
    setState(() => _isLoading = true);
    final data = await ScheduleService().getByDate(_fmtDate(_selectedDay));

    _selectedJamKerja.clear();
    _selectedJobdesk.clear();

    for (var s in data) {
      final userId = s['user_id'];
      final match = _jamKerjaList.firstWhere(
        (o) =>
            o['jam_mulai'].toString().substring(0, 5) == s['jam_mulai'].toString().substring(0, 5) &&
            o['jam_selesai'].toString().substring(0, 5) == s['jam_selesai'].toString().substring(0, 5),
        orElse: () => null,
      );
      _selectedJamKerja[userId] = match != null ? match['id'] : null;
      _selectedJobdesk[userId] = List<int>.from((s['jobdesk'] as List).map((j) => j['id']));
    }

    setState(() => _isLoading = false);
  }

  void _gantiMinggu(int offset) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * offset));
      _selectedDay = _weekStart;
    });
    _loadScheduleForSelectedDay();
  }

  void _pilihHari(DateTime day) {
    setState(() => _selectedDay = day);
    _loadScheduleForSelectedDay();
  }

  void _pilihJobdesk(int crewId) {
    final currentSelected = List<int>.from(_selectedJobdesk[crewId] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pilih Jobdesk (maks 5)'),
          content: SizedBox(
            width: double.maxFinite,
            child: _jobdeskList.isEmpty
                ? const Text('Belum ada jobdesk terdaftar')
                : ListView(
                    shrinkWrap: true,
                    children: _jobdeskList.map<Widget>((jd) {
                      final isChecked = currentSelected.contains(jd['id']);
                      return CheckboxListTile(
                        activeColor: AppColors.primary,
                        title: Text('${jd['nama']} (${jd['singkatan']})'),
                        value: isChecked,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              if (currentSelected.length < 5) {
                                currentSelected.add(jd['id']);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Maksimal 5 jobdesk')),
                                );
                              }
                            } else {
                              currentSelected.remove(jd['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _selectedJobdesk[crewId] = currentSelected);
                Navigator.pop(context);
              },
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }

  void _simpanSemua() async {
    setState(() => _isSaving = true);

    final entries = _crewList.map<Map<String, dynamic>>((c) {
      final crewId = c['id'];
      final jamKerjaId = _selectedJamKerja[crewId];

      if (jamKerjaId == null) {
        return {'user_id': crewId, 'libur': true};
      }

      final opsi = _jamKerjaList.firstWhere((o) => o['id'] == jamKerjaId);
      return {
        'user_id': crewId,
        'jam_mulai': opsi['jam_mulai'].toString().substring(0, 5),
        'jam_selesai': opsi['jam_selesai'].toString().substring(0, 5),
        'durasi_jam': double.tryParse(opsi['durasi_jam'].toString()) ?? 0,
        'jobdesk_ids': _selectedJobdesk[crewId] ?? [],
      };
    }).toList();

    final result = await ScheduleService().bulkSave(_fmtDate(_selectedDay), entries);

    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

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
              ).then((_) => _loadInitialData());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () => _gantiMinggu(-1),
                  ),
                  Text(
                    '${_fmtDate(_weekStart)} s/d ${_fmtDate(_weekStart.add(const Duration(days: 6)))}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () => _gantiMinggu(1),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 68,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isSelected = _fmtDate(day) == _fmtDate(_selectedDay);
                    return GestureDetector(
                      onTap: () => _pilihHari(day),
                      child: Container(
                        width: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _hariSingkat[index],
                              style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : Colors.white70),
                            ),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : Colors.white,
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
            Expanded(
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _crewList.length,
                          itemBuilder: (context, index) {
                            final c = _crewList[index];
                            final crewId = c['id'];
                            final selectedJobdeskIds = _selectedJobdesk[crewId] ?? [];
                            final jobdeskLabels = selectedJobdeskIds
                                .map((id) => _jobdeskList.firstWhere((j) => j['id'] == id)['singkatan'])
                                .join(', ');

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                          child: Text(
                                            c['nama'].toString().substring(0, 1).toUpperCase(),
                                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(c['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    DropdownButtonFormField<int?>(
                                      initialValue: _selectedJamKerja[crewId],
                                      decoration: const InputDecoration(
                                        labelText: 'Jam Kerja',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: [
                                        const DropdownMenuItem(value: null, child: Text('Libur')),
                                        ..._jamKerjaList.map<DropdownMenuItem<int?>>(
                                          (o) => DropdownMenuItem(
                                            value: o['id'],
                                            child: Text(
                                              '${o['label']} (${o['jam_mulai'].toString().substring(0, 5)}-${o['jam_selesai'].toString().substring(0, 5)})',
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() => _selectedJamKerja[crewId] = value);
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.work_outline, size: 18),
                                      label: Text(jobdeskLabels.isEmpty ? 'Pilih Jobdesk' : jobdeskLabels),
                                      onPressed: () => _pilihJobdesk(crewId),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _simpanSemua,
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SIMPAN JADWAL HARI INI', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}