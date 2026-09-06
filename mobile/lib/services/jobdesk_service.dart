import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class JobdeskService {
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<List<dynamic>> getAll() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/jobdesk'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }
}