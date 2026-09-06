import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class SwapService {
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>> ajukanSwap(String tanggal, int targetId, String? alasan) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/swap'),
      headers: headers,
      body: jsonEncode({'tanggal': tanggal, 'target_id': targetId, 'alasan': alasan}),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 201, 'message': data['message']};
  }

  Future<List<dynamic>> getMySwap() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/swap/mine'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<List<dynamic>> getAllSwap() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/swap'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<Map<String, dynamic>> updateStatus(int id, String status, {String? catatan}) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/swap/$id/status'),
      headers: headers,
      body: jsonEncode({'status': status, 'catatan_manajer': catatan}),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }
}