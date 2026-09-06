import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class UserService {
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getAllCrew() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> deleteCrew(int id) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/users/$id'),
      headers: headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'message': data['message'] ?? 'Gagal menghapus karyawan'};
  }

  Future<List<dynamic>> getCrewListSimple() async {
  final headers = await _authHeaders();
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/users/list'),
    headers: headers,
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  return [];
}
}