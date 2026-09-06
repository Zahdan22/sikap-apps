import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/schedule_service.dart';
import '../theme/app_colors.dart';

class MyScheduleScreen extends StatefulWidget {
  final bool embedded;
  const MyScheduleScreen({super.key, this.embedded = false});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _scheduleMap = {};
  List<dynamic> _rekanKerja = [];
  bool _isLoadingRekan = false;
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _init();
  }

  void _init() async {
    await _loadUserId();
    _loadSchedule();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getInt('user_id');
  }

  void _loadSchedule() async {
    setState(() => _isLoading = true);
    final data = await ScheduleService().getMySchedule();

    final map = <DateTime, List<dynamic>>{};
    for (var s in data) {
      final tanggal = DateTime.parse(s['tanggal']);
      final key = DateTime(tanggal.year, tanggal.month, tanggal.day);
      map.putIfAbsent(key, () => []).add(s);
    }

    setState(() {
      _schedules = data;
      _scheduleMap = map;
      _isLoading = false;
    });

    _loadRekanKerja();
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _loadRekanKerja() async {
    if (_selectedDay == null) return;
    setState(() => _isLoadingRekan = true);
    final data = await ScheduleService().getByDate(_fmtDate(_selectedDay!));
    setState(() {
      _rekanKerja = data.where((s) => s['user_id'] != _myUserId).toList();
      _isLoadingRekan = false;
    });
  }

  List<dynamic> _getSchedulesForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _scheduleMap[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedSchedules = _selectedDay != null ? _getSchedulesForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Saya'), automaticallyImplyLeading: !widget.embedded),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2025, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      eventLoader: _getSchedulesForDay,
                      calendarStyle: CalendarStyle(
                        markerDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                        selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _loadRekanKerja();
                      },
                      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Jadwal Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          if (selectedSchedules.isEmpty)
                            const Text('Tidak ada jadwal di tanggal ini', style: TextStyle(color: Colors.black54))
                          else
                            ...selectedSchedules.map((s) {
                              final jobdeskList = (s['jobdesk'] as List?) ?? [];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${s['jam_mulai'].toString().substring(0, 5)} - ${s['jam_selesai'].toString().substring(0, 5)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Durasi: ${s['durasi_jam']} jam', style: const TextStyle(color: Colors.black54)),
                                      if (jobdeskList.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: jobdeskList.map<Widget>((j) {
                                            return Chip(
                                              label: Text(j['singkatan'], style: const TextStyle(fontSize: 12)),
                                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                              labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                              padding: EdgeInsets.zero,
                                              visualDensity: VisualDensity.compact,
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 16),
                          const Text('Jadwal Rekan Kerja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          if (_isLoadingRekan)
                            const Center(child: CircularProgressIndicator())
                          else if (_rekanKerja.isEmpty)
                            const Text('Tidak ada rekan kerja di tanggal ini', style: TextStyle(color: Colors.black54))
                          else
                            ..._rekanKerja.map((r) {
                              final jobdeskList = (r['jobdesk'] as List?) ?? [];
                              final jobdeskText = jobdeskList.map((j) => j['singkatan']).join(', ');
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(child: Text(r['nama'].toString().substring(0, 1).toUpperCase())),
                                  title: Text(r['nama']),
                                  subtitle: Text(
                                    '${r['jam_mulai'].toString().substring(0, 5)} - ${r['jam_selesai'].toString().substring(0, 5)}'
                                    '${jobdeskText.isNotEmpty ? ' • $jobdeskText' : ''}',
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}