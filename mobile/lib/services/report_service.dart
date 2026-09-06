import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ReportService {
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getMonthlyReport(int bulan, int tahun) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report/monthly?bulan=$bulan&tahun=$tahun'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'summary': [], 'detail': []};
  }

  Future<Map<String, dynamic>> downloadMonthlyExcel(int bulan, int tahun) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/report/export?bulan=$bulan&tahun=$tahun'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        return {'success': false, 'message': 'Gagal mengunduh laporan'};
      }

      // Simpan ke folder Downloads publik HP
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = 'rekap_absensi_${bulan}_$tahun.xlsx';
      final filePath = '${downloadsDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return {'success': true, 'path': filePath, 'fileName': fileName};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
  Future<Map<String, dynamic>> getMyReport(int bulan, int tahun) async {
  final headers = await _authHeaders();
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/report/mine?bulan=$bulan&tahun=$tahun'),
    headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'summary': {}, 'detail': []};
  }
}