import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class LeaveService {
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Crew: ajukan izin
  Future<Map<String, dynamic>> ajukanIzin({
    required String jenis,
    required String tanggalMulai,
    required String tanggalSelesai,
    String? alasan,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/leave'),
      headers: headers,
      body: jsonEncode({
        'jenis': jenis,
        'tanggal_mulai': tanggalMulai,
        'tanggal_selesai': tanggalSelesai,
        'alasan': alasan,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'message': data['message'] ?? 'Gagal mengajukan izin'};
  }

  // Crew: lihat riwayat izin sendiri
  Future<List<dynamic>> getMyLeave() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/leave/mine'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Manager: lihat semua pengajuan izin
  Future<List<dynamic>> getAllLeave() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/leave'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // Manager: approve/reject izin
  Future<Map<String, dynamic>> updateStatus(int id, String status, {String? catatan}) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/leave/$id/status'),
      headers: headers,
      body: jsonEncode({
        'status': status,
        'catatan_manajer': catatan,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'message': data['message'] ?? 'Gagal memproses izin'};
  }
}