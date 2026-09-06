import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class PeriodeService {
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<List<dynamic>> getAll() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/periode'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<Map<String, dynamic>> create(String nama, String tanggalMulai, String tanggalSelesai) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/periode'),
      headers: headers,
      body: jsonEncode({'nama': nama, 'tanggal_mulai': tanggalMulai, 'tanggal_selesai': tanggalSelesai}),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 201, 'message': data['message']};
  }

  Future<Map<String, dynamic>> delete(int id) async {
    final headers = await _authHeaders();
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/periode/$id'), headers: headers);
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  Future<Map<String, dynamic>> getReportByPeriode(int periodeId) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/report/periode?periode_id=$periodeId'),
      headers: headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {'summary': [], 'detail': []};
  }
}