import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ScheduleService {
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Crew: lihat jadwal sendiri
  Future<List<dynamic>> getMySchedule() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/schedule/mine'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Manager: lihat semua jadwal
  Future<List<dynamic>> getAllSchedule() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/schedule'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Manager: bikin jadwal baru
  Future<Map<String, dynamic>> createSchedule({
    required int userId,
    required String tanggal,
    required String jamMulai,
    required String jamSelesai,
    required double durasiJam,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/schedule'),
      headers: headers,
      body: jsonEncode({
        'user_id': userId,
        'tanggal': tanggal,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'durasi_jam': durasiJam,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'message': data['message'] ?? 'Gagal membuat jadwal'};
  }

  // Manager: hapus jadwal
  Future<Map<String, dynamic>> deleteSchedule(int id) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/schedule/$id'),
      headers: headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'message': data['message'] ?? 'Gagal menghapus jadwal'};
  }

  Future<Map<String, dynamic>> bulkSave(String tanggal, List<Map<String, dynamic>> entries) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/schedule/bulk'),
      headers: headers,
      body: jsonEncode({'tanggal': tanggal, 'entries': entries}),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

Future<List<dynamic>> getByDate(String tanggal) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/schedule/date/$tanggal'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }
}